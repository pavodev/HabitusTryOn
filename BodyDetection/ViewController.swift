import UIKit
import RealityKit
import ARKit
import Combine // (Remove if unused elsewhere)
import Photos

/// Detects simple poses from an ARBodyAnchor.
final class PoseDetector {
    private let def = ARSkeletonDefinition.defaultBody3D
    private var didDumpNames = false
    enum Hand { case left, right, either }

    private func pos(_ exact: String, for anchor: ARBodyAnchor) -> SIMD3<Float>? {
        guard let i = index(named: exact) else { return nil }
        return worldPosition(of: i, for: anchor)
    }

    private func index(named exact: String) -> Int? {
        ARSkeletonDefinition.defaultBody3D.jointNames.firstIndex(of: exact)
    }

    private func findIndex(containing key: String) -> Int? {
        def.jointNames.firstIndex { $0.localizedCaseInsensitiveContains(key) }
    }

    private func worldPosition(of idx: Int, for anchor: ARBodyAnchor) -> SIMD3<Float> {
        let local = anchor.skeleton.jointModelTransforms[idx]
        let world = simd_mul(anchor.transform, local)
        return SIMD3<Float>(world.columns.3.x, world.columns.3.y, world.columns.3.z)
    }

    func dumpJointNamesOnce() {
        guard !didDumpNames else { return }
        didDumpNames = true
        print("Body3D joints (\(def.jointNames.count)):", def.jointNames)
    }

    /// True if both wrists are above the head by a small margin.
    func isHandsUp(_ anchor: ARBodyAnchor) -> Bool {
        dumpJointNamesOnce()
        guard
            let li = index(named: "left_hand_joint")  ?? findIndex(containing: "left_hand"),
            let ri = index(named: "right_hand_joint") ?? findIndex(containing: "right_hand"),
            let hi = index(named: "head_joint")       ?? findIndex(containing: "head")
        else { return false }

        let LW = worldPosition(of: li, for: anchor)
        let RW = worldPosition(of: ri, for: anchor)
        let HD = worldPosition(of: hi, for: anchor)

        let margin: Float = 0.02 // ~2 cm
        return (LW.y > HD.y + margin) && (RW.y > HD.y + margin)
    }

    // (Kept for future use)
    func isTPose(_ anchor: ARBodyAnchor) -> Bool {
        guard
            let lsi = index(named: "left_shoulder_1_joint")  ?? findIndex(containing: "left_shoulder"),
            let rsi = index(named: "right_shoulder_1_joint") ?? findIndex(containing: "right_shoulder"),
            let lwi = index(named: "left_hand_joint")        ?? findIndex(containing: "left_hand"),
            let rwi = index(named: "right_hand_joint")       ?? findIndex(containing: "right_hand")
        else { return false }

        let LS = worldPosition(of: lsi, for: anchor)
        let RS = worldPosition(of: rsi, for: anchor)
        let LW = worldPosition(of: lwi, for: anchor)
        let RW = worldPosition(of: rwi, for: anchor)

        let yTol: Float = 0.10
        let rMin: Float = 0.20

        let leftHoriz  = hypot(LS.x - LW.x, LS.z - LW.z)
        let rightHoriz = hypot(RS.x - RW.x, RS.z - RW.z)

        let leftOK  = abs(LW.y - LS.y) < yTol && leftHoriz  > rMin
        let rightOK = abs(RW.y - RS.y) < yTol && rightHoriz > rMin
        return leftOK && rightOK
    }

    // (Kept for future use)
    private func isThumbsUp(prefix: String, anchor: ARBodyAnchor) -> Bool {
        guard
            let palm    = pos("\(prefix)_hand_joint", for: anchor),
            let thumb   = pos("\(prefix)_handThumbEnd_joint", for: anchor),
            let index   = pos("\(prefix)_handIndexEnd_joint", for: anchor),
            let middle  = pos("\(prefix)_handMidEnd_joint", for: anchor),
            let ring    = pos("\(prefix)_handRingEnd_joint", for: anchor),
            let pinky   = pos("\(prefix)_handPinkyEnd_joint", for: anchor)
        else { return false }

        let up = SIMD3<Float>(0, 1, 0)
        let thumbVec = thumb - palm
        let thumbLen = simd_length(thumbVec)
        if thumbLen < 0.05 { return false }

        let cosUp = simd_dot(simd_normalize(thumbVec), up)
        if cosUp < 0.65 { return false }

        let maxOtherY = max(index.y, middle.y, ring.y, pinky.y)
        if !(thumb.y > maxOtherY + 0.04) { return false }

        let curlTol: Float = 0.03
        let othersDown = (index.y < palm.y + curlTol) &&
                         (middle.y < palm.y + curlTol) &&
                         (ring.y   < palm.y + curlTol) &&
                         (pinky.y  < palm.y + curlTol)

        return othersDown
    }

    func isThumbsUp(_ anchor: ARBodyAnchor, hand: Hand = .either) -> Bool {
        switch hand {
        case .left:  return isThumbsUp(prefix: "left",  anchor: anchor)
        case .right: return isThumbsUp(prefix: "right", anchor: anchor)
        case .either:
            return isThumbsUp(prefix: "left", anchor: anchor)
                || isThumbsUp(prefix: "right", anchor: anchor)
        }
    }
}

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet var arView: ARView!

    // Capture button (circular shutter style)
    private let captureButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 36
        btn.layer.borderWidth = 3
        btn.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        btn.setTitle(nil, for: .normal)
        btn.tintColor = .clear
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        btn.accessibilityLabel = "Shutter"
        return btn
    }()

    // Preview overlay
    private var previewImageView: UIImageView?
    private var isUploading = false
    private var isShowingQROverlay = false

    // HUD hint while detecting pose
    private var hintContainer: UIView?
    private var hintLabel: UILabel?
    private var hintProgress: UIProgressView?
    private var hintSecondsBadge: UILabel?
    private var hintStack: UIStackView?

    // Countdown state
    private var countdownTimer: DispatchSourceTimer?
    private var countdownRemaining = 0
    private var countdownRemainingQR = 30;
    private var countdownLabel: UILabel?
    private var countdownActive: Bool { countdownTimer != nil }
    // private let countdownHaptic = UIImpactFeedbackGenerator(style: .light)

    // Pose detection & control
    private let poseDetector = PoseDetector()
    private var poseHoldStartTime: CFTimeInterval? = nil
    private let requiredHoldDuration: CFTimeInterval = 3.0
    private var lastAutoCaptureTime = 0.0
    private let autoCaptureCooldown: Double = 4.0
    private var autoCaptureEnabled = true
    private var poseImageView: UIImageView?
    
    // UI epoch + explicit HUD state
    private var uiEpoch: Int = 0
    private enum HUDMode { case idle, holding, hidden }
    private var hudMode: HUDMode = .idle

    // MARK: - HUD

    private func ensureHintHUD() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.ensureHintHUD() }
            return
        }
        guard hintContainer == nil else { return }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        container.layer.cornerRadius = 14
        container.clipsToBounds = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.80
        label.allowsDefaultTighteningForTruncation = true

        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        progress.progress = 0
        progress.transform = CGAffineTransform(scaleX: 1, y: 3.0)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        let progressHeight = progress.heightAnchor.constraint(equalToConstant: 6)
        progressHeight.priority = .defaultHigh
        progressHeight.isActive = true

        let secBadge = UILabel()
        secBadge.translatesAutoresizingMaskIntoConstraints = false
        secBadge.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        secBadge.textColor = .white
        secBadge.font = .systemFont(ofSize: 18, weight: .bold)
        secBadge.textAlignment = .center
        secBadge.isHidden = true
        secBadge.layer.cornerRadius = 8
        secBadge.clipsToBounds = true
        NSLayoutConstraint.activate([
            secBadge.widthAnchor.constraint(equalToConstant: 40),
            secBadge.heightAnchor.constraint(equalToConstant: 30)
        ])

        let hstack = UIStackView(arrangedSubviews: [label, secBadge])
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 8

        let vstack = UIStackView(arrangedSubviews: [hstack, progress])
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.axis = .vertical
        vstack.alignment = .fill
        vstack.spacing = 10

        container.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            vstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            vstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        // Create pose illustration at the bottom
        let poseImage = UIImageView()
        poseImage.translatesAutoresizingMaskIntoConstraints = false
        poseImage.contentMode = .scaleAspectFit
        poseImage.tintColor = .white  // For SF Symbols or template images

        // Try to load your custom SVG/image from assets
        // Replace "hands_up_pose" with your actual asset name
        if let image = UIImage(named: "hands_up_pose") {
            poseImage.image = image
        } else {
            // Fallback to SF Symbol if custom image not found
            poseImage.image = UIImage(systemName: "figure.arms.open")
        }

        view.addSubview(poseImage)
        NSLayoutConstraint.activate([
            poseImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            poseImage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            poseImage.widthAnchor.constraint(equalToConstant: 160),
            poseImage.heightAnchor.constraint(equalToConstant: 160)
        ])

        poseImageView = poseImage

        hintContainer = container
        hintLabel = label
        hintProgress = progress
        hintSecondsBadge = secBadge
        hintStack = vstack
    }

    private func setHUDIdle() {
        ensureHintHUD()
        
        // Always update the text, even if already idle
        hintLabel?.text = "Raise your hands above your head"
        hintProgress?.isHidden = true
        hintProgress?.progress = 0  // Reset progress
        hintSecondsBadge?.isHidden = true
        hintContainer?.isHidden = false
        hintContainer?.alpha = 1.0
        poseImageView?.isHidden = false
        poseImageView?.alpha = 1.0
        
        // Only animate if transitioning from another state
        if hudMode != .idle {
            hudMode = .idle
            UIView.animate(withDuration: 0.25) {
                self.hintContainer?.alpha = 1.0
            }
        } else {
            hudMode = .idle
        }
    }

    private func setHUDHolding(elapsed: CFTimeInterval, required: CFTimeInterval) {
        ensureHintHUD()
        
        // Always update the progress and remaining time
        let progress = Float(min(elapsed / required, 1.0))
        let remaining = Int(ceil(max(required - elapsed, 0)))
        
        hintProgress?.progress = progress
        hintSecondsBadge?.text = "\(remaining)s"
        
        // Only animate state change if not already in holding mode
        if hudMode != .holding {
            hudMode = .holding
            UIView.animate(withDuration: 0.2) {
                self.hintLabel?.text = "Hold steady…"
                self.hintProgress?.isHidden = false
                self.hintSecondsBadge?.isHidden = false
                self.poseImageView?.alpha = 1.0
            }
        }
    }

    private func hideHint() {
        guard hudMode != .hidden else { return }
        hudMode = .hidden
        // Hide instantly without animation to prevent delay in countdown
        hintContainer?.alpha = 0
        hintContainer?.isHidden = true
        poseImageView?.alpha = 0
        poseImageView?.isHidden = true
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        arView.session.delegate = self
        arView.renderOptions.insert(.disableMotionBlur)

        let config = ARBodyTrackingConfiguration()
        arView.session.run(config)

        // Initialize WordPress client with hardcoded credentials
        self.wpClient = WordPressClient(
            baseURL: URL(string: "https://vmelab2.lu.usi.ch/wordpress_habitusar")!,
            username: "photo_uploader",
            appPassword: "oBus X6rG HA8y 4DVa PhGN xCxP"
        )

        view.addSubview(captureButton)
        captureButton.isHidden = true  // Hide the manual capture button
        let bottomOffset: CGFloat = 32
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomOffset),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72)
        ])
        captureButton.addTarget(self, action: #selector(manualCapture), for: .touchUpInside)

        let countdownLbl = UILabel()
        countdownLbl.translatesAutoresizingMaskIntoConstraints = false
        countdownLbl.font = .systemFont(ofSize: 120, weight: .bold)
        countdownLbl.textColor = .white
        countdownLbl.textAlignment = .center
        countdownLbl.isHidden = true
        countdownLbl.layer.shadowColor = UIColor.black.cgColor
        countdownLbl.layer.shadowOpacity = 0.5
        countdownLbl.layer.shadowOffset = CGSize(width: 0, height: 2)
        countdownLbl.layer.shadowRadius = 6
        view.addSubview(countdownLbl)
        NSLayoutConstraint.activate([
            countdownLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLbl.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        countdownLabel = countdownLbl

        ensureHintHUD()
        setHUDIdle()
    }

    // MARK: - Capture
    @objc private func manualCapture() {
        stopCountdown()
        capturePhoto()
    }

    private func capturePhoto() {
        guard let frame = arView.session.currentFrame else { return }
        let img = CIImage(cvPixelBuffer: frame.capturedImage)
        let ctx = CIContext()
        guard let cgImg = ctx.createCGImage(img, from: img.extent) else { return }
        let uiImg = UIImage(cgImage: cgImg, scale: 1.0, orientation: .right)

        showPreview(uiImg)
    }

    private func showProcessingLabel() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        container.layer.cornerRadius = 14
        container.clipsToBounds = true
        container.tag = 998  // Tag for easy removal

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.text = "Processing the image..."

        container.addSubview(label)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    private func hideProcessingLabel() {
        view.viewWithTag(998)?.removeFromSuperview()
    }

    private func showPreview(_ img: UIImage) {
        captureButton.isHidden = true

        let iv = UIImageView(image: img)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tag = 999
        view.insertSubview(iv, at: 0)
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            iv.topAnchor.constraint(equalTo: view.topAnchor),
            iv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        previewImageView = iv

        // Show "Processing..." label
        showProcessingLabel()
        
        // Automatically upload the photo
        savePhoto()
    }

    private func showQROverlay(qrImage: UIImage, link: URL) {
        isShowingQROverlay = true

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.92)
        overlay.tag = 1000

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        let qrView = UIImageView(image: qrImage)
        qrView.translatesAutoresizingMaskIntoConstraints = false
        qrView.contentMode = .scaleAspectFit

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Scan to download your photo"
        lbl.font = .systemFont(ofSize: 20, weight: .semibold)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.numberOfLines = 0

        // Add countdown label
        let countdownLbl = UILabel()
        countdownLbl.translatesAutoresizingMaskIntoConstraints = false
        countdownLbl.text = "Auto-closing in \(countdownRemainingQR) seconds"
        countdownLbl.font = .systemFont(ofSize: 16, weight: .regular)
        countdownLbl.textColor = .gray
        countdownLbl.textAlignment = .center
        countdownLbl.numberOfLines = 1
        countdownLbl.tag = 1001  // Tag for updating

        container.addSubview(qrView)
        container.addSubview(lbl)
        container.addSubview(countdownLbl)
        overlay.addSubview(container)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 300),

            qrView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            qrView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            qrView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            qrView.heightAnchor.constraint(equalTo: qrView.widthAnchor),

            lbl.topAnchor.constraint(equalTo: qrView.bottomAnchor, constant: 16),
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            lbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            countdownLbl.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            countdownLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            countdownLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            countdownLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissQR))
        overlay.addGestureRecognizer(tap)

        // Countdown timer that updates every second
        var remainingSeconds = countdownRemainingQR
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak overlay, weak countdownLbl] timer in
            guard let self = self, let ov = overlay, ov.superview != nil else {
                timer.invalidate()
                return
            }
            
            remainingSeconds -= 1
            
            if remainingSeconds <= 0 {
                timer.invalidate()
                self.dismissQR()
            } else {
                countdownLbl?.text = "Auto-closing in \(remainingSeconds) second\(remainingSeconds == 1 ? "" : "s")"
            }
        }
        
        // Store the timer so it doesn't get deallocated
        RunLoop.current.add(timer, forMode: .common)
    }

    @objc private func dismissQR() {
        view.viewWithTag(1000)?.removeFromSuperview()
        isShowingQROverlay = false
        
        // Reset to idle state
        stopCountdown()
        lastAutoCaptureTime = 0
        poseHoldStartTime = nil
        dismissPreview()
        setHUDIdle()
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Networking client
    private var wpClient: WordPressClient?
    private let credsStore = KeychainCredentialsStore()

    private func promptForCredentials() {
        let alert = UIAlertController(title: "Connect to WordPress",
                                      message: "Enter your site URL (including https), username, and Application Password.",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Site URL (e.g. https://example.com/wordpress)"
            tf.text = "https://"
            tf.keyboardType = .URL
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        alert.addTextField { tf in
            tf.placeholder = "Username"
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        alert.addTextField { tf in
            tf.placeholder = "Application Password"
            tf.isSecureTextEntry = true
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.presentAlert(title: "Missing credentials", message: "Set WordPress credentials to enable uploads.")
        })

        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let urlStr = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let user   = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let pass   = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !urlStr.isEmpty, !user.isEmpty, !pass.isEmpty, URL(string: urlStr) != nil else {
                self.presentAlert(title: "Invalid input", message: "Please enter a valid URL, username and application password.")
                return
            }

            if self.credsStore.save(urlString: urlStr, username: user, appPassword: pass),
               let creds = self.credsStore.load() {
                self.wpClient = WordPressClient(credentials: creds)
                self.presentAlert(title: "Saved", message: "WordPress credentials stored securely.")
            } else {
                self.presentAlert(title: "Could not save", message: "Keychain save failed.")
            }
        })

        present(alert, animated: true)
    }

    @objc private func savePhoto() {
        if isUploading { return }
        isUploading = true

        guard let client = wpClient else {
            isUploading = false
            hideProcessingLabel()
            presentAlert(title: "Not configured", message: "Set WordPress credentials to upload.")
            promptForCredentials()
            return
        }

        guard let image = previewImageView?.image else {
            isUploading = false
            hideProcessingLabel()
            return
        }

        let saveLocally = false
        if saveLocally {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }

        Task { @MainActor in
            do {
                let res = try await client.upload(image: image, title: "AR snapshot")

                guard let mediaURL = URL(string: res.media_url),
                      let qrURL = URL(string: res.qr_url) else {
                    throw NSError(domain: "Upload", code: -4, userInfo: [NSLocalizedDescriptionKey: "Bad URL(s) in server response"])
                }

                let qrImage = try await client.fetchImage(at: qrURL)
                
                // Hide processing label before showing QR
                self.hideProcessingLabel()
                self.showQROverlay(qrImage: qrImage, link: mediaURL)
            } catch {
                self.hideProcessingLabel()
                self.presentAlert(title: "Upload failed", message: error.localizedDescription)
                // After showing error, go back to idle
                self.dismissPreview()
            }

            self.isUploading = false
        }
    }

    @objc private func retakePhoto() {
        stopCountdown()
        lastAutoCaptureTime = 0
        poseHoldStartTime = nil
        dismissPreview()
        setHUDIdle()
    }

    private func dismissPreview() {
        view.viewWithTag(999)?.removeFromSuperview()
        view.viewWithTag(998)?.removeFromSuperview()  // Remove processing label if still there

        if let iv = previewImageView {
            iv.removeFromSuperview()
            previewImageView = nil
        }

        captureButton.isHidden = true  // Keep it hidden since we don't use manual capture
    }

    // Lock orientation to portrait only
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        captureButton.layer.cornerRadius = captureButton.bounds.height / 2
    }

    // MARK: - Countdown helpers
    private func startCountdown(seconds: Int = 5) {
        guard countdownTimer == nil else { return }
        countdownRemaining = seconds

        print("🔔 Countdown started with \(seconds) seconds")
        
        // Show initial countdown number
        countdownLabel?.text = "\(countdownRemaining)"
        countdownLabel?.isHidden = false
        
        // Prepare and trigger initial haptic
        // countdownHaptic.prepare()
        // countdownHaptic.impactOccurred()

        // Create timer that fires after 1 second, then repeats
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.countdownRemaining -= 1
            print("⏱️ Countdown tick: \(self.countdownRemaining)")
            if self.countdownRemaining <= 0 {
                print("📸 Countdown complete, capturing photo")
                self.stopCountdown()
                self.capturePhoto()
                return
            }
            self.countdownLabel?.text = "\(self.countdownRemaining)"
            
            // Prepare haptic ahead of time for smooth feedback
            // self.countdownHaptic.prepare()
            // self.countdownHaptic.impactOccurred()
        }
        countdownTimer = timer
        timer.resume()
        print("✅ Timer resumed")
    }

    private func stopCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
        countdownLabel?.isHidden = true
    }

    // MARK: - ARSessionDelegate (auto-capture on pose)
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard autoCaptureEnabled else { return }
        guard previewImageView == nil, !isUploading else { return }
        guard !countdownActive else { return }  // Don't check poses during photo countdown
        guard !isShowingQROverlay else { return }

        let now = CACurrentMediaTime()
        guard now - lastAutoCaptureTime > autoCaptureCooldown else { return }

        // Detect "hands up" (if no ARBodyAnchor at all, this stays false)
        var handsUpDetected = false
        for anchor in anchors {
            guard let body = anchor as? ARBodyAnchor else { continue }
            if poseDetector.isHandsUp(body) {
                handsUpDetected = true
                break
            }
        }

        if handsUpDetected {
            // User has hands up
            if poseHoldStartTime == nil {
                // Start the 3-second timer
                poseHoldStartTime = now
                uiEpoch += 1
                print("✋ Started 3-second hold timer")
            }

            if let start = poseHoldStartTime {
                let elapsed = now - start
                if elapsed >= requiredHoldDuration {
                    // 3 seconds completed! Start the photo countdown
                    print("✅ 3 seconds complete! Starting photo countdown")
                    poseHoldStartTime = nil
                    lastAutoCaptureTime = now
                    uiEpoch += 1
                    let epoch = uiEpoch
                    DispatchQueue.main.async { [weak self, epoch] in
                        guard let self = self, epoch == self.uiEpoch else { return }
                        self.hideHint()
                        self.startCountdown(seconds: 5)
                    }
                } else {
                    // Still holding, update UI with progress
                    let epoch = uiEpoch
                    DispatchQueue.main.async { [weak self, epoch] in
                        guard let self = self, epoch == self.uiEpoch else { return }
                        self.setHUDHolding(elapsed: elapsed, required: self.requiredHoldDuration)
                    }
                }
            }
        } else {
            // Hands are NOT up
            // Reset the timer if it was running
            if poseHoldStartTime != nil {
                print("❌ Hands lowered! Resetting 3-second timer")
                poseHoldStartTime = nil
                uiEpoch += 1
                let epoch = uiEpoch
                DispatchQueue.main.async { [weak self, epoch] in
                    guard let self = self, epoch == self.uiEpoch else { return }
                    self.setHUDIdle()
                }
            } else if hudMode != .idle {
                // Ensure HUD is in idle state
                let epoch = uiEpoch
                DispatchQueue.main.async { [weak self, epoch] in
                    guard let self = self, epoch == self.uiEpoch else { return }
                    self.setHUDIdle()
                }
            }
        }
    }
}
