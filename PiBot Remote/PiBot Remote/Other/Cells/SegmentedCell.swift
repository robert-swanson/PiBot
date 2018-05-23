//
//  SegmentedCell.swift
//  PiBot Remote
//
//  Created by Robert Swanson on 4/6/18.
//  Copyright © 2018 Robert Swanson. All rights reserved.
//

import UIKit
class SegmentedCell: UITableViewCell{
	
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	let settings = UserDefaults.standard
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		if superview != nil{
			if let console = settings.value(forKey: SettingsViewController.setting.consoleLevel.toString()) as! Int?{
				segmentedControl.selectedSegmentIndex = console
			}
		}
	}
	
	@IBAction func selectionChanged(_ sender: UISegmentedControl) {
		settings.set(sender.selectedSegmentIndex, forKey: SettingsViewController.setting.consoleLevel.toString())
		Console.update()
	}
}
