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

class AcceleromterControlViewController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {
	var network: NetworkManager?
	var tabView: TabBarController?
	@IBOutlet weak var webView: WKWebView!
	var url: URL? = nil
	var tabBarHide: Timer?
	var zero: [Double] = [0,0,0]
	
	@objc var track = false
	var calibrateNext = false
	
	let motion = CMMotionManager()
	
	var toggleStop = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabView = self.parent as? TabBarController
		network = tabView?.network
		let host = network!.getAddress()
		url = URL(string: "http://\(host)/html/#")
		Console.log(text: "Attempting to stream camera feed from \(url!)", level: .advanced)
		webView.load(URLRequest(url: url!))
		webView.navigationDelegate = self
		
//		let calibrateTap = UITapGestureRecognizer(target: self, action: #selector(calibrate))
		let stopTap = UITapGestureRecognizer(target: self, action: #selector(toggle))
		let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(tapr))
		let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(hide))
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(calibrate))
		
		longPress.numberOfTouchesRequired = 2

		swipeUp.direction = UISwipeGestureRecognizerDirection.up
		swipeDown.direction = UISwipeGestureRecognizerDirection.down
		
		stopTap.numberOfTapsRequired = 1
		stopTap.numberOfTouchesRequired = 3
		
//		calibrateTap.delegate = self
		longPress.delegate = self
		stopTap.delegate = self
		swipeUp.delegate = self
		swipeDown.delegate = self
		
//		view.addGestureRecognizer(calibrateTap)
		view.addGestureRecognizer(stopTap)
		view.addGestureRecognizer(swipeUp)
		view.addGestureRecognizer(swipeDown)
		view.addGestureRecognizer(longPress)
	}
	
	
	
	@objc func tapr(){
		if(tabBarHide != nil){
			tabBarHide?.fire()
			tabBarHide = nil
		}else{
			show()
			tabBarHide = Timer.scheduledTimer(timeInterval: TimeInterval(3), target: self, selector: #selector(hide), userInfo: nil, repeats: false)
		}
	}
	
	@objc func hide(){
		if(tabView?.selectedIndex == 1){
			tabBarHide = nil
			setTabBarHidden(true)
		}
	}
	func show(){
		setTabBarHidden(false)
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	@objc func calibrate(){
		calibrateNext = true
		print("Calibrate")
	}
	
	@objc func toggle(){
		if(!toggleStop){
			stop()
		}
		toggleStop = !toggleStop
	}
	
	@objc func stop(){
		network?.send(message: Message(type: .stop))
		print("stop")
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first
		Thread(target: self, selector: #selector(getter: track), object: touch).start()
		print("touch")
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		track = false
	}
	
	override func viewDidAppear(_ animated: Bool) {
		startMotion()
		webView.reload()
		tabBarHide = Timer.scheduledTimer(timeInterval: TimeInterval(3), target: self, selector: #selector(hide), userInfo: nil, repeats: false)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		print("should stop")
		motion.stopGyroUpdates()
		motion.stopDeviceMotionUpdates()
		usleep(1000)
		stop()
	}
	
	func startMotion () {
		motion.deviceMotionUpdateInterval = 0.1
		motion.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
			(data, error) in
//			print("Roll: \(String(describing: data?.attitude.roll)), Pitch: \(String(describing: data?.attitude.pitch)), Yaw: \(String(describing: data?.attitude.pitch))")
//			print(String(format: "Roll: %.2f, Pitch: %.2f, Yaw: %.2f", (data?.attitude.roll)!-self.zero[0], (data?.attitude.pitch)!-zero[1], (data?.attitude.yaw)!-zero[2]))
			self.updateInstruc(att: (data?.attitude)!)
			
		})
	}
	
	func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		print("Authenticating with RPi Cam Control")
		print(challenge.protectionSpace.host)
		if challenge.protectionSpace.host == network?.getAddress() {
			let user = network!.getUsername()
			let password = network!.getPassword()
			let credential = URLCredential(user: user, password: password, persistence: URLCredential.Persistence.forSession)
			challenge.sender?.use(credential, for: challenge)
			completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
		}
	}
	
	func updateInstruc(att: CMAttitude){
		var roll = att.roll
		var pitch = att.pitch
		var yaw = att.yaw
		
		if(calibrateNext){
			zero = [roll, pitch,yaw]
			print(zero)
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
		
//		print("\(left) \(right)")
		
			
//		print(String(format: "Roll: %.2f, Pitch: %.2f, Yaw: %.2f", roll, pitch, yaw))

		
		network?.send(message: Message(leftSpeed: CGFloat(left), rightSpeed: CGFloat(right)))

	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/
	
}
