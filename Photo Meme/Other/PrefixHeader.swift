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
	let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
	let documentsDirectory = paths[0]
	return documentsDirectory
}

func documentsPathForFileName(_ name: String) -> String {
	let directoryPath = getDocumentsDirectory() + "/resources/"
	let manager = FileManager.default
	if (!manager.fileExists(atPath: directoryPath)) {
		do {
			try manager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath + "\(name).dat"
}

func getImageByResizingImage(_ image: UIImage, ratio: CGFloat) -> UIImage {
	let imageRect = CGRect(x: 0, y: 0, width: image.size.width * ratio, height: image.size.height * ratio)
	UIGraphicsBeginImageContext(CGSize(width: image.size.width * ratio, height: image.size.height * ratio))
	image.draw(in: imageRect)
	let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
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
	func drawInRectAspectFill(_ rect: CGRect) {
		let targetSize = rect.size
		let scaledImage: UIImage
		if targetSize == CGSize.zero {
			scaledImage = self
		}
		else {
//			let aspectRatio = self.size.width / self.size.height
			let scalingFactor = targetSize.width / self.size.width > targetSize.height / self.size.height ? targetSize.width / self.size.width: targetSize.height / self.size.height
			let newSize = CGSize(width: self.size.width * scalingFactor, height: self.size.height * scalingFactor)
			UIGraphicsBeginImageContext(targetSize)
			self.draw(in: CGRect(origin: CGPoint(x: (targetSize.width - newSize.width) / 2, y: (targetSize.height - newSize.height) / 2), size: newSize))
			scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
		}
		scaledImage.draw(in: rect)
	}
}
