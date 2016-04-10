//
//  UnderlinedLabel.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/7/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class UnderlinedLabel: UILabel {
	
	@IBInspectable var drawsUnderline: Bool = false {
		didSet {
			setNeedsDisplay()
		}
	}

    override func drawRect(rect: CGRect) {
		
		super.drawRect(rect)
		
		if (drawsUnderline) {
			let beizerPath = beizerPathForText(self.text! as NSString, alignment: self.textAlignment)
			beizerPath.lineWidth = 1.5
			self.textColor.setStroke()
			beizerPath.stroke()
		}
		
    }
	
	func beizerPathForText(text: NSString, alignment: NSTextAlignment) -> UIBezierPath {
		let SIZE = self.bounds.size
		let ORIGIN = self.bounds.origin
		let boundingRect = text.boundingRectWithSize(CGSizeMake(1000, 1000), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.font], context: nil)
		let prescribedLength = boundingRect.size.width
		let offset = (SIZE.width - prescribedLength)/2
		let beizerPath = UIBezierPath()
		switch alignment {
			case .Center:
				beizerPath.moveToPoint(CGPointMake(ORIGIN.x + offset, ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLineToPoint(CGPointMake(ORIGIN.x + SIZE.width - offset, ORIGIN.y + SIZE.height - 2.0))
			case .Right:
				beizerPath.moveToPoint(CGPointMake(ORIGIN.x + SIZE.width - prescribedLength, ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLineToPoint(CGPointMake(SIZE.width, ORIGIN.y + SIZE.height - 2.0))
			default:
				beizerPath.moveToPoint(CGPointMake(ORIGIN.x, ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLineToPoint(CGPointMake(ORIGIN.x + prescribedLength, ORIGIN.y + SIZE.height - 2.0))
		}
		return beizerPath
	}

}
