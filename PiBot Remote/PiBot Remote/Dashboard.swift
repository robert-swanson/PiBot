//
//  ViewController.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/26/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit

class Dashboard: UIViewController, UITextViewDelegate {
	
	@IBOutlet weak var consoleView: UITextView!
	var debugConsole = "Welcome To PiBot Remote\n"
	var advancedConsole = "Welcome To PiBot Remote\n"
	var basicConsole = "Welcome To PiBot Remote\n"
	
	var network: NetworkManager?
	var tabView: TabBarController?
	var settingsView: SettingsViewController?
	
	@IBOutlet weak var connectionIcon: UIBarButtonItem!
	@IBOutlet weak var tools: UINavigationItem!
	@IBOutlet weak var connectButton: UIBarButtonItem!
	
	func initialize(){
		Console.dashboard = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		consoleView.isEditable = false
		consoleView.delegate = self
		tabView = self.parent as? TabBarController
		network = tabView?.network
		if(network?.TCPConnected())!{
			connectionIcon.image = #imageLiteral(resourceName: "connected").withRenderingMode(.alwaysOriginal)
		}else{
			connectionIcon.image = #imageLiteral(resourceName: "disconnected").withRenderingMode(.alwaysOriginal)
		}
		updateView()
	}
	
	public func updateView(){
		if consoleView != nil{
			if let val = UserDefaults.standard.value(forKey: SettingsViewController.setting.consoleLevel.toString()) as? Int{
				switch(val){
				case 0:
					consoleView.text = basicConsole
				case 1:
					consoleView.text = advancedConsole
				default:
					consoleView.text = debugConsole
				}
			}
		}
	}
	
	@IBAction func connectToggle(_ sender: Any) {
		if(network?.TCPConnected())!{
			network?.closeTCP()
		}else{
			network?.setupConnection()
		}
	}
	
	@IBAction func connectionAction(_ sender: Any) {
		if(network?.TCPConnected())!{
			network?.closeTCP()
		}else{
			network?.setupConnection()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if(segue.identifier == "settings"){
			let child = segue.destination as! UINavigationController
			let settingView = child.childViewControllers[0] as! SettingsViewController
			settingView.tabBar = tabView
			settingView.network = tabView?.network
		}
	}
	
	@IBAction func displayActions(_ sender: Any) {
		tabView?.displayActions(sender)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func becomeFirstResponder() -> Bool {
		return true
	}
	
	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake{
			Console.clear()
		}
	}
}
