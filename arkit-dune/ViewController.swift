import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var sceneNode : SCNNode?
    var animation : CAAnimation?
    var longestDuration : Double? = 0
    let light = SCNLight()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var session : ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
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
        
        let intensity = estimate!.ambientIntensity
        light.intensity = intensity
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    func placeObject() {
        let scene = SCNScene(named: "art.scnassets/hangar.scn")!
        let hangarNode = scene.rootNode.childNode(withName: "hangar", recursively: true)!
        let gateNode = hangarNode.childNode(withName: "gate", recursively: true)!
        
        hangarNode.enumerateChildNodes({ (child, stop) in
            let animationKeys = child.animationKeys
            
            if !animationKeys.isEmpty {
                for key: String in animationKeys {
                    self.animation = child.animation(forKey: key)
                    self.animation?.usesSceneTimeBase = false
                    
                    let duration = Double((animation?.duration)!)
                    if duration > self.longestDuration! {
                        self.longestDuration = duration
                    }
                }
            }
        })
        
        gateNode.enumerateChildNodes({ (child, stop) in
            let animationKeys = child.animationKeys
            if !animationKeys.isEmpty {
                for key : String in animationKeys {
                    self.animation = child.animation(forKey: key)
                    self.animation?.usesSceneTimeBase = false
                    
                    let duration = Double((animation?.duration)!)
                    
                    if duration > self.longestDuration! {
                        self.longestDuration = duration
                    }
                }
            }
        })
        
        self.sceneNode = hangarNode
        self.sceneNode?.eulerAngles = SCNVector3Make(45, 0, 0)
        self.sceneNode?.position = SCNVector3Make(0, 0, -2.5)
        self.sceneView.pointOfView?.addChildNode(sceneNode!)
        
        light.type = .directional
        light.spotOuterAngle = 45
        light.color = UIColor.white
        light.castsShadow = true
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.eulerAngles = SCNVector3Make(-45, 0, 0)
        lightNode.position = SCNVector3Make(0, 1, 1)
        
        self.sceneView.pointOfView?.addChildNode(lightNode)
        
    }
    
    @IBAction func start(_ sender: Any) {
        placeObject()
        self.disableButton()

        let timer = Timer.scheduledTimer(timeInterval: longestDuration!, target: self, selector: #selector(self.enableButton), userInfo: nil, repeats: false)
    }
    
    func disableButton() {
        self.start.isEnabled = false
        self.start.setTitle("Started", for: .disabled)
    }
    
    @objc func enableButton () {
        self.start.isEnabled = true
        self.start.setTitle("Click here to Start", for: .normal)
    }
}
