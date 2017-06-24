//
//  AcknowledgementsTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/13/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class AcknowledgementsTableViewController: UITableViewController {
	
	var fontAcks = NSMutableArray()
	var libsAcks = NSMutableArray()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "fontAck", ofType: "json")!)) {
			do {
				let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
				fontAcks = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		if let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "libsAck", ofType: "json")!)) {
			do {
				let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
				libsAcks = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.backgroundColor = globalBackColor
		
		if isDarkMode() {
			self.tableView.separatorColor = UIColor.darkGray
		}
		else {
			self.tableView.separatorColor = UIColor.lightGray
		}
		
    }
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return fontAcks.count
		}
		return libsAcks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ackCell", for: indexPath)
		
		if (indexPath.section == 0) {
			let fontAck = fontAcks.object(at: indexPath.row) as! NSDictionary
			cell.textLabel?.text = fontAck.object(forKey: "text") as? String
		}
		else {
			let libsAck = libsAcks.object(at: indexPath.row) as! NSDictionary
			cell.textLabel?.text = libsAck.object(forKey: "text") as? String
		}
		
		cell.backgroundColor = globalBackColor
		cell.textLabel?.font = UIFont(name: "EtelkaNarrowTextPro", size: 16)
		cell.textLabel?.textColor = globalTintColor
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if (section == 0) {
			return "Thanking the following people for providing awesome free-ware fonts."
		}
		return "Meme Maker uses the following open source libraries."
	}

    // MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 44
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		var URLString = ""
		if (indexPath.section == 0) {
			let fontAck = fontAcks.object(at: indexPath.row) as! NSDictionary
			URLString = fontAck.object(forKey: "link") as! String
		}
		else {
			let libsAck = libsAcks.object(at: indexPath.row) as! NSDictionary
			URLString = libsAck.object(forKey: "link") as! String
		}
		
		let URL = Foundation.URL(string: URLString)
		if (UIApplication.shared.canOpenURL(URL!)) {
			UIApplication.shared.openURL(URL!)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	

}
