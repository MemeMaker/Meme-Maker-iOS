//
//  MyMemesViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet
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


class MyMemesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	var userCreations = NSMutableArray()
	
	var context: NSManagedObjectContext?
	var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
	
	var editorVC: EditorViewController?
	
	var longPressGesture: UILongPressGestureRecognizer?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		context = appDelegate.managedObjectContext
		
		fetchRequest = NSFetchRequest(entityName: "XUserCreation")
		fetchRequest?.sortDescriptors = [NSSortDescriptor.init(key: "createdOn", ascending: false)]
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
			}
		}
		
		longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MyMemesViewController.handleLongPress(_:)))
		longPressGesture?.minimumPressDuration = 0.8
		collectionView.addGestureRecognizer(longPressGesture!)
		
		self.collectionView.emptyDataSetSource = self
		self.collectionView.emptyDataSetDelegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		do {
			let fetchedArray = try context?.fetch(fetchRequest!)
			userCreations = NSMutableArray(array: fetchedArray!)
		}
		catch _ {
			print("\(#function) | Unable to fetch")
		}
		collectionView.reloadData()
	}
	
	// MARK: - Collection view data source
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return userCreations.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! ViewerCollectionViewCell
		
		let ucreation = userCreations.object(at: indexPath.row) as! XUserCreation
		
		cell.topText = ucreation.topText!.uppercased()
		cell.bottomText = ucreation.bottomText!.uppercased()
		
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
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let ucreation = userCreations.object(at: indexPath.row) as! XUserCreation
		let topTextAttr = XTextAttributes(savename: "topAttr")
		let bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		topTextAttr.text = ucreation.topText! as NSString
		bottomTextAttr.text = ucreation.bottomText! as NSString
		topTextAttr.saveAttributes("topAttr")
		bottomTextAttr.saveAttributes("bottomAttr")
		var baseImage = UIImage()
		if (ucreation.isMeme) {
			baseImage = UIImage(contentsOfFile: imagesPathForFileName("\(ucreation.memeID)"))!
		}
		else {
			baseImage = UIImage(contentsOfFile: userImagesPathForFileName(ucreation.createdOn!))!
		}
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.editorVC?.editorMode = .viewer
			self.editorVC?.baseImage = baseImage
			self.editorVC?.memeNameLabel.text = "My memes"
			self.editorVC?.topTextField.text = ucreation.topText!
			self.editorVC?.bottomTextField.text = ucreation.bottomText!
			self.editorVC?.updateForViewing()
		}
		else {
			let editorVC = self.storyboard?.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
			editorVC.editorMode = .viewer
			editorVC.baseImage = baseImage
			editorVC.title = "My Memes"
			self.present(editorVC, animated: true, completion: nil)
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
	
	// MARK: - DZN Empty Data Set
	
	func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		let title = NSAttributedString(string: "No memes!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 24)!, NSForegroundColorAttributeName: globalTintColor])
		return title
	}
	
	func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		let title = NSAttributedString(string: "Go create a meme and share it!", attributes: [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 16)!, NSForegroundColorAttributeName: globalTintColor])
		return title
	}
	
	func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
		return globalBackColor
	}
	
	func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
		return userCreations.count == 0
	}
	
	// MARK: - Handle long press
	
	func handleLongPress(_ recognizer: UILongPressGestureRecognizer) -> Void {
		if let indexPath = collectionView.indexPathForItem(at: recognizer.location(in: self.collectionView)) {
			let alertController = UIAlertController(title: "Delete?", message: "This action is irreversible. Are you sure you want to continue?", preferredStyle: .actionSheet)
			let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
				let ucreation = self.userCreations.object(at: indexPath.row) as! XUserCreation
				self.context?.delete(ucreation)
				do {
					try self.context?.save()
				}
				catch _ {}
				self.viewDidAppear(true)
			})
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			alertController.addAction(deleteAction)
			alertController.addAction(cancelAction)
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				alertController.modalPresentationStyle = .popover
				alertController.popoverPresentationController?.permittedArrowDirections = .any
				if let sourceView = collectionView.cellForItem(at: indexPath) {
					alertController.popoverPresentationController?.sourceView = sourceView
				}
				else {
					alertController.popoverPresentationController?.sourceView = self.collectionView
				}
			}
			self.present(alertController, animated: true, completion: nil)
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
