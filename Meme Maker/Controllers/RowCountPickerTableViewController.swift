//
//  RowCountPickerTableViewController.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/13/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class RowCountPickerTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.backgroundColor = globalBackColor
		self.tableView.backgroundColor = globalBackColor
		self.tableView.tintColor = globalTintColor
		self.title = "Number of memes per row"
		
    }
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)

		let index = indexPath.row + 3
		
        cell.backgroundColor = globalBackColor
		cell.textLabel?.text = "\(index)"
		cell.textLabel?.textColor = globalTintColor
		
		if (SettingsManager.sharedManager().getInteger(kSettingsNumberOfElementsInGrid) == index) {
			cell.accessoryType = .checkmark
		}
		else {
			cell.accessoryType = .none
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return "The larger the value, the more memes you can see at once, but they become hard to click as well. Recommended value is 3 or 4."
	}

	// MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let index = indexPath.row + 3
		SettingsManager.sharedManager().setInteger(index, key: kSettingsNumberOfElementsInGrid)
		tableView.reloadData()
	}
	
}
