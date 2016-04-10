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

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, BWWalkthroughViewControllerDelegate {
	
	@IBOutlet weak var autoDismiss: UISwitch!
	@IBOutlet weak var resetSettings: UISwitch!
	@IBOutlet weak var contEditing: UISwitch!
	@IBOutlet weak var darkMode: UISwitch!
	@IBOutlet weak var uploadEnable: UISwitch!
	
	@IBOutlet weak var memesCountLabel: UILabel!
	
	@IBOutlet var tableViewCells: [UITableViewCell]!
	@IBOutlet var tableViewCellLabels: [UILabel]!
	
	var memes = NSMutableArray()
	var fetchedMemes = NSMutableArray()
	
	var context: NSManagedObjectContext? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "Settings"
		
		autoDismiss.on = SettingsManager.sharedManager().getBool(kSettingsAutoDismiss)
		resetSettings.on = SettingsManager.sharedManager().getBool(kSettingsResetSettingsOnLaunch)
		contEditing.on = SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)
		darkMode.on = SettingsManager.sharedManager().getBool(kSettingsDarkMode)
		uploadEnable.on = SettingsManager.sharedManager().getBool(kSettingsUploadMemes)
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		context = appDelegate.managedObjectContext

		updateCount()
		updateViews()
    }
	
	func updateViews() -> Void {
		self.tableView.backgroundColor = globalBackColor
		for cell in tableViewCells {
			cell.backgroundColor = globalBackColor
			cell.textLabel?.textColor = globalTintColor
			cell.textLabel?.font = UIFont(name: "EtelkaNarrowTextPro", size: 18)
		}
		for label in tableViewCellLabels {
			label.textColor = globalTintColor
			label.font = UIFont(name: "EtelkaNarrowTextPro", size: 18)
		}
	}
	
	// MARK: - Switches
	
	@IBAction func autoDismissSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsAutoDismiss)
	}
	
	@IBAction func resetSettingsOnLaunchSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsResetSettingsOnLaunch)
	}
	
	@IBAction func continuousEditingSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsContinuousEditing)
	}
	
	@IBAction func darkModeSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsDarkMode)
		updateGlobalTheme()
		let redrawHelperVC = UIViewController()
		redrawHelperVC.modalPresentationStyle = .FullScreen
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			self.splitViewController?.presentViewController(redrawHelperVC, animated: false, completion: nil)
		}
		else {
			self.navigationController?.presentViewController(redrawHelperVC, animated: false, completion: nil)
		}
		self.dismissViewControllerAnimated(false, completion: nil)
		if (UI_USER_INTERFACE_IDIOM() == .Pad) {
			if self.splitViewController?.viewControllers.count > 1 {
				let editorVC = self.splitViewController?.viewControllers[1] as? EditorViewController
				editorVC?.backgroundImageView.layoutSubviews()
			}
		}
		updateViews()
	}
	
	@IBAction func uploadEnableSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsUploadMemes)
	}
	

	// MARK: - Table view data source
	
	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		let noos = tableView.numberOfSections
		switch section {
			case 0:
				return "Turning this on will dismiss the editing options as you select any option."
			case 1:
				return "Enabling this function will reset the text editing settings on launch, i.e. no preservations in settings."
			case 2:
				return "Turning this off will prevent generation of text on image as you enter it, but may help in saving battery life."
			case 4:
				return "Check this if you want your \"creations\" to be uploaded to the server."
			case noos - 4:
				let formatter = NSDateFormatter()
				formatter.dateFormat = "MMM dd yyyy, hh:mm a"
				let date = SettingsManager.sharedManager().getLastUpdateDate()
				return "Last updated: \(formatter.stringFromDate(date))"
			case noos - 1:
				return "Swipe up to bring up editing options.\n\nSwipe left and right to switch between options.\n\nPinch on top or bottom of the image to set text size.\n\nTwo finger pan on top or bottom half to place top or bottom text, Shake or two finger double tap to reset position.\n\nSwipe right text field to add default text. Swipe left to clear text.\n\nDouble tap to change case.\n\n--------------------------\n\nMade by avikantz"
			default:
				return nil
		}
	}
	
    // MARK: - Table view delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		if (indexPath.section == tableView.numberOfSections - 4) {
			// Update...
			SVProgressHUD.showWithStatus("Fetching latest memes, Just for you!")
			self.fetchedMemes = NSMutableArray()
			self.fetchMemes(1)
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
				self.presentViewController(mailComposeViewController, animated: true, completion: nil)
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
		let page1 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage1")
		let page2 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage2")
		let page3 = storyboard.instantiateViewControllerWithIdentifier("WalkthroughPage3")
		walkthrough.delegate = self
		walkthrough.addViewController(page1)
		walkthrough.addViewController(page2)
		walkthrough.addViewController(page3)
		self.presentViewController(walkthrough, animated: true, completion: nil)
	}
	
	// MARK: - Walkthrough delegate
	
	func walkthroughCloseButtonPressed() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - Mail things
	
	func configuredMailComposeViewController() -> MFMailComposeViewController {
		let mailComposerVC = MFMailComposeViewController()
		mailComposerVC.mailComposeDelegate = self
		mailComposerVC.setToRecipients(["avikantsainidbz@gmail.com"])
		mailComposerVC.setMessageBody("\n\n\n-----------Device: \(UIDevice.currentDevice().modelName)\nSystem: \(UIDevice.currentDevice().systemName)|\(UIDevice.currentDevice().systemVersion)", isHTML: false)
		return mailComposerVC
	}
	
	func showSendMailErrorAlert() {
		let alertController = modalAlertControllerFor("What year is this!", message: "Your device cannot send e-mail.  Please check e-mail configuration and try again.")
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - Fetch Memes
	
	func updateCount() -> Void {
		let request = NSFetchRequest(entityName: "XMeme")
		do {
			let fetchedArray = try self.context?.executeFetchRequest(request)
			memes = NSMutableArray(array: fetchedArray!)
			self.memesCountLabel.text = "\(memes.count) Memes"
		}
		catch _ {
			print("Error in fetching.")
		}
	}
	
	func fetchMemes(paging: Int) -> Void {
		
		let request = NSMutableURLRequest(URL: apiMemesPaging(paging))
		request.HTTPMethod = "GET"
		
		NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
			
			if (error != nil) {
				print("Error: %@", error?.localizedDescription)
				return
			}
			
			if (data != nil) {
				
				do {
					let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
					let code = json.valueForKey("code") as! Int
					if (code == 200) {
						let jsonmemes = json.valueForKey("data") as! NSArray
						let memesArray = XMeme.getAllMemesFromArray(jsonmemes, context: self.context!)!
						self.fetchedMemes.addObjectsFromArray(memesArray as [AnyObject])
						dispatch_async(dispatch_get_main_queue(), {
							self.fetchMemes(paging + 1)
						})
					}
					else {
						self.memes = self.fetchedMemes
						dispatch_async(dispatch_get_main_queue(), {
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
					SVProgressHUD.showErrorWithStatus("Failed to fetch")
					return
				}
				
			}
			
			}.resume()
		
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
