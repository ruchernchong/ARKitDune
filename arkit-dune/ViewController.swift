import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var sceneNode : SCNNode?
    let light = SCNLight()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var start: UIButton!
    
    var session : ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let estimate = session.currentFrame?.lightEstimate
        
        if estimate == nil {
            return
        }
        
        let intensity = estimate!.ambientIntensity / 40
        light.intensity = intensity
        sceneView.scene.lightingEnvironment.intensity = intensity
        }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
    }
    
    func createBox() {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        
        light.type = .spot
//        light.spotOuterAngle = 10
        light.color = UIColor.red
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3Make(0, 0, 1)
        
        self.sceneView.pointOfView?.addChildNode(lightNode)
        
        let boxMaterial = UIImage(named: "checkered.png")
        
        let boxNode = SCNNode(geometry: box)
        boxNode.geometry?.firstMaterial?.diffuse.contents = boxMaterial
        boxNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
        boxNode.eulerAngles = SCNVector3Make(45, 45, 0)
        boxNode.position = SCNVector3Make(0, 0, -0.5)
        boxNode.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 1, 0, 0)
        
        let animation = CABasicAnimation(keyPath: "position.z")
        animation.byValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAAnimationLinear)
        animation.duration = 10
        
        boxNode.addAnimation(animation, forKey: "rotate")
        
        self.sceneView.pointOfView?.addChildNode(boxNode)
    }
    
    @IBAction func start(_ sender: Any) {
        createBox()
    }
}

