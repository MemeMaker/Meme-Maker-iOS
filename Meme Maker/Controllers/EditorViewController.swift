//
//  EditorViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreData
import SDWebImage
import TextFieldEffects
import IQKeyboardManagerSwift
import Photos

enum EditorMode {
	case meme
	case userImage
	case viewer
}

class EditorViewController: UIViewController, MemesViewControllerDelegate, UITextFieldDelegate, SwipableTextFieldDelegate, TextAttributeChangingDelegate, UIGestureRecognizerDelegate {
	
	var meme: XMeme?
	
	var editorMode: EditorMode = .meme
	
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
		swipeUpGesture?.direction = .up
		self.view.addGestureRecognizer(swipeUpGesture!)
		
		swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(EditorViewController.dismissFontAction(_:)))
		swipeDownGesture?.direction = .down
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
		
		if (editorMode == .meme) {
			if (self.meme != nil) {
				self.didSelectMeme(self.meme!)
				AppDelegate.updateActivityIcons(self.meme!.name!)
			}
		}
		else if (editorMode == .userImage) {
			let image = UIImage(contentsOfFile: imagesPathForFileName("lastImage"))
			topTextAttr = XTextAttributes(savename: "topAttr")
			bottomTextAttr = XTextAttributes(savename: "bottomAttr")
			self.didPickImage(image!)
			AppDelegate.updateActivityIcons("")
		}
		updateForViewing()
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.dismissButton.isHidden = true
		}
		
		let notifCenter = NotificationCenter.default
		notifCenter.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { (notification) in
			let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
			try? data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: [.atomic])
			self.topTextAttr.saveAttributes("topAttr")
			self.bottomTextAttr.saveAttributes("bottomAttr")
		}
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	/*
	override func viewDidAppear(animated: Bool) {
		if (UIScreen.mainScreen().bounds.size.height < 500) {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EditorViewController.willShowKeyboard(_:)), name: UIKeyboardWillShowNotification, object: nil)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EditorViewController.willHideKeyboard(_:)), name: UIKeyboardWillHideNotification, object: nil)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		if (UIScreen.mainScreen().bounds.size.height < 500) {
			NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
			NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
		}
	}
	
	// MARK: - Keyboard
	
	func willShowKeyboard(notification: NSNotification) -> Void {
		if (self.bottomTextField.isFirstResponder()) {
			let dict = notification.userInfo
			let rect = dict![UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
			let height = rect?.size.height
			UIView.animateWithDuration(0.3) {
				self.view.layer.transform = CATransform3DMakeTranslation(0, -height!, 0)
			}
		}
		else {
			UIView.animateWithDuration(0.3) {
				self.view.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
			}
		}
	}
	
	func willHideKeyboard(notification: NSNotification) -> Void {
		UIView.animateWithDuration(0.3) {
			self.view.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
		}
	}
	*/
	
	// MARK: - Updating views
	
	func updateForViewing() -> Void {
		self.topTextField.isEnabled = true
		self.bottomTextField.isEnabled = true
		if (editorMode == .viewer) {
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				self.topTextField.isEnabled = false
				self.bottomTextField.isEnabled = false
				self.topTextAttr.text = self.topTextField.text as! NSString
				self.bottomTextAttr.text = self.bottomTextField.text as! NSString
			}
			else {
				self.topTextField.text = String(self.topTextAttr.text)
				self.bottomTextField.text = String(self.bottomTextAttr.text)
				self.memeNameLabel.text = self.title
			}
			AppDelegate.updateActivityIcons("")
			self.memeImageView.image = baseImage
			cookImage()
			self.backgroundImageView.image = baseImage
		}
	}
	
	func updateMemeViews() -> Void {
		if (self.meme == nil) {
			self.memeNameLabel.text = "Select a Meme"
			self.topTextField.isEnabled = false
			self.bottomTextField.isEnabled = false
		}
		else {
			// Meme is there, update views
			self.topTextField.isEnabled = true
			self.bottomTextField.isEnabled = true
			
			self.topTextField.text = topTextAttr.text as String
			self.bottomTextField.text = bottomTextAttr.text as String
			
			self.memeNameLabel.text = self.meme!.name
			
			var filePath = ""
			if (editorMode == .meme) {
				filePath = imagesPathForFileName("\(self.meme!.memeID)")
			}
			else {
				filePath = "\(self.meme!.image!)"
			}
			
			if (FileManager.default.fileExists(atPath: filePath)) {
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
		
		let maxHeight = (imageSize?.height)!/2 + 2	// Max height of top and bottom texts
		let stringDrawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
		
		let topText = topTextAttr.uppercase ? topTextAttr.text.uppercased : String(topTextAttr.text);
		let bottomText = bottomTextAttr.uppercase ? bottomTextAttr.text.uppercased : String(bottomTextAttr.text);
		
		var topTextRect = topText.boundingRect(with: CGSize(width: (imageSize?.width)!, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRect(x: 0, y: 8, width: (imageSize?.width)!, height: (imageSize?.height)!/2 - 8)
		// Adjust top size
		while (ceil(topTextRect.size.height) > maxHeight) {
			topTextAttr.fontSize -= 1;
			topTextRect = topText.boundingRect(with: CGSize(width: (imageSize?.width)!, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomText.boundingRect(with: CGSize(width: (imageSize?.width)!, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		var expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRect(x: 0, y: (imageSize?.height)! - (expectedBottomSize.height), width: (imageSize?.width)!, height: expectedBottomSize.height);
		// Adjust bottom size
		while (ceil(bottomTextRect.size.height) > maxHeight) {
			bottomTextAttr.fontSize -= 1;
			bottomTextRect = bottomText.boundingRect(with: CGSize(width: (imageSize?.width)!, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
			expectedBottomSize = bottomTextRect.size
			bottomTextAttr.rect = CGRect(x: 0, y: (imageSize?.height)! - (expectedBottomSize.height), width: (imageSize?.width)!, height: expectedBottomSize.height)
		}
		
		UIGraphicsBeginImageContext(imageSize!)
		
		baseImage?.draw(in: CGRect(x: 0, y: 0, width: (imageSize?.width)!, height: (imageSize?.height)!))
		
		let topRect = CGRect(x: topTextAttr.rect.origin.x + topTextAttr.offset.x, y: topTextAttr.rect.origin.y + topTextAttr.offset.y, width: topTextAttr.rect.size.width, height: topTextAttr.rect.size.height)
		let bottomRect = CGRect(x: bottomTextAttr.rect.origin.x + bottomTextAttr.offset.x, y: bottomTextAttr.rect.origin.y + bottomTextAttr.offset.y, width: bottomTextAttr.rect.size.width, height: bottomTextAttr.rect.size.height)

		topText.draw(in: topRect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.draw(in: bottomRect, withAttributes: bottomTextAttr.getTextAttributes())
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		memeImageView.image = image
		
		UIGraphicsEndImageContext()
		
	}
	
	// MARK: - Button Actions
	
	@IBAction func saveImageAction(_ sender: AnyObject) {
		// Get the current authorization state.
		let status = PHPhotoLibrary.authorizationStatus()
		if (status == PHAuthorizationStatus.authorized) {
			saveImageToPhotos()
		} else if (status == PHAuthorizationStatus.denied) {
			// Access has been denied.
		} else if (status == PHAuthorizationStatus.notDetermined) {
			// Access has not been determined.
			PHPhotoLibrary.requestAuthorization({ (newStatus) in
				if (newStatus == PHAuthorizationStatus.authorized) {
					self.saveImageToPhotos()
				} else {
					
				}
			})
		} else if (status == PHAuthorizationStatus.restricted) {
			// Restricted access - normally won't happen.
		}
		saveUserCreation()
	}
	
	func saveImageToPhotos() -> Void {
		UIImageWriteToSavedPhotosAlbum(memeImageView.image!, nil, nil, nil)
		SVProgressHUD.showSuccess(withStatus: "Saved!")
	}
	
	@IBAction func shareImageAction(_ sender: AnyObject) {
		let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
		try? data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: [.atomic])
		self.topTextAttr.saveAttributes("topAttr")
		self.bottomTextAttr.saveAttributes("bottomAttr")
		let imageToShare = memeImageView.image
		let activityVC = UIActivityViewController(activityItems: [imageToShare!], applicationActivities: nil)
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			activityVC.modalPresentationStyle = .popover
			activityVC.popoverPresentationController?.sourceView = self.shareImageButton
		}
		self.present(activityVC, animated: true) { 
			self.saveUserCreation()
//			if (self.editorMode == .Meme) {
//				if (SettingsManager.sharedManager().getBool(kSettingsUploadMemes)) {
//					self.uploadMemeToServer()
//				}
//			}
		}
	}
	
	
	// MARK: - Gesture handlers
	
	@IBAction func fontAction(_ sender: AnyObject) -> Void {
		self.view.endEditing(true)
		if (shouldDisplayFTVC) {
			shouldDisplayFTVC = false
			fontTableVC = self.storyboard?.instantiateViewController(withIdentifier: "FontVC") as! FontTableViewController
			fontTableVC.textAttrChangeDelegate = self
			fontTableVC.topTextAttr = topTextAttr
			fontTableVC.bottomTextAttr = bottomTextAttr
			
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				fontTableVC.view.frame = CGRect(x: 100, y: self.view.frame.size.height, width: self.view.frame.size.width - 200, height: 390)
			}
			else {
				fontTableVC.view.frame = CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 270)
			}
			
			self.addChildViewController(fontTableVC)
			self.view.addSubview(fontTableVC.view)
			
			fontTableVC?.didMove(toParentViewController: self)
			
			UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: { 
				if (UI_USER_INTERFACE_IDIOM() == .pad) {
					self.fontTableVC.view.frame = CGRect(x: 100, y: self.view.frame.size.height - 400, width: self.view.frame.size.width - 200, height: 390);
				}
				else {
					self.fontTableVC.view.frame = CGRect(x: 5, y: self.view.frame.size.height - 275, width: self.view.frame.size.width - 10, height: 270);
				}
			}, completion: nil)
		}
	}
	
	func dismissFontAction(_ sender: AnyObject) -> Void {
		self.view.endEditing(true)
		if (shouldDisplayFTVC == false) {
			UIView.animate(withDuration: 0.15, animations: {
				if (UI_USER_INTERFACE_IDIOM() == .pad) {
					self.fontTableVC.view.frame = CGRect(x: 100, y: self.view.frame.size.height, width: self.view.frame.size.width - 200, height: 390)
				}
				else {
					self.fontTableVC.view.frame = CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 270)
				}
				self.fontTableVC.view.alpha = 0
			}, completion: { (success) in
				self.fontTableVC.view.removeFromSuperview()
				self.fontTableVC.removeFromParentViewController()
				self.shouldDisplayFTVC = true
			})
		}
		else {
			self.view.endEditing(true)
		}
	}
	
	func handlePinch(_ recognizer: UIPinchGestureRecognizer) -> Void {
		let fontScale = 0.3 * recognizer.velocity
		let point = recognizer.location(in: self.memeImageView)
		let topRect = CGRect(x: 0, y: 0, width: self.memeImageView.bounds.size.width, height: self.memeImageView.bounds.size.height/2)
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
	
	func handlePan(_ recognizer: UIPanGestureRecognizer) -> Void {
		let translation = recognizer.translation(in: memeImageView)
//		let location = recognizer.locationInView(self.memeImageView)
		if (movingTop) {
			topTextAttr.offset = CGPoint(x: topTextAttr.offset.x + recognizer.velocity(in: self.view).x/80,
			                                 y: topTextAttr.offset.y + recognizer.velocity(in: self.view).y/80);
		}
		else {
			bottomTextAttr.offset = CGPoint(x: bottomTextAttr.offset.x + recognizer.velocity(in: self.view).x/80,
			                                    y: bottomTextAttr.offset.y + recognizer.velocity(in: self.view).y/80);
		}
		recognizer.setTranslation(translation, in: self.memeImageView)
		cookImage()
	}
	
	func handleDoubleTap(_ recognizer: UITapGestureRecognizer) -> Void {
		topTextAttr.uppercase = !topTextAttr.uppercase
		bottomTextAttr.uppercase = !bottomTextAttr.uppercase
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		cookImage()
	}
	
	func resetOffset(_ recognizer: UITapGestureRecognizer) -> Void {
		topTextAttr.offset = CGPoint.zero
		topTextAttr.fontSize = 44
		bottomTextAttr.offset = CGPoint.zero
		bottomTextAttr.fontSize = 44
		cookImage()
	}
	
	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		resetOffset(twoDoubleTapGesture!)
	}
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if (gestureRecognizer == self.panGestureRecognizer) {
			let topRect = CGRect(x: memeImageView.bounds.origin.x, y: memeImageView.bounds.origin.y, width: memeImageView.bounds.size.width, height: memeImageView.bounds.size.height/2)
			let location = gestureRecognizer.location(in: self.memeImageView)
			movingTop = (topRect.contains(location))
		}
		return true
	}
	
	func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
		shareImageAction(self.shareImageButton)
	}
	
	// MARK: - Text change delegate
	
	func didUpdateTextAttributes(_ topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) {
		topTextAttr = topTextAttributes
		bottomTextAttr = bottomTextAttributes
		if (SettingsManager.sharedManager().getBool(kSettingsAutoDismiss)) {
			self.dismissFontAction(self)
		}
		cookImage()
	}
	
	// MARK: - Memes view controller delegate
	
	func didSelectMeme(_ meme: XMeme) {
		self.meme = meme
		self.editorMode = .meme
		updateMemeViews()
	}
	
	func didPickImage(_ image: UIImage) {
		self.editorMode = .userImage
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		let context = appDelegate.managedObjectContext
		self.meme = XMeme(entity: NSEntityDescription.entity(forEntityName: "XMeme", in: context)!, insertInto: nil)
		self.meme?.name = "Custom Image"
		self.meme?.imageURL = URL(fileURLWithPath: imagesPathForFileName("lastImage"))
		self.meme?.image = imagesPathForFileName("lastImage")
		updateMemeViews()
	}
	
	// MARK: - Text field delegate
	
	@IBAction func topTextChangedAction(_ sender: AnyObject) {
		topTextAttr.text = "\(topTextField.text!)" as NSString
		topTextAttr.saveAttributes("topAttr")
		if (SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)) {
			cookImage()
		}
	}
	
	@IBAction func bottomTextChangedAction(_ sender: AnyObject) {
		bottomTextAttr.text = "\(bottomTextField.text!)" as NSString
		bottomTextAttr.saveAttributes("bottomAttr")
		if (SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)) {
			cookImage()
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if (textField == self.topTextField) {
			self.bottomTextField.becomeFirstResponder()
		}
		else {
			self.view.endEditing(true)
		}
		cookImage()
		return true
	}
	
	func textFieldDidSwipeLeft(_ textField: SwipableTextField) {
		textField.text = ""
		if (textField == self.topTextField) {
			self.topTextChangedAction(textField)
		}
		else if (textField == self.bottomTextField) {
			self.bottomTextChangedAction(textField)
		}
		textField.resignFirstResponder()
	}
	
	func textFieldDidSwipeRight(_ textField: SwipableTextField) {
		if (textField == self.topTextField) {
			if let topText = self.meme?.topText as String! {
				if (topText.characters.count > 0) {
					self.topTextAttr.text = topText as NSString
					self.topTextField.text = topText
				}
			}
		}
		else if (textField == self.bottomTextField) {
			if let bottomText = self.meme?.bottomText as String! {
				if (bottomText.characters.count > 0) {
					self.bottomTextAttr.text = bottomText as NSString
					self.bottomTextField.text = bottomText
				}
			}
		}
		cookImage()
	}
	
    // MARK: - Navigation
	
	@IBAction func dismissAction(_ sender: AnyObject) {
		let data = UIImageJPEGRepresentation(self.baseImage!, 0.8)
		try? data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: [.atomic])
		self.topTextAttr.saveAttributes("topAttr")
		self.bottomTextAttr.saveAttributes("bottomAttr")
		self.dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Utility
	
	func uploadMemeToServer() -> Void {
		
		print("Uploading...")
		
		let URLString = "\(API_BASE_URL)/memes/\(meme!.memeID)/submissions/"
		let URL = Foundation.URL(string: URLString)
		
		print("upload url: \(URLString)")
		
		var request = URLRequest(url: URL!)
		request.httpMethod = "POST"
		
		let postBodyString =  NSString(format: "topText=%@&bottomText=%@", topTextAttr.text!, bottomTextAttr.text!)
		let postData = postBodyString.data(using: String.Encoding.utf8.rawValue)
		request.httpBody = postData
		
		URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
			
			if (error != nil) {
				// Handle error...
				print("Upload failed")
				return
			}
			
			if (data != nil) {
				do {
					let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
					let code = (json as AnyObject).value(forKey: "code") as! Int
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
			
		}) .resume()

	}
	
	func saveUserCreation () -> Void {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		let context = appDelegate.managedObjectContext
		if (editorMode == .meme) {
			XUserCreation.createOrUpdateUserCreationWithMeme(self.meme!, topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, dateCreated: Date(), context: context)
		}
		else if (editorMode == .userImage) {
			XUserCreation.createOrUpdateUserCreationWithUserImage(baseImage!, topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, dateCreated: Date(), context: context)
		}
	}
	
	func downloadImageWithURL(_ url: Foundation.URL, filePath: String) -> Void {
		SDWebImageDownloader.shared().downloadImage(with: url, options: .progressiveDownload, progress: nil, completed: { (image, data, error, success) in
			if (success && error == nil) {
				if let fileURL = URL(string: filePath) {
					do {
						try data?.write(to: fileURL, options: .atomicWrite)
					}
					catch _ {}
					DispatchQueue.main.async(execute: {
						self.baseImage = image
						self.memeImageView.image = image
						self.backgroundImageView.image = image
						self.cookImage()
					})
				}
			}
		})
	}

}
