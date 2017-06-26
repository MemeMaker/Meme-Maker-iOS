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
	case meme
	case created
	case userCreation
}

class MemesCollectionViewCell: UICollectionViewCell {
	
	var meme: XMeme? = nil {
		didSet {
			self.memeNameLabel.text = meme?.name
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
	@IBOutlet weak var labelContainerView: UIView!
	
	override func draw(_ rect: CGRect) {
		
		if (isListCell) {
			
			if isDarkMode() {
				UIColor.darkGray.setStroke()
			}
			else {
				UIColor.lightGray.setStroke()
			}
			
			// Disclosure
			let disclosurePath = UIBezierPath()
			disclosurePath.lineWidth = 1.0;
			disclosurePath.lineCapStyle = .round
			disclosurePath.lineJoinStyle = .round
			disclosurePath.move(to: CGPoint(x: self.frame.width - 20, y: self.frame.height/2 - 6))
			disclosurePath.addLine(to: CGPoint(x: self.frame.width - 15, y: self.frame.height/2))
			disclosurePath.addLine(to: CGPoint(x: self.frame.width - 20, y: self.frame.height/2 + 6))
			disclosurePath.stroke()

			// Separator
			let beizerPath = UIBezierPath()
			beizerPath.lineWidth = 0.5
			beizerPath.lineCapStyle = .round
			beizerPath.move(to: CGPoint(x: self.bounds.height + 8, y: self.bounds.height - 0.5))
			beizerPath.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height - 0.5))
			beizerPath.stroke()
		}
		
	}
	
	func updateImageView() -> Void {
		
		let filePath = imagesPathForFileName("\(self.meme!.memeID)")
		if (FileManager.default.fileExists(atPath: filePath)) {
			if (self.isListCell) {
				let filePathC = imagesPathForFileName("\(self.meme!.memeID)c")
				if (FileManager.default.fileExists(atPath: filePathC)) {
					self.memeImageView.image = UIImage(contentsOfFile: filePathC)
				}
				else {
					let image = getCircularImage(UIImage(contentsOfFile: filePath)!)
					let data = UIImagePNGRepresentation(image)
					try? data?.write(to: URL(fileURLWithPath: filePathC), options: [.atomic])
					self.memeImageView.image = image
				}
			}
			else {
				let filePathS = imagesPathForFileName("\(self.meme!.memeID)s")
				if (FileManager.default.fileExists(atPath: filePathS)) {
					self.memeImageView.image = UIImage(contentsOfFile: filePathS)
				}
				else {
					let image = getSquareImage(UIImage(contentsOfFile: filePath)!)
					let data = UIImagePNGRepresentation(image)
					try? data?.write(to: URL(fileURLWithPath: filePathS), options: [.atomic])
					self.memeImageView.image = image
				}
			}
		}
		else {
			self.memeImageView.image = UIImage(named: "MemeBlank")
			if let URLString = meme?.image {
				if let URL = URL(string: URLString) {
//					print("Downloading image \'\(meme!.memeID)\'")
					self.downloadImageWithURL(URL, filePath: filePath)
				}
			}
		}
		
	}
	
	func downloadImageWithURL(_ url: Foundation.URL, filePath: String) -> Void {
		SDWebImageDownloader.shared().downloadImage(with: url, options: .progressiveDownload, progress: nil, completed: { (image, data, error, success) in
			if (success && error == nil) {
				if let fileURL = URL(string: filePath) {
					do {
						try data?.write(to: fileURL, options: .atomicWrite)
						DispatchQueue.main.async(execute: {
							self.updateImageView()
						})
					}
					catch _ {
						print("")
					}
				}
			}
		})
	}
	
}
