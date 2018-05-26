//
//  AcellerometerControlViewController.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/28/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit
import WebKit
import CoreMotion

class AcceleromterControlViewController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate, WKUIDelegate {
	// MARK: - Paramaters
	var network: NetworkManager?
	var tabView: TabBarController?
	@IBOutlet weak var webView: WKWebView!
	var url: URL? = nil
	var tabBarHide: Timer?
	var zero: [Double] = [0,0,0]
	
	var camAng: CGFloat = 8.25
	var longStart: CGPoint?
	
	@objc var track = false
	var calibrateNext = false
	
	let motion = CMMotionManager()
	
	var toggleStop = true
	
	// MARK: - View
	override func viewDidLoad() {
		super.viewDidLoad()
		tabView = self.parent as? TabBarController
		network = tabView?.network
		let host = network!.getAddress()
		url = URL(string: "http://\(host)/html/#")
		Console.log(text: "Attempting to stream camera feed from \(url!)", level: .advanced)
		webView.load(URLRequest(url: url!))
		webView.navigationDelegate = self
		webView.uiDelegate = self
		toggleStop = true
		
		let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
		let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(hide))
		swipeUp.direction = UISwipeGestureRecognizerDirection.up
		swipeDown.direction = UISwipeGestureRecognizerDirection.down
		swipeUp.delegate = self
		swipeDown.delegate = self
		
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(long))
		let stopTap = UITapGestureRecognizer(target: self, action: #selector(toggle))
		longPress.numberOfTouchesRequired = 2
		longPress.delegate = self
		stopTap.numberOfTapsRequired = 2
		stopTap.numberOfTouchesRequired = 2
		stopTap.delegate = self
		
		view.addGestureRecognizer(stopTap)
		view.addGestureRecognizer(swipeUp)
		view.addGestureRecognizer(swipeDown)
		view.addGestureRecognizer(longPress)
	}
	
	@objc func long(_ sender: UILongPressGestureRecognizer) {
		switch sender.state {
		case .began:
			calibrate()
			longStart = sender.location(in: webView)
			let impulse = UIImpactFeedbackGenerator(style: .light)
			impulse.impactOccurred()
		case .ended:
			let current = sender.location(in: webView)
			var newAng = camAng + ((longStart?.y)! - current.y)/100
			if(newAng > 11.5){
				newAng = 11.5
			}else if(newAng < 5){
				newAng = 5
			}
			camAng = newAng
			print("End Cam Ang: \(camAng)")
			network?.send(message: Message(servoValue: newAng))
		default:
			return
		}
	}
	
	@objc func swipe(){
		if(tabBarHide != nil){
			tabBarHide?.fire()
			tabBarHide = nil
		}else{
			setTabBarHidden(false)
			tabBarHide = Timer.scheduledTimer(timeInterval: TimeInterval(3), target: self, selector: #selector(hide), userInfo: nil, repeats: false)
		}
	}
	
	@objc func hide(){
		setTabBarHidden(true)
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	@objc func toggle(){
		if(!toggleStop){
			stop()
			let impulse = UIImpactFeedbackGenerator(style: .heavy)
			impulse.impactOccurred()
		}
		toggleStop = !toggleStop
	}
	
	override func viewDidAppear(_ animated: Bool) {
		startMotion()
		webView.reload()
		tabBarHide = Timer.scheduledTimer(timeInterval: TimeInterval(3), target: self, selector: #selector(hide), userInfo: nil, repeats: false)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		motion.stopGyroUpdates()
		motion.stopDeviceMotionUpdates()
		tabBarHide?.invalidate()
		usleep(1000)
		stop()
	}
	
	func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		Console.log(text: "Authenticating with RPi Cam Control", level: .advanced)
		if challenge.protectionSpace.host == network?.getAddress() {
			let user = network!.getUsername()
			let password = network!.getPassword()
			let credential = URLCredential(user: user, password: password, persistence: URLCredential.Persistence.forSession)
			challenge.sender?.use(credential, for: challenge)
			completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Movement
	func calibrate(){
		calibrateNext = true
	}
	
	@objc func stop(){
		network?.send(message: Message(type: .stop))
		print("stop")
	}
	
	
	
	func startMotion () {
		motion.deviceMotionUpdateInterval = 0.1
		motion.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
			(data, error) in
			self.updateInstruc(att: (data?.attitude)!)
			
		})
	}
	
	func updateInstruc(att: CMAttitude){
		var roll = att.roll
		var pitch = att.pitch
		var yaw = att.yaw
		
		if(calibrateNext){
			zero = [roll, pitch,yaw]
			calibrateNext = false
			print("-------Calibrated!---------")
		}
		
		roll -= zero[0]
		pitch -= zero[1]
		yaw -= zero[2]
		
		var left = pitch / 1.0
		var right = pitch / -1.0
		left += roll / 0.3
		right += roll / 0.3
		
		left = min(left, 1)
		right = min(right,1)
		left = max(left,-1)
		right = max(right,-1)
		
		if(toggleStop){
			return
		}
		if(abs(left) < 0.05){
			left = 0
		}
		if(abs(right) < 0.05){
			right = 0
		}
		if(left == 0 && right == 0 && network?.lastMovementInstruc == [0.0, 0.0]){
			return
		}
		network?.send(message: Message(leftSpeed: CGFloat(left), rightSpeed: CGFloat(right)))
	}
	
	
	/*
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/
	
}
