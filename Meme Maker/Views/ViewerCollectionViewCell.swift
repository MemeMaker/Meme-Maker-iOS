//
//  ViewerCollectionViewCell.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/9/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import AVFoundation

class ViewerCollectionViewCell: UICollectionViewCell {
	
	var image: UIImage = UIImage() {
		didSet {
			setNeedsDisplay()
		}
	}
	
	var topText: String = "" {
		didSet {
//			setNeedsDisplay()
		}
	}
	
	var bottomText: String = "" {
		didSet {
//			setNeedsDisplay()
		}
	}
	
	override func draw(_ rect: CGRect) {
		
		super.draw(rect)
		
		let size = max(self.bounds.size.width, self.bounds.size.height)
		var ratio: CGFloat = 1
		if max(image.size.width, image.size.height) > 0 {
			ratio = size/max(image.size.width, image.size.height)
		}
		
		var baseImage = UIImage()
		if (image.size.width > 10) {
			baseImage = getImageByResizingImage(image, ratio: ratio)
		}
		
		let topTextAttr = XTextAttributes(savename: "topo")
		topTextAttr.fontSize = 20
		topTextAttr.font = UIFont(name: "LeagueGothic-Regular", size: 16)!
		topTextAttr.strokeWidth = 0
		topTextAttr.text = topText as NSString
		let bottomTextAttr = XTextAttributes(savename: "boto")
		bottomTextAttr.text = bottomText as NSString
		bottomTextAttr.fontSize = 20
		bottomTextAttr.font = UIFont(name: "LeagueGothic-Regular", size: 16)!
		bottomTextAttr.strokeWidth = 0
		
		let maxHeight = self.bounds.height/2 - 4	// Max height of top and bottom texts
		let stringDrawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
		
		var topTextRect = topTextAttr.text.boundingRect(with: CGSize(width: self.bounds.width, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRect(x: 4, y: 4, width: self.bounds.width - 8, height: self.bounds.height/2 - 4)
		// Adjust top size
		while (ceil(topTextRect.size.height) >= maxHeight) {
			topTextAttr.fontSize -= 1;
			topTextRect = topTextAttr.text.boundingRect(with: CGSize(width: self.bounds.width - 8, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomTextAttr.text.boundingRect(with: CGSize(width: self.bounds.width, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		var expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRect(x: 4, y: (self.bounds.height - expectedBottomSize.height), width: self.bounds.width - 8, height: expectedBottomSize.height);
		// Adjust bottom size
		while (ceil(bottomTextRect.size.height) >= maxHeight) {
			bottomTextAttr.fontSize -= 1;
			bottomTextRect = bottomTextAttr.text.boundingRect(with: CGSize(width: self.bounds.width - 8, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
			expectedBottomSize = bottomTextRect.size
			bottomTextAttr.rect = CGRect(x: 4, y: (self.bounds.height - expectedBottomSize.height), width: self.bounds.width - 8, height: expectedBottomSize.height)
		}
	
		baseImage.drawInRectAspectFill(self.bounds)
		
		topText.draw(in: topTextAttr.rect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.draw(in: bottomTextAttr.rect, withAttributes: bottomTextAttr.getTextAttributes())
		
	}
	
}
