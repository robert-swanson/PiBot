//
//  settings.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 4/6/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit
class SettingsViewController: UITableViewController{
	
	enum setting {
		case consoleLevel
		case hostName
		case port
		case client
		case password
		case username
		case connectOnStartUp
		case autoStartClient
		
		enum Pin{
			case PWMA
			case AIN1
			case AIN2
			case STBY
			case BIN1
			case BIN2
			case PWMB
			case SERVO
			case connected
			case replaying
			case data
			
			func toString()->String{
				switch self {
				case .PWMA:
					return "PWMA"
				case .AIN1:
					return "AIN1"
				case .AIN2:
					return "AIN2"
				case .BIN1:
					return "BIN1"
				case .BIN2:
					return "BIN2"
				case.PWMB:
					return "PWMB"
				case .STBY:
					return "STBY"
				case .connected:
					return "connected"
				case .data:
					return "data"
				case .replaying:
					return "replaying"
				case .SERVO:
					return "SERVO"
				}
			}
		}
		
		func toString() -> String{
			switch self {
			case .consoleLevel:
				return "consoleLevel"
			case .hostName:
				return "hostName"
			case .port:
				return "port"
			case .client:
				return "client"
			case .password:
				return "password"
			case .username:
				return "username"
			case .connectOnStartUp:
				return "connectOnStartUp"
			case .autoStartClient:
				return "autoStartClient"
			}
		}
	}
	
	let settings = UserDefaults.standard
	
	var tabBar: TabBarController? = nil
	var network: NetworkManager? = nil
	
	@IBAction func button(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 4
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if(section == 0){
			return 3
		}else if(section == 1){
			return 4
		}else if(section == 2){
			return 2
		}else{
			return 11
		}
	}
	
	func getSet(set: SettingsViewController.setting.Pin, def: Int) -> Int{
		if let val = settings.value(forKey: set.toString()) as? Int{
			return val
		}else{
			settings.set(def, forKey: set.toString())
			return def
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var identifier = "cell"
		var title = ""
		var data = ""
		switch (indexPath.section,indexPath.row) {
		case (0,0):
			identifier = "console"
		case (0,1):
			identifier = "onoff"
			title = "Connect to Robot on Startup"
			data = setting.connectOnStartUp.toString()
			
		case (0,2):
			identifier = "onoff"
			title = "Auto Start Client"
			data = setting.autoStartClient.toString()
			
		case (1,0):
			title = "Hostname"
			if let host = settings.value(forKey: SettingsViewController.setting.hostName.toString()) as! String?{
				data = host
			}else{
				data = "pibot.local"
			}
		case (1,1):
			title = "Username"
			if let user = settings.value(forKey: SettingsViewController.setting.username.toString()) as! String?{
				data = user
			}else{
				data = "pi"
			}
		case (1,2):
			title = "Password"
			if let pass = settings.value(forKey: SettingsViewController.setting.password.toString()) as! String?{
				for _ in pass{
					data += "•"
				}
			}else{
				data = "••••••"
			}
		case (1,3):
			title = "Port"
			if let port = settings.value(forKey: SettingsViewController.setting.port.toString()) as! String?{
				data = "\(port)"
			}else{
				data = "2000"
			}
			
		case (2,0):
			title = "Set Robot To AdHoc"
		case (2,1):
			title = "Set Robot To Wifi"
		case (3,0):
			title = "Left Speed"
			data = "\(getSet(set: setting.Pin.PWMA, def: 7))"
		case (3,1):
			title = "Left Forward"
			data = "\(getSet(set: setting.Pin.AIN1, def: 12))"
		case (3,2):
			title = "Left Backward"
			data = "\(getSet(set: setting.Pin.AIN2, def: 11))"
		case (3,3):
			title = "Standby"
			data = "\(getSet(set: setting.Pin.STBY, def: 13))"
		case (3,4):
			title = "Right Forward"
			data = "\(getSet(set: setting.Pin.BIN1, def: 15))"
		case (3,5):
			title = "Right Backward"
			data = "\(getSet(set: setting.Pin.BIN2, def: 16))"
		case (3,6):
			title =  "Right Speed"
			data = "\(getSet(set: setting.Pin.PWMB, def: 18))"
		case (3,7):
			title = "Servo Motor"
			data = "\(getSet(set: setting.Pin.SERVO, def: 22))"
		case (3,8):
			title =  "Connection LED"
			data = "\(getSet(set: setting.Pin.connected, def: 37))"
		case (3,9):
			title = "Replay LED"
			data = "\(getSet(set: setting.Pin.replaying, def: 38))"
		case (3,10):
			title = "Data LED"
			data = "\(getSet(set: setting.Pin.data, def: 40))"
		default:
			break
		}
		let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
		if(identifier == "cell"){
			cell.textLabel?.text = title
			cell.detailTextLabel?.text = data
		}else if(identifier == "onoff"){
			let onoff = cell as! SwitchCell
			onoff.Label.text = title
			onoff.key = data
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let pinMess1 = "Insert a number from 1 to 40 that indicates the GPIO pin you used for this function."
		let pinMess2 = "If you will not support this function, insert 0 to bypass it."
		switch (indexPath.section,indexPath.row) {
		case (1,0):
			askSetting(withTitle: "Host Name", message: "If your robot is on your local network, be sure to include \".local\" at the end of the hostname", settingKey: SettingsViewController.setting.hostName.toString(), numpad: false, pass: false, index: indexPath)
		case (1,1):
			askSetting(withTitle: "Username", message: "Insert the username of the account on the pi", settingKey: setting.username.toString(), numpad: false, pass: false, index: indexPath)
		case (1,2):
			askSetting(withTitle: "Password", message: "Insert the password of your pi's account", settingKey: setting.password.toString(), numpad: false, pass: true, index: indexPath)
		case (1,3):
			askSetting(withTitle: "Port", message: "Be sure this port is not being used by another operation", settingKey: SettingsViewController.setting.port.toString(), numpad: true, pass: false, index: indexPath)
		case (2,0):
			performTask(withCode: 0, title: "Setting Network to AdHoc", message: "This may take a moment")
		case (2,1):
			performTask(withCode: 1, title: "Setting Network to Wifi", message: "This may take a moment")
		case (3,0):
			askSetting(withTitle: "Left Speed", message: pinMess1, settingKey: setting.Pin.PWMA.toString(), numpad: true, pass: false, index: indexPath)
		case (3,1):
			askSetting(withTitle: "Left Forward", message: pinMess1, settingKey: setting.Pin.AIN1.toString(), numpad: true, pass: false, index: indexPath)
		case (3,2):
			askSetting(withTitle: "Left Backward", message: pinMess1, settingKey: setting.Pin.AIN2.toString(), numpad: true, pass: false, index: indexPath)
		case (3,3):
			askSetting(withTitle: "Standby ", message: pinMess1, settingKey: setting.Pin.STBY.toString(), numpad: true, pass: false, index: indexPath)
		case (3,4):
			askSetting(withTitle: "Right Forward", message: pinMess1, settingKey: setting.Pin.BIN1.toString(), numpad: true, pass: false, index: indexPath)
		case (3,5):
			askSetting(withTitle: "Right Backward", message: pinMess1, settingKey: setting.Pin.BIN2.toString(), numpad: true, pass: false, index: indexPath)
		case (3,6):
			askSetting(withTitle: "Right Speed", message: pinMess1, settingKey: setting.Pin.PWMB.toString(), numpad: true, pass: false, index: indexPath)
		case (3,7):
			askSetting(withTitle: "Servo Motor", message: pinMess1, settingKey: setting.Pin.SERVO.toString(), numpad: true, pass: false, index: indexPath)
		case (3,8):
			askSetting(withTitle: "Connected LED", message: pinMess1+" "+pinMess2, settingKey: setting.Pin.connected.toString(), numpad: true, pass: false, index: indexPath)
		case (3,9):
			askSetting(withTitle: "Replay LED", message: pinMess1+" "+pinMess2, settingKey: setting.Pin.replaying.toString(), numpad: true, pass: false, index: indexPath)
		case (3,10):
			askSetting(withTitle: "Data LED", message: pinMess1+" "+pinMess2, settingKey: setting.Pin.data.toString(), numpad: true, pass: false, index: indexPath)
		default:
			break
		}
		tableView.deselectRow(at: indexPath, animated: true)
		tableView.reloadData()
	}
	
	func askSetting(withTitle: String, message: String, settingKey: String, numpad: Bool, pass: Bool, index: IndexPath){
		let alert = UIAlertController(title: withTitle, message: message, preferredStyle: .alert)
		var start: String? = ""
		if let setting = settings.value(forKey: settingKey) as? String?{
			start = setting
		}
		alert.addTextField(configurationHandler: {(textField) in
			if(numpad){
				textField.keyboardType = UIKeyboardType.numberPad
			}else if(pass){
				textField.isSecureTextEntry = true
			}
			textField.placeholder = "Enter Value"
			textField.text = start
		})
		let ok = UIAlertAction(title: "OK", style: .default, handler: {UIAlertAction in
			let tf = alert.textFields![0] as UITextField
			if let text = tf.text{
				if(text.count > 0){
					self.settings.set(tf.text, forKey: settingKey)
					self.tableView.reloadRows(at: [index], with: .automatic)
				}
			}
		})
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(ok)
		alert.addAction(cancel)
		present(alert, animated: true, completion: nil)
	}
	func performTask(withCode: Int, title: String, message: String){
		var newTitle: String?
		var newMessage: String?
		
		if(withCode == 0){
			let result = network?.sendSSHCommand(command: "sudo bash Desktop/PiBotRemoteFiles/adhoc.sh", progressBar: nil)
			if(result?.trimmingCharacters(in: .whitespaces).starts(with: "before: # wifi"))!{
				newMessage = "The change was succesful, however it will not take affect until you restart the robot"
				newTitle = "Success"
			}else if(result?.trimmingCharacters(in: .whitespaces).starts(with: "before: # adhoc"))!{
				newMessage = "The robot was already set to an adhoc"
				newTitle = "No Change"
			}else{
				newMessage = "Unable to execute the command via SSH"
				newTitle = "Error"
			}
		}else{
			let result = network?.sendSSHCommand(command: "sudo bash Desktop/PiBotRemoteFiles/wifi.sh", progressBar: nil)
			if(result?.trimmingCharacters(in: .whitespaces).starts(with: "before: # adhoc"))!{
				newMessage = "The change was succesful, however it will not take affect until you restart the robot"
				newTitle = "Success"
			}else if(result?.trimmingCharacters(in: .whitespaces).starts(with: "before: # wifi"))!{
				newMessage = "The robot was already set to a wifi"
				newTitle = "No Change"
			}else{
				newMessage = "Unable to execute the command via SSH"
				newTitle = "Error"
			}
		}
		let newAlert = UIAlertController(title: newTitle, message: newMessage, preferredStyle: .alert)
		newAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		present(newAlert, animated: true, completion: nil)
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch(section){
		case 0:
			return "App Settings"
		case 1:
			return "Robot Settings"
		case 2:
			return "Robot Actions"
		default:
			return "GPIO Pins"
		}
	}
}
