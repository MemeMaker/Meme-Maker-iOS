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
	func textFieldDidSwipeLeft(_ textField: SwipableTextField) -> Void
	func textFieldDidSwipeRight(_ textField: SwipableTextField) -> Void
}

open class SwipableTextField: KaedeTextField {
	
	var swipeDelegate: SwipableTextFieldDelegate?
	
	fileprivate var swipeLeft: UISwipeGestureRecognizer?
	fileprivate var swipeRight: UISwipeGestureRecognizer?
	
	override open func willMove(toSuperview newSuperview: UIView!) {
		self.layer.cornerRadius = 4.0
		super.willMove(toSuperview: newSuperview)
		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .left
		self.addGestureRecognizer(swipeLeft!)
		swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeRightAction))
		swipeRight?.direction = .right
		self.addGestureRecognizer(swipeRight!)
	}
	
	func swipeLeftAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeLeft(self)
	}
	
	func swipeRightAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeRight(self)
	}

}
