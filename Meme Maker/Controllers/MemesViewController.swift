//
//  MemesViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreData

protocol MemesViewControllerDelegate {
	func didSelectMeme(meme: XMeme) -> Void
	func didPickImage(image: UIImage) -> Void
}

class MemesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	var memeSelectionDelegate: MemesViewControllerDelegate?
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!

	@IBOutlet weak var searchPlaceholderTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var collectionViewToSearchViewConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var photoGalleryButton: UIBarButtonItem!
	@IBOutlet weak var listViewToggleBarButton: UIBarButtonItem!
	
	var isListView: Bool = true
	
	var searchController: UISearchController?
	
	var memes: NSMutableArray? = NSMutableArray()
	var fetchedMemes: NSMutableArray? = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
//		SVProgressHUD.show()
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		let request = NSFetchRequest(entityName: "XMeme")
		request.sortDescriptors = [NSSortDescriptor.init(key: "memeID", ascending: true)]
		do {
			let fetchedArray = try self.context?.executeFetchRequest(request)
			memes = NSMutableArray(array: fetchedArray!)
			fetchedMemes = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("Error in fetching.")
		}
		
//		self.fetchedMemes = NSMutableArray()
//		self.fetchMemes(1)
		
    }
	
	func fetchMemes(paging: Int) -> Void {
		
		let request = NSMutableURLRequest(URL: apiMemesPaging(paging))
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
						let jsonmemes = json.valueForKey("data") as! NSArray
						let memesArray = XMeme.getAllMemesFromArray(jsonmemes, context: self.context!)!
						self.fetchedMemes?.addObjectsFromArray(memesArray as [AnyObject])
						dispatch_async(dispatch_get_main_queue(), {
							self.fetchMemes(paging + 1)
							SVProgressHUD.dismiss()
						})
					}
					else {
						self.memes = self.fetchedMemes
						dispatch_async(dispatch_get_main_queue(), {
							self.collectionView.reloadData()
							SVProgressHUD.dismiss()
						})
						return
					}
				}
				catch _ {
					print("Unable to parse")
					return
				}
				
			}
			
		}.resume()
		
	}
	
	// MARK: - Bar Button Actions

	@IBAction func searchAction(sender: AnyObject) {
		
		let searchBarButton = sender as! UIBarButtonItem
		
		if (searchPlaceholderTopConstraint.constant == -44) {
			searchBarButton.image = UIImage(named: "crossButton")
			UIView.animateWithDuration(0.15, animations: {
				self.searchPlaceholderTopConstraint.constant = 0
				self.collectionViewToSearchViewConstraint.constant = -64
				}, completion: { (done) in
					self.searchBar.becomeFirstResponder()
			})
		}
		else {
			searchBarButton.image = UIImage(named: "MagnifyingGlass")
			self.searchBarCancelButtonClicked(self.searchBar)
		}
		
	}
	
	@IBAction func toggleListGridAction(sender: AnyObject) {
		
		self.isListView = !self.isListView
		
		if (isListView) {
			self.listViewToggleBarButton.image = UIImage(named: "collectionViewIcon")
		}
		else {
			self.listViewToggleBarButton.image = UIImage(named: "tableViewIcon")
		}
		
		self.collectionView.reloadData()
		
	}
	

	// MARK: - Collection view data source
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1;
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return (self.memes?.count)!;
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell: MemesCollectionViewCell!
			
		if (isListView) {
			cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("listCell", forIndexPath: indexPath) as! MemesCollectionViewCell
		}
		else {
			cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("gridCell", forIndexPath: indexPath) as! MemesCollectionViewCell
		}
		
		let meme = self.memes?.objectAtIndex(indexPath.row) as! XMeme
		
		cell.meme = meme
		cell.isListCell = self.isListView
		
		return cell;
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let meme = memes?.objectAtIndex(indexPath.row) as! XMeme
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.memeSelectionDelegate?.didSelectMeme(meme)
		}
		else {
			let editorVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditorVC") as! EditorViewController
			editorVC.meme = meme
			editorVC.editorMode = .Meme
			self.presentViewController(editorVC, animated: true, completion: nil)
		}
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		if (isListView) {
			return CGSizeMake(self.view.bounds.width, 60)
		}
		return CGSizeMake(self.collectionView.bounds.width/3, self.collectionView.bounds.width/3)
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	// MARK: - Scroll view delegate
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		self.searchBar.resignFirstResponder()
	}
	
	// MARK: - Search bar delegate
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		self.filterMemesWithSearchText(searchText)
	}
	
	func filterMemesWithSearchText(text: String) -> Void {
		if (text.characters.count > 0) {
			let predicate = NSPredicate(format: "name contains[cd] %@ OR tags contains[cd] %@", text, text)
			memes = NSMutableArray(array: (fetchedMemes?.filteredArrayUsingPredicate(predicate))!)
		}
		else {
			memes = fetchedMemes
		}
		self.collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		self.searchBar.text = ""
		self.filterMemesWithSearchText("")
		self.searchBar.resignFirstResponder()
		UIView.animateWithDuration(0.15) {
			self.searchPlaceholderTopConstraint.constant = -44
			self.collectionViewToSearchViewConstraint.constant = -64
		}
	}
	
//	// NO: - Search controller delagate
//	
//	func willDismissSearchController(searchController: UISearchController) {
//		self.collectionViewTopConstraint.constant = -22
//	}
//	
//	func willPresentSearchController(searchController: UISearchController) {
//		self.collectionViewTopConstraint.constant = 22
//	}
	
	// MARK: - Camera or Gallery pickup
	
	@IBAction func photoGalleryAction(sender: AnyObject) {
		
		let alertController = UIAlertController(title: "Select source", message: "", preferredStyle: .ActionSheet)
		
		let photoGalleryAction = UIAlertAction(title: "Photo Gallery", style: .Default) { (alertAction) in
			let picker = UIImagePickerController()
			picker.delegate = self
			picker.allowsEditing = false
			picker.navigationItem.title = "Select Image"
			picker.sourceType = .PhotoLibrary
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				let popupController = UIPopoverController(contentViewController: picker)
				popupController.presentPopoverFromBarButtonItem(self.photoGalleryButton, permittedArrowDirections: .Any, animated: true)
			}
			else {
				self.presentViewController(picker, animated: true, completion: nil)
			}
		}
		let cameraAction = UIAlertAction(title: "Camera", style: .Default) { (alertAction) in
			if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
				let picker = UIImagePickerController()
				picker.delegate = self
				picker.allowsEditing = false
				picker.sourceType = .Camera
				picker.cameraCaptureMode = .Photo
				self.presentViewController(picker, animated: true, completion: nil)
			}
			else {
				let alertC = UIAlertController(title: "Error", message: "Camera not found!", preferredStyle: .Alert)
				let cancelA = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
				alertC.addAction(cancelA)
				self.presentViewController(alertC, animated: true, completion: nil)
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		
		alertController.addAction(photoGalleryAction)
		alertController.addAction(cameraAction)
		alertController.addAction(cancelAction)

		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			let popupController = UIPopoverController(contentViewController: alertController)
			popupController.presentPopoverFromBarButtonItem(self.photoGalleryButton, permittedArrowDirections: .Any, animated: true)
		}
		else {
			self.presentViewController(alertController, animated: true, completion: nil)
		}

		
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
		
		let ratio = 1024/image.size.height
		
		let newImage = getImageByResizingImage(image, ratio: ratio)
		
		let data = UIImageJPEGRepresentation(newImage, 0.8)
		do {
			try data?.writeToFile(imagesPathForFileName("lastImage"), options: .AtomicWrite)
		}
		catch _ {}
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.memeSelectionDelegate?.didPickImage(newImage)
		}
		else {
			let editorVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditorVC") as! EditorViewController
			editorVC.editorMode = .UserImage
			self.presentViewController(editorVC, animated: true, completion: nil)
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
