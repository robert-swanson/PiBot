//
//  Console.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 5/6/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import Foundation
class Console{
	enum Level {
		case debug
		case advanced
		case basic
	}
	
	public static var dashboard: Dashboard? = nil
	
	static func log(text: String, level: Level){
		print(text)
		let mess = "\n-> \(text)"
		if(level == .debug){
			dashboard!.debugConsole.append(mess)
		}else if(level == .advanced){
			dashboard!.debugConsole.append(mess)
			dashboard!.advancedConsole.append(mess)
		}else{
			dashboard!.debugConsole.append(mess)
			dashboard!.advancedConsole.append(mess)
			dashboard!.basicConsole.append(mess)
		}
		dashboard!.updateView()
	}
	
	public static func clear(){
		dashboard!.advancedConsole = "Welcome To PiBot Remote\n"
		dashboard!.basicConsole = "Welcome To PiBot Remote\n"
		dashboard!.debugConsole = "Welcome To PiBot Remote\n"
		dashboard?.updateView()
	}
	public static func update(){
		dashboard?.updateView()
	}
}
