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
	func textFieldDidSwipeRight(textField: SwipableTextField) -> Void
}

public class SwipableTextField: KaedeTextField {
	
	var swipeDelegate: SwipableTextFieldDelegate?
	
	private var swipeLeft: UISwipeGestureRecognizer?
	private var swipeRight: UISwipeGestureRecognizer?
	
	override public func willMoveToSuperview(newSuperview: UIView!) {
		super.willMoveToSuperview(newSuperview)
		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .Left
		self.addGestureRecognizer(swipeLeft!)
		swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeRightAction))
		swipeRight?.direction = .Right
		self.addGestureRecognizer(swipeRight!)
	}
	
	func swipeLeftAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeLeft(self)
	}
	
	func swipeRightAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeRight(self)
	}

}
