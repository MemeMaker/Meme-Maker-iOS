//
//  BlurredImageView.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/7/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import UIKit

class BlurredImageView: UIImageView {
	
	var blurView: UIVisualEffectView?
	
	override func layoutSubviews() {
		
		blurView?.removeFromSuperview()
		
		if isDarkMode() {
			let blurEffect = UIBlurEffect(style: .Dark)
			blurView = UIVisualEffectView(effect: blurEffect)
		}
		else {
			let blurEffect = UIBlurEffect(style: .Light)
			blurView = UIVisualEffectView(effect: blurEffect)
		}
		
		blurView?.frame = self.bounds
		
		self.addSubview(blurView!)

	}

}
