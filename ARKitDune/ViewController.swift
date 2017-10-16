import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
//    var scene : SCNScene?
    var hangarNode : SCNNode!
//    var sceneNode : SCNNode?
    var animation : CAAnimation?
    var longestDuration : Double? = 0
    let light = SCNLight()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var debugSwitch: UISwitch!
    
    var session : ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupScene()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        session.run(configuration)
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupScene() {
        sceneView.delegate = self
        
        sceneView.session = session
        
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        DispatchQueue.main.async {
            let hangarScene = SCNScene(named: "art.scnassets/hangar.scn")!
            self.hangarNode = hangarScene.rootNode.childNode(withName: "hangar", recursively: true)
        }
    }
    
    @IBAction func toggleDebug(_ sender: Any) {
        if debugSwitch.isOn {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        } else {
            sceneView.debugOptions = []
        }
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
            self.light.type = .directional
            self.light.color = UIColor.white
            self.light.castsShadow = true
            
            let lightNode = SCNNode()
            lightNode.light = self.light
            lightNode.eulerAngles = SCNVector3Make(-45, 0, 0)
            lightNode.position = SCNVector3Make(0, 0, 1)
            
            self.sceneView.scene.rootNode.addChildNode(lightNode)
            
            // MARK: Floor
            
            let floor = UIImage(named: "art.scnassets/floor.png")!
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            plane.firstMaterial?.diffuse.contents = floor
            plane.firstMaterial?.lightingModel = .physicallyBased
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.name = "planeAnchor"
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
            
            // MARK: Hangar
            
            self.hangarNode?.scale = SCNVector3(0.004, 0.004, 0.004)
            self.hangarNode?.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            node.addChildNode(self.hangarNode!)
        }
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor,
//            let planeNode = node.childNode(withName: "planeAnchor", recursively: true),
//            let plane = planeNode.geometry as? SCNPlane
//            else { return }
//
//        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//        plane.width = CGFloat(planeAnchor.extent.x)
//        plane.height = CGFloat(planeAnchor.extent.z)
//    }
    
//    func placeObject() {
//        let scene = SCNScene(named: "art.scnassets/hangar.scn")!
//        let hangarNode = scene.rootNode.childNode(withName: "hangar", recursively: true)!
//        print(hangarNode.scale)
//        let gateNode = hangarNode.childNode(withName: "gate", recursively: true)!
//
//        hangarNode.enumerateChildNodes({ (child, stop) in
//            let animationKeys = child.animationKeys
//
//            if !animationKeys.isEmpty {
//                for key: String in animationKeys {
//                    self.animation = child.animation(forKey: key)
//                    self.animation?.usesSceneTimeBase = false
//
//                    let duration = Double((animation?.duration)!)
//                    if duration > self.longestDuration! {
//                        self.longestDuration = duration
//                    }
//                }
//            }
//        })
//
//        gateNode.enumerateChildNodes({ (child, stop) in
//            let animationKeys = child.animationKeys
//            if !animationKeys.isEmpty {
//                for key : String in animationKeys {
//                    self.animation = child.animation(forKey: key)
//                    self.animation?.usesSceneTimeBase = false
//
//                    let duration = Double((animation?.duration)!)
//
//                    if duration > self.longestDuration! {
//                        self.longestDuration = duration
//                    }
//                }
//            }
//        })
//
//        self.sceneNode = hangarNode
//        self.sceneNode?.eulerAngles = SCNVector3Make(45, 0, 0)
//        self.sceneNode?.position = SCNVector3Make(0, 0, -2.5)
//        self.sceneView.pointOfView?.addChildNode(sceneNode!)
//
//        light.type = .directional
//        light.spotOuterAngle = 45
//        light.color = UIColor.white
//        light.castsShadow = true
//
//        let lightNode = SCNNode()
//        lightNode.light = light
//        lightNode.eulerAngles = SCNVector3Make(-45, 0, 0)
//        lightNode.position = SCNVector3Make(0, 1, 1)
//
//        self.sceneView.pointOfView?.addChildNode(lightNode)
//
//    }
}
