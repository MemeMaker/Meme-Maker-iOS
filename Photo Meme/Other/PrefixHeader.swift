//
//  PrefixHeader.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import UIKit

func getDocumentsDirectory() -> String {
	let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
	let documentsDirectory = paths[0]
	return documentsDirectory
}

func documentsPathForFileName(name: String) -> String {
	let directoryPath = getDocumentsDirectory().stringByAppendingString("/resources/")
	let manager = NSFileManager.defaultManager()
	if (!manager.fileExistsAtPath(directoryPath)) {
		do {
			try manager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath.stringByAppendingString("\(name).dat")
}

func getImageByResizingImage(image: UIImage, ratio: CGFloat) -> UIImage {
	let imageRect = CGRectMake(0, 0, image.size.width * ratio, image.size.height * ratio)
	UIGraphicsBeginImageContext(CGSizeMake(image.size.width * ratio, image.size.height * ratio))
	image.drawInRect(imageRect)
	let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()
	return newImage
}

extension UIColor {
	var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r,g,b,a)
	}
}

extension UIImage {
	func drawInRectAspectFill(rect: CGRect) {
		let targetSize = rect.size
		let scaledImage: UIImage
		if targetSize == CGSizeZero {
			scaledImage = self
		}
		else {
//			let aspectRatio = self.size.width / self.size.height
			let scalingFactor = targetSize.width / self.size.width > targetSize.height / self.size.height ? targetSize.width / self.size.width: targetSize.height / self.size.height
			let newSize = CGSize(width: self.size.width * scalingFactor, height: self.size.height * scalingFactor)
			UIGraphicsBeginImageContext(targetSize)
			self.drawInRect(CGRect(origin: CGPoint(x: (targetSize.width - newSize.width) / 2, y: (targetSize.height - newSize.height) / 2), size: newSize))
			scaledImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}
		scaledImage.drawInRect(rect)
	}
}