//
//  D-Pad.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 2/28/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import SpriteKit

protocol DPadDelegate {
	func joystickPositionDidChange(to position: CGPoint, withBackgroundRadius rad: CGFloat, joystick: SKSpriteNode)
}

class DPadScene: SKScene{
	
	public var joystick: SKSpriteNode?
	public var background: SKSpriteNode?
	var touchControl: TouchControlViewController?
	var tabView: TabBarController?
	var dPadDelegate: DPadDelegate?
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first
		let pos = touch?.location(in: self)
		let radius: CGFloat = (background?.frame.width)!/2
		joystick?.position = getJoyPos(withTouchAt: pos!, backgroundRadius: radius)
		dPadDelegate?.joystickPositionDidChange(to: (joystick?.position)!, withBackgroundRadius: radius, joystick: joystick!)
		
	}
	override func didMove(to view: SKView) {
		joystick = self.childNode(withName: "joystick") as? SKSpriteNode
		background = self.childNode(withName: "background") as? SKSpriteNode
	}
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		joystick?.position = CGPoint(x: 0, y: 0)
		let radius: CGFloat = (background?.frame.width)!/2
		dPadDelegate?.joystickPositionDidChange(to: CGPoint(x:0, y:0), withBackgroundRadius: radius, joystick: joystick!)
	}
	func isLandscape() -> Bool{
		return touchControl!.orientation != UIInterfaceOrientation.portrait && touchControl!.orientation != UIInterfaceOrientation.portraitUpsideDown
	}
	
	func getJoyPos(withTouchAt touch: CGPoint, backgroundRadius radius: CGFloat) -> CGPoint{
		let x = touch.x
		let y = touch.y
		if(isLandscape()){
			if(abs(y) <= radius){
				return CGPoint(x: 0, y: y)
			}
			else{
				return CGPoint(x: 0, y: radius * ((y > 0) ? 1 : -1))
			}
		}
		else{
			if abs(x) <= radius && abs(y) <= radius{
				return touch
			}
			var angle = atan(y/x)
			if x < 0{
				angle += CGFloat.pi
			}
			let nx = radius * cos(angle)
			let ny = radius * sin(angle)
			return CGPoint(x: nx, y: ny)
		}
	}
	
}
