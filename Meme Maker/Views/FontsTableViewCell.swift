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
	
	override func draw(_ rect: CGRect) {
		if (ticked) {
			let w = self.bounds.size.width
			let h = self.bounds.size.height
			tickPath.move(to: CGPoint(x: w - 60, y: h - 40))
			tickPath.addLine(to: CGPoint(x: w - 48, y: h - 16))
			tickPath.addLine(to: CGPoint(x: w - 16, y: h - 60))
			tickPath.addLine(to: CGPoint(x: w - 48, y: h - 28))
			tickPath.close()
			globalTintColor.setFill()
			tickPath.fill()
		}
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
