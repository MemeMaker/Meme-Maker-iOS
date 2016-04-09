//
//  XUserCreation.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/8/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class XUserCreation: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
	
	var dateCreated: NSDate? {
		didSet {
			let formatter = NSDateFormatter()
			formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			self.createdOn = formatter.stringFromDate(dateCreated!)
		}
	}
	
	class func createOrUpdateUserCreationWithMeme(meme: XMeme, topText: String, bottomText: String, dateCreated: NSDate, context: NSManagedObjectContext) -> XUserCreation {
		
		let fetchRequest = NSFetchRequest(entityName: "XUserCreation")
		fetchRequest.predicate = NSPredicate(format: "memeID == %li AND topText == %@ AND bottomText == %@", meme.memeID, topText, bottomText)
		
		var creation: XUserCreation!
		
		do {
			let fetchedArray = try context.executeFetchRequest(fetchRequest)
			if (fetchedArray.count > 0) {
				creation = fetchedArray.first as! XUserCreation
			}
			else {
				creation = NSEntityDescription.insertNewObjectForEntityForName("XUserCreation", inManagedObjectContext: context) as! XUserCreation
				creation.memeID = meme.memeID
				creation.topText = topText
				creation.bottomText = bottomText
				creation.dateCreated = dateCreated
				creation.imagePath = imagesPathForFileName("\(meme.memeID)")
				creation.isMeme = true
			}
		}
		catch _ {
		}
		
		do {
			try context.save()
		}
		catch _ {
			print("\(#function): Unable to save!")
		}
		
		return creation
	}
	
	class func createOrUpdateUserCreationWithUserImage(image: UIImage, topText: String, bottomText: String, dateCreated: NSDate, context: NSManagedObjectContext) -> XUserCreation {
		
		var creation: XUserCreation!
		
		creation = NSEntityDescription.insertNewObjectForEntityForName("XUserCreation", inManagedObjectContext: context) as! XUserCreation
		creation.topText = topText
		creation.bottomText = bottomText
		creation.dateCreated = dateCreated
		creation.isMeme = false
		
		let data = UIImageJPEGRepresentation(image, 0.8)
		let filePath = userImagesPathForFileName(creation.createdOn!)
		
		if (NSFileManager.defaultManager().fileExistsAtPath(filePath)) {
			print("\(#function) | file already present.")
		}
		
		do {
			try data?.writeToFile(filePath, options: .AtomicWrite)
		}
		catch _ {}
		
		creation.imagePath = filePath
		
		do {
			try context.save()
		}
		catch _ {
			print("\(#function): Unable to save!")
		}

		return creation
	}
	
	override var description: String {
		return "{\n\tisMeme = \(isMeme),\n\tcreated = \(createdOn!),\n\timagePath = \(imagePath!)\n}"
	}
	
}
