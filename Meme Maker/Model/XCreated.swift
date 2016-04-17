//
//  XCreated.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class XCreated: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
	
	var dateSubmission: NSDate?
	
	class func createOrUpdateSubmissionWithData(data: NSDictionary, context: NSManagedObjectContext) -> NSManagedObject {
		
		let ID: Int32 = (data.objectForKey("memeID")?.intValue)!
		let topText = data.objectForKey("topText") as? String
		let bottomText = data.objectForKey("bottomText") as? String
		
		let fetchRequest = NSFetchRequest(entityName: "XCreated")
		fetchRequest.predicate = NSPredicate(format: "memeID == %i AND topText == %@ AND bottomText == %@", ID, topText!, bottomText!)
		
		var submission: XCreated!
		
		do {
			let fetchedArray = try context.executeFetchRequest(fetchRequest)
			if (fetchedArray.count > 0) {
//			print("Submission \(ID) already present.")
				submission = fetchedArray.first as! XCreated
			}
			else {
//				print("Inserting submission \(ID).")
				submission = NSEntityDescription.insertNewObjectForEntityForName("XCreated", inManagedObjectContext: context) as! XCreated
				submission.memeID = ID
				submission.topText = topText
				submission.bottomText = bottomText
				submission.dateCreated = data.objectForKey("dateCreated") as? String
				let dateFormatter = NSDateFormatter.init()
				dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
				submission.dateSubmission = dateFormatter.dateFromString(submission.dateCreated!)
				
			}
		}
		catch _ {
			
		}
		
		return submission
	}
	
	class func getAllSubmissionsFromArray(array: NSArray, context: NSManagedObjectContext) -> NSArray? {
		
		let submissionsArray = NSMutableArray()
		
		for dict in array {
			let subm = self.createOrUpdateSubmissionWithData(dict as! NSDictionary, context: context)
			submissionsArray.addObject(subm)
		}
		
		return submissionsArray
		
	}
	
	override var description: String {
		return "{\n\tmemeID = \(memeID),\n\tdateCreated = \(dateCreated!)\n}"
	}

}
