//
//  SettingsManager.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import Foundation

func settingsSetNumberOfCollectionCells(rows: Int) -> Void {
	NSUserDefaults.standardUserDefaults().setInteger(rows, forKey: "settingsSetNumberOfCollectionCells")
}