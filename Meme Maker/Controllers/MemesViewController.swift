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
import BWWalkthrough

protocol MemesViewControllerDelegate {
	func didSelectMeme(meme: XMeme) -> Void
	func didPickImage(image: UIImage) -> Void
}

class MemesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BWWalkthroughViewControllerDelegate {
	
	var editorVC: EditorViewController?
	
	var memeSelectionDelegate: MemesViewControllerDelegate?
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!

	@IBOutlet weak var searchPlaceholderTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var collectionViewToSearchViewConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var searchBarButton: UIBarButtonItem!
	@IBOutlet weak var lastEditBarButton: UIBarButtonItem!
	@IBOutlet weak var photoGalleryButton: UIBarButtonItem!
	@IBOutlet weak var listViewToggleBarButton: UIBarButtonItem!
	
	var isListView: Bool = false {
		didSet {
			SettingsManager.sharedManager().setBool(isListView, key: kSettingsViewModeIsList)
		}
	}
	
	var memes = NSMutableArray()
	var allMemes = NSMutableArray()
	var fetchedMemes = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		if (SettingsManager.sharedManager().getInteger(kSettingsTimesLaunched) == 1) {
			showTutorial()
		}
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.navigationItem.rightBarButtonItems = [self.searchBarButton, self.photoGalleryButton]
			if let image = UIImage(contentsOfFile: imagesPathForFileName("lastImage")) {
				self.memeSelectionDelegate?.didPickImage(image)
				self.editorVC?.memeNameLabel.text = "Last Edit"
			}
		}
		
    }
	
	override func viewDidAppear(animated: Bool) {
		
		let request = NSFetchRequest(entityName: "XMeme")
		request.sortDescriptors = [NSSortDescriptor.init(key: "memeID", ascending: true)]
		do {
			let fetchedArray = try self.context?.executeFetchRequest(request)
			memes = NSMutableArray(array: fetchedArray!)
			allMemes = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("Error in fetching.")
		}
		
		if (NSDate().timeIntervalSinceDate(SettingsManager.sharedManager().getLastUpdateDate())) > 7 * 86400 {
			SVProgressHUD.showWithStatus("Fetching latest memes, Just for you!")
			self.fetchedMemes = NSMutableArray()
			self.fetchMemes(1)
		}
		
		isListView = SettingsManager.sharedManager().getBool(kSettingsViewModeIsList)
		updateCollectionViewCells()
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
						self.fetchedMemes.addObjectsFromArray(memesArray as [AnyObject])
						dispatch_async(dispatch_get_main_queue(), {
							self.fetchMemes(paging + 1)
						})
					}
					else {
						self.memes = self.fetchedMemes
						dispatch_async(dispatch_get_main_queue(), {
							SettingsManager.sharedManager().saveLastUpdateDate()
							self.collectionView.reloadData()
							SVProgressHUD.dismiss()
						})
						return
					}
				}
				catch _ {
					print("Unable to parse")
					SVProgressHUD.showErrorWithStatus("Failed to fetch")
					return
				}
			}
		}.resume()
	}
	
	// MARK: - Bar Button Actions

	@IBAction func lastEditAction(sender: AnyObject) {
		if (NSFileManager.defaultManager().fileExistsAtPath(imagesPathForFileName("lastImage"))) {
			let editorVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditorVC") as! EditorViewController
			editorVC.editorMode = .UserImage
			editorVC.title = "Last Edit"
			self.presentViewController(editorVC, animated: true, completion: nil)
		}
		else {
			let alertC = modalAlertControllerFor("No last edit", message: "Go on, pick a meme from the list below, or choose your own.")
			self.presentViewController(alertC, animated: true, completion: nil)
		}
	}
	
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
		updateCollectionViewCells()
	}
	
	func updateCollectionViewCells () -> Void {
		isListView = SettingsManager.sharedManager().getBool(kSettingsViewModeIsList)
		if (isListView) {
			self.listViewToggleBarButton.image = UIImage(named: "collectionViewIcon")
		}
		else {
			self.listViewToggleBarButton.image = UIImage(named: "tableViewIcon")
		}
		self.collectionView.reloadData()
	}
	
	@IBAction func sortAction(sender: AnyObject) {
		let alertController = UIAlertController(title: "Sort", message: nil, preferredStyle: .ActionSheet)
		let nameSort = UIAlertAction(title: "Alphabetical", style: .Default) { (action) in
			self.memes.sortUsingDescriptors([NSSortDescriptor.init(key: "name", ascending: true)])
			self.collectionView.reloadData()
		}
		let popSort = UIAlertAction(title: "Popularity", style: .Default) { (action) in
			self.memes.sortUsingDescriptors([NSSortDescriptor.init(key: "rank", ascending: true)])
			self.collectionView.reloadData()
		}
		let defSort = UIAlertAction(title: "Default", style: .Default) { (action) in
			self.memes.sortUsingDescriptors([NSSortDescriptor.init(key: "memeID", ascending: true)])
			self.collectionView.reloadData()
		}
		alertController.addAction(nameSort)
		alertController.addAction(popSort)
		alertController.addAction(defSort)
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			alertController.modalPresentationStyle = .Popover
			alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}

	// MARK: - Collection view data source
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1;
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.memes.count;
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell: MemesCollectionViewCell!
			
		if (isListView) {
			cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("listCell", forIndexPath: indexPath) as! MemesCollectionViewCell
		}
		else {
			cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("gridCell", forIndexPath: indexPath) as! MemesCollectionViewCell
		}
		
		let meme = self.memes.objectAtIndex(indexPath.row) as! XMeme
		
		cell.meme = meme
		cell.isListCell = self.isListView
		
		return cell;
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		let meme = memes.objectAtIndex(indexPath.row) as! XMeme
		
		if let image = UIImage(contentsOfFile: imagesPathForFileName("\(meme.memeID)")) {
			let data = UIImageJPEGRepresentation(image, 0.8)
			do {
				try data?.writeToFile(imagesPathForFileName("lastImage"), options: .AtomicWrite)
			}
			catch _ {}
		}
		else {
			return
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.memeSelectionDelegate?.didSelectMeme(meme)
		}
		else {
			// We don't want text to retain while selecting new meme on iPhone, let it be there on iPad
			XTextAttributes.clearTopAndBottomTexts()
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
	
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		lastEditBarButton?.enabled = false
		photoGalleryButton?.enabled = false
	}
	
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
		lastEditBarButton?.enabled = true
		photoGalleryButton?.enabled = true
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		self.filterMemesWithSearchText(searchText)
	}
	
	func filterMemesWithSearchText(text: String) -> Void {
		if (text.characters.count > 0) {
			let predicate = NSPredicate(format: "name contains[cd] %@ OR tags contains[cd] %@", text, text)
			memes = NSMutableArray(array: (allMemes.filteredArrayUsingPredicate(predicate)))
		}
		else {
			memes = allMemes
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
				picker.modalPresentationStyle = .Popover
				picker.popoverPresentationController?.barButtonItem = self.photoGalleryButton
			}
			self.presentViewController(picker, animated: true, completion: nil)
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
				let alertC = modalAlertControllerFor("Error", message: "Camera not found")
				self.presentViewController(alertC, animated: true, completion: nil)
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		
		alertController.addAction(photoGalleryAction)
		alertController.addAction(cameraAction)
		alertController.addAction(cancelAction)

		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			alertController.modalPresentationStyle = .Popover
			alertController.popoverPresentationController?.barButtonItem = self.photoGalleryButton
		}
		self.presentViewController(alertController, animated: true, completion: nil)
		
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		
		let ratio1 = 1024/image.size.height
		let ratio2 = 1024/image.size.width
		let ratio = min(ratio1, ratio2)
		
		let newImage = getImageByResizingImage(image, ratio: ratio)
		
		let data = UIImageJPEGRepresentation(newImage, 0.8)
		do {
			try data?.writeToFile(imagesPathForFileName("lastImage"), options: .AtomicWrite)
		}
		catch _ {}
		
		self.dismissViewControllerAnimated(true) { 
			if (UI_USER_INTERFACE_IDIOM() == .Pad) {
				self.memeSelectionDelegate?.didPickImage(newImage)
			}
			else {
				// We don't want text to retain while selecting new meme on iPhone, let it be there on iPad
				XTextAttributes.clearTopAndBottomTexts()
				let editorVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditorVC") as! EditorViewController
				editorVC.editorMode = .UserImage
				self.presentViewController(editorVC, animated: true, completion: nil)
			}
		}
		
	}
	
	// MARK: - Walkthrough and delegate
	
	func showTutorial() -> Void {
		let storyboard = UIStoryboard(name: "Walkthrough", bundle: nil)
		let walkthrough = storyboard.instantiateViewControllerWithIdentifier("WalkthroughBase") as! BWWalkthroughViewController
		let page1 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage1")
		let page2 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage2")
		let page3 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage3")
		walkthrough.delegate = self
		walkthrough.addViewController(page1)
		walkthrough.addViewController(page2)
		walkthrough.addViewController(page3)
		self.presentViewController(walkthrough, animated: true, completion: nil)
	}
	
	func walkthroughCloseButtonPressed() {
		self.dismissViewControllerAnimated(true, completion: nil)
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
