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

let Alignments = [NSTextAlignment.Center, NSTextAlignment.Justified, NSTextAlignment.Left, NSTextAlignment.Right]

let FontTableTypes = [FontTableType.Font, FontTableType.Alignment, FontTableType.TextColor, FontTableType.OutlineColor, FontTableType.Opacity, FontTableType.OutlineThickness, FontTableType.RelativeFontSize]

protocol TextAttributeChangingDelegate {
	func didUpdateTextAttributes(topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) -> Void
}

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
	
	var textAttrChangeDelegate: TextAttributeChangingDelegate?
	
	var topTextAttr: XTextAttributes! = XTextAttributes(savename: "topAttr")
	var bottomTextAttr: XTextAttributes! = XTextAttributes(savename: "bottomAttr")
	
	var currentFTType: Int = 0
	
	var swipeLeft: UISwipeGestureRecognizer?
	var swipeRight: UISwipeGestureRecognizer?
	
	var fDataSource = NSMutableArray()
	
	var selectedAttrs = NSMutableArray()

    override func viewDidLoad() {
		
        super.viewDidLoad()
		
		self.tableView.separatorStyle = .None
		
		self.view.backgroundColor = globalBackColor
		
		self.view.alpha = 0.7
		self.view.layer.cornerRadius = 8.0
		
		let horizontalME = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
		horizontalME.maximumRelativeValue = -10
		horizontalME.minimumRelativeValue = 10
		self.view.addMotionEffect(horizontalME)
		
		let verticalME = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
		verticalME.maximumRelativeValue = -10
		verticalME.minimumRelativeValue = 10
		self.view.addMotionEffect(verticalME)
		
		self.view.layer.shadowPath = UIBezierPath(rect: self.view.bounds).CGPath
		self.view.layer.shadowColor = UIColor.blackColor().CGColor
		self.view.layer.shadowOffset = CGSizeZero
		self.view.layer.shadowRadius = 1.5
		self.view.layer.shadowOpacity = 0.8
		
		var dFonts: NSMutableArray?
		if let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("fonts", ofType: "json")!) {
			do {
				let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSArray
				dFonts = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		// For now I'm gonna hard-code these values, maybe later move them to JSON or server
		
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
			["displayName": "Transparent", "value": UIColor.clearColor()])
		
		let dOutlineColors = NSMutableArray(objects:
			["displayName": "Black (Default)", "value": UIColor.blackColor()],
			["displayName": "Dark Gray", "value": UIColor.darkGrayColor()],
			["displayName": "White", "value": UIColor.whiteColor()],
			["displayName": "Brown", "value": UIColor.brownColor()],
			["displayName": "Purple", "value": UIColor.purpleColor()],
			["displayName": "Magenta", "value": UIColor.magentaColor()],
			["displayName": "Red", "value": UIColor.redColor()],
			["displayName": "Light Gray", "value": UIColor.lightGrayColor()],
			["displayName": "No outline", "value": UIColor.clearColor()])
		
		let dOpacity = NSMutableArray(objects:
			["displayName": "100% (Default)", "value": 1.0],
			["displayName": "80%", "value": 0.8],
			["displayName": "60%", "value": 0.6],
			["displayName": "40%", "value": 0.4],
			["displayName": "20%", "value": 0.2],
			["displayName": "0% (Only outline)", "value": 0.0])
		
		let dOutlineThickness = NSMutableArray(objects:
			["displayName": "2pt (Default)", "value": 2.0],
		    ["displayName": "1pt", "value": 1.0],
		    ["displayName": "0pt (Only shadow)", "value": 0.0],
			["displayName": "3pt", "value": 3.0],
			["displayName": "4pt", "value": 4.0],
			["displayName": "5pt", "value": 5.0],
			["displayName": "6pt", "value": 6.0],
			["displayName": "7pt", "value": 7.0])
		
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
		
		currentFTType = 0
		
		selectedAttrs = NSMutableArray(objects:
			NSMutableDictionary(dictionary: dFonts?.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dAlignments.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dTextColors.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dOutlineColors.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dOpacity.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dOutlineThickness.objectAtIndex(0) as! Dictionary),
			NSMutableDictionary(dictionary: dRelativeFontSize.objectAtIndex(0) as! Dictionary))
		
		updateSelectedAttrs()
		
    }
	
	func updateSelectedAttrs () {
		
		let dict0 = selectedAttrs.objectAtIndex(0) as! NSMutableDictionary
		dict0["value"] = topTextAttr.font.fontName
		
		let dict1 = selectedAttrs.objectAtIndex(1) as! NSMutableDictionary
		dict1["value"] = Alignments.indexOf(topTextAttr.alignment)
		
		let dict2 = selectedAttrs.objectAtIndex(2) as! NSMutableDictionary
		dict2["value"] = topTextAttr.textColor
		
		let dict3 = selectedAttrs.objectAtIndex(3) as! NSMutableDictionary
		dict3["value"] = topTextAttr.outlineColor
		
		let dict4 = selectedAttrs.objectAtIndex(4) as! NSMutableDictionary
		dict4["value"] = topTextAttr.opacity
		
		let dict5 = selectedAttrs.objectAtIndex(5) as! NSMutableDictionary
		dict5["value"] = topTextAttr.strokeWidth
		
		let dict6 = selectedAttrs.objectAtIndex(6) as! NSMutableDictionary
		dict6["value"] = topTextAttr.fontSize
		
		self.tableView.reloadData()
		
	}
	
	// MARK: - Handle swipe
	
	func swipeLeftAction() -> Void {
		
		UIView.animateWithDuration(0.12, delay: 0.0, options: .CurveEaseIn, animations: {
			self.view.layer.transform = CATransform3DMakeTranslation(-self.view.bounds.size.width, 0, 0)
			self.view.alpha = 0.1
			}) { (success) in
				if (self.currentFTType == 0) {
					self.currentFTType = 6
				}
				else {
					self.currentFTType -= 1
				}
				self.updateSelectedAttrs()
				self.view.layer.transform = CATransform3DMakeTranslation(self.view.bounds.size.width, 0, 0)
				UIView.animateWithDuration(0.12, delay: 0.0, options: .CurveEaseOut, animations: {
					self.view.layer.transform = CATransform3DIdentity
					self.view.alpha = 0.7
					}, completion: nil)
		}
		
	}
	
	func swipeRightAction() -> Void {
		
		UIView.animateWithDuration(0.12, delay: 0.0, options: .CurveEaseIn, animations: {
			self.view.layer.transform = CATransform3DMakeTranslation(self.view.bounds.size.width, 0, 0)
			self.view.alpha = 0.1
		}) { (success) in
			if (self.currentFTType == 6) {
				self.currentFTType = 0
			}
			else {
				self.currentFTType += 1
			}
			self.updateSelectedAttrs()
			self.view.layer.transform = CATransform3DMakeTranslation(-self.view.bounds.size.width, 0, 0)
			UIView.animateWithDuration(0.12, delay: 0.0, options: .CurveEaseOut, animations: {
				self.view.layer.transform = CATransform3DIdentity
				self.view.alpha = 0.7
				}, completion: nil)
		}
		
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
		
        let cell = tableView.dequeueReusableCellWithIdentifier("fontCell", forIndexPath: indexPath) as! FontsTableViewCell

        // Configure the cell...
		
		let dataSource = fDataSource.objectAtIndex(currentFTType) as! XDataSource
		let dict = dataSource.array.objectAtIndex(indexPath.row) as! NSDictionary
		cell.fontNameLabel?.text = dict.objectForKey("displayName") as? String
		
		let currentDict = selectedAttrs.objectAtIndex(currentFTType) as! NSDictionary
		
		cell.ticked = dict["value"]!.isEqual(currentDict["value"])
//		
//		if (dict["value"]!.isEqual(currentDict["value"])) {
//			cell.imageView?.image = UIImage(named: "tickmark")
//		}
//		else {
//			cell.imageView?.image = UIImage()
//		}
		
		if (currentFTType == 0) {
			cell.fontNameLabel?.font = UIFont(name: dict["value"] as! String, size: 25)!
		}
		else {
			cell.fontNameLabel?.font = UIFont(name: "Impact", size: 25)!
		}

		return cell
    }
	
	// MARK: - Table view delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		let dataSource = fDataSource.objectAtIndex(currentFTType) as! XDataSource
		let dict = dataSource.array.objectAtIndex(indexPath.row) as! NSDictionary
		
		let fttype = FontTableTypes[currentFTType]
		
		switch fttype {
			case .Font:
				let fontName = dict["value"] as! String
				topTextAttr.font = UIFont(name: fontName, size: topTextAttr.fontSize)!
				bottomTextAttr.font = UIFont(name: fontName, size: bottomTextAttr.fontSize)!
				// Specific fonts shouldn't have outlines
				if ("AvenirCondensedHand Arabella Darkwoman angelina TrashHand JennaSue HoneyScript-Light daniel Bolina LouisaCP Prisma".containsString(fontName)) {
					topTextAttr.outlineColor = UIColor.clearColor()
					topTextAttr.strokeWidth = 0.0
					bottomTextAttr.outlineColor = UIColor.clearColor()
					bottomTextAttr.strokeWidth = 0.0
				}
				if ("AppleSDGothicNeo Copperplate LeagueGothic-Regular LeagueGothic-Italic EtelkaNarrowTextPro TrashHand Skipping_Stones MarketingScript Artbrush".containsString(fontName)) {
					topTextAttr.outlineColor = UIColor.blackColor()
					topTextAttr.strokeWidth = 1.0
					bottomTextAttr.outlineColor = UIColor.blackColor()
					bottomTextAttr.strokeWidth = 1.0
				}
			case .Alignment:
				let align = dict["value"] as! Int
				topTextAttr.alignment = Alignments[align]
				bottomTextAttr.alignment = Alignments[align]
			case .TextColor:
				topTextAttr.textColor = dict["value"] as! UIColor
				bottomTextAttr.textColor = dict["value"] as! UIColor
			case .OutlineColor:
				topTextAttr.outlineColor = dict["value"] as! UIColor
				bottomTextAttr.outlineColor = dict["value"] as! UIColor
			case .Opacity:
				topTextAttr.opacity = dict["value"] as! CGFloat
				bottomTextAttr.opacity = dict["value"] as! CGFloat
			case .OutlineThickness:
				let thickness = dict["value"] as! CGFloat
				topTextAttr.strokeWidth = thickness
				bottomTextAttr.strokeWidth = thickness
			case .RelativeFontSize:
				let size = dict["value"] as! CGFloat
				topTextAttr.fontSize = size
				bottomTextAttr.fontSize = size
		}
		
		if (indexPath.row == 0 && currentFTType == 0) {
			// Restore default...
			topTextAttr.setDefault()
			bottomTextAttr.setDefault()
		}
		
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		
		updateSelectedAttrs()
		
		self.textAttrChangeDelegate?.didUpdateTextAttributes(topTextAttr, bottomTextAttributes: bottomTextAttr)
		
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 30))
		headerView.backgroundColor = globalBackColor
		let label = UILabel(frame: CGRectMake(16, 0, self.view.frame.size.width - 76, 25))
		let dataSource = fDataSource.objectAtIndex(currentFTType) as! XDataSource
		label.text = dataSource.title?.uppercaseString
		label.textAlignment = .Center
		label.font = UIFont(name: "Impact", size: 15)
		label.textColor = globalTintColor
		headerView.addSubview(label)
		return headerView
	}
	
}
