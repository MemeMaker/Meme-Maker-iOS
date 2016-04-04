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
	
	func createOrUpdateSubmissionWithData(data: NSDictionary, context: NSManagedObjectContext) -> NSManagedObject {
		
		let submission: XCreated = NSEntityDescription.insertNewObjectForEntityForName("XCreated", inManagedObjectContext: context) as! XCreated
		
		submission.memeID = (data.objectForKey("ID")?.intValue)!
		submission.topText = data.objectForKey("topText")?.stringValue
		submission.bottomText = data.objectForKey("bottomText")?.stringValue
		submission.dateCreated = data.objectForKey("dateCreated")?.stringValue
		let dateFormatter = NSDateFormatter.init()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		submission.dateSubmission = dateFormatter.dateFromString(submission.dateCreated!)
		
		return submission
	}

}
