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
		
		if let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("fontAck", ofType: "json")!) {
			do {
				let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSArray
				fontAcks = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		if let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("libsAck", ofType: "json")!) {
			do {
				let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSArray
				libsAcks = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.backgroundColor = globalBackColor
		
    }
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return fontAcks.count
		}
		return libsAcks.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ackCell", forIndexPath: indexPath)
		
		if (indexPath.section == 0) {
			let fontAck = fontAcks.objectAtIndex(indexPath.row) as! NSDictionary
			cell.textLabel?.text = fontAck.objectForKey("text") as? String
		}
		else {
			let libsAck = libsAcks.objectAtIndex(indexPath.row) as! NSDictionary
			cell.textLabel?.text = libsAck.objectForKey("text") as? String
		}
		
		cell.backgroundColor = globalBackColor
		cell.textLabel?.font = UIFont(name: "EtelkaNarrowTextPro", size: 16)
		cell.textLabel?.textColor = globalTintColor
		
		return cell
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if (section == 0) {
			return "Thanking the following people for providing awesome free-ware fonts."
		}
		return "Meme Maker uses the following open source libraries."
	}

    // MARK: - Table view delegate
	
	override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 44
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		var URLString = ""
		if (indexPath.section == 0) {
			let fontAck = fontAcks.objectAtIndex(indexPath.row) as! NSDictionary
			URLString = fontAck.objectForKey("link") as! String
		}
		else {
			let libsAck = libsAcks.objectAtIndex(indexPath.row) as! NSDictionary
			URLString = libsAck.objectForKey("link") as! String
		}
		
		let URL = NSURL(string: URLString)
		if (UIApplication.sharedApplication().canOpenURL(URL!)) {
			UIApplication.sharedApplication().openURL(URL!)
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	

}
