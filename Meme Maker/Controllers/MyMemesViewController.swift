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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
		
		print("user creation : \(ucreation)")
		
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
		
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			let ucreation = userCreations.objectAtIndex(indexPath.row) as! XUserCreation
			let baseImage = UIImage(contentsOfFile: ucreation.imagePath!)
			self.editorVC?.editorMode = .Viewer
			self.editorVC?.baseImage = baseImage
			self.editorVC?.topTextField.text = ucreation.topText!
			self.editorVC?.bottomTextField.text = ucreation.bottomText!
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
