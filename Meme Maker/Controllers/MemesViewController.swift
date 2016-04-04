//
//  MemesViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import CoreData

class MemesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchControllerDelegate {
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var searchBarPlaceholderView: UIView!

	@IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var listViewToggleBarButton: UIBarButtonItem!
	
	var isListView: Bool = true
	
	var searchController: UISearchController?
	
	var memes: NSMutableArray? = NSMutableArray()
	var fetchedMemes: NSMutableArray? = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
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
		
		self.setupSearchController()
		
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
						})
					}
					else {
						self.memes = self.fetchedMemes
						dispatch_async(dispatch_get_main_queue(), {
							self.collectionView.reloadData()
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

	func setupSearchController() -> Void {
		self.searchController = UISearchController.init(searchResultsController: nil)
		self.searchController?.searchBar.frame = CGRectMake(0, 0, self.collectionView.bounds.size.width, 44)
		self.searchController?.searchResultsUpdater = self
		self.searchController?.delegate = self
		self.searchController?.searchBar.backgroundColor = UIColor.whiteColor()
		let txtSearchField = self.searchController?.searchBar.valueForKey("_searchField") as! UITextField
		txtSearchField.backgroundColor = UIColor(white: 0.85, alpha: 1)
		self.searchController?.searchBar.barTintColor = UIColor.whiteColor()
		self.searchController?.dimsBackgroundDuringPresentation = false
		self.definesPresentationContext = true
		self.searchController?.searchBar.sizeToFit()
		self.searchBarPlaceholderView.addSubview((self.searchController?.searchBar)!)
	}
	
	// MARK: - Bar Button Actions

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
	
	// MARK: - Search results updater
	
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		let searchBar = searchController.searchBar
		let text = searchBar.text!
		self.filterMemesWithSearchText(text)
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
	
	// MARK: - Search controller delagate
	
	func willDismissSearchController(searchController: UISearchController) {
		self.collectionViewTopConstraint.constant = -22
	}
	
	func willPresentSearchController(searchController: UISearchController) {
		self.collectionViewTopConstraint.constant = 22
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
