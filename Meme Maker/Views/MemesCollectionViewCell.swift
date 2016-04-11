//
//  MemesCollectionViewCell.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SDWebImage

private enum CellMode {
	case Meme
	case Created
	case UserCreation
}

class MemesCollectionViewCell: UICollectionViewCell {
	
	var meme: XMeme? = nil {
		didSet {
			self.memeNameLabel.text = meme?.name
			self.updateImageView()
		}
	}
	
	var isListCell: Bool = true {
		didSet {
			self.setNeedsDisplay()
			tintColor = globalTintColor
			memeNameLabel.textColor = globalTintColor
			backgroundColor = globalBackColor
			self.updateImageView()
		}
	}

	@IBOutlet weak var memeImageView: UIImageView!
	@IBOutlet weak var memeNameLabel: UILabel!
	
	override func drawRect(rect: CGRect) {
		
		if (isListCell) {
			// Disclosure
			/*
			let disclosurePath = UIBezierPath()
			disclosurePath.lineWidth = 1.0;
			disclosurePath.lineCapStyle = .Round
			disclosurePath.lineJoinStyle = .Round
			disclosurePath.moveToPoint(CGPointMake(self.bounds.width - 12, self.center.y - 4))
			disclosurePath.addLineToPoint(CGPointMake(self.bounds.width - 8, self.center.y))
			disclosurePath.addLineToPoint(CGPointMake(self.bounds.width - 12, self.center.y + 4))
			UIColor.lightGrayColor().setStroke()
			disclosurePath.stroke()
			*/

			// Separator
			let beizerPath = UIBezierPath()
			beizerPath.lineWidth = 0.5
			beizerPath.lineCapStyle = .Round
			beizerPath.moveToPoint(CGPointMake(self.bounds.height + 8, self.bounds.height - 0.5))
			beizerPath.addLineToPoint(CGPointMake(self.bounds.width, self.bounds.height - 0.5))
			UIColor.lightGrayColor().setStroke()
			beizerPath.stroke()
		}
		
	}
	
	func updateImageView() -> Void {
		
		let filePath = imagesPathForFileName("\(self.meme!.memeID)")
		if (NSFileManager.defaultManager().fileExistsAtPath(filePath)) {
			if (self.isListCell) {
				let filePathC = imagesPathForFileName("\(self.meme!.memeID)c")
				if (NSFileManager.defaultManager().fileExistsAtPath(filePathC)) {
					self.memeImageView.image = UIImage(contentsOfFile: filePathC)
				}
				else {
					let image = getCircularImage(UIImage(contentsOfFile: filePath)!)
					let data = UIImagePNGRepresentation(image)
					data?.writeToFile(filePathC, atomically: true)
					self.memeImageView.image = image
				}
			}
			else {
				let filePathS = imagesPathForFileName("\(self.meme!.memeID)s")
				if (NSFileManager.defaultManager().fileExistsAtPath(filePathS)) {
					self.memeImageView.image = UIImage(contentsOfFile: filePathS)
				}
				else {
					let image = getSquareImage(UIImage(contentsOfFile: filePath)!)
					let data = UIImageJPEGRepresentation(image, 0.8)
					data?.writeToFile(filePathS, atomically: true)
					self.memeImageView.image = image
				}
			}
		}
		else {
			self.memeImageView.image = UIImage(named: "MemeBlank")
			if let URL = meme?.imageURL {
				self.downloadImageWithURL(URL, filePath: filePath)
			}
		}
		
	}
	
	func downloadImageWithURL(URL: NSURL, filePath: String) -> Void {
		SDWebImageDownloader.sharedDownloader().downloadImageWithURL(URL, options: .ProgressiveDownload, progress: nil, completed: { (image, data, error, success) in
			if (success && error == nil) {
				data.writeToFile(filePath, atomically: true)
				dispatch_async(dispatch_get_main_queue(), {
					self.updateImageView()
				})
			}
		})
	}
	
}
