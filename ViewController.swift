//
//  ViewController.swift
//  Camera Access6
//  Copyright (c) 2015 ElenaWill. All rights reserved.
//  PROJECT DESCRIPTION: iPhone camera app that uses AVCapture to take photo, also modifying focus, zoom, torch, etc.
//  CREATED BY: Elena and Will on 6/22/15 aka Elena's birthday
//  LAST MODIFIED BY: Elena on 7/20
//
//  TO DO: fix the saving function, draw circle thing, color wheel, freehand draw

import UIKit //for the UI elements including the slider, the pinch, etc.
import AVFoundation //for the AVCaptureSession

class ViewController: UIViewController
{
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var stillImageOutput: AVCaptureStillImageOutput!
    var imageData: NSData!
    var tap = UITapGestureRecognizer()
    
    // MARK: CONSTANTS: UI THINGS INCLUDING CUSTOM COLORS AND DIMENSIONS
    let pathonomicGreen = UIColor(red: 0x73/255, green: 0xC4/255, blue: 0x8E/255, alpha: 1.0)
    let pathonomicBlue = UIColor(red: 0x16/255, green: 0x36/255, blue: 0x50/255, alpha: 1.0)
    let pathonomicGreenish = UIColor(red: 0x73/255, green: 0xC4/255, blue: 0x8E/255, alpha: 0.5)
    let pathonomicBlueish = UIColor(red: 0x16/255, green: 0x36/255, blue: 0x50/255, alpha: 0.5)
    let whiteish = UIColor(red: 255, green: 255, blue: 255, alpha: 0.4)
    let whiteish_lessOpaque = UIColor(red: 255, green: 255, blue: 255, alpha: 0.6)
    let magentaish = UIColor(red: 255, green: 0, blue: 255, alpha: 0.5)
    let margin = CGFloat(10) //margin width for slider
    let height = CGFloat(40) //height of each UI element
    let length = CGFloat(200)
    let maxZoom = 10
    let diameter = CGFloat(80) // diameter of photo button
    let miniDiameter = CGFloat(40)
    
    // MARK: SET UP CAPTURE SESSION AND PREVIEW LAYER
    override func viewDidLoad(){ //SELECTS THE CORRECT CAMERA, AND CALLS SEVERAL LATER FUNCTIONS
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh //changed low to high quality
        let devices = AVCaptureDevice.devices()
        for device in devices //loop through all available devices
        {
            if (device.hasMediaType(AVMediaTypeVideo)) // if this  device supports video
            {
                if(device.position == AVCaptureDevicePosition.Back)//if it's the back camera
                {
                    captureDevice = device as? AVCaptureDevice //takes the device that's AVCaptureDevice
                    if captureDevice != nil{
                        println("Capture device found")
                        beginSession() //function call
                        createSliderLight()
                        createSliderZoom()
                        //createSliderFocus() //uncomment if using focus slider
                        createButton()
                    }
                }
            }
        }
    }
    
    func beginSession() //STARTS THE PREVIEW SESSION ON THE CAMERA
    {
        var err : NSError? = nil //?
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err)) //adds the selected device as input in the capture session
        if err != nil{
            println("error: \(err?.localizedDescription)") //if there's an error print it out
        }
        stillImageOutput = AVCaptureStillImageOutput() // Create still image output and attach to session
        let outputSettings:Dictionary = [AVVideoCodecJPEG:AVVideoCodecKey]
        stillImageOutput?.outputSettings = outputSettings
        captureSession.addOutput(stillImageOutput)
        //preview layer:
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) //sets the session as a preview layer
        self.view.layer.addSublayer(previewLayer) //setup
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning() //start
    }
    
    // MARK: UI BUTTON FOR CAMERA FUNCTIONALITY
    func createButton(){ //CREATE A CAMERA BUTTON THAT WILL TAKE A PHOTO
        let image = UIImage(named: "play.png") as UIImage!
        var cameraButton = UIButton.buttonWithType(.Custom) as! UIButton
        cameraButton.setImage(image, forState: .Normal)
        cameraButton.imageEdgeInsets = UIEdgeInsets(top: 25,left: 22,bottom: 25,right: 22)
        cameraButton.frame = CGRectMake(view.frame.size.width / 2 - diameter/2, (view.frame.size.height - diameter - margin), diameter, diameter)
        UIEdgeInsetsMake(60,60,60,60) //make it so that user can drag slider by touching
        cameraButton.layer.cornerRadius = 0.5 * cameraButton.bounds.size.width //0.5 makes it pefectly round
        cameraButton.backgroundColor = whiteish
        cameraButton.layer.borderWidth = 5
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        cameraButton.setTitle("Photo", forState: UIControlState.Normal)
        cameraButton.transform = CGAffineTransformRotate(cameraButton.transform,CGFloat(-270.0/180*M_PI))
        cameraButton.addTarget(self, action: "photoAction:", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(cameraButton)
    }
    
    func flashScreen(){ //SHUTTER SCREEN, FLASHES BACK
        let flashView : UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        flashView.alpha = 0.0
        flashView.backgroundColor = UIColor.blackColor()
        view.addSubview(flashView)
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            flashView.alpha = 1 },
            completion: { _ in
                flashView.alpha = 0
        })
    }
    
    // MARK: PHOTO PREVIEW CODE AND UIBUTTONS TO SAVE IMAGE OR CANCEL IMAGE
    func photoAction(sender: AnyObject) //FREEZES SCREEN TO SHOW PHOTO PREVIEW
    {
        self.flashScreen()
        self.previewLayer!.connection.enabled = false //freeze
        if let videoConnection = stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo){ // Get 1 image as JPEG and store to photo roll
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection){
                (imageSampleBuffer : CMSampleBuffer!, _) in
                let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                var pickedImage: UIImage = UIImage(data: imageDataJpeg)!
                UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil)
            }
        }
        for subUIView in self.view.subviews as! [UIView]{ //hide ui sliders and everything
            subUIView.removeFromSuperview()
        }
        self.createButtonX() // creates the buttons after picture appears
        //self.createButtonV()
        
        var photoSavedPopup = UILabel(frame: CGRectMake(0, 0, 200,35)) //size of the box
        photoSavedPopup.alpha = 1
        photoSavedPopup.center = CGPointMake(160, 284)
        photoSavedPopup.font = UIFont(name: photoSavedPopup.font.fontName, size:20)
        photoSavedPopup.backgroundColor = pathonomicGreen
        photoSavedPopup.layer.cornerRadius = 10
        photoSavedPopup.layer.masksToBounds = true
        photoSavedPopup.textAlignment = NSTextAlignment.Center
        photoSavedPopup.text = "Photo Saved!"
        photoSavedPopup.textColor = UIColor.whiteColor()
        self.view.addSubview(photoSavedPopup)
        photoSavedPopup.transform=CGAffineTransformRotate(photoSavedPopup.transform,CGFloat(-270.0/180*M_PI))
        photoSavedPopup.alpha = 1
        UIView.animateWithDuration(2.0, animations: { () -> Void in
            photoSavedPopup.alpha = 0
        })
    }
    
    func createButtonX(){ //INITIALIZE THE CANCEL BUTTON DURING IMAGE PREVIEW
        let buttonX = UIButton() //initialize a button object
        buttonX.setTitle("X", forState: .Normal) //set the title and color
        buttonX.setTitleColor(UIColor.magentaColor(), forState: .Normal)
        buttonX.titleLabel?.adjustsFontSizeToFitWidth = true //larger font "x"
        buttonX.frame = CGRectMake(view.frame.size.width - miniDiameter - margin, miniDiameter/2 + margin, miniDiameter, miniDiameter)
        buttonX.layer.cornerRadius = 0.1 * buttonX.bounds.size.width //0.5 makes it pefectly round
        buttonX.backgroundColor = whiteish
        buttonX.layer.borderWidth = 5
        buttonX.layer.borderColor = UIColor.whiteColor().CGColor
        buttonX.addTarget(self, action: "buttonActionX:", forControlEvents: .TouchUpInside)
        buttonX.transform=CGAffineTransformRotate(buttonX.transform,CGFloat(-270.0/180*M_PI))
        self.view.addSubview(buttonX)
    }
    
    func buttonActionX(sender: UIButton!){ //ACTION METHOD FOR THE CANCEL BUTTON
        self.previewLayer!.connection.enabled = true //UNfreez
        for subUIView in self.view.subviews as! [UIView]{ //hide xo buttons
            subUIView.removeFromSuperview()
        }
        createSliderLight() //re-builds the UI
        createSliderZoom()
        //createSliderFocus() //uncomment this if you would like the focus slider
        createButton()
    }
    
    
    // MARK: SLIDE FOR LIGHT: SETS UP A SLIDER THAT CONTROLS TORCH LEVEL
    func createSliderLight() //CREATES A SLIDER ON THE SCREEN, SPECIYING LOCATION, ROTATION, COLOR, STARTING VALUE
    {
        //var lightValueSlider = UISlider(frame:CGRectMake(margin, view.frame.size.height - 60, view.frame.size.width - 2*margin, height)) //initialize a slider object, and (x,y,width,height)
        //var label = UILabel(frame: CGRectMake(margin, view.frame.size.height - 40, view.frame.size.width - 2*margin, height)) //initialize the text label
        slideLight(1)
        var lightValueSlider = UISlider(frame:CGRectMake(view.frame.size.width/2 + 35, view.frame.size.height - (length)/2 - 60, length, height)) //initialize a slider object, and (x,y,width,height)
        lightValueSlider.transform=CGAffineTransformRotate(lightValueSlider.transform,CGFloat(-270.0/180*M_PI))
        var label = UILabel(frame: CGRectMake(view.frame.size.width/2 - 20, view.frame.size.height - 180, view.frame.size.width - 2*20,height)) //initialize the text label
        label.transform=CGAffineTransformRotate(label.transform,CGFloat(-270.0/180*M_PI))
        label.textAlignment = NSTextAlignment.Right //format the text
        label.text = "Light"
        label.textColor = whiteish_lessOpaque
        label.font = UIFont(name: label.font.fontName, size:20)
        self.view.addSubview(label)
        lightValueSlider.minimumValue = 1 //format the slider
        lightValueSlider.maximumValue = 100
        lightValueSlider.continuous = true
        lightValueSlider.tintColor = pathonomicGreenish
        lightValueSlider.thumbTintColor = pathonomicGreen
        lightValueSlider.value = 1 //start at 1 (off)
        lightValueSlider.transform = CGAffineTransformScale(lightValueSlider.transform, CGFloat(1.3), CGFloat(1.3))
        lightValueSlider.addTarget(self, action: "sliderActionLight:", forControlEvents: .ValueChanged) //adds the action method
        self.view.addSubview(lightValueSlider)
    }
    
    func sliderActionLight(sender: UISlider) //ACTION METHOD FOR THE SLIDER
    {
        var currentSliderValue = Int(sender.value)
        slideLight(currentSliderValue) //calls slideLight function below
    }
    
    func slideLight(Value: Int) //CONTROLS THE GRADUAL LIGHT INCREASE AS SLIDER IS SLID
    {
        var percentLight = (Float(Value) / 100) //becomes .01 - 1.0
        if let device = captureDevice
        {
            device.lockForConfiguration(nil) //lock
            if (percentLight < 0.03){  //last 3% is off
                device.torchMode = AVCaptureTorchMode.Off
            }
            else{
                device.setTorchModeOnWithLevel(percentLight, error: nil) //graual levels dependent on percentLight
            }
            device.unlockForConfiguration() //unlock
        }
    }
    
    // MARK: PORTRAIT LOCK: LOCKS THE ENTIRE APP TO PORTRAIT MODE SO THE USER CANNOT ROTATE IT [plagarized]
    override func shouldAutorotate() -> Bool
    {
        return false
    }
    override func supportedInterfaceOrientations() -> Int
    {
        return UIInterfaceOrientation.Portrait.rawValue
    }
    
    // MARK: SLIDE TO ZOOM: CREATES A SLIDER THAT ALLOWS 1-20x ZOOM
    func createSliderZoom() //CREATES A SLIDER ON THE SCREEN
    {
        //var zoomValueSlider = UISlider(frame:CGRectMake(margin, view.frame.size.height - 110, view.frame.size.width - 2*margin, height)) //initialize a slider object, and (x,y,width,height)
        //var label = UILabel(frame: CGRectMake(margin, view.frame.size.height - 90, view.frame.size.width - 2*margin, height)) //initialize the text label
        slideZoom(1)
        var zoomValueSlider = UISlider(frame:CGRectMake(-(view.frame.size.width - 4*20)/2 + 40, view.frame.size.height - (length)/2 - 60, length, height)) //initialize a slider object, and (x,y,width,height)
        var label = UILabel(frame: CGRectMake(-view.frame.size.width/2 + 60, view.frame.size.height - 180, view.frame.size.width - 2 * 20, height)) //initialize the text label
        zoomValueSlider.transform = CGAffineTransformRotate(zoomValueSlider.transform,CGFloat(-270.0/180*M_PI))
        label.transform = CGAffineTransformRotate(label.transform,CGFloat(-270.0/180*M_PI))
        
        label.textAlignment = NSTextAlignment.Right //format tet label
        label.text = "Zoom"
        label.font = UIFont(name: label.font.fontName, size:20)
        label.textColor = whiteish_lessOpaque
        self.view.addSubview(label)
        zoomValueSlider.minimumValue = 1 //format slider
        zoomValueSlider.maximumValue = 100
        zoomValueSlider.continuous = true
        zoomValueSlider.tintColor = pathonomicBlueish
        zoomValueSlider.thumbTintColor = pathonomicBlue
        zoomValueSlider.value = 1 //start at 1
        zoomValueSlider.transform = CGAffineTransformScale(zoomValueSlider.transform, CGFloat(1.3), CGFloat(1.3))
        zoomValueSlider.addTarget(self, action: "sliderActionZoom:", forControlEvents: .ValueChanged)
        self.view.addSubview(zoomValueSlider)
    }
    
    func sliderActionZoom(sender: UISlider) //THE ACTION METHOD FOR THE SLIDER
    {
        var currentSliderValue = Int(sender.value)
        slideZoom(currentSliderValue)
    }
    
    func slideZoom(Value: Int) //control the gradual light increase as the slider is slid
    {
        var percentZoom = (Float(Value) / 100) //becomes .01 - 1.0
        if let device = captureDevice
        {
            device.lockForConfiguration(nil) //lock
            if (percentZoom * 20 < 1.0){ //if less than 1 stay at 1x zoom
                device.videoZoomFactor = CGFloat(1)
            }
            else{
                device.videoZoomFactor = CGFloat(percentZoom * 20)
            }
            device.unlockForConfiguration() //unlock
        }
    }
    
// UNCOMMENT THIS IF YOU WOULD LIKE THE APP TO INCLUDE FOCUS SLIDER
// MARK: SLIDE TO FOCUS CODE: CREATE A SLIDER THAT ALLOWS USER TO ADJUST THE FOCUS OF THE CAMERA
    
//    func createSliderFocus() //CREATES A SLIDER ON THE SCREEN
//    {
//        //var focusValueSlider = UISlider(frame:CGRectMake(margin, view.frame.size.height - 160, view.frame.size.width - 2*margin, height)) //initialize a slider object, and (x,y,width,height)
//        //var label = UILabel(frame: CGRectMake(margin, view.frame.size.height - 140, view.frame.size.width - 2*margin, height)) //initialize the text label
//        slideFocus(1)
//        var focusValueSlider = UISlider(frame:CGRectMake(-(view.frame.size.width - 4*20)/2 + 80, view.frame.size.height - (length)/2 - 60, length , height)) //initialize a slider object, and (x,y,width,height)
//        var label = UILabel(frame: CGRectMake(-view.frame.size.width/2 + 100, view.frame.size.height - 180, view.frame.size.width - 2 * 20, height)) //initialize the text label
//        focusValueSlider.transform = CGAffineTransformRotate(focusValueSlider.transform,CGFloat(-270.0/180*M_PI))
//        label.transform = CGAffineTransformRotate(label.transform,CGFloat(-270.0/180*M_PI))
//        label.textAlignment = NSTextAlignment.Right //format tet label
//        label.text = "Focus"
//        label.font = UIFont(name: label.font.fontName, size:20)
//        label.textColor = whiteish_lessOpaque
//        self.view.addSubview(label)
//        focusValueSlider.minimumValue = 1 //format slider
//        focusValueSlider.maximumValue = 100
//        focusValueSlider.continuous = true
//        focusValueSlider.tintColor = magentaish // UIColor.magentaColor()
//        focusValueSlider.thumbTintColor = UIColor.magentaColor()
//        focusValueSlider.transform = CGAffineTransformScale(focusValueSlider.transform, CGFloat(1.3), CGFloat(1.3))
//        focusValueSlider.value = 1 //start at 1
//        focusValueSlider.addTarget(self, action: "sliderActionFocus:", forControlEvents: .ValueChanged)
//        self.view.addSubview(focusValueSlider)
//        configureDevice() //call
//    }
//    
//    func configureDevice() //SETS FOCUS TO LOCKED, DEFAULT IS DISABLED
//    {
//        if let device = captureDevice {
//            device.lockForConfiguration(nil)
//            device.focusMode = .Locked
//            device.unlockForConfiguration()
//        }
//    }
//    
//    func sliderActionFocus(sender: UISlider) //THE ACTION METHOD FOR THE FOCUS SLIDER
//    {
//        var currentSliderValue = Int(sender.value)
//        slideFocus(currentSliderValue)
//    }
//    
//    func slideFocus(value: Int) //CONTROLS THE GRADUAL LIGHT INCREASE AS THE SLIDER IS SLID
//    {
//        var percentFocus = (Float(value) / 100) //becomes .01 - 1.0
//        if let device = captureDevice
//        {
//            device.lockForConfiguration(nil) //lock
//            focusTo(Float(percentFocus))
//            device.unlockForConfiguration() //unlock
//        }
//    }
//    
//    func focusTo(value : Float) { //FOCUSES BASED ON THE PERCENT VALUE OF THE SLIDER
//        if let device = captureDevice { // based on value .01 - 1.0
//            if(device.lockForConfiguration(nil)) { //lock
//                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
//                    // tell camera to focus on the 'value' passed into the method
//                })
//                device.unlockForConfiguration() //unlock
//            }
//        }
//    }
    
} //end
