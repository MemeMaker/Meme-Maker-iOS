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
import DZNEmptyDataSet
import ReachabilitySwift
import SDWebImage
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


class BrowseViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
	
	var editorVC: EditorViewController?
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	var creations = NSMutableArray()
	var fetchedCreations = NSMutableArray()
	
	var context: NSManagedObjectContext?
	var fetchRequest: NSFetchRequest<XMeme>?

	var longPressGesture: UILongPressGestureRecognizer?
	
	// MARK: -
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: "XCreated")
		request.sortDescriptors = [NSSortDescriptor.init(key: "dateCreated", ascending: false)]
		do {
			let fetchedArray = try self.context?.fetch(request)
			creations = NSMutableArray(array: fetchedArray!)
			fetchedCreations = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("Error in fetching.")
		}
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
			}
		}
		
		longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(BrowseViewController.handleLongPress(_:)))
		longPressGesture?.minimumPressDuration = 0.8
		collectionView.addGestureRecognizer(longPressGesture!)
		
		if (Date().timeIntervalSince(SettingsManager.sharedManager().getLastUpdateDate())) > 7 * 86400 || creations.count == 0 {
			self.refershAction(self)
		}
		
		self.collectionView.emptyDataSetDelegate = self
		self.collectionView.emptyDataSetSource = self
		
    }
	
	@IBAction func refershAction(_ sender: AnyObject) {
		SVProgressHUD.show(withStatus: "Loading...")
		do {
			if let reachable = Reachability.init()?.isReachable {
				if reachable {
					self.fetchedCreations = NSMutableArray()
					self.fetchCreations(1)
				}
			}
		}
		catch _ {
			SVProgressHUD.showError(withStatus: "No connection!")
		}
	}
	
	func fetchCreations(_ paging: Int) -> Void {
		
		var request = URLRequest(url: apiSubmissionsPaging(paging))
		request.httpMethod = "GET"
		
		URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
			
			if (error != nil) {
				print("Error: %@", error?.localizedDescription ?? "nil")
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
					
					let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: AnyObject]
					let code = json["code"] as! Int
					if (code == 200) {
						let jsoncreations = json["data"] as! NSArray
						let creationsArray = XCreated.getAllSubmissionsFromArray(jsoncreations, context: asyncContext)!
						for creation in creationsArray {
							self.fetchedCreations.add(creation)
						}
						try asyncContext.save()
						DispatchQueue.main.async(execute: {
							self.fetchCreations(paging + 1)
						})
					}
					else {
						DispatchQueue.main.async(execute: {
							self.creations = NSMutableArray(array: self.fetchedCreations as [AnyObject])
							self.collectionView.reloadData()
							SVProgressHUD.dismiss()
						})
						return
					}
				}
				catch _ {
					print("\(#function) | Unable to parse")
					SVProgressHUD.showError(withStatus: "Failed to fetch")
					return
				}
				
			}
			
		}) .resume()
		
	}
	
	// MARK: - Collection view data source
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return creations.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! ViewerCollectionViewCell
		
		let creation = creations.object(at: indexPath.row) as! XCreated
		
		let imagePath = imagesPathForFileName("\(creation.memeID)")
		if let image = UIImage(contentsOfFile: imagePath) {
			cell.image = image
		}
		else {
			var meme: XMeme!
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "XMeme")
			fetchRequest.predicate = NSPredicate(format: "memeID == %li", creation.memeID)
			do {
				let fetchedArray = try self.context!.fetch(fetchRequest)
				if (fetchedArray.count > 0) {
					meme = fetchedArray.first as! XMeme
					if let imageURLString = meme.image {
						let imageURL = URL(string: imageURLString)
						DispatchQueue.main.async(execute: {
							let data = try? Data(contentsOf: imageURL!)
							try? data?.write(to: URL(fileURLWithPath: imagePath), options: [.atomic])
							if let dimage = UIImage(data: data!) {
								cell.image = dimage
							}
						})
					}
				}
			}
			catch _ {
				
			}
		}
		
		if let topText = creation.topText {
			cell.topText = topText.uppercased()
		}
		if let bottomText = creation.bottomText {
			cell.bottomText = bottomText.uppercased()
		}
		
		return cell
		
	}
	
	// MARK: - Collection view delegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			let creation = creations.object(at: indexPath.row) as! XCreated
			let baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(creation.memeID)"))
			self.editorVC?.editorMode = .viewer
			self.editorVC?.baseImage = baseImage
			self.editorVC?.topTextField.text = creation.topText!
			self.editorVC?.bottomTextField.text = creation.bottomText!
			self.editorVC?.memeNameLabel.text = "Browse"
			self.editorVC?.updateForViewing()
		}
		else {
			
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: self.collectionView.bounds.width/2, height: self.collectionView.bounds.width/2)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}
	
	func handleLongPress(_ recognizer: UILongPressGestureRecognizer) -> Void {
		if let indexPath = collectionView.indexPathForItem(at: recognizer.location(in: self.collectionView)) {
			let creation = creations.object(at: indexPath.row) as! XCreated
			if let baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(creation.memeID)")) {
				let editedImage = getImageByDrawingOnImage(baseImage, topText: creation.topText!, bottomText: creation.bottomText!)
				let activityVC = UIActivityViewController(activityItems: [editedImage], applicationActivities: nil)
				if (UI_USER_INTERFACE_IDIOM() == .pad) {
					activityVC.modalPresentationStyle = .popover
					activityVC.popoverPresentationController?.sourceView = self.collectionView
				}
				self.present(activityVC, animated: true) {
				}
			}
		}
	}
	
	// MARK: - DZN Empty Data Set
	
	func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		let title = NSAttributedString(string: "No memes to browse!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 24)!, NSForegroundColorAttributeName: globalTintColor])
		return title
	}
	
	func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
		let title = NSAttributedString(string: "Reload!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 18)!, NSForegroundColorAttributeName: globalTintColor])
		return title
	}
	
	func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
		return globalBackColor
	}
	
	func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
		return creations.count == 0
	}
	
	func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
		refershAction(self)
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
