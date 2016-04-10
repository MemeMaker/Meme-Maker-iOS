//
//  MyMemesViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import CoreData

class MyMemesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	var userCreations = NSMutableArray()
	
	var context: NSManagedObjectContext?
	var fetchRequest: NSFetchRequest?
	
	var editorVC: EditorViewController?
	
	var longPressGesture: UILongPressGestureRecognizer?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		fetchRequest = NSFetchRequest(entityName: "XUserCreation")
		fetchRequest?.sortDescriptors = [NSSortDescriptor.init(key: "createdOn", ascending: false)]
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
			}
		}
		
		longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MyMemesViewController.handleLongPress(_:)))
		longPressGesture?.minimumPressDuration = 0.8
		collectionView.addGestureRecognizer(longPressGesture!)
    }
	
	override func viewDidAppear(animated: Bool) {
		do {
			let fetchedArray = try context?.executeFetchRequest(fetchRequest!)
			userCreations = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("\(#function) | Unable to fetch")
		}
		collectionView.reloadData()
	}
	
	// MARK: - Collection view data source
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return userCreations.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gridCell", forIndexPath: indexPath) as! ViewerCollectionViewCell
		
		let ucreation = userCreations.objectAtIndex(indexPath.row) as! XUserCreation
		
		cell.topText = ucreation.topText!.uppercaseString
		cell.bottomText = ucreation.bottomText!.uppercaseString
		
		if (ucreation.isMeme) {
			let image = UIImage(contentsOfFile: imagesPathForFileName("\(ucreation.memeID)"))
			cell.image = image!
		}
		else {
			let image = UIImage(contentsOfFile: userImagesPathForFileName(ucreation.createdOn!))
			cell.image = image!
		}
		
		return cell
		
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let ucreation = userCreations.objectAtIndex(indexPath.row) as! XUserCreation
		let topTextAttr = XTextAttributes(savename: "topAttr")
		let bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		topTextAttr.text = ucreation.topText!
		bottomTextAttr.text = ucreation.bottomText!
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		var baseImage = UIImage()
		if (ucreation.isMeme) {
			baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(ucreation.memeID)"))!
		}
		else {
			baseImage = UIImage(contentsOfFile: userImagesPathForFileName(ucreation.createdOn!))!
		}
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.editorVC?.editorMode = .Viewer
			self.editorVC?.baseImage = baseImage
			self.editorVC?.memeNameLabel.text = "My memes"
			self.editorVC?.topTextField.text = ucreation.topText!
			self.editorVC?.bottomTextField.text = ucreation.bottomText!
			self.editorVC?.updateForViewing()
		}
		else {
			let editorVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditorVC") as! EditorViewController
			editorVC.editorMode = .Viewer
			editorVC.baseImage = baseImage
			editorVC.title = "My Memes"
			self.presentViewController(editorVC, animated: true, completion: nil)
		}
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return CGSizeMake(self.collectionView.bounds.width/2, self.collectionView.bounds.width/2)
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	// MARK: - Handle long press
	
	func handleLongPress(recognizer: UILongPressGestureRecognizer) -> Void {
		if let indexPath = collectionView.indexPathForItemAtPoint(recognizer.locationInView(self.collectionView)) {
			let alertController = UIAlertController(title: "Delete?", message: "This action is irreversible. Are you sure you want to continue?", preferredStyle: .ActionSheet)
			let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) in
				let ucreation = self.userCreations.objectAtIndex(indexPath.row) as! XUserCreation
				self.context?.deleteObject(ucreation)
				do {
					try self.context?.save()
				}
				catch _ {}
				self.viewDidAppear(true)
			})
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			alertController.addAction(deleteAction)
			alertController.addAction(cancelAction)
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				alertController.modalPresentationStyle = .Popover
				alertController.popoverPresentationController?.permittedArrowDirections = .Any
				if let sourceView = collectionView.cellForItemAtIndexPath(indexPath) {
					alertController.popoverPresentationController?.sourceView = sourceView
				}
				else {
					alertController.popoverPresentationController?.sourceView = self.collectionView
				}
			}
			self.presentViewController(alertController, animated: true, completion: nil)
		}
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
