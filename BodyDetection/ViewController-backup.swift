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
