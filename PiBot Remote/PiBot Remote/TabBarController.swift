//
//  TabBarController.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/28/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit

extension UIViewController {
	
	func setTabBarHidden(_ hidden: Bool, animated: Bool = true, duration: TimeInterval = 0.3) {
		if animated {
			if let frame = self.tabBarController?.tabBar.frame {
				let factor: CGFloat = hidden ? 1 : -1
				let y = self.view.frame.size.height + frame.size.height * factor
				UIView.animate(withDuration: duration, animations: {
					self.tabBarController?.tabBar.frame = CGRect(x: frame.origin.x, y: y, width: frame.width, height: frame.height)
				})
				if self is AcceleromterControlViewController{
					let accel = self as! AcceleromterControlViewController
					let webview = accel.webView
					UIView.animate(withDuration: duration, animations: {
						webview?.frame = self.view.frame
					})
				}
				return
			}
		}
		self.tabBarController?.tabBar.isHidden = hidden
	}
	
}

class TabBarController: UITabBarController, NetworkManagerDelegate {
	
	
	var touch: TouchControlViewController?
	var acceleromter: AcceleromterControlViewController?
	var dashboard: Dashboard?
	
	var network: NetworkManager = NetworkManager()
	var forwardAlert: UIAlertController?
	var backwardAlert: UIAlertController?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		touch = childViewControllers.first as? TouchControlViewController
		acceleromter = childViewControllers[1] as? AcceleromterControlViewController
		dashboard = childViewControllers.last as? Dashboard
		network.tabBar = self
		network.delegate = self
		dashboard?.initialize()
    }
	override func viewDidAppear(_ animated: Bool) {
//		network.setupConnection()

		
	}
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func connect(){
		network.delegate = self
		network.setupConnection()
	}
	
	
	func updateConnectedIcons(to: Bool){
		if(to){
			touch?.connectionIcon.image = #imageLiteral(resourceName: "connected").withRenderingMode(.alwaysOriginal)
			touch?.connectButton.title = "Disconnect"
			if let icon = dashboard?.connectionIcon{
				icon.image = #imageLiteral(resourceName: "connected").withRenderingMode(.alwaysOriginal)
				dashboard?.connectButton.title = "Disconnect"
			}
		}else{
			touch?.connectionIcon.image = #imageLiteral(resourceName: "disconnected").withRenderingMode(.alwaysOriginal)
			touch?.connectButton.title = "Connect"
			if let icon = dashboard?.connectionIcon{
				icon.image = #imageLiteral(resourceName: "disconnected").withRenderingMode(.alwaysOriginal)
				dashboard?.connectButton.title = "Connect"
			}
		}
		touch?.tools.leftBarButtonItems = [touch?.connectButton,touch?.connectionIcon] as? [UIBarButtonItem]
		if let tools = dashboard?.tools{
			tools.leftBarButtonItems = [touch?.connectButton,touch?.connectionIcon] as? [UIBarButtonItem]
		}
	}
	
	@objc
	public func showActivityIndicator(){
		let activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		activity.startAnimating()
		if let tools = touch?.tools{
			tools.leftBarButtonItems = [touch?.connectButton, UIBarButtonItem(customView: activity)] as? [UIBarButtonItem]
		}
		if let tools = dashboard?.tools{
			tools.leftBarButtonItems = [touch?.connectButton, UIBarButtonItem(customView: activity)] as? [UIBarButtonItem]
		}
	}
	
	func receivedMessage(message: Message) {
		Console.log(text: "Recieved Message: \(message)", level: .debug)
		if message.type == .ping{
			if network.ping == false {
				network.send(message: Message(type: .ping))
				Console.log(text: "Ping Recieved From Client", level: .advanced)
			}else{
				network.ping = false
				Console.log(text: "Connection Succesfull", level: .basic)
				updateConnectedIcons(to: true)
			}
		}else if(message.type == .done){
			if let alert = forwardAlert{
				alert.dismiss(animated: true, completion: nil)
			}
			if let alert = backwardAlert{
				alert.dismiss(animated: true, completion: nil)
			}
		}else{
			Console.log(text: "Message recieved: \(message.toString())", level: .debug)
		}
	}
	
	
	func displayFailedConnectionAlert(){
		let alert = UIAlertController(title: "Connection Failed", message: "Check the console for details", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	func forward(){
		forwardAlert = UIAlertController(title: "Replaying History", message: "The robot is tracing the given path", preferredStyle: .alert)
		forwardAlert?.addAction(UIAlertAction(title: "Stop", style: .cancel, handler: {UIAlertAction in self.network.send(message: Message(type: .stop))}))
		present(forwardAlert!, animated: true, completion: {
			self.network.send(message: Message(type: .forward))
		})
	}
	
	func backward(){
		backwardAlert = UIAlertController(title: "Rewinding History", message: "The robot is tracing the given path backwards", preferredStyle: .alert)
		backwardAlert?.addAction(UIAlertAction(title: "Stop", style: .cancel, handler: {UIAlertAction in self.network.send(message: Message(type: .stop))}))
		present(backwardAlert!, animated: true, completion: {
			self.network.send(message: Message(type: .backward))
		})
	}
	
	func displayActions(_ sender: Any) {
		let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
		let ssh = UIAlertAction(title: "Terminate SSH", style: .default, handler: {
			UIAlertAction in
			self.network.closeTCP()
			self.network.session?.disconnect()
		})
		let forward = UIAlertAction(title: "Play Forward", style: .default, handler: {UIAlertAction in self.forward()})
		let backward = UIAlertAction(title: "Play Backward", style: .default, handler: {UIAlertAction in self.backward()})
		let clear = UIAlertAction(title: "Clear History", style: .default, handler: {UIAlertAction in self.network.send(message: Message(type: .clear))})

		let restart = UIAlertAction(title: "Restart", style: .destructive, handler: {UIAlertAction in
			_ = self.network.sendSSHCommand(command: "sudo shutdown -r now", progressBar: nil)
			self.network.closeTCP()
		})
		let shutdown = UIAlertAction(title: "Shutdown", style: .destructive, handler: {UIAlertAction in
			_ = self.network.sendSSHCommand(command: "sudo shutdown now", progressBar: nil)
			self.network.closeTCP()
		})
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(ssh)
		alert.addAction(forward)
		alert.addAction(backward)
		alert.addAction(clear)
		alert.addAction(shutdown)
		alert.addAction(restart)
		alert.addAction(cancel)
		present(alert, animated: true, completion: nil)
	}
	
	
}
