//
//  XUserCreation+CoreDataProperties.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/8/16.
//  Copyright © 2016 avikantz. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension XUserCreation {

    @NSManaged var memeID: Int32
    @NSManaged var topText: String?
    @NSManaged var bottomText: String?
	@NSManaged var createdOn: String?
    @NSManaged var isMeme: Bool
    @NSManaged var imagePath: String?

}
