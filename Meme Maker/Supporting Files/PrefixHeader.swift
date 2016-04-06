//
//  PrefixHeader.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import UIKit

let API_BASE_URL: String = "http://alpha-meme-maker.herokuapp.com/"

func apiMemesPaging(page: Int) -> NSURL {
	return NSURL(string: "http://alpha-meme-maker.herokuapp.com/\(page)")!
}

func apiParticularMeme(memeID: Int) -> NSURL {
	return NSURL(string: "http://alpha-meme-maker.herokuapp.com/memes/\(memeID)")!
}

func apiSubmissionsPaging(page: Int) -> NSURL {
	return NSURL(string: "http://alpha-meme-maker.herokuapp.com/submissions/\(page)")!
}

func apiSubmissionsForMeme(memeID: Int) -> NSURL {
	return NSURL(string: "http://alpha-meme-maker.herokuapp.com/memes/\(memeID)/submissions")!
}

func getDocumentsDirectory() -> String {
	let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
	let documentsDirectory = paths[0]
	return documentsDirectory
}

func imagesPathForFileName(name: String) -> String {
	let directoryPath = getDocumentsDirectory().stringByAppendingString("/images/")
	let manager = NSFileManager.defaultManager()
	if (!manager.fileExistsAtPath(directoryPath)) {
		do {
			try manager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath.stringByAppendingString("\(name).jpg")
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

func getCircularImage(image: UIImage) -> UIImage {
	let minwh = min(image.size.width, image.size.height)
	let centerRect = CGRectMake((image.size.width - minwh)/2, (image.size.height - minwh)/2, minwh, minwh)
	let imageRect = CGRectMake(0, 0, image.size.width, image.size.height)
	UIGraphicsBeginImageContext(imageRect.size)
	let maskPath = UIBezierPath(ovalInRect: centerRect)
	maskPath.addClip()
	image.drawInRect(imageRect)
	let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()
	return newImage
}

func getSquareImage(image: UIImage) -> UIImage {
	let minwh = min(image.size.width, image.size.height)
	let centerRect = CGRectMake((image.size.width - minwh)/2, (image.size.height - minwh)/2, minwh, minwh)
	let imageRect = CGRectMake(0, 0, image.size.width, image.size.height)
	UIGraphicsBeginImageContext(imageRect.size)
	let maskPath = UIBezierPath(rect: centerRect)
	maskPath.addClip()
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