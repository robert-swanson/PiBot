//
//  TouchControlViewController.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/28/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit
import SpriteKit

class TouchControlViewController: UIViewController, DPadDelegate {
	
	@IBOutlet weak var speed: UISlider!
	@IBOutlet weak var servo: UISlider!
	
	@IBOutlet weak var leftSKView: SKView!
	@IBOutlet weak var rightSKView: SKView!
	@IBOutlet weak var connectionIcon: UIBarButtonItem!
	@IBOutlet weak var tools: UINavigationItem!
	@IBOutlet weak var connectButton: UIBarButtonItem!
	
	var network: NetworkManager?
	var tabView: TabBarController?
	var lScene: DPadScene?
	var rScene: DPadScene?
	
	var lWithoutSpeed = CGFloat(0.0)
	var rWithoutSpeed = CGFloat(0.0)
	var orientation: UIInterfaceOrientation = UIInterfaceOrientation.portrait
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabView = self.parent as? TabBarController
		network = tabView?.network
		lScene = leftSKView.scene as? DPadScene
		lScene?.dPadDelegate = self
		lScene?.touchControl = self
		rScene = rightSKView.scene as? DPadScene
		rScene?.dPadDelegate = self
		rScene?.touchControl = self
		lScene?.joystick?.texture = SKTexture(image: #imageLiteral(resourceName: "joystick"))
		lScene?.joystick?.scale(to: CGSize(width: 100, height: 100))
		lScene?.background?.scale(to: CGSize(width: 150, height: 150))
		connectionIcon.image = #imageLiteral(resourceName: "disconnected").withRenderingMode(.alwaysOriginal)
		if let act = UserDefaults.standard.value(forKey: SettingsViewController.setting.connectOnStartUp.toString()) as! Bool?{
			if(act && !(network!.TCPConnected())){
				let _ = Timer.scheduledTimer(timeInterval: TimeInterval(0.1), target: network!, selector: #selector(network?.setupConnection), userInfo: nil, repeats: false)
			}
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		stop()
		lScene?.joystick?.position = CGPoint(x: 0, y: 0)
	}
	
	override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
		orientation = toInterfaceOrientation
		
		if(toInterfaceOrientation == .portrait){
			lScene?.joystick?.texture = SKTexture(image: #imageLiteral(resourceName: "joystick"))
			lScene?.joystick?.scale(to: CGSize(width: 100, height: 100))
			lScene?.background?.scale(to: CGSize(width: 150, height: 150))
		}else{
			lScene?.joystick?.texture = SKTexture(image: #imageLiteral(resourceName: "joystickUpDown"))
			rScene?.joystick?.texture = SKTexture(image: #imageLiteral(resourceName: "joystickUpDown"))
			lScene?.joystick?.scale(to: CGSize(width: 80, height: 80))
			rScene?.joystick?.scale(to: CGSize(width: 80, height: 80))
			lScene?.background?.scale(to: CGSize(width: 120, height: 120))
			rScene?.background?.scale(to: CGSize(width: 120, height: 120))
		}
	}
	
	@IBAction func displayActions(_ sender: Any) {
		tabView?.displayActions(sender)
	}
	
	@IBAction func SpeedChanged(_ sender: UISlider) {
		tabView?.network.send(message: Message(leftSpeed: lWithoutSpeed * CGFloat(speed.value), rightSpeed: rWithoutSpeed * CGFloat(speed.value)))
	}
	@IBAction func servoChanged(_ sender: Any) {
		tabView?.network.send(message: Message(servoValue: CGFloat(servo.value)))
	}
	
	@IBAction func toggleConnect(_ sender: Any) {
		if(network?.TCPConnected())!{
			network?.closeTCP()
		}else{
			network?.setupConnection()
		}
	}
	@IBAction func connectAction(_ sender: UIBarButtonItem) {
		if(network?.TCPConnected())!{
			network?.closeTCP()
		}else{
			network?.setupConnection()
		}
	}
	
	func stop(){
		lWithoutSpeed = 0
		rWithoutSpeed = 0
		network?.send(message: Message(leftSpeed: 0, rightSpeed: 0))
	}
	
	func joystickPositionDidChange(to position: CGPoint, withBackgroundRadius rad: CGFloat, joystick: SKSpriteNode) {
		let message = getRobotInstuc(fromJoystickPosition: position, withBackgroundRadius: rad, joystick: joystick)
		if(message != nil){
			network?.send(message: message!)
		}
		if(position.x == 0 && position.y == 0){
			network?.send(message: Message(type: .stop))
		}
	}
	
	func getRobotInstuc(fromJoystickPosition pos: CGPoint, withBackgroundRadius rad: CGFloat, joystick: SKSpriteNode) -> Message?{
		if(orientation == .portrait || orientation == .portraitUpsideDown){
			if pos == CGPoint(x: 0, y: 0){
				lWithoutSpeed = 0
				rWithoutSpeed = 0
				return Message(leftSpeed: 0, rightSpeed: 0)
			}
			let dist = sqrt(pow(pos.x, 2) + pow(pos.y,2))/rad
			var ang = atan(pos.y/pos.x)
			if pos.x < 0{
				ang += CGFloat.pi
			}
			if ang < 0{
				ang += CGFloat.pi * 2
			}
			var lmult: CGFloat = 1
			var rmult: CGFloat = 1
			if ang <= CGFloat.pi/2{//1st Quad
				rmult = (4*ang)/(CGFloat.pi)-1
			}else if ang <= CGFloat.pi{//2nd Quad
				lmult = (4*(CGFloat.pi-ang))/(CGFloat.pi)-1
			}else if ang <= 3*CGFloat.pi/2{//3rd  Quad
				lmult = -1
				let relang = (ang - CGFloat.pi) / (CGFloat.pi / 2)
				rmult = 1 - 2 * relang
			}else{
				rmult = -1
				let relang = (ang - 3/2 * CGFloat.pi)/(CGFloat.pi/2)
				lmult = -1+2*relang
			}
			lWithoutSpeed = lmult * dist
			rWithoutSpeed = rmult * dist
			lmult *= CGFloat(speed.value) * dist
			rmult *= CGFloat(speed.value) * dist
			return Message(leftSpeed: lmult, rightSpeed: rmult)
		}else{
			var l = lWithoutSpeed
			var r = rWithoutSpeed
			if(joystick == lScene?.joystick){
				l = (pos.y > 0) ? min(1,pos.y/rad) : max(-1,pos.y/rad)
				if(lWithoutSpeed == l){
					return nil
				}
				lWithoutSpeed = l
			}else{
				r = (pos.y > 0) ? min(1,pos.y/rad) : max(-1,pos.y/rad)
				if(rWithoutSpeed == r){
					return nil
				}
				rWithoutSpeed = r
			}
			l *= CGFloat(speed.value)
			r *= CGFloat(speed.value)
			return Message(leftSpeed: l, rightSpeed: r)

		}
		
	}

	override var shouldAutorotate: Bool{
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		if UIDevice.current.userInterfaceIdiom == .phone {
			return .allButUpsideDown
		} else {
			return .all
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
