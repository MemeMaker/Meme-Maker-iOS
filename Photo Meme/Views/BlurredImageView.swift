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
		
		let blurEffect = UIBlurEffect(style: .dark)
		blurView = UIVisualEffectView(effect: blurEffect)
		
		blurView?.frame = self.bounds
		
		self.addSubview(blurView!)

	}

}
