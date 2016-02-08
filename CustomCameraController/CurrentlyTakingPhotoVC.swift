/*
The MIT License (MIT)

Copyright (c) 2016 Forrest Collins

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//-----------------------------------------------------------------------------------------
// PURPOSE: This class is for the photo capturing view you will see when taking a photo.
//          Here you can access your camera roll, turn the flash on and off, and flip the
//          camera to front face. The front face camera strategy I used is similar to
//          Snapchat's stye, where your front face photo will not be flipped after capture.
//-----------------------------------------------------------------------------------------


import UIKit
import AVFoundation
import Photos
import AudioToolbox

class currentlyTakingPhotoVC: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var frameForCapture: UIView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var camButton: UIButton!
    @IBOutlet weak var takePhotoButton: RoundedCameraButton!
    @IBOutlet weak var cancelButtonTakingPhoto: UIButton!
    @IBOutlet weak var lastPhotoImageView: UIImageView!
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // the "viewfinder" layer of what you see when you photograph
    
    //-------------------------
    // MARK: - View Will Appear
    //-------------------------
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        lastPhotoImageView.layer.cornerRadius = 8
        lastPhotoImageView.layer.borderColor = UIColor.blackColor().CGColor
        lastPhotoImageView.layer.borderWidth = 1
        lastPhotoImageView.clipsToBounds = true
        
        //------------------------------------------
        // MARK: - Show Last Photo From Camera Roll
        //------------------------------------------
        // fetch the last photo based on creation date
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        
        // check result is not nil, if a last photo actually exists
        if (fetchResult.lastObject != nil) {
            
            let lastAsset: PHAsset = fetchResult.lastObject as! PHAsset
            
            PHImageManager.defaultManager().requestImageForAsset(lastAsset, targetSize: self.lastPhotoImageView.bounds.size, contentMode: PHImageContentMode.AspectFill, options: PHImageRequestOptions(), resultHandler: { (result, info) -> Void in
                
                // set the result (last photo fetched) to the ImageView on screen
                self.lastPhotoImageView.image = result
            })
        }
        
        // turn flash off before returning to camera view
        if let device = GlobalSingleton.sharedInstance.backCamera {
            
            if device.hasFlash {
                
                do {
                    try device.lockForConfiguration()
                } catch _ {
                }
                device.flashMode = AVCaptureFlashMode.Off
                device.unlockForConfiguration()
            }
        }
        
        captureSession = AVCaptureSession()
        
        // the preset is high to get the full previewed image when saved, else use Photo
        captureSession!.sessionPreset = AVCaptureSessionPresetHigh
        
        var error: NSError?
        
        // use the global shared instance of the device
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: GlobalSingleton.sharedInstance.backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        let otherQueue: dispatch_queue_t = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
        
        dispatch_async(otherQueue, { () -> Void in
            
            // no error and capture session can add INPUT of the global shared instance, do the following
            if error == nil && self.captureSession!.canAddInput(input) {
                
                self.captureSession!.addInput(input)
                
                self.stillImageOutput = AVCaptureStillImageOutput()
                self.stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                // if the capture session can add OUTPUT of a still image, do the following
                if self.captureSession!.canAddOutput(self.stillImageOutput) {
                    
                    self.captureSession!.addOutput(self.stillImageOutput)
                    
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    
                    self.previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                    
                    self.captureSession!.startRunning()
                    
                    
                    
                    // do this before
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        // frame you see when taking photo
                        self.previewLayer!.frame = self.frameForCapture.bounds
                        self.frameForCapture.layer.addSublayer(self.previewLayer!)
                        
                        // subviews to add
                        self.frameForCapture.addSubview(self.takePhotoButton)
                        self.frameForCapture.addSubview(self.flashButton)
                        self.frameForCapture.addSubview(self.cancelButtonTakingPhoto)
                        self.frameForCapture.addSubview(self.camButton)
                        self.frameForCapture.addSubview(self.lastPhotoImageView)
                        
                        self.view.layoutIfNeeded()
                        
                    })
                }
            }
        })
    }
    
    //------------------------
    // MARK: - Hide Status Bar
    //------------------------
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //--------------------------------
    // MARK: Focus On Touching Screen
    //--------------------------------
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touchPer = touches.first! as UITouch
        let screenSize = frameForCapture.bounds
        let focus_x = touchPer.locationInView(frameForCapture).x / screenSize.width
        let focus_y = touchPer.locationInView(frameForCapture).y / screenSize.height
        let focusPoint = CGPointMake(focus_x, focus_y)
        
        if let device = GlobalSingleton.sharedInstance.backCamera {
            
            do {
                
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = focusPoint
                device.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                device.unlockForConfiguration()
                
            } catch {print(error)}
        }
    }
    
    //-----------------------------------------------
    // MARK: - Back Button Tapped Go To Name Card VC
    //-----------------------------------------------
    @IBAction func backButtonTapped(sender: AnyObject) {
        
        print("backButtonTapped")
        // stop the capture session
        // self.captureSession!.stopRunning()
    }
    
    //-----------------------------
    // MARK: - Flash Button Tapped
    //-----------------------------
    @IBAction func flashButtonTapped(sender: AnyObject) {
        
        print("flashButtonTapped")
        // global variable of the device
        if let device = GlobalSingleton.sharedInstance.backCamera {
            
            if device.hasFlash {
                
                // check for both flash capability and if the flash is turned on or off
                // in order to turn the flash on or off when the user presses the flash button.
                
                // Turn flash OFF
                if (device.hasFlash && (device.flashMode == AVCaptureFlashMode.On)) {
                    
                    do {
                        try device.lockForConfiguration()
                    } catch _ {
                    }
                    device.flashMode = AVCaptureFlashMode.Off
                    device.unlockForConfiguration()
                    
                    let flashOffImage = UIImage(named: "betterflash")
                    flashOffImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    flashButton.setImage(flashOffImage, forState: UIControlState.Normal)
                    flashButton.tintColor = UIColor.whiteColor()
                    
                    print("flashOff")
                    
                    // Turn flash ON
                } else if (device.hasFlash && (device.flashMode == AVCaptureFlashMode.Off)) {
                    
                    do {
                        try device.lockForConfiguration()
                    } catch _ {
                    }
                    device.flashMode = AVCaptureFlashMode.On
                    device.unlockForConfiguration()
                    
                    let flashOnImage = UIImage(named: "flashOn")
                    flashOnImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    flashButton.setImage(flashOnImage, forState: UIControlState.Normal)
                    flashButton.tintColor = UIColor.yellowColor()
                    
                    print("flashOn")
                }
            }
        }
    }
    
    //---------------------------------------
    // MARK: Front Face Camera Button Tapped
    //---------------------------------------
    // add an "if - else" for this just like the flash ON and OFF logic
    @IBAction func camFlipButtonTapped(sender: AnyObject) {
        
        print("camFlipButtonTapped")
        
        if let sess = captureSession {
            let currentCameraInput: AVCaptureInput = sess.inputs[0] as! AVCaptureInput
            sess.removeInput(currentCameraInput)
            var newCamera: AVCaptureDevice
            
            // if you tap the flipCam Button while the device is currently on the back camera,
            // it will change to the front camera
            if (currentCameraInput as! AVCaptureDeviceInput).device.position == .Back {
                newCamera = self.cameraWithPosition(.Front)!
                
                // hide the flash button because it wont be used with front camera
                flashButton.alpha = 0
                flashButton.enabled = false
                
                // if you tap the flipCam Button while the device is currently on the front camera,
                // it will change to the back camera
            } else {
                newCamera = self.cameraWithPosition(.Back)!
                
                // enable and show the flash button for back camera
                flashButton.alpha = 1
                flashButton.enabled = true
            }
            let newVideoInput = try? AVCaptureDeviceInput(device: newCamera)
            captureSession?.addInput(newVideoInput)
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            if device.position == position {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    
    //---------------------------------
    // MARK: - Take Photo Button Tapped
    //---------------------------------
    @IBAction func takePhotoButtonTapped(sender: AnyObject) {
        
        // FYI I assume you cannot publish your app with a custom vibration, otherwise I would add
        // a short vibration when you press the takePhoto button to inform the user that
        // he/she pressed the button. I feel like this would be a great reassuring feature.
        // Take for example the circumstance when someone is not looking at their camera screen
        // while taking a photo and has to shuffle their thumb around predicting the camera button's
        // location on the screen. Vibration when pressed would be a reassuring or confirming feature
        // to let the user know for sure that he/she pressed the takePhoto button.
        
        let queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        // get the global (or background?) queue, do the following
        dispatch_async(queue, { () in
            
            // This "if let" statement means "if I allow stillImageOutput, do the following..."
            if let videoConnection = self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                
                self.stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                    
                    if (sampleBuffer != nil) {
                        
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        
                        let dataProvider = CGDataProviderCreateWithCFData(imageData)
                        
                        let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                        
                        let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            //-------------------------------------------
                            // MARK: - Front Face Camera Take Photo Logic
                            //-------------------------------------------
                            let currentCameraInput: AVCaptureInput = self.captureSession!.inputs[0] as! AVCaptureInput
                            self.captureSession!.removeInput(currentCameraInput)
                            //var newCamera: AVCaptureDevice
                            
                            // If current capture device is the front facing camera, flip the image captured
                            if (currentCameraInput as! AVCaptureDeviceInput).device.position == .Front {
                                
                                GlobalSingleton.sharedInstance.globalImg.image = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation:.LeftMirrored)
                                
                                // set frontFacePhotoTaken = true
                                GlobalSingleton.sharedInstance.isFrontFacePhotoTaken = true
                            } else {
                                
                                // don't flip the image because it was taken on back camera
                                GlobalSingleton.sharedInstance.globalImg.image = image
                                
                                // set frontFacePhotoTaken = false
                                GlobalSingleton.sharedInstance.isFrontFacePhotoTaken = false
                            }
                            
                            // stop the capture session after a photo is taken
                            self.captureSession!.stopRunning()
                            
                            // after everything, segue over to show the photo you just took
                            self.performSegueWithIdentifier("showCapturedImageSegue", sender: self)
                        })
                    }
                })
            }
        })
    }
    
    //---------------------------------
    // MARK: - Image Picker Controller
    //---------------------------------
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        // set the global image to the image you got from your camera roll
        GlobalSingleton.sharedInstance.globalImg.image = image
        
        // stop the capture session after a photo is taken
        self.captureSession!.stopRunning()
        
        self.dismissViewControllerAnimated(true, completion: {
            // after everything, segue over to show the photo you just took
            self.performSegueWithIdentifier("showCapturedImageSegue", sender: self)
        })
    }
    
    //-----------------------------------
    // MARK: - Choose Photo Button Tapped
    //-----------------------------------
    @IBAction func choosePhotoButtonTapped(sender: AnyObject) {
        
        let pickedImage = UIImagePickerController()
        pickedImage.delegate = self
        pickedImage.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        pickedImage.allowsEditing = false
        
        self.presentViewController(pickedImage, animated: true, completion: nil)
    }
}

