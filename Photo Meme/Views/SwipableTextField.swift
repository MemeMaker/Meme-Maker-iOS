//
//  SwipableTextField.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

protocol SwipableTextFieldDelegate {
	func textFieldDidSwipeLeft(_ textField: SwipableTextField) -> Void
}

open class SwipableTextField: KaedeTextField {
	
	var swipeDelegate: SwipableTextFieldDelegate?
	
	fileprivate var swipeLeft: UISwipeGestureRecognizer?
	
	override open func willMove(toSuperview newSuperview: UIView!) {
		self.layer.cornerRadius = 4.0
		super.willMove(toSuperview: newSuperview)
		swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeLeftAction))
		swipeLeft?.direction = .left
		self.addGestureRecognizer(swipeLeft!)
	}
	
	func swipeLeftAction() -> Void {
		self.swipeDelegate?.textFieldDidSwipeLeft(self)
	}

}
