//
//  SettingsManager.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/5/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import SVProgressHUD
import IQKeyboardManagerSwift

let kSettingsTimesLaunched			= "kTimesLaunched"
let kSettingsContinuousEditing		= "kContinuousEditing"
let kSettingsAutoDismiss			= "kAutoDismiss"
let kSettingsUploadMemes			= "kEnableMemeUpload"
let kSettingsResetSettingsOnLaunch	= "kResetSettingsOnLaunch"
let kSettingsDarkMode				= "kDarkMode"
let kSettingsViewModeIsList			= "kMemeListViewModeIsList"
let kSettingsLastSortKey			= "kLastSortOrderKey"
let kSettingsNumberOfElementsInGrid	= "kNumberOfElementsInGrid"

var globalBackColor: UIColor = UIColor(hexString: "EFF0EF")
var globalTintColor: UIColor = UIColor(hexString: "326400")

extension UIColor {
	convenience init(hexString: String) {
		let scanner = Scanner(string: hexString)
		scanner.scanLocation = 0
		
		var rgbValue: UInt64 = 0
		
		scanner.scanHexInt64(&rgbValue)
		
		let r = (rgbValue & 0xff0000) >> 16
		let g = (rgbValue & 0xff00) >> 8
		let b = rgbValue & 0xff
		
		self.init(
			red: CGFloat(r) / 0xff,
			green: CGFloat(g) / 0xff,
			blue: CGFloat(b) / 0xff, alpha: 1
		)
	}
}

func updateGlobalTheme () -> Void {
	if isDarkMode() {
		globalBackColor = UIColor(white: 0.12, alpha: 1)
		globalTintColor = UIColor(hexString: "AAFA78")
		UIApplication.shared.statusBarStyle = .lightContent
		IQKeyboardManager.sharedManager().keyboardAppearance = .dark
	}
	else {
		globalBackColor = UIColor(hexString: "EFF0EF")
		globalTintColor = UIColor(hexString: "326400")
		UIApplication.shared.statusBarStyle = .default
		IQKeyboardManager.sharedManager().keyboardAppearance = .light
	}
	
	UINavigationBar.appearance().backgroundColor = globalBackColor
	UINavigationBar.appearance().tintColor = globalTintColor
	UINavigationBar.appearance().barTintColor = globalBackColor
	
	UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 18)!, NSForegroundColorAttributeName: globalTintColor]
	
	UITabBar.appearance().backgroundColor = globalBackColor
	UITabBar.appearance().tintColor = globalTintColor
	UITabBar.appearance().barTintColor = globalBackColor
	
	UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 13)!, NSForegroundColorAttributeName: globalTintColor], for: .selected)
	UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 13)!, NSForegroundColorAttributeName: UIColor.lightGray], for: UIControlState())
	
	UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 16)!, NSForegroundColorAttributeName: globalTintColor], for: UIControlState())
	
	UITableView.appearance().backgroundColor = globalBackColor
	UITableView.appearance().tintColor = globalTintColor
	
	UICollectionView.appearance().backgroundColor = globalBackColor
	UICollectionView.appearance().tintColor = globalTintColor
	
	UIButton.appearance().tintColor = globalTintColor
	
	UISwitch.appearance().tintColor = globalTintColor
	UISwitch.appearance().onTintColor = globalTintColor
	
	UISearchBar.appearance().backgroundColor = globalBackColor
	UISearchBar.appearance().tintColor = globalTintColor
	UISearchBar.appearance().barTintColor = globalBackColor
	
	UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 14)!, NSForegroundColorAttributeName: globalTintColor]
	UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSFontAttributeName: UIFont(name: "EtelkaNarrowTextPro", size: 14)!, NSForegroundColorAttributeName: globalTintColor.withAlphaComponent(0.8)]
	
	SVProgressHUD.setFont(UIFont(name: "EtelkaNarrowTextPro", size: 16))
	SVProgressHUD.setBackgroundColor(globalBackColor)
	SVProgressHUD.setForegroundColor(globalTintColor)
}

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
	
	func setObject(_ object: Any?, key: String) {
		defaults.set(object, forKey: key)
	}
	
	func getObject(_ key: String) -> Any? {
		return defaults.object(forKey: key)
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
	
	func saveLastUpdateDate() -> Void {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		let date = formatter.string(from: Date())
		defaults.set(date, forKey: "lastUpdateDate")
	}
	
	func getLastUpdateDate() -> Date {
		if (defaults.object(forKey: "lastUpdateDate") != nil) {
			let dateString = "\(defaults.object(forKey: "lastUpdateDate") as! String)"
			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			let date = formatter.date(from: dateString)
			return date!
		}
		return Date(timeIntervalSinceNow: (-10 * 86400))
	}
	
}
