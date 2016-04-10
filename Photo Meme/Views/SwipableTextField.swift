//
//  SwipableTextField.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit
import TextFieldEffects

protocol SwipableTextFieldDelegate {
	func textFieldDidSwipeLeft(textField: SwipableTextField) -> Void
}

public class SwipableTextField: KaedeTextField {
	
	var swipeDelegate: SwipableTextFieldDelegate?
	
	private var swipeLeft: UISwipeGestureRecognizer?
	
	override public func willMoveToSuperview(newSuperview: UIView!) {
		self.layer.cornerRadius = 4.0
		super.willMoveToSuperview(newSuperview)
		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .Left
		self.addGestureRecognizer(swipeLeft!)
	}
	
	func swipeLeftAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeLeft(self)
	}

}
