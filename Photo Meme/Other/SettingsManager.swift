//
//  SettingsManager.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/5/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

let kSettingsTimesLaunched			= "TimesLaunched"
let kSettingsContinuousEditing		= "ContinuousEditing"
let kSettingsAutoDismiss			= "AutoDismiss"
let kSettingsUploadMemes			= "EnableMemeUpload"
let kSettingsResetSettingsOnLaunch	= "ResetSettingsOnLaunch"
let kSettingsDarkMode				= "DarkMode"
let kSettingsViewModeIsList			= "MemeListViewModeIsList"

var globalBackColor: UIColor = UIColor(red: 239, green: 240, blue: 239, alpha: 1)
var globalTintColor: UIColor = UIColor(red: 50, green: 100, blue: 10, alpha: 1)

func isDarkMode() -> Bool {
	return SettingsManager.sharedManager().getBool(kSettingsDarkMode)
}

class SettingsManager: NSObject {

	// MARK:- Shared Instance
	
	fileprivate static let sharedInstance = SettingsManager()
	
	fileprivate let defaults = UserDefaults.standard
	
	class func sharedManager () -> SettingsManager {
		return sharedInstance
	}
	
	// MARK:- Save and fetch stuff
	
	func setObject(_ object: AnyObject, key: String) {
		defaults.set(object, forKey: key)
	}
	
	func getObject(_ key: String) -> AnyObject? {
		return defaults.object(forKey: key) as AnyObject
	}
	
	func setBool(_ bool: Bool, key: String) {
		defaults.set(bool, forKey: key)
	}
	
	func getBool(_ key: String) -> Bool {
		return defaults.bool(forKey: key)
	}
	
	func setInteger(_ value: Int, key: String) {
		defaults.set(value, forKey: key)
	}
	
	func getInteger(_ key: String) -> Int {
		return defaults.integer(forKey: key)
	}
	
	func setFloat(_ value: Float, key: String) {
		defaults.set(value, forKey: key)
	}
	
	func getFloat(_ key: String) -> Float {
		return defaults.float(forKey: key)
	}
	
	func deleteObject(_ key: String) {
		defaults.removeObject(forKey: key)
	}

}
