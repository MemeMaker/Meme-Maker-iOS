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
	
	var dateSubmission: Date?
	
	class func createOrUpdateSubmissionWithData(_ data: NSDictionary, context: NSManagedObjectContext) -> NSManagedObject {
		
		let ID: Int32 = ((data.object(forKey: "memeID") as AnyObject).int32Value)!
		let topText = data.object(forKey: "topText") as? String
		let bottomText = data.object(forKey: "bottomText") as? String
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "XCreated")
		fetchRequest.predicate = NSPredicate(format: "memeID == %i AND topText == %@ AND bottomText == %@", ID, topText!, bottomText!)
		
		var submission: XCreated!
		
		do {
			let fetchedArray = try context.fetch(fetchRequest)
			if (fetchedArray.count > 0) {
//			print("Submission \(ID) already present.")
				submission = fetchedArray.first as! XCreated
			}
			else {
//				print("Inserting submission \(ID).")
				submission = NSEntityDescription.insertNewObject(forEntityName: "XCreated", into: context) as! XCreated
				submission.memeID = ID
				submission.topText = topText
				submission.bottomText = bottomText
				submission.dateCreated = data.object(forKey: "dateCreated") as? String
				let dateFormatter = DateFormatter.init()
				dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
				submission.dateSubmission = dateFormatter.date(from: submission.dateCreated!)
				
			}
		}
		catch _ {
			
		}
		
		return submission
	}
	
	class func getAllSubmissionsFromArray(_ array: NSArray, context: NSManagedObjectContext) -> NSArray? {
		
		let submissionsArray = NSMutableArray()
		
		for dict in array {
			let subm = self.createOrUpdateSubmissionWithData(dict as! NSDictionary, context: context)
			submissionsArray.add(subm)
		}
		
		return submissionsArray
		
	}
	
	override var description: String {
		return "{\n\tmemeID = \(memeID),\n\tdateCreated = \(dateCreated!)\n}"
	}

}
