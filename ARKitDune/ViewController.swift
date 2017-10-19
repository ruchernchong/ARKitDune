import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    let configuration = ARWorldTrackingConfiguration()
    let light = SCNLight()
    
    var hangarNode : SCNNode!
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var reset: UIButton!
    
    var session : ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupLights()
        setupConfig()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Mark: Setup the configuration settings
    
    func setupConfig() {
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        session.run(configuration)
    }
    
    // Mark: Setup the scene
    
    func setupScene() {
        sceneView.delegate = self
        
        sceneView.session = session
        
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        DispatchQueue.main.async {
            let hangarScene = SCNScene(named: "art.scnassets/Hangar.scn")!
            self.hangarNode = hangarScene.rootNode.childNode(withName: "hangar", recursively: true)
        }
    }
    
    // Mark: Setup the lightings
    
    func setupLights() {
        light.type = .directional
        light.color = UIColor.white
        light.castsShadow = true
        light.shadowMode = .deferred
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.eulerAngles = SCNVector3Make(-45, 0, 0)
        lightNode.position = SCNVector3Make(0, 0, 1)
        
        self.sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let estimate = session.currentFrame?.lightEstimate
        
        if estimate == nil {
            return
        }
        
        let intensity = estimate!.ambientIntensity
        light.intensity = intensity
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else  { return }
        
        DispatchQueue.main.async {
            // MARK: Floor
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x * 5), height: CGFloat(planeAnchor.extent.z * 5))
            plane.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
            plane.firstMaterial?.lightingModel = .physicallyBased
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.name = "planeAnchor"
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
            
            // MARK: Hangar
            
            self.hangarNode?.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            node.addChildNode(self.hangarNode!)
            
            // MARK: Disable Plane Detection after object is being added
            
            self.configuration.planeDetection = []
            self.session.run(self.configuration)
        }
    }
    
    // Mark: ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        showMessage(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        showMessage(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        showMessage(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        let alert = UIAlertController(title: "Session Interrupted", message: "The AR session has been interrupted. The session will now restart.", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Session interruption ended. Restarting the session."
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "An error occurred while trying to setup an AR session.\nError: \(error.localizedDescription)"
        resetTracking()
    }
    
    func showMessage(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        let message : String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            message = "Move the device around to detect horizontal surfaces."
            
        case .normal:
            message = ""
            
        case .limited(.initializing):
            message = "Initialising AR session. Please wait..."
            
        case .notAvailable:
            message = "Camera tracking is not available."
            
        case .limited(.excessiveMotion):
            message = "Tracking Limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking Limited - Point the device at an area with more visible surface details or improved lighting conditions."
            
        }
        
        messageLabel.text = message
        messageView.isHidden = message.isEmpty
    }
    
    func resetTracking() {
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func reset(_ sender: Any) {
        messageLabel.text = "Tracking reset."
        resetTracking()
    }
}
