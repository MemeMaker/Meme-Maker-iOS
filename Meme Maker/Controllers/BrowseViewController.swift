//
//  BrowseViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreData

class BrowseViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	var editorVC: EditorViewController?
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	var creations = NSMutableArray()
	var fetchedCreations = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil
	var fetchRequest: NSFetchRequest? = nil

	var longPressGesture: UILongPressGestureRecognizer?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		let request = NSFetchRequest(entityName: "XCreated")
		request.sortDescriptors = [NSSortDescriptor.init(key: "dateCreated", ascending: false)]
		do {
			let fetchedArray = try self.context?.executeFetchRequest(request)
			creations = NSMutableArray(array: fetchedArray!)
			fetchedCreations = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("Error in fetching.")
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
			}
		}
		
		longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(BrowseViewController.handleLongPress(_:)))
		longPressGesture?.minimumPressDuration = 0.8
		collectionView.addGestureRecognizer(longPressGesture!)
		
    }
	
	@IBAction func refershAction(sender: AnyObject) {
		SVProgressHUD.showWithStatus("Loading...")
		self.fetchedCreations = NSMutableArray()
		self.fetchCreations(1)
	}
	
	func fetchCreations(paging: Int) -> Void {
		
		let request = NSMutableURLRequest(URL: apiSubmissionsPaging(paging))
		request.HTTPMethod = "GET"
		
		NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
			
			if (error != nil) {
				print("Error: %@", error?.localizedDescription)
				return
			}
			
			if (data != nil) {
				
				do {
					let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
					let code = json.valueForKey("code") as! Int
					if (code == 200) {
						let jsoncreations = json.valueForKey("data") as! NSArray
						let creationsArray = XCreated.getAllSubmissionsFromArray(jsoncreations, context: self.context!)!
						self.fetchedCreations.addObjectsFromArray(creationsArray as [AnyObject])
						dispatch_async(dispatch_get_main_queue(), {
							self.fetchCreations(paging + 1)
						})
					}
					else {
						self.creations = self.fetchedCreations
						dispatch_async(dispatch_get_main_queue(), {
							self.collectionView.reloadData()
							SVProgressHUD.dismiss()
						})
						return
					}
				}
				catch _ {
					print("\(#function) | Unable to parse")
					SVProgressHUD.showErrorWithStatus("Failed to fetch")
					return
				}
				
			}
			
		}.resume()
		
	}
	
	// MARK: - Collection view data source
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return creations.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gridCell", forIndexPath: indexPath) as! ViewerCollectionViewCell
		
		let creation = creations.objectAtIndex(indexPath.row) as! XCreated
		
		let image = UIImage(contentsOfFile: imagesPathForFileName("\(creation.memeID)"))
		
		cell.topText = creation.topText!.uppercaseString
		cell.bottomText = creation.bottomText!.uppercaseString
		cell.image = image!
		
		return cell
		
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			let creation = creations.objectAtIndex(indexPath.row) as! XCreated
			let baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(creation.memeID)"))
			self.editorVC?.editorMode = .Viewer
			self.editorVC?.baseImage = baseImage
			self.editorVC?.topTextField.text = creation.topText!
			self.editorVC?.bottomTextField.text = creation.bottomText!
			self.editorVC?.memeNameLabel.text = "Browse"
			self.editorVC?.updateForViewing()
		}
		else {
			
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
	
	func handleLongPress(recognizer: UILongPressGestureRecognizer) -> Void {
		if let indexPath = collectionView.indexPathForItemAtPoint(recognizer.locationInView(self.collectionView)) {
			let creation = creations.objectAtIndex(indexPath.row) as! XCreated
			let baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(creation.memeID)"))
			let editedImage = getImageByDrawingOnImage(baseImage!, topText: creation.topText!, bottomText: creation.bottomText!)
			let textToShare = "Check out this funny meme!"
			let imageToShare = editedImage
			let activityVC = UIActivityViewController(activityItems: [textToShare, imageToShare], applicationActivities: nil)
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				activityVC.modalPresentationStyle = .Popover
				activityVC.popoverPresentationController?.sourceView = self.collectionView
			}
			self.presentViewController(activityVC, animated: true) {
			}
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
