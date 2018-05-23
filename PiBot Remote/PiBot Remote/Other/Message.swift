//
//  Message.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/26/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit

class Message: NSObject {
	enum MessType {
		case close
		case greeting
		case stop
		case done
		case ping
		case move
		case forward
		case backward
		case clear
		case message
		case servo
		case capture
	}
	var type: MessType?
	private var text: String
	var values: [CGFloat]?
	init(messageString: String){
		switch messageString {
		case "close":
			type = .close
		case "greetings":
			type = .greeting
		case "stop":
			type = .stop
		case "ping":
			type = .ping
		case "forward":
			type = .forward
		case "backward":
			type = .backward
		case "clear":
			type = .clear
		case "done":
			type = .done
		case "servo":
			type = .servo
		case "capture":
			type = .capture
		default:
			type = .message
			text = messageString
		}
		text = messageString
	}
	init(type: MessType) {
		self.type = type
		text = ""
	}
	init(leftSpeed: CGFloat, rightSpeed: CGFloat) {
		type = MessType.move
		values = [leftSpeed,rightSpeed]
		text = ""
	}
	init(servoValue: CGFloat){
		type = MessType.servo
		values = [servoValue]
		text = ""
	}
	func toString() -> String{
		switch type! {
		case .close:
			return "close"
		case .greeting:
			return "greetings"
		case .stop:
			return "stop"
		case .done:
			return "done"
		case .ping:
			return "ping"
		case .move:
			return "\(values![0]) \(values![1]) "
		case .forward:
			return "forward"
		case .backward:
			return "backward"
		case .capture:
			return "capture"
		case .clear:
			return "clear"
		case .servo:
			return "\(values![0])"
		case .message:
			if text.isEmpty{
				return "Empty Message"
			}
			return text
		}
	}
}
