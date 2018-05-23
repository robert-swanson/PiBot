//
//  SegmentedCell.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 4/6/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit
class SwitchCell: UITableViewCell{
	
	let settings = UserDefaults.standard
	@IBOutlet weak var control: UISwitch!
	@IBOutlet weak var Label: UILabel!
	var key: String?
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		if superview != nil && key != nil{
			if let clinet = settings.value(forKey: key!) as! Bool?{
				control.setOn(clinet, animated: false)
			}
		}
	}
	
	@IBAction func ControlChanged(_ sender: UISwitch) {
		settings.set(sender.isOn, forKey: key!)
	}
}
