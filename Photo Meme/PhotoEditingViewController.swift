//
//  PhotoEditingViewController.swift
//  Photo Meme
//
//  Created by Avikant Saini on 4/10/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController, UITextFieldDelegate, SwipableTextFieldDelegate, TextAttributeChangingDelegate, UIGestureRecognizerDelegate {
	
	@IBOutlet weak var settingsButton: UIButton!
	
	@IBOutlet weak var topTextField: SwipableTextField!
	@IBOutlet weak var bottomTextField: SwipableTextField!
	
	@IBOutlet weak var memeImageView: UIImageView!
	@IBOutlet weak var backgroundImageView: BlurredImageView!
	
	var fontTableVC: FontTableViewController!
	var shouldDisplayFTVC: Bool = true
	
	var swipeUpGesture: UISwipeGestureRecognizer?
	var swipeDownGesture: UISwipeGestureRecognizer?
	var pinchGestureRecognizer: UIPinchGestureRecognizer?
	var doubleTapGesture: UITapGestureRecognizer?
	var twoDoubleTapGesture: UITapGestureRecognizer?
	var panGestureRecognizer: UIPanGestureRecognizer?
	
	var movingTop: Bool = true
	
	var baseImage: UIImage?
	var baseImageFullSize: UIImage?
	
	var topTextAttr: XTextAttributes = XTextAttributes(savename: "topAttr")
	var bottomTextAttr: XTextAttributes = XTextAttributes(savename: "bottomAttr")

    var input: PHContentEditingInput?
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		topTextAttr.setDefault()
		topTextAttr.text = ""
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.setDefault()
		bottomTextAttr.text = ""
		bottomTextAttr.saveAttributes("bottomAttr")
		
		self.topTextField.swipeDelegate = self
		self.bottomTextField.swipeDelegate = self
		
		pinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(PhotoEditingViewController.handlePinch(_:)))
		self.view.addGestureRecognizer(pinchGestureRecognizer!)
		
		swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.fontAction(_:)))
		swipeUpGesture?.direction = .up
		self.view.addGestureRecognizer(swipeUpGesture!)
		
		swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.dismissFontAction(_:)))
		swipeDownGesture?.direction = .down
		self.view.addGestureRecognizer(swipeDownGesture!)
		
		doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.handleDoubleTap(_:)))
		doubleTapGesture?.numberOfTapsRequired = 2
		doubleTapGesture?.numberOfTouchesRequired = 1
		self.view.addGestureRecognizer(doubleTapGesture!)
		
		twoDoubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.resetOffset(_:)))
		twoDoubleTapGesture?.numberOfTapsRequired = 2
		twoDoubleTapGesture?.numberOfTouchesRequired = 2
		self.view.addGestureRecognizer(twoDoubleTapGesture!)
		
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.handlePan(_:)))
		panGestureRecognizer?.minimumNumberOfTouches = 2
		panGestureRecognizer?.maximumNumberOfTouches = 3
		panGestureRecognizer?.delegate = self
		self.view.addGestureRecognizer(panGestureRecognizer!)
		
		self.memeImageView.image = baseImage
		self.backgroundImageView.image = baseImage
		
		NotificationCenter.default.addObserver(self, selector: #selector(PhotoEditingViewController.willShowKeyboard(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(PhotoEditingViewController.willHideKeyboard(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		
    }
	
	// MARK: - Keyboard
	
	func willShowKeyboard(_ notification: Notification) -> Void {
		if (self.bottomTextField.isFirstResponder) {
			let dict = notification.userInfo
			let rect = dict![UIKeyboardFrameEndUserInfoKey] as! CGRect
			let height = rect.size.height
			UIView.animate(withDuration: 0.3, animations: {
				self.view.layer.transform = CATransform3DMakeTranslation(0, -height, 0)
			}) 
		}
		else {
			UIView.animate(withDuration: 0.3, animations: {
				self.view.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
			}) 
		}
	}
	
	func willHideKeyboard(_ notification: Notification) -> Void {
		UIView.animate(withDuration: 0.3, animations: { 
			self.view.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
		}) 
	}
	
	// MARK: - Cooking
	
	func cookImage() -> Void {
		
		let imageSize = (baseImage?.size)!
		
		let maxHeight = (imageSize.height) / 2	// Max height of top and bottom texts
		let stringDrawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
		
		let topText = topTextAttr.uppercase ? topTextAttr.text.uppercased : String(topTextAttr.text);
		let bottomText = bottomTextAttr.uppercase ? bottomTextAttr.text.uppercased : String(bottomTextAttr.text);
		
		var topTextRect = topText.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		topTextAttr.rect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height/2)
		// Adjust top size
		while (ceil(topTextRect.size.height) > maxHeight) {
			topTextAttr.fontSize -= 1;
			topTextRect = topText.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: topTextAttr.getTextAttributes(), context: nil)
		}
		
		var bottomTextRect = bottomText.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
		var expectedBottomSize = bottomTextRect.size
		// Bottom rect starts from bottom, not from center.y
		bottomTextAttr.rect = CGRect(x: 0, y: (imageSize.height) - (expectedBottomSize.height), width: imageSize.width, height: expectedBottomSize.height);
		// Adjust bottom size
		while (ceil(bottomTextRect.size.height) > maxHeight) {
			bottomTextAttr.fontSize -= 1;
			bottomTextRect = bottomText.boundingRect(with: CGSize(width: imageSize.width, height: maxHeight), options: stringDrawingOptions, attributes: bottomTextAttr.getTextAttributes(), context: nil)
			expectedBottomSize = bottomTextRect.size
			bottomTextAttr.rect = CGRect(x: 0, y: (imageSize.height) - (expectedBottomSize.height), width: imageSize.width, height: expectedBottomSize.height)
		}
		
		UIGraphicsBeginImageContext(imageSize)
		
		baseImage!.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
		
		let topRect = CGRect(x: topTextAttr.rect.origin.x + topTextAttr.offset.x, y: topTextAttr.rect.origin.y + topTextAttr.offset.y, width: topTextAttr.rect.size.width, height: topTextAttr.rect.size.height)
		let bottomRect = CGRect(x: bottomTextAttr.rect.origin.x + bottomTextAttr.offset.x, y: bottomTextAttr.rect.origin.y + bottomTextAttr.offset.y, width: bottomTextAttr.rect.size.width, height: bottomTextAttr.rect.size.height)
		
		topText.draw(in: topRect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.draw(in: bottomRect, withAttributes: bottomTextAttr.getTextAttributes())
		
		memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
	}
	
	// MARK: - Text change selection delegate
	
	func didUpdateTextAttributes(_ topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) {
		topTextAttr = topTextAttributes
		bottomTextAttr = bottomTextAttributes
		cookImage()
	}
	
	// MARK: - Text field delegate
	
	@IBAction func topTextChangedAction(_ sender: AnyObject) {
		topTextAttr.text = "\(topTextField.text!)" as NSString
		cookImage()
	}
	
	@IBAction func bottomTextChangedAction(_ sender: AnyObject) {
		bottomTextAttr.text = "\(bottomTextField.text!)" as NSString
		cookImage()
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
		let ret1 = topTextAttr.saveAttributes("topAttr")
		let ret2 = bottomTextAttr.saveAttributes("bottomAttr")
		if (ret1 && ret2) {
			print("Save success")
		}
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


    // MARK: - PHContentEditingController

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }

    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
		
		self.baseImage = placeholderImage
		self.baseImageFullSize = UIImage(data: try! Data(contentsOf: (contentEditingInput.fullSizeImageURL!)))
		
		let ratio1 = 1024/(baseImage?.size.width)!
		let ratio2 = 1024/(baseImage?.size.height)!
		let ratio = min(ratio1, ratio2)
		
		self.baseImage = getImageByResizingImage(baseImage!, ratio: ratio)
		
//		print("Base image size = \(NSStringFromCGSize((baseImage?.size)!))")
//		print("Full image size = \(NSStringFromCGSize((baseImageFullSize?.size)!))")
		
		input = contentEditingInput
		
		self.viewDidLoad()
		
    }

    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        // Update UI to reflect that editing has finished and output is being rendered.
		
		self.view.endEditing(true)
		
		// Now render for the full size image
		
		let imageSize = self.baseImage!.size
		let fullImageSize = self.baseImageFullSize!.size
		let ratio = fullImageSize.width/imageSize.width
		
		UIGraphicsBeginImageContext(fullImageSize)
		
		self.baseImageFullSize!.draw(in: CGRect(x: 0, y: 0, width: fullImageSize.width, height: fullImageSize.height))
		
		self.topTextAttr.fontSize = self.topTextAttr.fontSize * ratio
		self.bottomTextAttr.fontSize = self.bottomTextAttr.fontSize * ratio
		
		self.topTextAttr.offset = CGPoint(x: self.topTextAttr.offset.x * ratio, y: self.topTextAttr.offset.y * ratio)
		self.bottomTextAttr.offset = CGPoint(x: self.bottomTextAttr.offset.x * ratio, y: self.bottomTextAttr.offset.y * ratio)
		
		let topText = self.topTextAttr.uppercase ? self.topTextAttr.text.uppercased : String(self.topTextAttr.text)
		let bottomText = self.bottomTextAttr.uppercase ? self.bottomTextAttr.text.uppercased : String(self.bottomTextAttr.text)
		
		let topRect = CGRect(x: self.topTextAttr.rect.origin.x * ratio + self.topTextAttr.offset.x, y: self.topTextAttr.rect.origin.y * ratio + self.topTextAttr.offset.y, width: self.topTextAttr.rect.size.width * ratio, height: self.topTextAttr.rect.size.height * ratio)
		
		let bottomRect = CGRect(x: self.bottomTextAttr.rect.origin.x * ratio + self.bottomTextAttr.offset.x, y: self.bottomTextAttr.rect.origin.y * ratio + self.bottomTextAttr.offset.y, width: self.bottomTextAttr.rect.size.width * ratio, height: self.bottomTextAttr.rect.size.height * ratio)
		
		topText.draw(in: topRect, withAttributes: self.topTextAttr.getTextAttributes())
		bottomText.draw(in: bottomRect, withAttributes: self.bottomTextAttr.getTextAttributes())
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		
        // Render and provide output on a background queue.
        DispatchQueue.main.async {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
			
			let archivedData = NSKeyedArchiver.archivedData(withRootObject: ["Meme maker version": 4.69, "Date created": Date(), "topTextAttributes": self.topTextAttr.getTextAttributes(), "bottomTextAttributes": self.bottomTextAttr.getTextAttributes()])
            
            // Provide new adjustments and render output to given location.
			
             output.adjustmentData = PHAdjustmentData(formatIdentifier: "com.avikantz.Meme-Maker.Photo-Meme", formatVersion: "4.69", data: archivedData)
             let renderedJPEGData = UIImageJPEGRepresentation(newImage!, 1.0)
             try? renderedJPEGData!.write(to: output.renderedContentURL, options: [.atomic])
			
            // Call completion handler to commit edit to Photos.
            completionHandler(output)
            
            // Clean up temporary files, etc.
        }
    }

    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return true
    }

    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }

}
