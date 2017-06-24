//
//  XTextAttributes.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class XTextAttributes: NSObject {
	
	var text: NSString! = ""
	var uppercase: Bool = true

	var rect: CGRect = CGRect.zero
	var offset: CGPoint = CGPoint.zero
	
	var fontSize: CGFloat = 44
	var font: UIFont = UIFont(name: "Impact", size: 44)!
	
	var textColor: UIColor = UIColor.white
	var outlineColor: UIColor = UIColor.black
	
	var alignment: NSTextAlignment = .center
	
	var strokeWidth: CGFloat = 2
	
	var opacity: CGFloat = 1
	
	init(savename: String) {
		
		super.init()
		
		do {
			
			text = ""
			rect = CGRect.zero
			setDefault()
			
			if (!FileManager.default.fileExists(atPath: documentsPathForFileName(savename))) {
//				print("No such attribute file")
				return
			}
			
			if let data = try? Data.init(contentsOf: URL(fileURLWithPath: documentsPathForFileName(savename))) {
				
				let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
				
//				print("\(savename) = \(dict)")
				
				text = dict["text"] as! NSString
				uppercase = dict["uppercase"] as! Bool
				
				rect = CGRectFromString(dict["rect"] as! String)
				offset = CGPointFromString(dict["offset"] as! String)
				
				fontSize = dict["fontSize"] as! CGFloat
				let fontName = dict["fontName"] as! String
				font = UIFont(name: fontName, size: fontSize)!
				
				let textRGB =  NSDictionary(dictionary: dict["textColorRGB"] as! Dictionary)
				textColor = UIColor(red: textRGB["red"] as! CGFloat, green: textRGB["green"] as! CGFloat, blue: textRGB["blue"] as! CGFloat, alpha: 1)
				
				let outRGB = dict["outColorRGB"] as! NSDictionary
				outlineColor = UIColor(red: outRGB["red"] as! CGFloat, green: outRGB["green"] as! CGFloat, blue: outRGB["blue"] as! CGFloat, alpha: 1)
				
				let align = dict["alignment"] as! Int
				switch align {
					case 0: alignment = .center
					case 1: alignment = .justified
					case 2: alignment = .left
					case 3: alignment = .right
					default: alignment = .center
				}
				
				strokeWidth = dict["strokeWidth"] as! CGFloat
				
				opacity	= dict["opacity"] as! CGFloat
				
			}
		}
		catch _ {
			print("attribute reading failed")
		}
		
	}
	
	func saveAttributes(_ savename: String) -> Bool {
		
		let dict = NSMutableDictionary()
		
		dict["text"] = text
		dict["uppercase"] = NSNumber(value: uppercase as Bool)
		
		dict["rect"] = NSStringFromCGRect(rect)
		dict["offset"] = NSStringFromCGPoint(offset)
		
		let fontName = font.fontName
		let fontSizeNum = NSNumber(value: Float(fontSize) as Float)
		dict["fontSize"] = fontSizeNum
		dict["fontName"] = fontName
		
		let textCC = textColor.components
		let textRGB = ["red": textCC.red, "green": textCC.green, "blue": textCC.blue]
		dict["textColorRGB"] = textRGB
		
		let outCC = outlineColor.components
		let outRGB = ["red": outCC.red, "green": outCC.green, "blue": outCC.blue]
		dict["outColorRGB"] = outRGB
		
		var align: Int = 0
		switch alignment {
			case .justified: align = 1
			case .left: align = 2
			case .right: align = 3
			default: align = 0
		}
		dict["alignment"] = NSNumber(value: align as Int)
		
		dict["strokeWidth"] = NSNumber(value: Float(strokeWidth) as Float)
		
		dict["opacity"] = NSNumber(value: Float(opacity) as Float)
		
//		print("SAVING : \(savename) = \(dict)")
		
		do {
			let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
			try data.write(to: URL(fileURLWithPath: documentsPathForFileName(savename)), options: .atomicWrite)
		}
		catch _ {
			print("attribute writing failed")
		}
		
		return true
		
	}
	
	func setDefault() -> Void {
		uppercase = true
		offset = CGPoint.zero
		fontSize = 44
		font = UIFont(name: "Impact", size: 44)!
		textColor = UIColor.white
		outlineColor = UIColor.black
		alignment = .center
		strokeWidth = 2
		opacity = 1
	}
	
	func getTextAttributes() -> [String: AnyObject] {
		
		var attr: [String: AnyObject] = [:]
		
		font = UIFont(name: font.fontName, size: fontSize)!
		attr[NSFontAttributeName] = font
		
		attr[NSForegroundColorAttributeName] = textColor.withAlphaComponent(opacity)
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = alignment
		paragraphStyle.maximumLineHeight = fontSize
		
		attr[NSParagraphStyleAttributeName] = paragraphStyle
		
		attr[NSStrokeWidthAttributeName] = NSNumber(value: Float(-strokeWidth) as Float)
		
		attr[NSStrokeColorAttributeName] = outlineColor
		
		let shadow = NSShadow()
		shadow.shadowColor = outlineColor
		shadow.shadowOffset = CGSize(width: 0.1, height: 0.1)
		shadow.shadowBlurRadius = 0.8
		attr[NSShadowAttributeName] = shadow
		
		return attr
		
	}
	
	class func clearTopAndBottomTexts() -> Void {
		// We don't want text to retain while selecting new meme on iPhone, let it be there on iPad
		let topTextAttr = XTextAttributes(savename: "topAttr")
		topTextAttr.text = ""
		topTextAttr.offset = CGPoint.zero
		topTextAttr.fontSize = 44
		topTextAttr.saveAttributes("topAttr")
		let bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		bottomTextAttr.text = ""
		bottomTextAttr.offset = CGPoint.zero
		bottomTextAttr.fontSize = 44
		bottomTextAttr.saveAttributes("bottomAttr")
	}
	
}
