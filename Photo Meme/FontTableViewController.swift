//
//  FontTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

enum FontTableType {
	case font
	case alignment
	case textColor
	case outlineColor
	case opacity
	case outlineThickness
	case relativeFontSize
}

let Alignments = [NSTextAlignment.center, NSTextAlignment.justified, NSTextAlignment.left, NSTextAlignment.right]

let FontTableTypes = [FontTableType.font, FontTableType.alignment, FontTableType.textColor, FontTableType.outlineColor, FontTableType.opacity, FontTableType.outlineThickness, FontTableType.relativeFontSize]

protocol TextAttributeChangingDelegate {
	func didUpdateTextAttributes(_ topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) -> Void
}

class XDataSource: NSObject {
	var title: String?
	var fontTableType: FontTableType = .font
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
	
	var fontSize: CGFloat = 18

    override func viewDidLoad() {
		
        super.viewDidLoad()
		
		self.tableView.separatorStyle = .none
		
		self.view.backgroundColor = UIColor(red: 239/255, green: 240/255, blue: 239/255, alpha: 1)
		
		self.view.alpha = 0.7
		self.view.layer.cornerRadius = 8.0
		
		let horizontalME = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
		horizontalME.maximumRelativeValue = -10
		horizontalME.minimumRelativeValue = 10
		self.view.addMotionEffect(horizontalME)
		
		let verticalME = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		verticalME.maximumRelativeValue = -10
		verticalME.minimumRelativeValue = 10
		self.view.addMotionEffect(verticalME)
		
		self.view.layer.shadowPath = UIBezierPath(rect: self.view.bounds).cgPath
		self.view.layer.shadowColor = UIColor.black.cgColor
		self.view.layer.shadowOffset = CGSize.zero
		self.view.layer.shadowRadius = 1.5
		self.view.layer.shadowOpacity = 0.8
		
		var dFonts: NSMutableArray?
		if let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "fonts", ofType: "json")!)) {
			do {
				let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
				dFonts = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			fontSize = 25
		}
		else {
			fontSize = 18
		}
		
		// For now I'm gonna hard-code these values, maybe later move them to JSON or server
		
		let dAlignments = NSMutableArray(objects:
			 ["displayName": "Center (Default)", "value": 0],
			 ["displayName": "Justify", "value": 1],
			 ["displayName": "Left", "value": 2],
			 ["displayName": "Right", "value": 3])
		
		let dTextColors = NSMutableArray(objects:
			["displayName": "White (Default)", "value": UIColor.white],
			["displayName": "Black", "value": UIColor.black],
			["displayName": "Yellow", "value": UIColor.yellow],
			["displayName": "Green", "value": UIColor.green],
			["displayName": "Cyan", "value": UIColor.cyan],
			["displayName": "Purple", "value": UIColor.purple],
			["displayName": "Magenta", "value": UIColor.magenta],
			["displayName": "Red", "value": UIColor.red],
			["displayName": "Light Gray", "value": UIColor.lightGray],
			["displayName": "Dark Gray", "value": UIColor.darkGray],
			["displayName": "Transparent", "value": UIColor.clear])
		
		let dOutlineColors = NSMutableArray(objects:
			["displayName": "Black (Default)", "value": UIColor.black],
			["displayName": "Dark Gray", "value": UIColor.darkGray],
			["displayName": "White", "value": UIColor.white],
			["displayName": "Brown", "value": UIColor.brown],
			["displayName": "Purple", "value": UIColor.purple],
			["displayName": "Magenta", "value": UIColor.magenta],
			["displayName": "Red", "value": UIColor.red],
			["displayName": "Light Gray", "value": UIColor.lightGray],
			["displayName": "No outline", "value": UIColor.clear])
		
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
			XDataSource(fontTableType: .font, array: dFonts!, title: "Fonts"),
			XDataSource(fontTableType: .alignment, array: dAlignments, title: "Text Alignment"),
			XDataSource(fontTableType: .textColor, array: dTextColors, title: "Text Color"),
			XDataSource(fontTableType: .outlineColor, array: dOutlineColors, title: "Outline Color"),
			XDataSource(fontTableType: .opacity, array: dOpacity, title: "Opacity"),
			XDataSource(fontTableType: .outlineThickness, array: dOutlineThickness, title: "Outline Thickness"),
			XDataSource(fontTableType: .relativeFontSize, array: dRelativeFontSize, title: "Relative Font Scale"))

		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .left
		self.view.addGestureRecognizer(swipeLeft!)
		swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeRightAction))
		swipeRight?.direction = .right
		self.view.addGestureRecognizer(swipeRight!)
		
		currentFTType = 0
		
		selectedAttrs = NSMutableArray(objects:
			NSMutableDictionary(dictionary: dFonts?.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dAlignments.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dTextColors.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dOutlineColors.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dOpacity.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dOutlineThickness.object(at: 0) as! Dictionary),
			NSMutableDictionary(dictionary: dRelativeFontSize.object(at: 0) as! Dictionary))
		
		updateSelectedAttrs()
		
    }
	
	func updateSelectedAttrs () {
		
		let dict0 = selectedAttrs.object(at: 0) as! NSMutableDictionary
		dict0["value"] = topTextAttr.font.fontName
		
		let dict1 = selectedAttrs.object(at: 1) as! NSMutableDictionary
		dict1["value"] = Alignments.index(of: topTextAttr.alignment)
		
		let dict2 = selectedAttrs.object(at: 2) as! NSMutableDictionary
		dict2["value"] = topTextAttr.textColor
		
		let dict3 = selectedAttrs.object(at: 3) as! NSMutableDictionary
		dict3["value"] = topTextAttr.outlineColor
		
		let dict4 = selectedAttrs.object(at: 4) as! NSMutableDictionary
		dict4["value"] = topTextAttr.opacity
		
		let dict5 = selectedAttrs.object(at: 5) as! NSMutableDictionary
		dict5["value"] = topTextAttr.strokeWidth
		
		let dict6 = selectedAttrs.object(at: 6) as! NSMutableDictionary
		dict6["value"] = topTextAttr.fontSize
		
		self.tableView.reloadData()
		
	}
	
	// MARK: - Handle swipe
	
	func swipeLeftAction() -> Void {
		
		UIView.animate(withDuration: 0.12, delay: 0.0, options: .curveEaseIn, animations: {
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
				UIView.animate(withDuration: 0.12, delay: 0.0, options: .curveEaseOut, animations: {
					self.view.layer.transform = CATransform3DIdentity
					self.view.alpha = 0.7
					}, completion: nil)
		}
		
	}
	
	func swipeRightAction() -> Void {
		
		UIView.animate(withDuration: 0.12, delay: 0.0, options: .curveEaseIn, animations: {
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
			UIView.animate(withDuration: 0.12, delay: 0.0, options: .curveEaseOut, animations: {
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let dataSource = fDataSource.object(at: currentFTType) as! XDataSource
        return dataSource.array.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
        let cell = tableView.dequeueReusableCell(withIdentifier: "fontCell", for: indexPath) as! FontsTableViewCell

        // Configure the cell...
		
		let dataSource = fDataSource.object(at: currentFTType) as! XDataSource
		let dict = dataSource.array.object(at: indexPath.row) as! NSDictionary
		cell.fontNameLabel?.text = dict.object(forKey: "displayName") as? String
		
		cell.fontNameLabel.textColor = UIColor(red: 50/255, green: 100/255, blue: 0, alpha: 1)
		
		let currentDict = selectedAttrs.object(at: currentFTType) as! NSDictionary
		
		cell.ticked = (dict["value"]! as AnyObject).isEqual(currentDict["value"])
//		
//		if (dict["value"]!.isEqual(currentDict["value"])) {
//			cell.imageView?.image = UIImage(named: "tickmark")
//		}
//		else {
//			cell.imageView?.image = UIImage()
//		}
		
		if (currentFTType == 0) {
			cell.fontNameLabel?.font = UIFont(name: dict["value"] as! String, size: fontSize)!
		}
		else {
			cell.fontNameLabel?.font = UIFont(name: "Impact", size: fontSize)!
		}

		return cell
	}
	
	// MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			return 70
		}
		return 52
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		let dataSource = fDataSource.object(at: currentFTType) as! XDataSource
		let dict = dataSource.array.object(at: indexPath.row) as! NSDictionary
		
		let fttype = FontTableTypes[currentFTType]
		
		switch fttype {
			case .font:
				let fontName = dict["value"] as! String
				topTextAttr.font = UIFont(name: fontName, size: topTextAttr.fontSize)!
				bottomTextAttr.font = UIFont(name: fontName, size: bottomTextAttr.fontSize)!
				// Specific fonts shouldn't have outlines
				if ("AvenirCondensedHand Arabella Darkwoman angelina TrashHand JennaSue HoneyScript-Light daniel Bolina LouisaCP Prisma CaviarDreams Gravity-Book Existence-Light".contains(fontName)) {
					topTextAttr.outlineColor = UIColor.clear
					topTextAttr.strokeWidth = 0.0
					bottomTextAttr.outlineColor = UIColor.clear
					bottomTextAttr.strokeWidth = 0.0
				}
				if ("AppleSDGothicNeo Copperplate LeagueGothic-Regular LeagueGothic-Italic EtelkaNarrowTextPro TrashHand Skipping_Stones MarketingScript Artbrush Roboto-Bold theboldfont".contains(fontName)) {
					topTextAttr.outlineColor = UIColor.black
					topTextAttr.strokeWidth = 1.0
					bottomTextAttr.outlineColor = UIColor.black
					bottomTextAttr.strokeWidth = 1.0
			}
			case .alignment:
				let align = dict["value"] as! Int
				topTextAttr.alignment = Alignments[align]
				bottomTextAttr.alignment = Alignments[align]
			case .textColor:
				topTextAttr.textColor = dict["value"] as! UIColor
				bottomTextAttr.textColor = dict["value"] as! UIColor
			case .outlineColor:
				topTextAttr.outlineColor = dict["value"] as! UIColor
				bottomTextAttr.outlineColor = dict["value"] as! UIColor
			case .opacity:
				topTextAttr.opacity = dict["value"] as! CGFloat
				bottomTextAttr.opacity = dict["value"] as! CGFloat
			case .outlineThickness:
				let thickness = dict["value"] as! CGFloat
				topTextAttr.strokeWidth = thickness
				bottomTextAttr.strokeWidth = thickness
			case .relativeFontSize:
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
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
		headerView.backgroundColor = UIColor(red: 239/255, green: 240/255, blue: 239/255, alpha: 1)
		let label = UILabel(frame: CGRect(x: 16, y: 0, width: self.view.frame.size.width - 76, height: 25))
		let dataSource = fDataSource.object(at: currentFTType) as! XDataSource
		label.text = dataSource.title?.uppercased()
		label.textAlignment = .center
		label.font = UIFont(name: "Impact", size: 15)
		label.textColor = UIColor(red: 50/255, green: 100/255, blue: 0, alpha: 1)
		headerView.addSubview(label)
		return headerView
	}
	
}
