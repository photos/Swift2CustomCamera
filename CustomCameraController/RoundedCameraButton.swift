//
//  RoundedCameraButton.swift
//  CustomCameraController
//
//  Created by Forrest Collins on 2/8/16.
//  Copyright © 2016 helloTouch. All rights reserved.
//

import UIKit

class RoundedCameraButton: UIButton {

    override func drawRect(rect: CGRect) {
        // make take photo button a circle programatically b/c it's originally a square
        layer.cornerRadius = bounds.size.width / 2
        layer.borderWidth = 3
        layer.borderColor = UIColor.whiteColor().CGColor
        backgroundColor = UIColor(netHex: 0xFFFFFF)
        alpha = 0.7
        layer.masksToBounds = true
    }
}
