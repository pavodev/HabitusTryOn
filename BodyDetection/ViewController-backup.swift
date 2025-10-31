/** BACKUP 1 **/

/*import UIKit
import RealityKit
import ARKit
import Combine
import Photos

class ViewController: UIViewController {
    @IBOutlet var arView: ARView!

    // Keep a reference so we can cancel the load publisher
    private var loadCancellable: AnyCancellable?

    // The .body anchor that RealityKit will drive for us
    private let bodyAnchor = AnchorEntity(.body)

    // Capture button
    private let captureButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Capture", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Preview overlay
    private var previewImageView: UIImageView?
    private var saveButton: UIButton?
    private var retakeButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Let RealityKit configure and run the AR session
        arView.automaticallyConfigureSession = true

        // Require body tracking
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("Body tracking requires an A12+ device with a rear camera.")
        }
        let config = ARBodyTrackingConfiguration()
        arView.session.run(config)

        // Add our body anchor
        arView.scene.addAnchor(bodyAnchor)

        // Load the skinned, body-tracked dress
        loadCancellable = Entity.loadBodyTrackedAsync(named: "character/asrl-finished-fix").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error loading model: \(error)")
                }
                self.loadCancellable?.cancel()
            },
            receiveValue: { [weak self] entity in
                guard let self = self,
                      let dressEntity = entity as? BodyTrackedEntity else {
                    print("Loaded entity is not a BodyTrackedEntity")
                    return
                }
                self.bodyAnchor.addChild(dressEntity)
                self.loadCancellable?.cancel()
            }
        )
    }

    // MARK: - Capture UI

    private func setupCaptureButton() {
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 100),
            captureButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    }

    @objc private func capturePhoto() {
        // Hide UI
        captureButton.isHidden = true

        // Take snapshot including AR content
        arView.snapshot(saveToHDR: false) { [weak self] image in
            guard let self = self, let image = image else { return }
            self.showPreview(for: image)
        }
    }

    private func showPreview(for image: UIImage) {
        // Dim background
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .black.withAlphaComponent(0.6)
        overlay.tag = 999
        view.addSubview(overlay)

        // Image view
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 20,
                                 y: 100,
                                 width: view.bounds.width - 40,
                                 height: view.bounds.height - 200)
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        view.addSubview(imageView)
        previewImageView = imageView

        // Save button
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.backgroundColor = .green
        saveBtn.layer.cornerRadius = 8
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        saveBtn.addTarget(self, action: #selector(savePhoto), for: .touchUpInside)
        view.addSubview(saveBtn)
        saveButton = saveBtn

        // Retake button
        let retakeBtn = UIButton(type: .system)
        retakeBtn.setTitle("Retake", for: .normal)
        retakeBtn.setTitleColor(.white, for: .normal)
        retakeBtn.backgroundColor = .red
        retakeBtn.layer.cornerRadius = 8
        retakeBtn.translatesAutoresizingMaskIntoConstraints = false
        retakeBtn.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        view.addSubview(retakeBtn)
        retakeButton = retakeBtn

        // Layout buttons
        NSLayoutConstraint.activate([
            saveBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveBtn.widthAnchor.constraint(equalToConstant: 100),
            saveBtn.heightAnchor.constraint(equalToConstant: 44),

            retakeBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            retakeBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            retakeBtn.widthAnchor.constraint(equalToConstant: 100),
            retakeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func savePhoto() {
        guard let image = previewImageView?.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        dismissPreview()
    }

    @objc private func retakePhoto() {
        dismissPreview()
    }

    private func dismissPreview() {
        view.viewWithTag(999)?.removeFromSuperview()
        previewImageView?.removeFromSuperview()
        saveButton?.removeFromSuperview()
        retakeButton?.removeFromSuperview()
        // Show UI again
        captureButton.isHidden = false
    }

    // Lock orientation to portrait only
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
} 
*/


/** BACKUP 2 */
//import UIKit
//import RealityKit
//import ARKit
//import Combine
//import Photos
//
///// Detects simple poses from an ARBodyAnchor.
//final class PoseDetector {
//    private let def = ARSkeletonDefinition.defaultBody3D
//    private var didDumpNames = false
//    enum Hand { case left, right, either }
//
//    private func pos(_ exact: String, for anchor: ARBodyAnchor) -> SIMD3<Float>? {
//        guard let i = index(named: exact) else { return nil }
//        return worldPosition(of: i, for: anchor)
//    }
//    
//    private func index(named exact: String) -> Int? {
//        ARSkeletonDefinition.defaultBody3D.jointNames.firstIndex(of: exact)
//    }
//
//    private func findIndex(containing key: String) -> Int? {
//        def.jointNames.firstIndex { $0.localizedCaseInsensitiveContains(key) }
//    }
//
//    private func worldPosition(of idx: Int, for anchor: ARBodyAnchor) -> SIMD3<Float> {
//        let local = anchor.skeleton.jointModelTransforms[idx]
//        let world = simd_mul(anchor.transform, local)
//        return SIMD3<Float>(world.columns.3.x, world.columns.3.y, world.columns.3.z)
//    }
//
//    func dumpJointNamesOnce() {
//        guard !didDumpNames else { return }
//        didDumpNames = true
//        print("Body3D joints (\(def.jointNames.count)):", def.jointNames)
//    }
//
//    /// True if both wrists are above the head by a small margin.
//    func isHandsUp(_ anchor: ARBodyAnchor) -> Bool {
//        dumpJointNamesOnce()
//        guard
//            let li = index(named: "left_hand_joint")  ?? findIndex(containing: "left_hand"),
//            let ri = index(named: "right_hand_joint") ?? findIndex(containing: "right_hand"),
//            let hi = index(named: "head_joint")       ?? findIndex(containing: "head")
//        else { return false }
//        
//        let LW = worldPosition(of: li, for: anchor)
//        let RW = worldPosition(of: ri, for: anchor)
//        let HD = worldPosition(of: hi, for: anchor)
//        
//        let margin: Float = 0.02 // ~2 cm
//        return (LW.y > HD.y + margin) && (RW.y > HD.y + margin)
//    }
//
//    /// Simple T-pose: wrists roughly at shoulder height and extended outwards.
//    func isTPose(_ anchor: ARBodyAnchor) -> Bool {
//        guard
//            let lsi = index(named: "left_shoulder_1_joint")  ?? findIndex(containing: "left_shoulder"),
//            let rsi = index(named: "right_shoulder_1_joint") ?? findIndex(containing: "right_shoulder"),
//            let lwi = index(named: "left_hand_joint")        ?? findIndex(containing: "left_hand"),
//            let rwi = index(named: "right_hand_joint")       ?? findIndex(containing: "right_hand")
//        else { return false }
//
//        let LS = worldPosition(of: lsi, for: anchor)
//        let RS = worldPosition(of: rsi, for: anchor)
//        let LW = worldPosition(of: lwi, for: anchor)
//        let RW = worldPosition(of: rwi, for: anchor)
//
//        // Vertical tolerance + horizontal spread in XZ plane
//        let yTol: Float = 0.10  // ~10 cm
//        let rMin: Float = 0.20  // >= 20 cm away from shoulder
//
//        let leftHoriz  = hypot(LS.x - LW.x, LS.z - LW.z)
//        let rightHoriz = hypot(RS.x - RW.x, RS.z - RW.z)
//
//        let leftOK  = abs(LW.y - LS.y) < yTol && leftHoriz  > rMin
//        let rightOK = abs(RW.y - RS.y) < yTol && rightHoriz > rMin
//        return leftOK && rightOK
//    }
//    
//    // Detect a thumbs-up for one hand using joint world positions.
//    private func isThumbsUp(prefix: String, anchor: ARBodyAnchor) -> Bool {
//        guard
//            let palm    = pos("\(prefix)_hand_joint", for: anchor),
//            let thumb   = pos("\(prefix)_handThumbEnd_joint", for: anchor),
//            let index   = pos("\(prefix)_handIndexEnd_joint", for: anchor),
//            let middle  = pos("\(prefix)_handMidEnd_joint", for: anchor),
//            let ring    = pos("\(prefix)_handRingEnd_joint", for: anchor),
//            let pinky   = pos("\(prefix)_handPinkyEnd_joint", for: anchor)
//        else { return false }
//
//        let up = SIMD3<Float>(0, 1, 0)
//        let thumbVec = thumb - palm
//        let thumbLen = simd_length(thumbVec)
//        if thumbLen < 0.05 { return false } // at least ~5 cm away from palm
//
//        // Thumb should point roughly upwards in world space
//        let cosUp = simd_dot(simd_normalize(thumbVec), up)
//        if cosUp < 0.65 { return false } // within ~49° of vertical
//
//        // Thumb clearly above other fingertips
//        let maxOtherY = max(index.y, middle.y, ring.y, pinky.y)
//        if !(thumb.y > maxOtherY + 0.04) { return false } // ≥4 cm above others
//
//        // Other fingers should not be up high (simple curl proxy)
//        let curlTol: Float = 0.03
//        let othersDown = (index.y < palm.y + curlTol) &&
//                         (middle.y < palm.y + curlTol) &&
//                         (ring.y   < palm.y + curlTol) &&
//                         (pinky.y  < palm.y + curlTol)
//
//        return othersDown
//    }
//
//    /// Public API: thumbs up on a specific hand or either hand.
//    func isThumbsUp(_ anchor: ARBodyAnchor, hand: Hand = .either) -> Bool {
//        switch hand {
//        case .left:  return isThumbsUp(prefix: "left",  anchor: anchor)
//        case .right: return isThumbsUp(prefix: "right", anchor: anchor)
//        case .either:
//            return isThumbsUp(prefix: "left", anchor: anchor)
//                || isThumbsUp(prefix: "right", anchor: anchor)
//        }
//    }
//}
//
//class ViewController: UIViewController, ARSessionDelegate {
//    @IBOutlet var arView: ARView!
//
//    // Keep a reference so we can cancel the load publisher
//    private var loadCancellable: AnyCancellable?
//
//    // The .body anchor that RealityKit will drive for us
//    private let bodyAnchor = AnchorEntity(.body)
//
//    // Capture button (circular shutter style)
//    private let captureButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        btn.backgroundColor = .white              // filled inner circle
//        btn.layer.cornerRadius = 36               // will be 72x72, so radius = 36
//        btn.layer.borderWidth = 3                 // subtle outer ring
//        btn.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
//        btn.setTitle(nil, for: .normal)           // no text
//        btn.tintColor = .clear                    // no symbol by default
//        // subtle shadow for separation
//        btn.layer.shadowColor = UIColor.black.cgColor
//        btn.layer.shadowOpacity = 0.25
//        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
//        btn.layer.shadowRadius = 4
//        btn.accessibilityLabel = "Shutter"
//        return btn
//    }()
//
//    // Preview overlay
//    private var previewImageView: UIImageView?
//    private var saveButton: UIButton?
//    private var retakeButton: UIButton?
//    // Prevent double-taps while uploading
//    private var isUploading = false
//    // Spinner shown inside the Save button while uploading
//    private var saveSpinner: UIActivityIndicatorView?
//    // --- Auto-capture countdown state ---
//    private var countdownTimer: DispatchSourceTimer?
//    private var countdownRemaining = 0
//    private var countdownLabel: UILabel?
//    private var countdownActive: Bool { countdownTimer != nil }
//    
//    // --- Auto-capture pose detection state ---
//    private let poseDetector = PoseDetector()
//    private var poseHoldFrames = 0
//    private let requiredHoldFrames = 8        // ~0.25s at 60 fps
//    private var lastAutoCaptureTime = 0.0
//    private let autoCaptureCooldown: Double = 4.0
//    private var autoCaptureEnabled = true      // toggle as needed
//
//    // Networking client injected from Keychain (created in viewDidLoad)
//    private var wpClient: WordPressClient?
//    private let credsStore = KeychainCredentialsStore()
//
//    // Fine-tuning for how the body-tracked model sits on the skeleton (in meters)
//    // Positive z nudges the model slightly back toward the skeleton if it looks in front
//    // Adjust these if your asset appears offset relative to the tracked body
//    private let modelXOffset: Float = 0   // e.g. -0.02 to lower slightly
//    private let modelYOffset: Float = -0.055   // e.g. 0.04–0.10 to push back onto the body
//    private let modelZOffset: Float = 0    // e.g. slight lateral nudge if needed
//    private let modelYawDegrees: Float = 0.0 // e.g. 180 if the asset faces the wrong way
//    private let modelXScale: Float = 0.0095  // 20% narrower (0.01 * 0.8)
//    private let modelYScale: Float = 0.0095 // Slight vertical shrink
//    private let modelZScale: Float = 0.0095  // 20% narrower (0.01 * 0.8)
//
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Forearm occlusion cylinders
//    private var leftForearmOccluder: ModelEntity?
//    private var rightForearmOccluder: ModelEntity?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCaptureButton()
//
//        // Load WordPress credentials from Keychain and create client if available
//        self.wpClient = WordPressClient(baseURL: URL(string: "https://vmelab2.lu.usi.ch/wordpress_habitusar")!,username: "photo_uploader", appPassword: "oBus X6rG HA8y 4DVa PhGN xCxP")
//        
//        /*if let creds = credsStore.load() {
//            self.wpClient = WordPressClient(credentials: creds)
//        } else {
//            // Prompt once to collect and store credentials securely
//            DispatchQueue.main.async { [weak self] in
//                self?.promptForCredentials()
//            }
//        }*/
//    }
//    /// Prompts for WordPress credentials and stores them in Keychain.
//    private func promptForCredentials() {
//        let alert = UIAlertController(title: "Connect to WordPress",
//                                      message: "Enter your site URL (including https), username, and Application Password.",
//                                      preferredStyle: .alert)
//        alert.addTextField { tf in
//            tf.placeholder = "Site URL (e.g. https://example.com/wordpress)"
//            tf.text = "https://"
//            tf.keyboardType = .URL
//            tf.autocapitalizationType = .none
//            tf.autocorrectionType = .no
//        }
//        alert.addTextField { tf in
//            tf.placeholder = "Username"
//            tf.autocapitalizationType = .none
//            tf.autocorrectionType = .no
//        }
//        alert.addTextField { tf in
//            tf.placeholder = "Application Password"
//            tf.isSecureTextEntry = true
//            tf.autocapitalizationType = .none
//            tf.autocorrectionType = .no
//        }
//
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
//            self.presentAlert(title: "Missing credentials", message: "Set WordPress credentials to enable uploads.")
//        })
//
//        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
//            let urlStr = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//            let user   = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//            let pass   = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//
//            guard !urlStr.isEmpty, !user.isEmpty, !pass.isEmpty, URL(string: urlStr) != nil else {
//                self.presentAlert(title: "Invalid input", message: "Please enter a valid URL, username and application password.")
//                return
//            }
//
//            if self.credsStore.save(urlString: urlStr, username: user, appPassword: pass),
//               let creds = self.credsStore.load() {
//                self.wpClient = WordPressClient(credentials: creds)
//                self.presentAlert(title: "Saved", message: "WordPress credentials stored securely.")
//            } else {
//                self.presentAlert(title: "Could not save", message: "Keychain save failed.")
//            }
//        })
//
//        present(alert, animated: true)
//    }
//    
//    // Recursive entity visitor
//    private func visitEntity(_ entity: Entity, _ closure: (Entity) -> Void) {
//        closure(entity)
//        for child in entity.children {
//            visitEntity(child, closure)
//        }
//    }
//    
//    private func applyOcclusionMaterial(to entity: Entity) {
//        // Replace "robot_body" with your actual mesh name
//        if let robotMesh = entity.findEntity(named: "ace_PLY") {
//            if var modelComponent = robotMesh.components[ModelComponent.self] {
//                modelComponent.materials = [OcclusionMaterial()]
//                robotMesh.components.set(modelComponent)
//                print("✅ Occlusion applied to robot mesh")
//            }
//        } else {
//            print("❌ Robot mesh not found - check entity names")
//        }
//    }
//    
//    private func printEntityTree(_ entity: Entity, level: Int) {
//        let indent = String(repeating: "  ", count: level)
//        let hasModel = entity.components[ModelComponent.self] != nil
//        print("\(indent)- '\(entity.name)' [Model: \(hasModel)] Children: \(entity.children.count)")
//        
//        for child in entity.children {
//            printEntityTree(child, level: level + 1)
//        }
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        // We'll configure the AR session ourselves
//        arView.automaticallyConfigureSession = false
//
//        // (Occlusion toggles removed per request)
//
//        guard ARBodyTrackingConfiguration.isSupported else {
//            fatalError("Body tracking requires an A12+ device with a rear camera.")
//        }
//
//        let config = ARBodyTrackingConfiguration()
//        config.isAutoFocusEnabled = true
//
//        // ---- Depth-based occlusion (LiDAR) ----
//        // People Segmentation occlusion isn't available on ARBodyTrackingConfiguration,
//        // so we use sceneDepth (and the smoothed variant) for occlusion instead.
//        if ARBodyTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
//            config.frameSemantics.insert(.sceneDepth)
//            print("Depth occlusion: sceneDepth enabled")
//        }
//        if ARBodyTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
//            config.frameSemantics.insert(.smoothedSceneDepth)
//            print("Depth occlusion: smoothedSceneDepth enabled")
//        }
//
//        // Start/Reset the session to apply semantics
//        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
//        arView.environment.sceneUnderstanding.options.insert(.occlusion)
//        
//        arView.session.delegate = self
//        
//        // Add our body anchor
//        arView.scene.addAnchor(bodyAnchor)
//
//        // Load the skinned, body-tracked dress
//        // Try loading as a regular Entity first
//        loadCancellable = Entity.loadBodyTrackedAsync(named: "asrl-hollow-thinner").sink(
//            receiveCompletion: { completion in
//                if case let .failure(error) = completion {
//                    print("Error loading model: \(error)")
//                }
//                self.loadCancellable?.cancel()
//            },
//            receiveValue: { [weak self] entity in
//                guard let self = self,
//                      let bodyEntity = entity as? BodyTrackedEntity else {
//                    print("Not a BodyTrackedEntity")
//                    return
//                }
//                
//                print("IT WORKED");
//                
//                /*
//                // Apply occlusion using material slots
//                if var modelComp = bodyEntity.components[ModelComponent.self] {
//                    print("BodyTrackedEntity has \(modelComp.materials.count) materials")
//                    
//                    // Apply occlusion to robot materials (slots 0, 1, 2)
//                    // Slot 3 is the dress, keep it visible
//                    if modelComp.materials.count >= 4 {
//                        modelComp.materials[1] = OcclusionMaterial()
//                        modelComp.materials[2] = OcclusionMaterial()
//                        modelComp.materials[3] = OcclusionMaterial()
//                        bodyEntity.components.set(modelComp)
//                        print("✅ Applied OcclusionMaterial to slots 0-2 (robot)")
//                    } else {
//                        print("⚠️ Expected 4 materials, found \(modelComp.materials.count)")
//                    }
//                } else {
//                    print("❌ No ModelComponent on BodyTrackedEntity")
//                }
//                */
//                
//                // Apply transforms
//                var t = bodyEntity.transform
//                t.scale = SIMD3<Float>(modelXScale, modelYScale, modelZScale)
//                t.translation.x += self.modelXOffset
//                t.translation.y += self.modelYOffset
//                t.translation.z += self.modelZOffset
//                if self.modelYawDegrees != 0.0 {
//                    let radians = self.modelYawDegrees * .pi / 180.0
//                    let yaw = simd_quatf(angle: radians, axis: SIMD3<Float>(0, 1, 0))
//                    t.rotation = simd_mul(yaw, t.rotation)
//                }
//                bodyEntity.transform = t
//
//                // Load occlusion mesh
//                // self.loadOcclusionMesh(for: bodyEntity)
//
//                self.bodyAnchor.addChild(bodyEntity)
//                self.setupForearmOccluders(bodyEntity: bodyEntity)
//                
//                print("📋 Available joint names:", bodyEntity.jointNames)
//                self.printAllJointNames(in: bodyEntity)
//                
//                self.loadCancellable?.cancel()
//            }
//        )
//    }
//
//
//private func updateForearmOccluderPositions(for bodyAnchor: ARBodyAnchor) {
//        guard let leftOccluder = leftForearmOccluder,
//              let rightOccluder = rightForearmOccluder else { return }
//
//        // Get indices of forearm joints
//        guard let leftForearmIndex = bodyAnchor.skeleton.definition.jointNames.firstIndex(of: "left_forearm_joint"),
//              let rightForearmIndex = bodyAnchor.skeleton.definition.jointNames.firstIndex(of: "right_forearm_joint") else {
//            return
//        }
//
//        // Get joint model transforms
//        let leftJointTransform = bodyAnchor.skeleton.jointModelTransforms[leftForearmIndex]
//        let rightJointTransform = bodyAnchor.skeleton.jointModelTransforms[rightForearmIndex]
//
//        // Convert to world transform
//        let leftWorldTransform = simd_mul(bodyAnchor.transform, leftJointTransform)
//        let rightWorldTransform = simd_mul(bodyAnchor.transform, rightJointTransform)
//
//        // Update position and orientation of occluders
//        leftOccluder.position = SIMD3<Float>(leftWorldTransform.columns.3.x,
//                                             leftWorldTransform.columns.3.y,
//                                             leftWorldTransform.columns.3.z)
//        leftOccluder.orientation = simd_quatf(leftWorldTransform)
//
//        rightOccluder.position = SIMD3<Float>(rightWorldTransform.columns.3.x,
//                                              rightWorldTransform.columns.3.y,
//                                              rightWorldTransform.columns.3.z)
//        rightOccluder.orientation = simd_quatf(rightWorldTransform)
//
//        // Adjust cylinder height orientation so it matches forearm axis roughly
//        // Here a simple approach: rotate cylinder by -90 deg around X to align vertical axis to forearm axis
//        // Adjust if needed for your model precision
//
//        let rotationAdjustment = simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(1, 0, 0))
//        leftOccluder.orientation = simd_mul(leftOccluder.orientation, rotationAdjustment)
//        rightOccluder.orientation = simd_mul(rightOccluder.orientation, rotationAdjustment)
//    }
//
//     private func setupForearmOccluders(bodyEntity: BodyTrackedEntity) {
//        // Remove old occluders if any
//        leftForearmOccluder?.removeFromParent()
//        rightForearmOccluder?.removeFromParent()
//
//        // Create cylinders for left and right forearms
//        let radius: Float = 0.035
//        let height: Float = 0.20
//
//        let leftCylinder = ModelEntity(mesh: .generateCylinder(height: height, radius: radius))
//        leftCylinder.name = "leftForearmOccluder"
//        leftCylinder.model?.materials = [OcclusionMaterial()]
//
//        let rightCylinder = ModelEntity(mesh: .generateCylinder(height: height, radius: radius))
//        rightCylinder.name = "rightForearmOccluder"
//        rightCylinder.model?.materials = [OcclusionMaterial()]
//
//        // Add to the body anchor for now; positions will be updated on each frame
//        bodyAnchor.addChild(leftCylinder)
//        bodyAnchor.addChild(rightCylinder)
//
//        self.leftForearmOccluder = leftCylinder
//        self.rightForearmOccluder = rightCylinder
//    }
//
//    private func loadOcclusionMesh(for parentEntity: Entity) {
//        Entity.loadAsync(named: "asrl-hollow-thinner").sink { completion in
//            if case let .failure(error) = completion {
//                print("Error loading occlusion model: \(error)")
//            }
//        } receiveValue: { [weak self] occlusionEntity in
//            guard let self = self else { return }
//            
//            // Apply OcclusionMaterial to all mesh parts
//            self.visitEntity(occlusionEntity) { entity in
//                if var modelComponent = entity.components[ModelComponent.self] {
//                    modelComponent.materials = [OcclusionMaterial()]
//                    entity.components.set(modelComponent)
//                }
//            }
//
//            // Scale the occlusion mesh (slightly smaller to avoid over-occlusion)
//            var t = occlusionEntity.transform
//            t.scale = SIMD3<Float>(0.95, 0.95, 0.95)
//            occlusionEntity.transform = t
//
//            // Add occlusion mesh as child to the parent entity
//            parentEntity.addChild(occlusionEntity)
//        }
//        .store(in: &cancellables) // Make sure you have a Set<AnyCancellable> property in your class
//    }
//
//
//    
//    private func printAllJointNames(in entity: Entity, level: Int = 0) {
//        let indent = String(repeating: "  ", count: level)
//        print("\(indent)- \(entity.name)")
//        
//        for child in entity.children {
//            printAllJointNames(in: child, level: level + 1)
//        }
//    }
//    
//    private func applySpineOffset(to bodyEntity: BodyTrackedEntity) {
//        guard let spineIndex = bodyEntity.jointNames.firstIndex(of: "spine_7_joint") else {
//            print("NO ENTITY")
//            return }
//        
//        var jointTransforms = bodyEntity.jointTransforms
//        var spineTransform = jointTransforms[spineIndex]
//        
//        let pitchDegrees: Float = -8.0
//        let pitchRadians = pitchDegrees * .pi / 180.0
//        let pitchRotation = simd_quatf(angle: pitchRadians, axis: SIMD3<Float>(1, 0, 0))
//        
//        spineTransform.rotation = simd_mul(pitchRotation, spineTransform.rotation)
//        jointTransforms[spineIndex] = spineTransform
//        bodyEntity.jointTransforms = jointTransforms
//    }
//
//    private func presentAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//
//    /// Shows a full-screen overlay with the QR image and a Close button.
//    private func showQROverlay(qrImage: UIImage, link: URL) {
//        // Full-screen dimmed overlay
//        let overlay = UIView(frame: view.bounds)
//        overlay.backgroundColor = .black.withAlphaComponent(0.7)
//        overlay.tag = 1001
//        overlay.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(overlay)
//
//        // Constrain overlay to fill the view
//        NSLayoutConstraint.activate([
//            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            overlay.topAnchor.constraint(equalTo: view.topAnchor),
//            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//
//        // QR image
//        let imgView = UIImageView(image: qrImage)
//        imgView.tag = 1002
//        imgView.translatesAutoresizingMaskIntoConstraints = false
//        imgView.contentMode = .scaleAspectFit
//        imgView.backgroundColor = .white
//        imgView.layer.cornerRadius = 8
//        imgView.clipsToBounds = true
//        overlay.addSubview(imgView)
//
//        // Link label
//        let label = UILabel()
//        label.tag = 1003
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = link.absoluteString
//        label.textColor = .white
//        label.font = .systemFont(ofSize: 12)
//        label.numberOfLines = 2
//        label.textAlignment = .center
//        overlay.addSubview(label)
//
//        // Close button (style like Retake button)
//        let close = UIButton(type: .system)
//        close.tag = 1004
//        close.translatesAutoresizingMaskIntoConstraints = false
//        close.setTitle("Retake", for: .normal)
//        close.setTitleColor(.black, for: .normal)
//        close.backgroundColor = .white
//        close.layer.cornerRadius = 8
//        close.addTarget(self, action: #selector(dismissQROverlay), for: .touchUpInside)
//        overlay.addSubview(close)
//
//        // Layout inside overlay
//        NSLayoutConstraint.activate([
//            imgView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
//            imgView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
//            imgView.widthAnchor.constraint(equalToConstant: 240),
//            imgView.heightAnchor.constraint(equalTo: imgView.widthAnchor),
//
//            label.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 12),
//            label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
//            label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),
//
//            close.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
//            close.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
//            close.widthAnchor.constraint(equalToConstant: 100),
//            close.heightAnchor.constraint(equalToConstant: 44)
//        ])
//    }
//
//    @objc private func dismissQROverlay() {
//        // Remove overlay (and everything inside it)
//        view.viewWithTag(1001)?.removeFromSuperview()
//
//        // Safety: in case older overlays added subviews directly to the view
//        view.viewWithTag(1002)?.removeFromSuperview() // QR image
//        view.viewWithTag(1003)?.removeFromSuperview() // label
//        view.viewWithTag(1004)?.removeFromSuperview() // close button
//    }
//
//    // MARK: - Capture UI
//
//    private func setupCaptureButton() {
//        view.addSubview(captureButton)
//        NSLayoutConstraint.activate([
//            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            captureButton.widthAnchor.constraint(equalToConstant: 72),
//            captureButton.heightAnchor.constraint(equalToConstant: 72)
//        ])
//        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
//        captureButton.addTarget(self, action: #selector(shutterDown), for: .touchDown)
//        captureButton.addTarget(self, action: #selector(shutterUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
//    }
//
//    @objc private func shutterDown() {
//        UIView.animate(withDuration: 0.08) {
//            self.captureButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
//        }
//    }
//
//    @objc private func shutterUp() {
//        UIView.animate(withDuration: 0.12, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [.allowUserInteraction], animations: {
//            self.captureButton.transform = .identity
//        }, completion: nil)
//    }
//
//    // White flash effect (like Camera.app)
//    private func shutterFlash() {
//        // Remove any previous flash (safety)
//        view.viewWithTag(2001)?.removeFromSuperview()
//
//        let flash = UIView()
//        flash.tag = 2001
//        flash.backgroundColor = .white
//        flash.alpha = 0.0
//        flash.isUserInteractionEnabled = false
//        flash.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(flash)
//
//        // Pin to full screen
//        NSLayoutConstraint.activate([
//            flash.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            flash.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            flash.topAnchor.constraint(equalTo: view.topAnchor),
//            flash.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//
//        // Quick fade in, then fade out and remove
//        UIView.animate(withDuration: 0.06, animations: {
//            flash.alpha = 1.0
//        }) { _ in
//            UIView.animate(withDuration: 0.25, animations: {
//                flash.alpha = 0.0
//            }) { _ in
//                flash.removeFromSuperview()
//            }
//        }
//    }
//
//    @objc private func capturePhoto() {
//        // Haptic feedback on capture
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.prepare()
//        generator.impactOccurred()
//
//        // White flash visual
//        shutterFlash()
//
//        // Hide UI
//        captureButton.isHidden = true
//
//        // Take snapshot including AR content (with occlusion applied)
//        arView.snapshot(saveToHDR: false) { [weak self] image in
//            guard let self = self, let image = image else { return }
//            self.showPreview(for: image)
//        }
//    }
//
//    private func showPreview(for image: UIImage) {
//        // Dim background
//        let overlay = UIView(frame: view.bounds)
//        overlay.backgroundColor = .black.withAlphaComponent(0.6)
//        overlay.tag = 999
//        view.addSubview(overlay)
//
//        // Image view
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        imageView.frame = CGRect(x: 20,
//                                 y: 100,
//                                 width: view.bounds.width - 40,
//                                 height: view.bounds.height - 200)
//        imageView.layer.borderColor = UIColor.white.cgColor
//        imageView.layer.borderWidth = 2
//        view.addSubview(imageView)
//        previewImageView = imageView
//
//        // Save button
//        let saveBtn = UIButton(type: .system)
//        saveBtn.setTitle("Save", for: .normal)
//        saveBtn.setTitleColor(.white, for: .normal)
//        saveBtn.backgroundColor = .green
//        saveBtn.layer.cornerRadius = 8
//        saveBtn.translatesAutoresizingMaskIntoConstraints = false
//        saveBtn.addTarget(self, action: #selector(savePhoto), for: .touchUpInside)
//        view.addSubview(saveBtn)
//        saveButton = saveBtn
//
//        // Retake button
//        let retakeBtn = UIButton(type: .system)
//        retakeBtn.setTitle("Retake", for: .normal)
//        retakeBtn.setTitleColor(.white, for: .normal)
//        retakeBtn.backgroundColor = .red
//        retakeBtn.layer.cornerRadius = 8
//        retakeBtn.translatesAutoresizingMaskIntoConstraints = false
//        retakeBtn.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
//        view.addSubview(retakeBtn)
//        retakeButton = retakeBtn
//
//        // Layout buttons
//        NSLayoutConstraint.activate([
//            saveBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            saveBtn.widthAnchor.constraint(equalToConstant: 100),
//            saveBtn.heightAnchor.constraint(equalToConstant: 44),
//
//            retakeBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
//            retakeBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            retakeBtn.widthAnchor.constraint(equalToConstant: 100),
//            retakeBtn.heightAnchor.constraint(equalToConstant: 44)
//        ])
//    }
//
//    @objc private func savePhoto() {
//        // Prevent double-taps
//        if isUploading { return }
//        isUploading = true
//
//        // Ensure we have a configured client
//        guard let client = wpClient else {
//            isUploading = false
//            presentAlert(title: "Not configured", message: "Set your WordPress credentials to upload.")
//            promptForCredentials()
//            return
//        }
//
//        guard let image = previewImageView?.image else {
//            isUploading = false
//            return
//        }
//
//        // Optional: also save locally
//        let saveLocally = false
//        if saveLocally {
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//        }
//
//        // Disable Save and Retake buttons, show uploading state
//        saveButton?.isEnabled = false
//        saveButton?.alpha = 0.6
//        saveButton?.setTitle("Uploading…", for: .normal)
//        retakeButton?.isEnabled = false
//        retakeButton?.alpha = 0.6
//
//        // Show spinner in the Save button
//        if saveSpinner == nil {
//            let spinner = UIActivityIndicatorView(style: .medium)
//            spinner.translatesAutoresizingMaskIntoConstraints = false
//            if let saveBtn = self.saveButton {
//                saveBtn.setTitle("", for: .normal) // hide text while spinning
//                saveBtn.addSubview(spinner)
//                NSLayoutConstraint.activate([
//                    spinner.centerXAnchor.constraint(equalTo: saveBtn.centerXAnchor),
//                    spinner.centerYAnchor.constraint(equalTo: saveBtn.centerYAnchor)
//                ])
//                spinner.startAnimating()
//                self.saveSpinner = spinner
//            }
//        }
//
//        // Async upload + fetch QR using WordPressClient
//        Task { @MainActor in
//            do {
//                let res = try await client.upload(image: image, title: "AR snapshot")
//
//                guard let mediaURL = URL(string: res.media_url),
//                      let qrURL = URL(string: res.qr_url) else {
//                    throw NSError(domain: "Upload", code: -4, userInfo: [NSLocalizedDescriptionKey: "Bad URL(s) in server response"])
//                }
//
//                let qrImage = try await client.fetchImage(at: qrURL)
//                self.showQROverlay(qrImage: qrImage, link: mediaURL)
//            } catch {
//                self.presentAlert(title: "Upload failed", message: error.localizedDescription)
//            }
//
//            // Teardown spinner & restore UI
//            self.saveSpinner?.stopAnimating()
//            self.saveSpinner?.removeFromSuperview()
//            self.saveSpinner = nil
//            self.saveButton?.setTitle("Save", for: .normal)
//            self.saveButton?.isEnabled = true
//            self.saveButton?.alpha = 1.0
//            self.retakeButton?.isEnabled = true
//            self.retakeButton?.alpha = 1.0
//            self.isUploading = false
//
//            // Dismiss the preview overlay (returns to AR view; QR overlay stays visible if shown)
//            self.dismissPreview()
//        }
//    }
//
//    @objc private func retakePhoto() {
//       // Stop any pending countdown and reset state so detection can re-arm immediately
//        stopCountdown()
//        lastAutoCaptureTime = 0
//        poseHoldFrames = 0
//        dismissPreview()
//    }
//
//    private func dismissPreview() {
//        // Remove overlay
//        view.viewWithTag(999)?.removeFromSuperview()
//
//        // Remove and nil out preview UI so pose detection can re-arm
//        if let iv = previewImageView {
//            iv.removeFromSuperview()
//            previewImageView = nil
//        }
//        if let btn = saveButton {
//            btn.removeFromSuperview()
//            saveButton = nil
//        }
//        if let btn = retakeButton {
//            btn.removeFromSuperview()
//            retakeButton = nil
//        }
//        if let spinner = saveSpinner {
//            spinner.stopAnimating()
//            spinner.removeFromSuperview()
//            saveSpinner = nil
//        }
//
//        // Show UI again
//        captureButton.isHidden = false
//    }
//
//    // Lock orientation to portrait only
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .portrait
//    }
//
//    override var shouldAutorotate: Bool {
//        return false
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        // Keep the button perfectly circular if constraints change
//        captureButton.layer.cornerRadius = captureButton.bounds.height / 2
//    }
//    
//    // MARK: - Countdown helpers
//    private func startCountdown(seconds: Int = 5) {
//        // Avoid double countdowns
//        guard countdownTimer == nil else { return }
//
//        countdownRemaining = seconds
//
//        // Big center label
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 72, weight: .bold)
//        label.textColor = .white
//        label.backgroundColor = UIColor.black.withAlphaComponent(0.35)
//        label.layer.cornerRadius = 16
//        label.clipsToBounds = true
//        label.text = "\(countdownRemaining)"
//        view.addSubview(label)
//        countdownLabel = label
//
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
//            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
//        ])
//
//        // Haptic on start
//        let startHaptic = UIImpactFeedbackGenerator(style: .light)
//        startHaptic.impactOccurred()
//
//        // Timer: tick every second
//        let timer = DispatchSource.makeTimerSource(queue: .main)
//        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
//        timer.setEventHandler { [weak self] in
//            guard let self = self else { return }
//            self.countdownRemaining -= 1
//            if self.countdownRemaining <= 0 {
//                self.stopCountdown()
//                self.capturePhoto()
//                return
//            }
//            self.countdownLabel?.text = "\(self.countdownRemaining)"
//            let tick = UIImpactFeedbackGenerator(style: .light)
//            tick.impactOccurred()
//        }
//        countdownTimer = timer
//        timer.resume()
//    }
//
//    private func stopCountdown() {
//        countdownTimer?.cancel()
//        countdownTimer = nil
//        countdownLabel?.removeFromSuperview()
//        countdownLabel = nil
//    }
//    
//    // MARK: - ARSessionDelegate (auto-capture on pose)
//    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        guard autoCaptureEnabled else { return }
//        // Don't auto-shoot while a preview is visible or during upload
//        guard previewImageView == nil, !isUploading else { return }
//        guard !countdownActive else { return }
//        
//        // if let bodyEntity = bodyAnchor.children.first as? BodyTrackedEntity {
//        //         applySpineOffset(to: bodyEntity)
//        // }
//
//        let now = CACurrentMediaTime()
//        guard now - lastAutoCaptureTime > autoCaptureCooldown else { return }
//
//        for anchor in anchors {
//            guard let body = anchor as? ARBodyAnchor else { continue }
//            guard let arBodyAnchor = anchor as? ARBodyAnchor else { continue }
//
//            // (Custom geometry occluders removed per request)
//            updateForearmOccluderPositions(for: arBodyAnchor)
//            
//            // Choose which pose to use:
//            let poseDetected = poseDetector.isTPose(body) // or: poseDetector.isTPose(body)
//
//            if poseDetected {
//                poseHoldFrames += 1
//                if poseHoldFrames == 1 || poseHoldFrames % 5 == 0 {
//                    print("Pose progressing… frames=\(poseHoldFrames)")
//                }
//                if poseHoldFrames >= requiredHoldFrames {
//                    poseHoldFrames = 0
//                    lastAutoCaptureTime = now
//                    DispatchQueue.main.async { [weak self] in
//                        // self?.capturePhoto()
//                        self?.startCountdown(seconds: 5)
//                    }
//                }
//            } else {
//                if poseHoldFrames != 0 { print("Pose RESET at \(poseHoldFrames) frames") }
//                poseHoldFrames = 0
//            }
//        }
//    }
//}
