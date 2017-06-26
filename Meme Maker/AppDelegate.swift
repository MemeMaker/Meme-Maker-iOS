//
//  AppDelegate.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import IQKeyboardManagerSwift
import SSZipArchive

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
			let splitVC: UISplitViewController = UISplitViewController.init()
			let tabBarVC = self.window?.rootViewController as! UITabBarController
			let memesVCNav = tabBarVC.viewControllers?.first as! UINavigationController
			let memesVC = memesVCNav.viewControllers.first as! MemesViewController
			let editorVC = storyboard.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
			memesVC.memeSelectionDelegate = editorVC
			memesVC.editorVC = editorVC
			splitVC.viewControllers = [tabBarVC, editorVC]
			self.window?.rootViewController = splitVC
		}
		
		let manager = SettingsManager.sharedManager()
		let timesLaunched = manager.getInteger(kSettingsTimesLaunched)
		if (timesLaunched == 0) {
			manager.setBool(false, key: kSettingsAutoDismiss)
			manager.setBool(false, key: kSettingsResetSettingsOnLaunch)
			manager.setBool(true, key: kSettingsContinuousEditing)
			manager.setBool(true, key: kSettingsDarkMode)
			manager.setBool(false, key: kSettingsUploadMemes)
			manager.setInteger(3, key: kSettingsNumberOfElementsInGrid)
			manager.setObject("rank" as AnyObject, key: kSettingsLastSortKey)
			print("Unarchiving to \(getImagesFolder())")
			SSZipArchive.unzipFile(atPath: Bundle.main.path(forResource: "defaultMemes", ofType: "zip")!, toDestination: getImagesFolder())
			saveDefaultMemes()
		}
		manager.setInteger(timesLaunched + 1, key: kSettingsTimesLaunched)
		if manager.getBool(kSettingsResetSettingsOnLaunch) {
			let topAttr = XTextAttributes(savename: "topAttr")
			topAttr.saveAttributes("topAttr")
			topAttr.setDefault()
			let bottomAttr = XTextAttributes(savename: "bottomAttr")
			bottomAttr.setDefault()
			bottomAttr.saveAttributes("bottomAttr")
		}
		if (SettingsManager.sharedManager().getInteger(kSettingsNumberOfElementsInGrid) < 3 || SettingsManager.sharedManager().getInteger(kSettingsNumberOfElementsInGrid) > 7) {
			SettingsManager.sharedManager().setInteger(3, key: kSettingsNumberOfElementsInGrid)
		}
		if ("rank memeID name".contains(SettingsManager.sharedManager().getObject(kSettingsLastSortKey) as! String)) {
			SettingsManager.sharedManager().setObject("rank" as AnyObject, key: kSettingsLastSortKey)
		}
		
		SVProgressHUD.setDefaultMaskType(.gradient)
		SVProgressHUD.setDefaultStyle(.custom)
		
		IQKeyboardManager.sharedManager().enable = true
		IQKeyboardManager.sharedManager().overrideKeyboardAppearance = true
		IQKeyboardManager.sharedManager().preventShowingBottomBlankSpace = true
		
		updateGlobalTheme()
		
		AppDelegate.updateActivityIcons("")
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		self.saveContext()
	}
	
	// MARK: - Handle URL Opens
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
		if (url.absoluteString.contains(".jpg")) {
			let data = try? Data(contentsOf: url)
			try? data?.write(to: URL(fileURLWithPath: imagesPathForFileName("lastImage")), options: [.atomic])
//			let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
			var editorVC: EditorViewController?
			if (UI_USER_INTERFACE_IDIOM() == .pad) {
				let svc = self.window?.rootViewController as! UISplitViewController
				if (svc.viewControllers.count > 1) {
					editorVC = svc.viewControllers[1] as? EditorViewController
					editorVC?.editorMode = EditorMode.viewer
				}
			}
			else {
				let tabBarVC = self.window?.rootViewController as! UITabBarController
				let navC = tabBarVC.viewControllers?.first as! UINavigationController
				let memesVC = navC.viewControllers.first as! MemesViewController
				memesVC.performSegue(withIdentifier: "LastEditSegue", sender: memesVC)
			}
			return true
		}
		return false
	}
	
	// MARK: - Utility
	
	func saveDefaultMemes() -> Void {
		let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "defaultMemes", ofType: "dat")!))
		if (data != nil) {
			do {
				let jsonmemes = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
				let _ = XMeme.getAllMemesFromArray(jsonmemes as! NSArray, context: managedObjectContext)!
				try managedObjectContext.save()
			}
			catch _ {
				print("Unable to parse")
				return
			}
		}
	}
	
	class func updateActivityIcons(_ leSubtitle: String) -> Void {
		if (UI_USER_INTERFACE_IDIOM() == .phone) {
			var shortcutItems : [UIApplicationShortcutItem] = []
			let shortcut1 = UIMutableApplicationShortcutItem(type: "com.avikantz.meme-maker.create", localizedTitle: "Create", localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "new"), userInfo: nil)
			shortcutItems.append(shortcut1)
			if let _ = UIImage(contentsOfFile: imagesPathForFileName("lastImage")) {
				let shortcut2 = UIMutableApplicationShortcutItem(type: "com.avikantz.meme-maker.lastedit", localizedTitle: "Last Edit", localizedSubtitle: leSubtitle, icon: UIApplicationShortcutIcon.init(templateImageName: "Undo"), userInfo: nil)
				shortcutItems.append(shortcut2)
			}
			let shortcut3 = UIMutableApplicationShortcutItem(type: "com.avikantz.meme-maker.mymemes", localizedTitle: "My Memes", localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "PhotoGallery"), userInfo: nil)
			shortcutItems.append(shortcut3)
			let application = UIApplication.shared
			application.shortcutItems = shortcutItems
		}
	}
	
	// MARK: - Shortcut icons
	
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		if (shortcutItem.type.contains("lastedit")) {
			let tabBarVC = self.window?.rootViewController as! UITabBarController
			let navC = tabBarVC.viewControllers?.first as! UINavigationController
			let memesVC = navC.viewControllers.first as! MemesViewController
			memesVC.performSegue(withIdentifier: "LastEditSegue", sender: memesVC)
		}
		if (shortcutItem.type.contains("mymemes")) {
			let tabBarVC = self.window?.rootViewController as! UITabBarController
			tabBarVC.selectedIndex = 2
		}
	}

	// MARK: - Core Data stack

	lazy var applicationDocumentsDirectory: URL = {
	    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.avikantz.Meme_Maker" in the application's documents Application Support directory.
	    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	    return urls[urls.count-1]
	}()

	lazy var managedObjectModel: NSManagedObjectModel = {
	    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
	    let modelURL = Bundle.main.url(forResource: "Meme_Maker", withExtension: "momd")!
	    return NSManagedObjectModel(contentsOf: modelURL)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
	    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
	    // Create the coordinator and store
	    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	    let url = self.applicationDocumentsDirectory.appendingPathComponent("MemeMaker.sqlite")
	    var failureReason = "There was an error creating or loading the application's saved data."
	    do {
	        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
	    } catch {
	        // Report any error we got.
	        var dict = [String: AnyObject]()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
	        dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject

	        dict[NSUnderlyingErrorKey] = error as NSError
	        let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
	        // Replace this with code to handle the error appropriately.
	        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	        NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
//	        abort()
	    }
	    
	    return coordinator
	}()

	lazy var managedObjectContext: NSManagedObjectContext = {
	    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
	    let coordinator = self.persistentStoreCoordinator
	    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
	    managedObjectContext.persistentStoreCoordinator = coordinator
	    return managedObjectContext
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    if managedObjectContext.hasChanges {
	        do {
	            try managedObjectContext.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
	            abort()
	        }
	    }
	}

}

