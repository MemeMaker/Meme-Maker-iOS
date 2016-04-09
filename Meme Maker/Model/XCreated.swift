//
//  XCreated.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import CoreData


class XCreated: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
	
	var dateSubmission: NSDate?
	
	class func createOrUpdateSubmissionWithData(data: NSDictionary, context: NSManagedObjectContext) -> NSManagedObject {
		
		let ID: Int = (data.objectForKey("memeID")?.integerValue)!
		let topText: String = data.objectForKey("topText") as! String
		let bottomText: String = data.objectForKey("bottomText") as! String
		
		let fetchRequest = NSFetchRequest(entityName: "XMeme")
		fetchRequest.predicate = NSPredicate(format: "memeID == %li AND topText == %@ AND bottomText == %@", ID, topText, bottomText)
		
		var submission: XCreated!
		
		do {
			let fetchedArray = try context.executeFetchRequest(fetchRequest)
			if (fetchedArray.count > 0) {
//			print("Submission \(ID) already present.")
				submission = fetchedArray.first as! XCreated
			}
			else {
//				print("Inserting meme \(ID).")
				submission = NSEntityDescription.insertNewObjectForEntityForName("XCreated", inManagedObjectContext: context) as! XCreated
				submission.memeID = (data.objectForKey("memeID")?.intValue)!
				submission.topText = topText
				submission.bottomText = bottomText
				
			}
		}
		catch _ {
			
		}
		
		submission.dateCreated = data.objectForKey("dateCreated")?.stringValue
		let dateFormatter = NSDateFormatter.init()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		submission.dateSubmission = dateFormatter.dateFromString(submission.dateCreated!)
		
		return submission
	}
	
	class func getAllSubmissionsFromArray(array: NSArray, context: NSManagedObjectContext) -> NSArray? {
		
		let submissionsArray: NSMutableArray = NSMutableArray()
		
		for dict in array {
			let subm = self.createOrUpdateSubmissionWithData(dict as! NSDictionary, context: context)
			submissionsArray.addObject(subm)
		}
		
		do {
			try context.save()
		}
		catch _ {
			print("Unable to save");
		}
		
		return submissionsArray
		
	}

}
