//
//  SettingsTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import MessageUI
import BWWalkthrough
import ReachabilitySwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, BWWalkthroughViewControllerDelegate {
	
	@IBOutlet weak var autoDismiss: UISwitch!
	@IBOutlet weak var resetSettings: UISwitch!
	@IBOutlet weak var contEditing: UISwitch!
	@IBOutlet weak var darkMode: UISwitch!
	@IBOutlet weak var uploadEnable: UISwitch!
	
	@IBOutlet weak var memesCountLabel: UILabel!
	
	@IBOutlet weak var memesPerRowLabel: UILabel!
	
	@IBOutlet var tableViewCells: [UITableViewCell]!
	@IBOutlet var tableViewCellLabels: [UILabel]!
	
	var memes = NSMutableArray()
	var fetchedMemes = NSMutableArray()
	
	var quotes = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "Settings"
		
		autoDismiss.isOn = SettingsManager.sharedManager().getBool(kSettingsAutoDismiss)
		resetSettings.isOn = SettingsManager.sharedManager().getBool(kSettingsResetSettingsOnLaunch)
		contEditing.isOn = SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)
		darkMode.isOn = SettingsManager.sharedManager().getBool(kSettingsDarkMode)
//		uploadEnable.on = SettingsManager.sharedManager().getBool(kSettingsUploadMemes)
		
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		context = appDelegate.managedObjectContext

		if let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "quotes", ofType: "json")!)) {
			do {
				let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSArray
				quotes = NSMutableArray(array: jsonData)
			}
			catch _ {}
		}
		
		updateCount()
		updateViews()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		self.memesPerRowLabel.text = "\(SettingsManager.sharedManager().getInteger(kSettingsNumberOfElementsInGrid))"
	}
	
	func updateViews() -> Void {
		self.tableView.backgroundColor = globalBackColor
		if isDarkMode() {
			self.tableView.separatorColor = UIColor.darkGray
		}
		else {
			self.tableView.separatorColor = UIColor.lightGray
		}
		for cell in tableViewCells {
			cell.backgroundColor = globalBackColor
			cell.textLabel?.textColor = globalTintColor
			cell.textLabel?.font = UIFont(name: "EtelkaNarrowTextPro", size: 18)
			cell.detailTextLabel?.font = UIFont(name: "EtelkaNarrowTextPro", size: 18)
		}
		for label in tableViewCellLabels {
			label.textColor = globalTintColor
			label.font = UIFont(name: "EtelkaNarrowTextPro", size: 18)
		}
	}
	
	// MARK: - Switches
	
	@IBAction func autoDismissSwitchAction(_ sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.isOn, key: kSettingsAutoDismiss)
	}
	
	@IBAction func resetSettingsOnLaunchSwitchAction(_ sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.isOn, key: kSettingsResetSettingsOnLaunch)
	}
	
	@IBAction func continuousEditingSwitchAction(_ sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.isOn, key: kSettingsContinuousEditing)
	}
	
	@IBAction func darkModeSwitchAction(_ sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.isOn, key: kSettingsDarkMode)
		updateGlobalTheme()
		let redrawHelperVC = UIViewController()
		redrawHelperVC.modalPresentationStyle = .fullScreen
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			self.splitViewController?.present(redrawHelperVC, animated: false, completion: nil)
		}
		else {
			self.tabBarController?.present(redrawHelperVC, animated: false, completion: nil)
		}
		self.dismiss(animated: false, completion: nil)
		if (UI_USER_INTERFACE_IDIOM() == .pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				let editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
				editorVC?.backgroundImageView.layoutSubviews()
			}
		}
		updateViews()
	}
	
	@IBAction func uploadEnableSwitchAction(_ sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.isOn, key: kSettingsUploadMemes)
	}
	

	// MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if (section == 0) {
			return quotes.object(at: arc4random() % quotes.count) as? String
		}
		return ""
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		let noos = tableView.numberOfSections
		switch section {
			case 0:
				return "Turning this on will dismiss the editing options as you select any option."
			case 1:
				return "Enabling this function will reset the text editing settings on launch, i.e. no preservations in settings."
			case 2:
				return "Turning this off will prevent generation of text on image as you enter it, but may help in saving battery life. If enabled, you need to press return to generate text after editing."
//			case 4:
//				return "Check this if you want your \"creations\" to be uploaded to the server."
			case noos - 4:
				let formatter = DateFormatter()
				formatter.dateFormat = "MMM dd yyyy, hh:mm a"
				let date = SettingsManager.sharedManager().getLastUpdateDate()
				return "Last updated: \(formatter.string(from: date))"
			case noos - 1:
				return "Swipe up to bring up editing options.\n\nSwipe left and right to switch between options.\n\nPinch on top or bottom of the image to set text size.\n\nTwo finger pan on top or bottom half to place top or bottom text, Shake or two finger double tap to reset position.\n\nSwipe right text field to add default text. Swipe left to clear text.\n\nDouble tap to change case.\n\n--------------------------\n\n"
			default:
				return nil
		}
	}
	
    // MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		if (indexPath.section == tableView.numberOfSections - 4) {
			// Update...
			SVProgressHUD.show(withStatus: "Fetching latest memes, Just for you!")
			do {
				let _ = try Reachability.reachabilityForInternetConnection()
				self.fetchedMemes = NSMutableArray()
				self.fetchMemes(1)
			}
			catch _ {
				SVProgressHUD.showError(withStatus: "No connection!")
			}
		}
		
		if (indexPath.section == tableView.numberOfSections - 3) {
			let mailComposeViewController = configuredMailComposeViewController()
			if (indexPath.row == 0) {
				mailComposeViewController.setSubject("Meme Maker Bug Report")
			}
			else {
				mailComposeViewController.setSubject("Meme Maker Feedback")
			}
			if MFMailComposeViewController.canSendMail() {
				self.present(mailComposeViewController, animated: true, completion: nil)
			}
			else {
				self.showSendMailErrorAlert()
			}
		}
		
		if (indexPath.section == tableView.numberOfSections - 2) {
			// Tutorial!
			showTutorial()
		}
		
	}
	
	func showTutorial() -> Void {
		let storyboard = UIStoryboard(name: "Walkthrough", bundle: nil)
		let walkthrough = storyboard.instantiateViewControllerWithIdentifier("WalkthroughBase") as! BWWalkthroughViewController
		let page1 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage1")
		let page2 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage2")
		let page3 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage3")
		let page4 = storyboard.instantiateViewController(withIdentifier: "WalkthroughPage4")
		walkthrough.delegate = self
		walkthrough.addViewController(page1)
		walkthrough.addViewController(page2)
		walkthrough.addViewController(page3)
		walkthrough.addViewController(page4)
		self.presentViewController(walkthrough, animated: true, completion: nil)
	}
	
	// MARK: - Walkthrough delegate
	
	func walkthroughCloseButtonPressed() {
		self.dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Mail things
	
	func configuredMailComposeViewController() -> MFMailComposeViewController {
		let mailComposerVC = MFMailComposeViewController()
		mailComposerVC.mailComposeDelegate = self
		mailComposerVC.setToRecipients(["avikantsainidbz@gmail.com"])
		mailComposerVC.setMessageBody("\n\n\n-----------Device: \(UIDevice.current.modelName)\nSystem: \(UIDevice.current.systemName)|\(UIDevice.current.systemVersion)", isHTML: false)
		return mailComposerVC
	}
	
	func showSendMailErrorAlert() {
		let alertController = modalAlertControllerFor("What year is this!", message: "Your device cannot send e-mail.  Please check e-mail configuration and try again.")
		self.present(alertController, animated: true, completion: nil)
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Fetch Memes
	
	func updateCount() -> Void {
		let request = NSFetchRequest(entityName: "XMeme")
		do {
			let fetchedArray = try self.context?.fetch(request)
			memes = NSMutableArray(array: fetchedArray!)
			self.memesCountLabel.text = "\(memes.count) Memes"
		}
		catch _ {
			print("Error in fetching.")
		}
	}
	
	func fetchMemes(_ paging: Int) -> Void {
		
		let request = NSMutableURLRequest(url: apiMemesPaging(paging))
		request.httpMethod = "GET"
		
		URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
			
			if (error != nil) {
				print("Error: %@", error?.localizedDescription)
				DispatchQueue.main.async(execute: {
					SVProgressHUD.showError(withStatus: "No connection!")
				})
				return
			}
			
			if (data != nil) {
				
				do {
					
					let persistentStoreCoordinator = self.context?.persistentStoreCoordinator
					let asyncContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
					asyncContext.persistentStoreCoordinator = persistentStoreCoordinator
					
					let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
					let code = json.value(forKey: "code") as! Int
					if (code == 200) {
						let jsonmemes = json.value(forKey: "data") as! NSArray
						let memesArray = XMeme.getAllMemesFromArray(jsonmemes, context: asyncContext)!
						for meme in memesArray {
							self.fetchedMemes.add(meme)
						}
						try asyncContext.save()
						DispatchQueue.main.async(execute: {
							self.fetchMemes(paging + 1)
						})
					}
					else {
						self.memes = self.fetchedMemes
						DispatchQueue.main.async(execute: {
							SettingsManager.sharedManager().saveLastUpdateDate()
							self.tableView.reloadData()
							self.updateCount()
							SVProgressHUD.dismiss()
						})
						return
					}
				}
				catch _ {
					print("Unable to parse")
					SVProgressHUD.showError(withStatus: "Failed to fetch")
					return
				}
				
			}
			
			}) .resume()
		
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
