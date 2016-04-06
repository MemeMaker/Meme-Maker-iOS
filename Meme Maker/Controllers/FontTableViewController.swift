//
//  FontTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

enum FontTableType {
	case Font
	case Alignment
	case TextColor
	case OutlineColor
	case Opacity
	case OutlineThickness
	case RelativeFontSize
}

let FontTableTypes = [FontTableType.Font, FontTableType.Alignment, FontTableType.TextColor, FontTableType.OutlineColor, FontTableType.Opacity, FontTableType.OutlineThickness, FontTableType.RelativeFontSize]

class XDataSource: NSObject {
	var title: String?
	var fontTableType: FontTableType = .Font
	var array: NSMutableArray = NSMutableArray()
	override init() { super.init() }
	convenience init(fontTableType: FontTableType, array: NSArray, title: String) {
		self.init()
		self.title = title
		self.fontTableType = fontTableType
		self.array = NSMutableArray(array: array)
	}
}

class FontTableViewController: UITableViewController {
	
	var topTextAttr = XTextAttributes(savename: "topAttr")
	var bottomTextAttr = XTextAttributes(savename: "bottomAttr")
	
	var fontTableType: FontTableType = .Font
	var currentFTType: Int = 0
	
	var swipeLeft: UISwipeGestureRecognizer?
	var swipeRight: UISwipeGestureRecognizer?
	
	var fDataSource = NSMutableArray()

    override func viewDidLoad() {
		
        super.viewDidLoad()
		
		var dFonts: NSMutableArray?
		if let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("fonts", ofType: "json")!) {
			do {
				let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSArray
				dFonts = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		let dAlignments = NSMutableArray(objects:
			 ["displayName": "Center (Default)", "value": 0],
			 ["displayName": "Justify", "value": 1],
			 ["displayName": "Left", "value": 2],
			 ["displayName": "Right", "value": 3])
		
		let dTextColors = NSMutableArray(objects:
			["displayName": "White (Default)", "value": UIColor.whiteColor()],
			["displayName": "Black", "value": UIColor.blackColor()],
			["displayName": "Yellow", "value": UIColor.yellowColor()],
			["displayName": "Green", "value": UIColor.greenColor()],
			["displayName": "Cyan", "value": UIColor.cyanColor()],
			["displayName": "Purple", "value": UIColor.purpleColor()],
			["displayName": "Magenta", "value": UIColor.magentaColor()],
			["displayName": "Red", "value": UIColor.redColor()],
			["displayName": "Light Gray", "value": UIColor.lightGrayColor()],
			["displayName": "Dark Gray", "value": UIColor.darkGrayColor()],
			["displayName": "Clear Color", "value": UIColor.clearColor()])
		
		let dOutlineColors = NSMutableArray(array: dTextColors)
		
		let dOpacity = NSMutableArray(objects:
			["displayName": "100%", "value": 1.0],
			["displayName": "90%", "value": 0.9],
			["displayName": "80%", "value": 0.8],
			["displayName": "70%", "value": 0.7],
			["displayName": "60%", "value": 0.6],
			["displayName": "50%", "value": 0.5],
			["displayName": "40%", "value": 0.4],
			["displayName": "30%", "value": 0.3],
			["displayName": "20%", "value": 0.2],
			["displayName": "10%", "value": 0.1],
			["displayName": "0%", "value": 0.0])
		
		let dOutlineThickness = NSMutableArray(objects:
			["displayName": "4pt (Default)", "value": -4.0],
			["displayName": "3pt", "value": -3.0],
			["displayName": "2pt", "value": -2.0],
			["displayName": "1pt", "value": -1.0],
			["displayName": "0pt", "value": 0.0],
			["displayName": "5pt", "value": -5.0],
			["displayName": "6pt", "value": -6.0],
			["displayName": "7pt", "value": -7.0])
		
		let dRelativeFontSize = NSMutableArray(objects:
			["displayName": "Medium (Default)", "value": 44],
			["displayName": "Extra Small", "value": 22],
			["displayName": "Small", "value": 33],
			["displayName": "Large", "value": 55],
			["displayName": "Extra Large", "value": 66],
			["displayName": "Microscopic", "value": 11],
			["displayName": "Gigantic", "value": 88])
		
		fDataSource = NSMutableArray(objects:
			XDataSource(fontTableType: .Font, array: dFonts!, title: "Fonts"),
			XDataSource(fontTableType: .Alignment, array: dAlignments, title: "Text Alignment"),
			XDataSource(fontTableType: .TextColor, array: dTextColors, title: "Text Color"),
			XDataSource(fontTableType: .OutlineColor, array: dOutlineColors, title: "Outline Color"),
			XDataSource(fontTableType: .Opacity, array: dOpacity, title: "Opacity"),
			XDataSource(fontTableType: .OutlineThickness, array: dOutlineThickness, title: "Outline Thickness"),
			XDataSource(fontTableType: .RelativeFontSize, array: dRelativeFontSize, title: "Relative Font Scale"))

		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .Left
		self.view.addGestureRecognizer(swipeLeft!)
		swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeRightAction))
		swipeRight?.direction = .Right
		self.view.addGestureRecognizer(swipeRight!)
		
    }
	
	// MARK: - Handle swipe
	
	func swipeLeftAction() -> Void {
		
	}
	
	func swipeRightAction() -> Void {
		
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let dataSource = fDataSource.objectAtIndex(currentFTType) as! XDataSource
        return dataSource.array.count
    }
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fontCell", forIndexPath: indexPath)

        // Configure the cell...
		
		let dataSource = fDataSource.objectAtIndex(currentFTType) as! XDataSource
		let dict = dataSource.array.objectAtIndex(indexPath.row) as! NSDictionary
		cell.textLabel?.text = dict.objectForKey("displayName") as? String

		return cell
    }
	
	// MARK: - Table view delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
