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
	
	override func drawRect(rect: CGRect) {
		
		super.drawRect(rect)
		
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
		topTextAttr.text = topText
		let bottomTextAttr = XTextAttributes(savename: "boto")
		bottomTextAttr.text = bottomText
		bottomTextAttr.fontSize = 20
		bottomTextAttr.font = UIFont(name: "LeagueGothic-Regular", size: 16)!
		bottomTextAttr.strokeWidth = 0
		
		let maxHeight = self.bounds.height/2 - 4	// Max height of top and bottom texts
		let stringDrawingOptions: NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]
		
		var topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(self.bounds.width, maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRectMake(4, 0, self.bounds.width - 8, self.bounds.height/2)
		// Adjust top size
		while (ceil(topTextRect.size.height) >= maxHeight) {
			topTextAttr.fontSize -= 1;
			topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(self.bounds.width - 8, maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(self.bounds.width, maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		var expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRectMake(4, (self.bounds.height - expectedBottomSize.height), self.bounds.width - 8, expectedBottomSize.height);
		// Adjust bottom size
		while (ceil(bottomTextRect.size.height) >= maxHeight) {
			bottomTextAttr.fontSize -= 1;
			bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(self.bounds.width - 8, maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
			expectedBottomSize = bottomTextRect.size
			bottomTextAttr.rect = CGRectMake(4, (self.bounds.height - expectedBottomSize.height), self.bounds.width - 8, expectedBottomSize.height)
		}
	
		baseImage.drawInRectAspectFill(self.bounds)
		
		topText.drawInRect(topTextAttr.rect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.drawInRect(bottomTextAttr.rect, withAttributes: bottomTextAttr.getTextAttributes())
		
	}
	
}
