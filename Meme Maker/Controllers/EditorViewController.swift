//
//  EditorViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import PermissionScope
import ChameleonFramework
import SVProgressHUD
import CoreData
import SDWebImage
import TextFieldEffects

enum EditorMode {
	case Meme
	case UserImage
	case Viewer
}

class EditorViewController: UIViewController, MemesViewControllerDelegate, UITextFieldDelegate, SwipableTextFieldDelegate, TextAttributeChangingDelegate, UIGestureRecognizerDelegate {
	
	var meme: XMeme?
	
	var editorMode: EditorMode = .Meme
	
	@IBOutlet weak var navBarBackgroundView: UIView!
	@IBOutlet weak var memeNameLabel: UILabel!
	
	@IBOutlet weak var dismissButton: UIButton!
	
	@IBOutlet weak var settingsButton: UIButton!
	@IBOutlet weak var shareImageButton: UIButton!
	
	@IBOutlet weak var topTextField: SwipableTextField!
	@IBOutlet weak var bottomTextField: SwipableTextField!
	
	var isEditingTop: Bool = true
	
	@IBOutlet weak var backgroundImageView: BlurredImageView!
	@IBOutlet weak var memeImageView: UIImageView!
	
	var fontTableVC: FontTableViewController!
	var shouldDisplayFTVC: Bool = true
	
	var swipeUpGesture: UISwipeGestureRecognizer?
	var swipeDownGesture: UISwipeGestureRecognizer?
	var pinchGestureRecognizer: UIPinchGestureRecognizer?
	var doubleTapGesture: UITapGestureRecognizer?
	var twoDoubleTapGesture: UITapGestureRecognizer?
	var panGestureRecognizer: UIPanGestureRecognizer?
	var longPressGestureRecognizer: UILongPressGestureRecognizer?
	
	var movingTop: Bool = true
	
	var baseImage: UIImage?
	
	var topTextAttr: XTextAttributes =  XTextAttributes(savename: "topAttr")
	var bottomTextAttr: XTextAttributes = XTextAttributes(savename: "bottomAttr")
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
//		topTextAttr = XTextAttributes(savename: "topAttr")
//		bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		
		self.topTextField.swipeDelegate = self
		self.bottomTextField.swipeDelegate = self
		
		pinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(EditorViewController.handlePinch(_:)))
		self.view.addGestureRecognizer(pinchGestureRecognizer!)
		
		swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(EditorViewController.fontAction(_:)))
		swipeUpGesture?.direction = .Up
		self.view.addGestureRecognizer(swipeUpGesture!)
		
		swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(EditorViewController.dismissFontAction(_:)))
		swipeDownGesture?.direction = .Down
		self.view.addGestureRecognizer(swipeDownGesture!)
		
		doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.handleDoubleTap(_:)))
		doubleTapGesture?.numberOfTapsRequired = 2
		doubleTapGesture?.numberOfTouchesRequired = 1
		self.view.addGestureRecognizer(doubleTapGesture!)
		
		twoDoubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.resetOffset(_:)))
		twoDoubleTapGesture?.numberOfTapsRequired = 2
		twoDoubleTapGesture?.numberOfTouchesRequired = 2
		self.view.addGestureRecognizer(twoDoubleTapGesture!)
		
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(EditorViewController.handlePan(_:)))
		panGestureRecognizer?.minimumNumberOfTouches = 2
		panGestureRecognizer?.maximumNumberOfTouches = 3
		panGestureRecognizer?.delegate = self
		self.view.addGestureRecognizer(panGestureRecognizer!)
		
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(EditorViewController.handleLongPress(_:)))
		longPressGestureRecognizer?.minimumPressDuration = 0.8
		self.view.addGestureRecognizer(longPressGestureRecognizer!)
		
		if (editorMode == .Meme) {
			if (self.meme != nil) {
				self.didSelectMeme(self.meme!)
			}
		}
		else if (editorMode == .UserImage) {
			let image = UIImage(contentsOfFile: imagesPathForFileName("lastImage"))
			topTextAttr = XTextAttributes(savename: "topAttr")
			bottomTextAttr = XTextAttributes(savename: "bottomAttr")
			self.didPickImage(image!)
		}
		updateForViewing()
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.dismissButton.hidden = true
		}
		
		let notifCenter = NSNotificationCenter.defaultCenter()
		notifCenter.addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) in
			let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
			data?.writeToFile(imagesPathForFileName("lastImage"), atomically: true)
			self.topTextAttr.saveAttributes("topAttr")
			self.bottomTextAttr.saveAttributes("bottomAttr")
		}
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Updating views
	
	func updateForViewing() -> Void {
		self.topTextField.enabled = true
		self.bottomTextField.enabled = true
		if (editorMode == .Viewer) {
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				self.topTextField.enabled = false
				self.bottomTextField.enabled = false
				self.topTextAttr.text = self.topTextField.text
				self.bottomTextAttr.text = self.bottomTextField.text
			}
			else {
				self.topTextField.text = String(self.topTextAttr.text)
				self.bottomTextField.text = String(self.bottomTextAttr.text)
				self.memeNameLabel.text = self.title
			}
			self.memeImageView.image = baseImage
			cookImage()
			self.backgroundImageView.image = baseImage
		}
	}
	
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
			
			var filePath = ""
			if (editorMode == .Meme) {
				filePath = imagesPathForFileName("\(self.meme!.memeID)")
			}
			else {
				filePath = "\(self.meme!.image!)"
			}
			
			if (NSFileManager.defaultManager().fileExistsAtPath(filePath)) {
				baseImage = UIImage(contentsOfFile: filePath)
				self.memeImageView.image = baseImage
				self.backgroundImageView.image = baseImage
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
		
		if (baseImage == nil) {
			return
		}
		
		let imageSize = baseImage?.size as CGSize!
		
		let maxHeight = imageSize.height/2	// Max height of top and bottom texts
		let stringDrawingOptions: NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]
		
		var topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRectMake(0, 0, imageSize.width, imageSize.height/2)
		// Adjust top size
		while (ceil(topTextRect.size.height) > maxHeight) {
			topTextAttr.fontSize -= 1;
			topTextRect = topTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		var expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRectMake(0, (imageSize.height) - (expectedBottomSize.height), imageSize.width, expectedBottomSize.height);
		// Adjust bottom size
		while (ceil(bottomTextRect.size.height) > maxHeight) {
			bottomTextAttr.fontSize -= 1;
			bottomTextRect = bottomTextAttr.text.boundingRectWithSize(CGSizeMake(imageSize.width, maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
			expectedBottomSize = bottomTextRect.size
			bottomTextAttr.rect = CGRectMake(0, (imageSize.height) - (expectedBottomSize.height), imageSize.width, expectedBottomSize.height)
		}
		
		UIGraphicsBeginImageContext(imageSize)
		
		baseImage?.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
		
		let topText = topTextAttr.uppercase ? topTextAttr.text.uppercaseString : topTextAttr.text;
		let bottomText = bottomTextAttr.uppercase ? bottomTextAttr.text.uppercaseString : bottomTextAttr.text;
		
		let topRect = CGRectMake(topTextAttr.rect.origin.x + topTextAttr.offset.x, topTextAttr.rect.origin.y + topTextAttr.offset.y, topTextAttr.rect.size.width, topTextAttr.rect.size.height)
		let bottomRect = CGRectMake(bottomTextAttr.rect.origin.x + bottomTextAttr.offset.x, bottomTextAttr.rect.origin.y + bottomTextAttr.offset.y, bottomTextAttr.rect.size.width, bottomTextAttr.rect.size.height)

		topText.drawInRect(topRect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.drawInRect(bottomRect, withAttributes: bottomTextAttr.getTextAttributes())
		
//		topText.drawInRect(topTextAttr.rect, withAttributes: topTextAttr.getTextAttributes())
//		bottomText.drawInRect(bottomTextAttr.rect, withAttributes: bottomTextAttr.getTextAttributes())
		
		memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
	}
	
	// MARK: - Button Actions
	
	@IBAction func saveImageAction(sender: AnyObject) {
		switch PermissionScope().statusPhotos() {
			case .Unauthorized, .Unknown, .Disabled:
				let pscope = PermissionScope()
				pscope.addPermission(PhotosPermission(), message: "Allow meme maker to access photos to save it to the gallery.")
				pscope.show({ (finished, results) in
					self.saveImageToPhotos()
					}, cancelled: { (results) in
						SVProgressHUD.showErrorWithStatus("Allow Photo Access!")
				})
			default:
				saveImageToPhotos()
		}
		saveUserCreation()
	}
	
	func saveImageToPhotos() -> Void {
		UIImageWriteToSavedPhotosAlbum(memeImageView.image!, nil, nil, nil)
		SVProgressHUD.showSuccessWithStatus("Saved!")
	}
	
	@IBAction func shareImageAction(sender: AnyObject) {
		let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
		data?.writeToFile(imagesPathForFileName("lastImage"), atomically: true)
		self.topTextAttr.saveAttributes("topAttr")
		self.bottomTextAttr.saveAttributes("bottomAttr")
		let textToShare = "Check out this funny meme I made..."
		let imageToShare = memeImageView.image
		let activityVC = UIActivityViewController(activityItems: [textToShare, imageToShare!], applicationActivities: nil)
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			activityVC.modalPresentationStyle = .Popover
			activityVC.popoverPresentationController?.sourceView = self.shareImageButton
		}
		self.presentViewController(activityVC, animated: true) { 
			self.saveUserCreation()
			if (self.editorMode == .Meme) {
				if (SettingsManager.sharedManager().getBool(kSettingsUploadMemes)) {
					self.uploadMemeToServer()
				}
			}
		}
	}
	
	
	// MARK: - Gesture handlers
	
	@IBAction func fontAction(sender: AnyObject) -> Void {
		self.view.endEditing(true)
		if (shouldDisplayFTVC) {
			shouldDisplayFTVC = false
			fontTableVC = self.storyboard?.instantiateViewControllerWithIdentifier("FontVC") as! FontTableViewController
			fontTableVC.textAttrChangeDelegate = self
			fontTableVC.topTextAttr = topTextAttr
			fontTableVC.bottomTextAttr = bottomTextAttr
			
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				fontTableVC.view.frame = CGRectMake(100, self.view.frame.size.height, self.view.frame.size.width - 200, 390)
			}
			else {
				fontTableVC.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 270)
			}
			
			self.addChildViewController(fontTableVC)
			self.view.addSubview(fontTableVC.view)
			
			fontTableVC?.didMoveToParentViewController(self)
			
			UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: .CurveEaseInOut, animations: { 
				if (UI_USER_INTERFACE_IDIOM() == .Pad) {
					self.fontTableVC.view.frame = CGRectMake(100, self.view.frame.size.height - 400, self.view.frame.size.width - 200, 390);
				}
				else {
					self.fontTableVC.view.frame = CGRectMake(5, self.view.frame.size.height - 275, self.view.frame.size.width - 10, 270);
				}
			}, completion: nil)
		}
	}
	
	func dismissFontAction(sender: AnyObject) -> Void {
		self.view.endEditing(true)
		if (shouldDisplayFTVC == false) {
			UIView.animateWithDuration(0.15, animations: {
				if (UI_USER_INTERFACE_IDIOM() == .Pad) {
					self.fontTableVC.view.frame = CGRectMake(100, self.view.frame.size.height, self.view.frame.size.width - 200, 390)
				}
				else {
					self.fontTableVC.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 270)
				}
				self.fontTableVC.view.alpha = 0
			}, completion: { (success) in
				self.fontTableVC.view.removeFromSuperview()
				self.fontTableVC.removeFromParentViewController()
				self.shouldDisplayFTVC = true
			})
		}
		else {
			self.dismissAction(self)
		}
	}
	
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
	
	func handlePan(recognizer: UIPanGestureRecognizer) -> Void {
		let translation = recognizer.translationInView(memeImageView)
//		let location = recognizer.locationInView(self.memeImageView)
		if (movingTop) {
			topTextAttr.offset = CGPointMake(topTextAttr.offset.x + recognizer.velocityInView(self.view).x/80,
			                                 topTextAttr.offset.y + recognizer.velocityInView(self.view).y/80);
		}
		else {
			bottomTextAttr.offset = CGPointMake(bottomTextAttr.offset.x + recognizer.velocityInView(self.view).x/80,
			                                    bottomTextAttr.offset.y + recognizer.velocityInView(self.view).y/80);
		}
		recognizer.setTranslation(translation, inView: self.memeImageView)
		cookImage()
	}
	
	func handleDoubleTap(recognizer: UITapGestureRecognizer) -> Void {
		topTextAttr.uppercase = !topTextAttr.uppercase
		bottomTextAttr.uppercase = !bottomTextAttr.uppercase
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		cookImage()
	}
	
	func resetOffset(recognizer: UITapGestureRecognizer) -> Void {
		topTextAttr.offset = CGPointZero
		topTextAttr.fontSize = 44
		bottomTextAttr.offset = CGPointZero
		bottomTextAttr.fontSize = 44
		cookImage()
	}
	
	override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
		resetOffset(twoDoubleTapGesture!)
	}
	
	func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		if (gestureRecognizer == self.panGestureRecognizer) {
			let topRect = CGRectMake(memeImageView.bounds.origin.x, memeImageView.bounds.origin.y, memeImageView.bounds.size.width, memeImageView.bounds.size.height/2)
			let location = gestureRecognizer.locationInView(self.memeImageView)
			movingTop = (topRect.contains(location))
		}
		return true
	}
	
	func handleLongPress(recognizer: UILongPressGestureRecognizer) {
		shareImageAction(self.shareImageButton)
	}
	
	// MARK: - Text change delegate
	
	func didUpdateTextAttributes(topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) {
		topTextAttr = topTextAttributes
		bottomTextAttr = bottomTextAttributes
		if (SettingsManager.sharedManager().getBool(kSettingsAutoDismiss)) {
			self.dismissFontAction(self)
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
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		let context = appDelegate.managedObjectContext
		self.meme = XMeme(entity: NSEntityDescription.entityForName("XMeme", inManagedObjectContext: context)!, insertIntoManagedObjectContext: nil)
		self.meme?.name = "Custom Image"
		self.meme?.imageURL = NSURL(fileURLWithPath: imagesPathForFileName("lastImage"))
		self.meme?.image = imagesPathForFileName("lastImage")
		updateMemeViews()
	}
	
	// MARK: - Text field delegate
	
	@IBAction func topTextChangedAction(sender: AnyObject) {
		topTextAttr.text = "\(topTextField.text!)"
		topTextAttr.saveAttributes("topAttr")
		if (SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)) {
			cookImage()
		}
	}
	
	@IBAction func bottomTextChangedAction(sender: AnyObject) {
		bottomTextAttr.text = "\(bottomTextField.text!)"
		bottomTextAttr.saveAttributes("bottomAttr")
		if (SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)) {
			cookImage()
		}
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if (textField == self.topTextField) {
			self.bottomTextField.becomeFirstResponder()
		}
		else {
			self.view.endEditing(true)
		}
		cookImage()
		return true
	}
	
	func textFieldDidSwipeLeft(textField: SwipableTextField) {
		textField.text = ""
		if (textField == self.topTextField) {
			self.topTextChangedAction(textField)
		}
		else if (textField == self.bottomTextField) {
			self.bottomTextChangedAction(textField)
		}
		textField.resignFirstResponder()
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
		let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
		data?.writeToFile(imagesPathForFileName("lastImage"), atomically: true)
		self.topTextAttr.saveAttributes("topAttr")
		self.bottomTextAttr.saveAttributes("bottomAttr")
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - Utility
	
	func uploadMemeToServer() -> Void {
		
		print("Uploading...")
		
		let URLString = "\(API_BASE_URL)/memes/\(meme!.memeID)/submissions/"
		let URL = NSURL(string: URLString)
		
		print("upload url: \(URLString)")
		
		let request = NSMutableURLRequest(URL: URL!)
		request.HTTPMethod = "POST"
		
		let postBodyString =  NSString(format: "topText=%@&bottomText=%@", topTextAttr.text!, bottomTextAttr.text!)
		let postData = postBodyString.dataUsingEncoding(NSUTF8StringEncoding)
		request.HTTPBody = postData
		
		NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
			
			if (error != nil) {
				// Handle error...
				print("Upload failed")
				return
			}
			
			if (data != nil) {
				do {
					let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
					let code = json.valueForKey("code") as! Int
					if (code == 201) {
						print("Upload success")
					}
					else {
						print("Upload failed")
					}
				}
				catch _ {
				}
			}
			
		}.resume()

	}
	
	func saveUserCreation () -> Void {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		let context = appDelegate.managedObjectContext
		if (editorMode == .Meme) {
			XUserCreation.createOrUpdateUserCreationWithMeme(self.meme!, topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, dateCreated: NSDate(), context: context)
		}
		else if (editorMode == .UserImage) {
			XUserCreation.createOrUpdateUserCreationWithUserImage(baseImage!, topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, dateCreated: NSDate(), context: context)
		}
	}
	
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
					self.backgroundImageView.image = image
					self.cookImage()
				})
			}
		})
	}

}
