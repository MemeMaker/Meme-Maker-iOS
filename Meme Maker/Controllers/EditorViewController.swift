//
//  EditorViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SDWebImage
import TextFieldEffects

enum EditorMode {
	case Meme
	case UserImage
}

class EditorViewController: UIViewController, MemesViewControllerDelegate, UITextFieldDelegate, SwipableTextFieldDelegate {
	
	var meme: XMeme?
	
	var editorMode: EditorMode = .Meme
	
	@IBOutlet weak var memeNameLabel: UILabel!
	
	@IBOutlet weak var dismissButton: UIButton!
	
	@IBOutlet weak var topTextField: SwipableTextField!
	@IBOutlet weak var bottomTextField: SwipableTextField!
	
	@IBOutlet weak var memeImageView: UIImageView!
	
	var pinchGestureRecognizer: UIPinchGestureRecognizer?
	
	var baseImage: UIImage?
	
	var topTextAttr: XTextAttributes!
	var bottomTextAttr: XTextAttributes!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		topTextAttr = XTextAttributes(savename: "topAttr")
		bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		
		self.topTextField.swipeDelegate = self
		self.bottomTextField.swipeDelegate = self
		
		pinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(EditorViewController.handlePinch(_:)))
		self.view.addGestureRecognizer(pinchGestureRecognizer!)
		
		if (editorMode == .Meme) {
			if (self.meme != nil) {
				self.didSelectMeme(self.meme!)
			}
		}
		else {
			let image = UIImage(contentsOfFile: imagesPathForFileName("lastImage"))
			self.didPickImage(image!)
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.dismissButton.hidden = true
		}
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Updating views
	
	func updateMemeViews() -> Void {
		if (self.meme == nil) {
			self.memeNameLabel.text = "Select a Meme"
			self.topTextField.enabled = false
			self.bottomTextField.enabled = false
		}
		else {
			
			// Meme is there, update views
			
			self.topTextField.enabled = true
			self.bottomTextField.enabled = true
			
			self.topTextField.text = topTextAttr.text as String
			self.bottomTextField.text = bottomTextAttr.text as String
			
			self.memeNameLabel.text = self.meme!.name
			
			let filePath = imagesPathForFileName("\(self.meme!.memeID)")
			
			if (NSFileManager.defaultManager().fileExistsAtPath(filePath)) {
				baseImage = UIImage(contentsOfFile: filePath)
				self.memeImageView.image = baseImage
				cookImage()
			}
			else {
				if let URL = self.meme!.imageURL {
					self.downloadImageWithURL(URL, filePath: filePath)
				}
			}
			
		}
	}
	
	// MARK: - Cooking
	
	func cookImage() -> Void {
		
		let imageSize = memeImageView.image?.size as CGSize!
		
//		topTextAttr.setDefault()
//		bottomTextAttr.setDefault()
		
		topTextAttr.textColor = UIColor.whiteColor()
		bottomTextAttr.textColor = UIColor.whiteColor()
		
		let maxHeight = imageSize.height/2 - 10	// Max height of top and bottom texts
		
		var topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, imageSize.height/2 - 10), options: .UsesLineFragmentOrigin, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRectMake(0, 0, imageSize.width, imageSize.height/2 - 10)
		// Adjust top size
		while (topTextRect.size.height >= maxHeight) {
			topTextAttr.fontSize -= 2;
			topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, imageSize.height/2 - 10), options: .UsesLineFragmentOrigin, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, imageSize.height/2 - 10), options: .UsesLineFragmentOrigin, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		let expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRectMake(0, (baseImage!.size.height) - (expectedBottomSize.height), baseImage!.size.width, baseImage!.size.height/2);
		// Adjust bottom size
		while (bottomTextRect.size.height >= maxHeight) {
			bottomTextAttr.fontSize -= 2;
			bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, imageSize.height/2 - 10), options: .UsesLineFragmentOrigin, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		}
		
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		
		UIGraphicsBeginImageContext(imageSize)
		
		baseImage?.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
		
		let topText = topTextAttr.uppercase ? topTextAttr.text.uppercaseString : topTextAttr.text;
		let bottomText = bottomTextAttr.uppercase ? bottomTextAttr.text.uppercaseString : bottomTextAttr.text;
		
		topText.drawInRect(topTextAttr.rect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.drawInRect(bottomTextAttr.rect, withAttributes: bottomTextAttr.getTextAttributes())
		
		memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
	}
	
	// MARK: - Gesture handlers
	
	func handlePinch(recognizer: UIPinchGestureRecognizer) -> Void {
		let fontScale = 0.3 * recognizer.velocity
		let point = recognizer.locationInView(self.memeImageView)
		let topRect = CGRectMake(0, 0, self.memeImageView.bounds.size.width, self.memeImageView.bounds.size.height/2)
		if (topRect.contains(point)) {
			if (recognizer.scale > 1) {
				topTextAttr.fontSize = min(topTextAttr.fontSize + fontScale, 150)
			}
			else {
				topTextAttr.fontSize = max(topTextAttr.fontSize + fontScale, 20)
			}
		}
		else {
			if (recognizer.scale > 1) {
				bottomTextAttr.fontSize = min(bottomTextAttr.fontSize + fontScale, 150)
			}
			else {
				bottomTextAttr.fontSize = max(bottomTextAttr.fontSize + fontScale, 20)
			}
		}
		cookImage()
	}
	
	// MARK: - Memes view controller delegate
	
	func didSelectMeme(meme: XMeme) {
		self.meme = meme
		self.editorMode = .Meme
		updateMemeViews()
	}
	
	func didPickImage(image: UIImage) {
		self.editorMode = .UserImage
		self.meme = XMeme()
		self.meme?.name = "Custom Image"
		self.meme?.imageURL = NSURL(fileURLWithPath: imagesPathForFileName("lastImage"))
		self.meme?.image = imagesPathForFileName("lastImage")
		updateMemeViews()
	}
	
	// MARK: - Text field delegate
	
	@IBAction func topTextChangedAction(sender: AnyObject) {
		topTextAttr.text = "\(topTextField.text!)"
		cookImage()
	}
	
	@IBAction func bottomTextChangedAction(sender: AnyObject) {
		bottomTextAttr.text = "\(bottomTextField.text!)"
		cookImage()
	}
	
	func textFieldDidSwipeLeft(textField: SwipableTextField) {
		textField.text = ""
		if (textField == self.topTextField) {
			self.topTextChangedAction(textField)
		}
		else if (textField == self.bottomTextField) {
			self.bottomTextChangedAction(textField)
		}
	}
	
	func textFieldDidSwipeRight(textField: SwipableTextField) {
		if (textField == self.topTextField) {
			if let topText = self.meme?.topText as String! {
				if (topText.characters.count > 0) {
					self.topTextAttr.text = topText
					self.topTextField.text = topText
				}
			}
		}
		else if (textField == self.bottomTextField) {
			if let bottomText = self.meme?.bottomText as String! {
				if (bottomText.characters.count > 0) {
					self.bottomTextAttr.text = bottomText
					self.bottomTextField.text = bottomText
				}
			}
		}
		cookImage()
	}
	
    // MARK: - Navigation
	
	@IBAction func dismissAction(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	/*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	// MARK: - Utility
	
	func downloadImageWithURL(URL: NSURL, filePath: String) -> Void {
		SDWebImageDownloader.sharedDownloader().downloadImageWithURL(URL, options: .ProgressiveDownload, progress: nil, completed: { (image, data, error, success) in
			if (success) {
				do {
					try data.writeToFile(filePath, options: .AtomicWrite)
				}
				catch _ {}
				dispatch_async(dispatch_get_main_queue(), {
					self.baseImage = image
					self.memeImageView.image = image
					self.cookImage()
				})
			}
		})
	}

}
