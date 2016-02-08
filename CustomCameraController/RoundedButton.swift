//
//  RoundedButton.swift
//  CustomCameraController
//
//  Created by Forrest Collins on 2/8/16.
//  Copyright © 2016 helloTouch. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    // called when UI is loaded from storyboard
    override func awakeFromNib() {
        layer.cornerRadius = 8.0
    }

}
