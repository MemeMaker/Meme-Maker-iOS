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

    override func draw(_ rect: CGRect) {
		
		super.draw(rect)
		
		if (drawsUnderline) {
			let beizerPath = beizerPathForText(self.text! as NSString, alignment: self.textAlignment)
			beizerPath.lineWidth = 1.5
			self.textColor.setStroke()
			beizerPath.stroke()
		}
		
    }
	
	func beizerPathForText(_ text: NSString, alignment: NSTextAlignment) -> UIBezierPath {
		let SIZE = self.bounds.size
		let ORIGIN = self.bounds.origin
		let boundingRect = text.boundingRect(with: CGSize(width: 1000, height: 1000), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.font], context: nil)
		let prescribedLength = boundingRect.size.width
		let offset = (SIZE.width - prescribedLength)/2
		let beizerPath = UIBezierPath()
		switch alignment {
			case .center:
				beizerPath.move(to: CGPoint(x: ORIGIN.x + offset, y: ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLine(to: CGPoint(x: ORIGIN.x + SIZE.width - offset, y: ORIGIN.y + SIZE.height - 2.0))
			case .right:
				beizerPath.move(to: CGPoint(x: ORIGIN.x + SIZE.width - prescribedLength, y: ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLine(to: CGPoint(x: SIZE.width, y: ORIGIN.y + SIZE.height - 2.0))
			default:
				beizerPath.move(to: CGPoint(x: ORIGIN.x, y: ORIGIN.y + SIZE.height - 2.0))
				beizerPath.addLine(to: CGPoint(x: ORIGIN.x + prescribedLength, y: ORIGIN.y + SIZE.height - 2.0))
		}
		return beizerPath
	}

}
