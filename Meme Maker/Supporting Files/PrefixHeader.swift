//
//  PrefixHeader.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import UIKit

let API_BASE_URL: String = "http://alpha-meme-maker.herokuapp.com"

func apiMemesPaging(_ page: Int) -> URL {
	return URL(string: "\(API_BASE_URL)/\(page)/")!
}

func apiParticularMeme(_ memeID: Int) -> URL {
	return URL(string: "\(API_BASE_URL)/memes/\(memeID)/")!
}

func apiSubmissionsPaging(_ page: Int) -> URL {
	return URL(string: "\(API_BASE_URL)/submissions/\(page)/")!
}

func apiSubmissionsForMeme(_ memeID: Int) -> URL {
	return URL(string: "\(API_BASE_URL)/memes/\(memeID)/submissions/")!
}

func getDocumentsDirectory() -> String {
	let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
	let documentsDirectory = paths[0]
	return documentsDirectory
}

func imagesPathForFileName(_ name: String) -> String {
	let directoryPath = getDocumentsDirectory() + "/images/"
	let manager = FileManager.default
	if (!manager.fileExists(atPath: directoryPath)) {
		do {
			try manager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath + "\(name).jpg"
}

func getImagesFolder() -> String {
	let directoryPath = getDocumentsDirectory() + "/images/"
	let manager = FileManager.default
	if (!manager.fileExists(atPath: directoryPath)) {
		do {
			try manager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath
}

func userImagesPathForFileName(_ name: String) -> String {
	let directoryPath = getDocumentsDirectory() + "/userImages/"
	let manager = FileManager.default
	if (!manager.fileExists(atPath: directoryPath)) {
		do {
			try manager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
		} catch _ { }
	}
	return directoryPath + "\(name).jpg"
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

func getCircularImage(_ image: UIImage) -> UIImage {
	let minwh = min(image.size.width, image.size.height)
	let centerRect = CGRect(x: (image.size.width - minwh)/2, y: (image.size.height - minwh)/2, width: minwh, height: minwh)
	let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
	UIGraphicsBeginImageContext(imageRect.size)
	let maskPath = UIBezierPath(ovalIn: centerRect)
	maskPath.addClip()
	image.draw(in: imageRect)
	let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
	UIGraphicsEndImageContext()
	let ratio1 = 180/image.size.height
	let ratio2 = 180/image.size.width
	let ratio = min(ratio1, ratio2)
	let resizedImage = getImageByResizingImage(newImage, ratio: ratio)
	return resizedImage
}

func getSquareImage(_ image: UIImage) -> UIImage {
	let minwh = min(image.size.width, image.size.height)
	let centerRect = CGRect(x: (image.size.width - minwh)/2, y: (image.size.height - minwh)/2, width: minwh, height: minwh)
	let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
	UIGraphicsBeginImageContext(imageRect.size)
	let maskPath = UIBezierPath(rect: centerRect)
	maskPath.addClip()
	image.draw(in: imageRect)
	let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
	UIGraphicsEndImageContext()
	let ratio1 = 240/image.size.height
	let ratio2 = 240/image.size.width
	let ratio = min(ratio1, ratio2)
	let resizedImage = getImageByResizingImage(newImage, ratio: ratio)
	return resizedImage
}

func getImageByResizingImage(_ image: UIImage, ratio: CGFloat) -> UIImage {
	let imageRect = CGRect(x: 0, y: 0, width: image.size.width * ratio, height: image.size.height * ratio)
	UIGraphicsBeginImageContext(CGSize(width: image.size.width * ratio, height: image.size.height * ratio))
	image.draw(in: imageRect)
	let newImage = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()
	return newImage!
}

func getImageByDrawingOnImage(_ image: UIImage, topText: String, bottomText: String) -> UIImage {
	
	let ratio1 = 600/image.size.height
	let ratio2 = 600/image.size.width
	let ratio = min(ratio1, ratio2)
	let baseImage = getImageByResizingImage(image, ratio: ratio)
	
	let imageSize = baseImage.size as CGSize!
	let topTextAttr = XTextAttributes(savename: "topo")
	topTextAttr.fontSize = 44
	topTextAttr.font = UIFont(name: "LeagueGothic-Regular", size: 44)!
	topTextAttr.strokeWidth = 0.5
	topTextAttr.text = topText as NSString
	let bottomTextAttr = XTextAttributes(savename: "boto")
	bottomTextAttr.text = bottomText as NSString
	bottomTextAttr.fontSize = 44
	bottomTextAttr.font = UIFont(name: "LeagueGothic-Regular", size: 44)!
	bottomTextAttr.strokeWidth = 0.5
	
	let maxHeight = imageSize?.height/2	// Max height of top and bottom texts
	let stringDrawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
	
	var topTextRect = topTextAttr.text.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
	topTextAttr.rect = CGRect(x: 0, y: 0, width: imageSize?.width, height: imageSize.height/2)
	// Adjust top size
	while (ceil(topTextRect.size.height) > maxHeight) {
		topTextAttr.fontSize -= 1;
		topTextRect = topTextAttr.text.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
	}
	
	var bottomTextRect = bottomTextAttr.text.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
	var expectedBottomSize = bottomTextRect.size
	// Bottom rect starts from bottom, not from center.y
	bottomTextAttr.rect = CGRect(x: 0, y: (imageSize.height) - (expectedBottomSize.height), width: imageSize.width, height: imageSize.height/2);
	// Adjust bottom size
	while (ceil(bottomTextRect.size.height) > maxHeight) {
		bottomTextAttr.fontSize -= 1;
		bottomTextRect = bottomTextAttr.text.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		expectedBottomSize = bottomTextRect.size
		bottomTextAttr.rect = CGRect(x: 0, y: (imageSize.height) - (expectedBottomSize.height), width: imageSize.width, height: imageSize.height/2)
	}
	
	UIGraphicsBeginImageContext(imageSize!)
	
	baseImage.draw(in: CGRect(x: 0, y: 0, width: imageSize?.width, height: imageSize.height))
	
	topText.uppercased().draw(in: topTextAttr.rect, withAttributes: topTextAttr.getTextAttributes())
	bottomText.uppercased().draw(in: bottomTextAttr.rect, withAttributes: bottomTextAttr.getTextAttributes())
	
	let newImage = UIGraphicsGetImageFromCurrentImageContext()
	
	UIGraphicsEndImageContext()
	
	return newImage!
	
}

func modalAlertControllerFor(_ title: String, message: String) -> UIAlertController {
	let alertC = UIAlertController(title: title, message: message, preferredStyle: .alert)
	let cancelA = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
	alertC.addAction(cancelA)
	return alertC
}

extension UIColor {
	var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r,g,b,a)
	}
}

extension UIDevice {
	var modelName: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		switch identifier {
			case "iPod5,1":                                 return "iPod Touch 5"
			case "iPod7,1":                                 return "iPod Touch 6"
			case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
			case "iPhone4,1":                               return "iPhone 4s"
			case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
			case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
			case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
			case "iPhone7,2":                               return "iPhone 6"
			case "iPhone7,1":                               return "iPhone 6 Plus"
			case "iPhone8,1":                               return "iPhone 6s"
			case "iPhone8,2":                               return "iPhone 6s Plus"
			case "iPhone8,4":                               return "iPhone SE"
			case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
			case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
			case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
			case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
			case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
			case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
			case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
			case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
			case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
			case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
			case "AppleTV5,3":                              return "Apple TV"
			case "i386", "x86_64":                          return "Simulator"
			default:                                        return identifier
		}
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
