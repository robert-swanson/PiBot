//
//  AppDelegate.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/26/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var tabBar: TabBarController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		tabBar = application.windows.first?.rootViewController as? TabBarController
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		tabBar?.network.send(message: Message(type: Message.MessType.stop))
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		tabBar?.network.send(message: Message(type: Message.MessType.stop))

	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		if let act = UserDefaults.standard.value(forKey: SettingsViewController.setting.connectOnStartUp.toString()) as! Bool?{
			if(act && !(tabBar?.network.TCPConnected())!){
				tabBar?.network.setupConnection()
			}
		}
	}

	func applicationWillTerminate(_ application: UIApplication) {
		Console.log(text: "Terminating", level: .debug)
		if(tabBar?.network.TCPConnected())!{
			tabBar?.network.closeTCP()
		}
		if(tabBar?.network.SSHConnected())!{
			tabBar?.network.closeSSH()
		}
	}


}

