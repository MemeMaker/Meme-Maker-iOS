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
import DZNEmptyDataSet
import ReachabilitySwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol MemesViewControllerDelegate {
	func didSelectMeme(_ meme: XMeme) -> Void
	func didPickImage(_ image: UIImage) -> Void
}

class MemesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BWWalkthroughViewControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
	
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
	@IBOutlet weak var sortBarButton: UIBarButtonItem!
	
	@IBOutlet var barButtons: [UIBarButtonItem]!
	
	
	var memesPerRow : Int = 3
	var shouldRefershOnAppear: Bool = false
	
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
		
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.navigationItem.rightBarButtonItems = [self.searchBarButton, self.photoGalleryButton]
			if let image = UIImage(contentsOfFile: imagesPathForFileName("lastImage")) {
				self.memeSelectionDelegate?.didPickImage(image)
				self.editorVC?.memeNameLabel.text = "Last Edit"
			}
		}
		
		self.collectionView.emptyDataSetSource = self
		self.collectionView.emptyDataSetDelegate = self
		
		self.fetchLocalMemes()
		
		if (Date().timeIntervalSince(SettingsManager.sharedManager().getLastUpdateDate())) > 7 * 86400 {
//			SVProgressHUD.showWithStatus("Fetching latest memes, Just for you!")
			print("Fetching latest memes, just for you!")
			if let reachable = Reachability.init()?.isReachable {
				if reachable {
					self.fetchedMemes = NSMutableArray()
					self.fetchMemes(1)
				}
			}
		}
		
    }
	
	override func viewWillAppear(_ animated: Bool) {
		if (shouldRefershOnAppear) {
			fetchLocalMemes()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		shouldRefershOnAppear = true
	}
	
	func fetchLocalMemes() {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: "XMeme")
		if let lastSortKey = SettingsManager.sharedManager().getObject(kSettingsLastSortKey) {
			request.sortDescriptors = [NSSortDescriptor.init(key: lastSortKey as? String, ascending: true)]
		}
		else {
			request.sortDescriptors = [NSSortDescriptor.init(key: "rank", ascending: true)]
		}
		do {
			let fetchedArray = try self.context?.fetch(request)
			memes = NSMutableArray(array: fetchedArray!)
			allMemes = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("Error in fetching.")
		}
		
		memesPerRow = SettingsManager.sharedManager().getInteger(kSettingsNumberOfElementsInGrid)
		isListView = SettingsManager.sharedManager().getBool(kSettingsViewModeIsList)
		updateCollectionViewCells()
		
		self.filterMemesWithSearchText(self.searchBar.text!)
	}
	
	func fetchMemes(_ paging: Int) -> Void {
		var request = URLRequest(url: apiMemesPaging(paging))
		request.httpMethod = "GET"
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if (error != nil) {
				print("Error: ", error?.localizedDescription ?? "nil")
				DispatchQueue.main.async(execute: {
					SVProgressHUD.showError(withStatus: "No connection!")
				})
				return
			}
			if (data != nil) {
				do {
					let persistentStoreCoordinator = self.context?.persistentStoreCoordinator
					let asyncContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
					asyncContext.persistentStoreCoordinator = persistentStoreCoordinator
					
					guard let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: AnyObject] else {
						print("Error in parsing")
						return
					}
					let code = json["code"] as! Int
					if (code == 200) {
						let jsonmemes = json["data"] as! NSArray
						let memesArray = XMeme.getAllMemesFromArray(jsonmemes, context: asyncContext)!
						for meme in memesArray {
							self.fetchedMemes.add(meme)
						}
						try asyncContext.save()
						DispatchQueue.main.async(execute: {
							self.fetchMemes(paging + 1)
						})
					}
					else {
						DispatchQueue.main.async(execute: {
							if (self.fetchedMemes.count >= self.memes.count) {
								print("Finished updating all memes!")
								self.memes = NSMutableArray(array: self.fetchedMemes)
								SettingsManager.sharedManager().saveLastUpdateDate()
	//							SVProgressHUD.dismiss()
								DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
									self.shouldRefershOnAppear = true
									self.viewWillAppear(true)
								})
							}
						})
						return
					}
				}
				catch _ {
					print("Unable to parse")
					SVProgressHUD.showError(withStatus: "Failed to fetch")
					return
				}
			}
		}
		task.resume()
	}
	
	// MARK: - Bar Button Actions

	@IBAction func lastEditAction(_ sender: AnyObject) {
		if (FileManager.default.fileExists(atPath: imagesPathForFileName("lastImage"))) {
			let editorVC = self.storyboard?.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
			editorVC.editorMode = .userImage
			editorVC.title = "Last Edit"
			self.present(editorVC, animated: true, completion: nil)
		}
		else {
			let alertC = modalAlertControllerFor("No last edit", message: "Go on, pick a meme from the list below, or choose your own.")
			self.present(alertC, animated: true, completion: nil)
		}
	}
	
	@IBAction func searchAction(_ sender: AnyObject) {
		let searchBarButton = sender as! UIBarButtonItem
		if (searchPlaceholderTopConstraint.constant == -44) {
			searchBarButton.image = UIImage(named: "crossButton")
			UIView.animate(withDuration: 0.15, animations: {
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
	
	@IBAction func toggleListGridAction(_ sender: AnyObject) {
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
	
	@IBAction func sortAction(_ sender: AnyObject) {
		let alertController = UIAlertController(title: "Sort", message: nil, preferredStyle: .actionSheet)
		let nameSort = UIAlertAction(title: "Alphabetical", style: .default) { (action) in
			self.memes.sort(using: [NSSortDescriptor.init(key: "name", ascending: true)])
			SettingsManager.sharedManager().setObject("name", key: kSettingsLastSortKey)
			self.collectionView.reloadData()
		}
		let popSort = UIAlertAction(title: "Popularity", style: .default) { (action) in
			self.memes.sort(using: [NSSortDescriptor.init(key: "rank", ascending: true)])
			SettingsManager.sharedManager().setObject("rank", key: kSettingsLastSortKey)
			self.collectionView.reloadData()
		}
		let defSort = UIAlertAction(title: "Default", style: .default) { (action) in
			self.memes.sort(using: [NSSortDescriptor.init(key: "memeID", ascending: true)])
			SettingsManager.sharedManager().setObject("memeID", key: kSettingsLastSortKey)
			self.collectionView.reloadData()
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alertController.addAction(nameSort)
		alertController.addAction(popSort)
		alertController.addAction(defSort)
		alertController.addAction(cancelAction)
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			alertController.modalPresentationStyle = .popover
			alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
		}
		self.present(alertController, animated: true, completion: nil)
	}

	// MARK: - Collection view data source
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1;
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.memes.count;
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell: MemesCollectionViewCell!
			
		if (isListView) {
			cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! MemesCollectionViewCell
		}
		else {
			cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! MemesCollectionViewCell
			cell.labelContainerView?.isHidden = (memesPerRow > 4)
		}
		
		let meme = self.memes.object(at: indexPath.row) as! XMeme
		
		cell.meme = meme
		cell.isListCell = self.isListView
		
		return cell;
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		let meme = memes.object(at: indexPath.row) as! XMeme
		
		if let image = UIImage(contentsOfFile: imagesPathForFileName("\(meme.memeID)")) {
			let data = UIImageJPEGRepresentation(image, 0.8)
			do {
				try data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: .atomicWrite)
			}
			catch _ {}
		}
		else {
			return
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.memeSelectionDelegate?.didSelectMeme(meme)
		}
		else {
			// We don't want text to retain while selecting new meme on iPhone, let it be there on iPad
			XTextAttributes.clearTopAndBottomTexts()
			let editorVC = self.storyboard?.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
			editorVC.meme = meme
			editorVC.editorMode = .meme
			self.present(editorVC, animated: true, completion: nil)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if (isListView) {
			return CGSize(width: self.view.bounds.width, height: 60)
		}
		return CGSize(width: self.collectionView.bounds.width/CGFloat(memesPerRow), height: self.collectionView.bounds.width/CGFloat(memesPerRow))
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
	// MARK: - DZN Empty Data Set
	
	func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		let attrs = [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 26)!, NSForegroundColorAttributeName: globalTintColor] as [String : Any]
		let title = NSMutableAttributedString(string: "No memes found!", attributes: attrs)
		if (self.searchBar.text?.characters.count > 0) {
			title.setAttributedString(NSAttributedString(string: "No results", attributes: attrs))
		}
		return title
	}
	
	func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		let desc = NSAttributedString(string: "This shouldn't happen!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 18)!, NSForegroundColorAttributeName: globalTintColor])
		if (self.searchBar.text?.characters.count > 0) {
			return nil
		}
		return desc
	}
	
	func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
		let title = NSAttributedString(string: "Reload!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 22)!, NSForegroundColorAttributeName: globalTintColor])
		if (self.searchBar.text?.characters.count > 0) {
			return nil
		}
		return title
	}
	
	func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
		return globalBackColor
	}
	
	func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
		return memes.count == 0
	}
	
	func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
		SVProgressHUD.show(withStatus: "Fetching Memes!")
		fetchedMemes = NSMutableArray()
		fetchMemes(1)
	}
	
	// MARK: - Scroll view delegate
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.searchBar.resignFirstResponder()
	}
	
	// MARK: - Search bar delegate
	
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		lastEditBarButton?.isEnabled = false
		photoGalleryButton?.isEnabled = false
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		lastEditBarButton?.isEnabled = true
		photoGalleryButton?.isEnabled = true
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		self.filterMemesWithSearchText(searchText)
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func filterMemesWithSearchText(_ text: String) -> Void {
		if (text.characters.count > 0) {
			let predicate = NSPredicate(format: "name contains[cd] %@ OR tags contains[cd] %@", text, text)
			memes = NSMutableArray(array: (allMemes.filtered(using: predicate)))
		}
		else {
			memes = allMemes
		}
		self.collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.searchBar.text = ""
		searchBarButton.image = UIImage(named: "MagnifyingGlass")
		self.filterMemesWithSearchText("")
		self.searchBar.resignFirstResponder()
		UIView.animate(withDuration: 0.15, animations: {
			self.searchPlaceholderTopConstraint.constant = -44
			self.collectionViewToSearchViewConstraint.constant = -64
		}) 
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
	
	@IBAction func photoGalleryAction(_ sender: AnyObject) {
		
		let alertController = UIAlertController(title: "Select source", message: "", preferredStyle: .actionSheet)
		
		let photoGalleryAction = UIAlertAction(title: "Photo Gallery", style: .default) { (alertAction) in
			let picker = UIImagePickerController()
			picker.delegate = self
			picker.allowsEditing = false
			picker.navigationItem.title = "Select Image"
			picker.sourceType = .photoLibrary
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				picker.modalPresentationStyle = .popover
				picker.popoverPresentationController?.barButtonItem = self.photoGalleryButton
			}
			self.present(picker, animated: true, completion: nil)
		}
		let cameraAction = UIAlertAction(title: "Camera", style: .default) { (alertAction) in
			if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
				let picker = UIImagePickerController()
				picker.delegate = self
				picker.allowsEditing = false
				picker.sourceType = .camera
				picker.cameraCaptureMode = .photo
				self.present(picker, animated: true, completion: nil)
			}
			else {
				let alertC = modalAlertControllerFor("Error", message: "Camera not found")
				self.present(alertC, animated: true, completion: nil)
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		
		alertController.addAction(photoGalleryAction)
		alertController.addAction(cameraAction)
		alertController.addAction(cancelAction)

		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			alertController.modalPresentationStyle = .popover
			alertController.popoverPresentationController?.barButtonItem = self.photoGalleryButton
		}
		self.present(alertController, animated: true, completion: nil)
		
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		
		let ratio1 = 1024/image.size.height
		let ratio2 = 1024/image.size.width
		let ratio = min(ratio1, ratio2)
		
		let newImage = getImageByResizingImage(image, ratio: ratio)
		
		let data = UIImageJPEGRepresentation(newImage, 0.8)
		do {
			try data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: .atomicWrite)
		}
		catch _ {}
		
		self.dismiss(animated: true) { 
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				self.memeSelectionDelegate?.didPickImage(newImage)
			}
			else {
				// We don't want text to retain while selecting new meme on iPhone, let it be there on iPad
				XTextAttributes.clearTopAndBottomTexts()
				let editorVC = self.storyboard?.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
				editorVC.editorMode = .userImage
				self.present(editorVC, animated: true, completion: nil)
			}
		}
		
	}
	
	// MARK: - Walkthrough and delegate
	
	func showTutorial() -> Void {
		let storyboard = UIStoryboard(name: "Walkthrough", bundle: nil)
		let walkthrough = storyboard.instantiateViewController(withIdentifier: "WalkthroughBase") as! BWWalkthroughViewController
		let page1 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage1")
		let page2 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage2")
		let page3 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage3")
		let page4 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage4")
		walkthrough.delegate = self
		walkthrough.add(viewController: page1)
		walkthrough.add(viewController: page2)
		walkthrough.add(viewController: page3)
		walkthrough.add(viewController: page4)
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.splitViewController?.present(walkthrough, animated: true, completion: nil)
		}
		else {
			self.navigationController?.present(walkthrough, animated: true, completion: nil)
		}
	}
	
	func walkthroughCloseButtonPressed() {
		self.dismiss(animated: true, completion: nil)
	}
	
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "LastEditSegue") {
			self.lastEditAction(self)
		}
    }

}
