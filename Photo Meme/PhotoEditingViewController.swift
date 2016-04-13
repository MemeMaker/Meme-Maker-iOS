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
import TextFieldEffects
import IQKeyboardManagerSwift

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
		swipeUpGesture?.direction = .Up
		self.view.addGestureRecognizer(swipeUpGesture!)
		
		swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(PhotoEditingViewController.dismissFontAction(_:)))
		swipeDownGesture?.direction = .Down
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
		
		IQKeyboardManager.sharedManager().enable = true
		IQKeyboardManager.sharedManager().preventShowingBottomBlankSpace = true
		
    }
	
	// MARK: - Cooking
	
	func cookImage() -> Void {
		
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
		
		baseImage!.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
		
		let topText = topTextAttr.uppercase ? topTextAttr.text.uppercaseString : topTextAttr.text;
		let bottomText = bottomTextAttr.uppercase ? bottomTextAttr.text.uppercaseString : bottomTextAttr.text;
		
		let topRect = CGRectMake(topTextAttr.rect.origin.x + topTextAttr.offset.x, topTextAttr.rect.origin.y + topTextAttr.offset.y, topTextAttr.rect.size.width, topTextAttr.rect.size.height)
		let bottomRect = CGRectMake(bottomTextAttr.rect.origin.x + bottomTextAttr.offset.x, bottomTextAttr.rect.origin.y + bottomTextAttr.offset.y, bottomTextAttr.rect.size.width, bottomTextAttr.rect.size.height)
		
		topText.drawInRect(topRect, withAttributes: topTextAttr.getTextAttributes())
		bottomText.drawInRect(bottomRect, withAttributes: bottomTextAttr.getTextAttributes())
		
		memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
	}
	
	// MARK: - Text change selection delegate
	
	func didUpdateTextAttributes(topTextAttributes: XTextAttributes, bottomTextAttributes: XTextAttributes) {
		topTextAttr = topTextAttributes
		bottomTextAttr = bottomTextAttributes
		cookImage()
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


    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
		
		self.baseImage = placeholderImage
		self.baseImageFullSize = UIImage(data: NSData(contentsOfURL: (contentEditingInput?.fullSizeImageURL!)!)!)
		
		let ratio1 = 1024/(baseImage?.size.width)!
		let ratio2 = 1024/(baseImage?.size.height)!
		let ratio = min(ratio1, ratio2)
		
		self.baseImage = getImageByResizingImage(baseImage!, ratio: ratio)
		
//		print("Base image size = \(NSStringFromCGSize((baseImage?.size)!))")
//		print("Full image size = \(NSStringFromCGSize((baseImageFullSize?.size)!))")
		
		input = contentEditingInput
		
		self.viewDidLoad()
		
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        // Update UI to reflect that editing has finished and output is being rendered.
		
		self.view.endEditing(true)
		
		// Now render for the full size image
		
		let imageSize = self.baseImage?.size as CGSize!
		let fullImageSize = self.baseImageFullSize?.size as CGSize!
		let ratio = fullImageSize.width/imageSize.width
		
		UIGraphicsBeginImageContext(fullImageSize)
		
		self.baseImageFullSize!.drawInRect(CGRectMake(0, 0, fullImageSize.width, fullImageSize.height))
		
		self.topTextAttr.fontSize = self.topTextAttr.fontSize * ratio
		self.bottomTextAttr.fontSize = self.bottomTextAttr.fontSize * ratio
		
		self.topTextAttr.offset = CGPointMake(self.topTextAttr.offset.x * ratio, self.topTextAttr.offset.y * ratio)
		self.bottomTextAttr.offset = CGPointMake(self.bottomTextAttr.offset.x * ratio, self.bottomTextAttr.offset.y * ratio)
		
		let topText = self.topTextAttr.uppercase ? self.topTextAttr.text.uppercaseString : self.topTextAttr.text;
		let bottomText = self.bottomTextAttr.uppercase ? self.bottomTextAttr.text.uppercaseString : self.bottomTextAttr.text;
		
		let topRect = CGRectMake(self.topTextAttr.rect.origin.x * ratio + self.topTextAttr.offset.x, self.topTextAttr.rect.origin.y * ratio + self.topTextAttr.offset.y, self.topTextAttr.rect.size.width * ratio, self.topTextAttr.rect.size.height * ratio)
		
		let bottomRect = CGRectMake(self.bottomTextAttr.rect.origin.x * ratio + self.bottomTextAttr.offset.x, self.bottomTextAttr.rect.origin.y * ratio + self.bottomTextAttr.offset.y, self.bottomTextAttr.rect.size.width * ratio, self.bottomTextAttr.rect.size.height * ratio)
		
		topText.drawInRect(topRect, withAttributes: self.topTextAttr.getTextAttributes())
		bottomText.drawInRect(bottomRect, withAttributes: self.bottomTextAttr.getTextAttributes())
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		
        // Render and provide output on a background queue.
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
			
			let archivedData = NSKeyedArchiver.archivedDataWithRootObject(["Meme maker version": 4.69, "Date created": NSDate(), "topTextAttributes": self.topTextAttr.getTextAttributes(), "bottomTextAttributes": self.bottomTextAttr.getTextAttributes()])
            
            // Provide new adjustments and render output to given location.
			
             output.adjustmentData = PHAdjustmentData(formatIdentifier: "com.avikantz.Meme-Maker.Photo-Meme", formatVersion: "4.69", data: archivedData)
             let renderedJPEGData = UIImageJPEGRepresentation(newImage, 1.0)
             renderedJPEGData!.writeToURL(output.renderedContentURL, atomically: true)
			
            // Call completion handler to commit edit to Photos.
            completionHandler?(output)
            
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
