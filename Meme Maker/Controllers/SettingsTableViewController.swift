//
//  SettingsTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/4/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
	
	@IBOutlet weak var autoDismiss: UISwitch!
	@IBOutlet weak var resetSettings: UISwitch!
	@IBOutlet weak var contEditing: UISwitch!
	@IBOutlet weak var darkMode: UISwitch!
	@IBOutlet weak var uploadEnable: UISwitch!
	
	@IBOutlet weak var memesCountLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "Settings"
		
		autoDismiss.on = SettingsManager.sharedManager().getBool(kSettingsAutoDismiss)
		resetSettings.on = SettingsManager.sharedManager().getBool(kSettingsResetSettingsOnLaunch)
		contEditing.on = SettingsManager.sharedManager().getBool(kSettingsContinuousEditing)
		darkMode.on = SettingsManager.sharedManager().getBool(kSettingsDarkMode)
		uploadEnable.on = SettingsManager.sharedManager().getBool(kSettingsUploadMemes)

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
	}
	
	@IBAction func uploadEnableSwitchAction(sender: AnyObject) {
		let swtch = sender as! UISwitch
		SettingsManager.sharedManager().setBool(swtch.on, key: kSettingsUploadMemes)
	}
	

	// MARK: - Table view data source
	
	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if (section == tableView.numberOfSections - 3) {
			return "Last updated: \(SettingsManager.sharedManager().getLastUpdateDate())"
		}
		return nil
	}
	
    // MARK: - Table view delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		if (indexPath.section == tableView.numberOfSections - 3) {
			// Update...
			
		}
		
		if (indexPath.section == tableView.numberOfSections - 2) {
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
		let sendMailErrorAlert = UIAlertView(title: "What year is this!", message: "Your device cannot send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "Dismiss")
		sendMailErrorAlert.show()
	}
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		controller.dismissViewControllerAnimated(true, completion: nil)
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
