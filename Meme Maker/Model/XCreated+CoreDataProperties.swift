//
//  XCreated+CoreDataProperties.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension XCreated {

    @NSManaged var bottomText: String?
    @NSManaged var dateCreated: String?
    @NSManaged var memeID: Int32
    @NSManaged var topText: String?
    @NSManaged var meme: NSManagedObject?

}
