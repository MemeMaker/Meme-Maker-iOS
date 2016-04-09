//
//  FontsTableViewCell.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/7/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class FontsTableViewCell: UITableViewCell {
	
	@IBOutlet weak var fontNameLabel: UnderlinedLabel!
	
	var tickLayer = CAShapeLayer()
	var tickPath = UIBezierPath()
	var tickAnimation = CABasicAnimation()
	
	var ticked: Bool = false {
		didSet {
			self.fontNameLabel.drawsUnderline = ticked
			setNeedsDisplay()
		}
	}
	
	override func layoutSubviews() {
		tintColor = globalTintColor
		fontNameLabel.textColor = globalTintColor
		backgroundColor = globalBackColor
	}
	
	override func drawRect(rect: CGRect) {
		if (ticked) {
			let w = self.bounds.size.width
			let h = self.bounds.size.height
			tickPath.moveToPoint(CGPointMake(w - 60, h - 40))
			tickPath.addLineToPoint(CGPointMake(w - 48, h - 16))
			tickPath.addLineToPoint(CGPointMake(w - 16, h - 60))
			tickPath.addLineToPoint(CGPointMake(w - 48, h - 28))
			tickPath.closePath()
			globalTintColor.setFill()
			tickPath.fill()
		}
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
