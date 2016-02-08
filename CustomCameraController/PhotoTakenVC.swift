/*
The MIT License (MIT)

Copyright (c) 2016 Forrest Collins

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//-------------------------------------------------------------------------------------
// PURPOSE: After you take a photo, photoTakenVC is shown. Here you can "Use Photo" 
//          for any purpose you want, save the photo you just took to your camera roll, 
//          or eixt back to take another photo.
//-------------------------------------------------------------------------------------


import UIKit
import Foundation
import AVFoundation

class photoTakenVC: UIViewController {
    
    // the imageview of the photo that was taken
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var usePhotoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    //----------------------
    // MARK: - View Did Load
    //----------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update UI and captured Image on main thread
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            
            // Set the imageview to the photo you took from "currentlyTakingPhotoVC"
            // I used a global variable to be able to use the photo in this VC.
            self.capturedImage.image = GlobalSingleton.sharedInstance.globalImg.image
        }
    }
    
    //------------------------
    // MARK: - Hide Status Bar
    //------------------------
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //-------------------------------------------------------------------------
    // MARK: - Expand & Compress Brightness, Camera, & Options Buttons Function
    //-------------------------------------------------------------------------
    func expandAndCompressButton(button: UIButton, duration: NSTimeInterval, edgeInsetExpandValue: CGFloat, edgeInsetShrinkValue: CGFloat){
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseOut, animations: {
            
            button.bounds.size.width += 5.0
            button.bounds.size.height += 5.0
            button.contentEdgeInsets = UIEdgeInsetsMake(edgeInsetExpandValue, edgeInsetExpandValue, edgeInsetExpandValue, edgeInsetExpandValue)
            //button.layer.masksToBounds = true
            button.layoutIfNeeded()
            
            }, completion: { finished in
                UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseIn, animations: {
                    
                    button.bounds.size.width -= 5.0
                    button.bounds.size.height -= 5.0
                    button.contentEdgeInsets = UIEdgeInsetsMake(edgeInsetShrinkValue, edgeInsetShrinkValue, edgeInsetShrinkValue, edgeInsetShrinkValue)
                    //button.layer.masksToBounds = true
                    button.layoutIfNeeded()
                    
                }, completion: nil)
        })
    }

    //--------------------------------------------------------------
    // MARK: - Save Button Tapped (Save photo taken to camera roll)
    //--------------------------------------------------------------
    @IBAction func saveImageButtonTapped(sender: AnyObject) {
        
        print("saveImageButtonTapped")
        // Animation when you tap the save photo button
        expandAndCompressButton(saveButton, duration: 0.2, edgeInsetExpandValue: 44, edgeInsetShrinkValue: 39)
        saveButton.layoutIfNeeded()
        
        if GlobalSingleton.sharedInstance.isFrontFacePhotoTaken == true {
            
            // Flip image when saved to camera roll if it was taken with front face camera
            let modImage = UIImage(CGImage: capturedImage.image!.CGImage!, scale: capturedImage.image!.scale, orientation: UIImageOrientation.RightMirrored)
            
            UIImageWriteToSavedPhotosAlbum(modImage, nil, nil, nil)
            
        } else {
            
            UIImageWriteToSavedPhotosAlbum(capturedImage.image!, nil, nil, nil)
        }
    }
    
    //--------------------------------
    // MARK: - Use Photo Button Tapped
    //--------------------------------
    @IBAction func usePhotoButtonTapped(sender: AnyObject) {
        print("usePhotoButtonTapped")
        
    }
    
    //-----------------------------
    // MARK: - Cancel Button Tapped
    //-----------------------------
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        print("cancelButtonTapped")
    }
}

