//
//  GlobalSingleton.swift
//  CustomCameraController
//
//  Created by Forrest Collins on 2/8/16.
//  Copyright © 2016 helloTouch. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class GlobalSingleton {
    
    // make a shared instance to use global variables in other VC's
    static let sharedInstance = GlobalSingleton()

    // device
    var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    // image taken
    var globalImg: UIImageView = UIImageView()
 
    var isFrontFacePhotoTaken: Bool = false
    
}