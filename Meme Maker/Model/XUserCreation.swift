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
	
	var dateCreated: Date? {
		didSet {
			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			self.createdOn = formatter.string(from: dateCreated!)
		}
	}
	
	class func createOrUpdateUserCreationWithMeme(_ meme: XMeme, topText: String, bottomText: String, dateCreated: Date, context: NSManagedObjectContext) -> XUserCreation {
		
		let fetchRequest = NSFetchRequest(entityName: "XUserCreation")
		fetchRequest.predicate = NSPredicate(format: "memeID == %li AND topText == %@ AND bottomText == %@", meme.memeID, topText, bottomText)
		
		var creation: XUserCreation!
		
		do {
			let fetchedArray = try context.fetch(fetchRequest)
			if (fetchedArray.count > 0) {
				creation = fetchedArray.first as! XUserCreation
			}
			else {
				creation = NSEntityDescription.insertNewObject(forEntityName: "XUserCreation", into: context) as! XUserCreation
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
	
	class func createOrUpdateUserCreationWithUserImage(_ image: UIImage, topText: String, bottomText: String, dateCreated: Date, context: NSManagedObjectContext) -> XUserCreation {
		
		let fetchRequest = NSFetchRequest(entityName: "XUserCreation")
		fetchRequest.predicate = NSPredicate(format: "topText == %@ AND bottomText == %@", topText, bottomText)
		
		var creation: XUserCreation!
		
		do {
			let fetchedArray = try context.fetch(fetchRequest)
			if (fetchedArray.count > 0) {
				creation = fetchedArray.first as! XUserCreation
			}
			else {
				creation = NSEntityDescription.insertNewObject(forEntityName: "XUserCreation", into: context) as! XUserCreation
				creation.topText = topText
				creation.bottomText = bottomText
				creation.dateCreated = dateCreated
				creation.isMeme = false
				
			}
		}
		catch _ {
		}
		
		
		let data = UIImageJPEGRepresentation(image, 0.8)
		let filePath = userImagesPathForFileName(creation.createdOn!)
		
		if (FileManager.default.fileExists(atPath: filePath)) {
			print("\(#function) | file already present.")
		}
		
		do {
			try data?.write(to: URL(fileURLWithPath: filePath), options: .atomicWrite)
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
