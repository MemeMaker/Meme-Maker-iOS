//
//  MemesViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class MemesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	
	@IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	// MARK: - Collection view data source
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1;
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 0;
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		return UICollectionViewCell();
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
