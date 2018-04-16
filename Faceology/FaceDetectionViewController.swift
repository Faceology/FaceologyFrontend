//
//  FaceDetectionViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/28/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import SwiftyJSON

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {
    
    var restClient: RestClient!
    var qrCode: String!
    
    private var getMatchingInfo: JSON? = nil

    private var imageView: UIImageView!
    private var scrollView: UIScrollView!
    
    //add a custome view
    @IBOutlet private weak var cameraView: UIView!
    //define layer for faces
    private var maskLayer = [CAShapeLayer]()
    private var matchingInfoDict: [Int:JSON] = [:]
    //define capture session
    private var captureSession: AVCaptureSession!
    //define a preview layer for displaying camera
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var scanTimer: Timer?
    
    //a request list
    private var requests = [VNRequest]() // you can do mutiple requests at the same time
    
    //defines face rectangle request
    private var faceDetectionRequest: VNRequest!
  
    //temporary buffer to hold sample image
    private var tempCIImage: CIImage!
    private var faceArray = [CIImage]()
    
    private var previousIds : [String] = ["0"]
    
    private var context: CIContext!
    
    private var videoCaptureDevice: AVCaptureDevice?
    
    private var isPending: Bool = false
    private var foundFacematch: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        

        self.navigationItem.title = "Camera"
        
        captureSession = AVCaptureSession()
        
        //init a CI Context since it is expensive
        context = CIContext(options: nil)

        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
        
        setupVision()
        
        videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput: AVCaptureDeviceInput
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the device object.
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
            
        } catch {
            // If any error occurs
            print(error)
            return
        }
        
        // Set the input device on the capture session.
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        //set video outpt for the capture session
        let videoOutput = AVCaptureVideoDataOutput()
        if (self.captureSession.canAddOutput(videoOutput)){
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            self.captureSession.addOutput(videoOutput)
        } else {
            failed()
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview cameraView's layer.
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        self.previewLayer.frame = self.cameraView.layer.bounds
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.cameraView.layer.addSublayer(previewLayer)
        
        //setting up pinching
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinchToZoom))
        
        pinchRecognizer.delegate = self
        self.cameraView.addGestureRecognizer(pinchRecognizer)
        
        
        //setting up scroll view
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: screenHeight-110, width: screenWidth, height: 110))
        
        scrollView.contentSize = CGSize(width: screenWidth, height: 110)
        view.addSubview(scrollView)
        
        self.captureSession.startRunning()

    }
    
//    @objc
    private func showFaces() {
        if (self.faceArray.isEmpty == false && !self.isPending) {
            
            self.isPending = true
//            clearSubviewsFromScrollView()
            
            var newImage : UIImage? = nil
            var uiImage : UIImage? = nil
            var tapGestureRecognizer : UITapGestureRecognizer!
            var tempCIImage: CIImage!
            var transform: CGAffineTransform!
            var usrId: String!
            let group = DispatchGroup()
            
            //define transformation
            

            
            //get the cropped ci image from facearray
            tempCIImage = self.faceArray[0]
            
            transform = CGAffineTransform(translationX: -tempCIImage.extent.origin.x, y: -tempCIImage.extent.origin.y)
            
            //init sync
            group.enter()
            
            //create ui image from tempCIImage
            uiImage = UIImage(ciImage: tempCIImage.transformed(by: transform))
            
            
            //create new bitmap based image
            if uiImage?.ciImage != nil {
                
                newImage = self.convertCIImageToUIImage(inputImage: uiImage!.ciImage!)
                
                let restClient : RestClient = RestClient()
                
                let imageData = UIImagePNGRepresentation(newImage!)
                
                let strBase64 = imageData?.base64EncodedString(options: .lineLength64Characters)
                
                self.imageView = UIImageView.init(image: newImage)
                
//                print(previousIds)
                restClient.getObjects(previousIds: previousIds, eventKey: qrCode, image: strBase64!){
                    (responseData: Any?) in
                        if (responseData != nil){
                            self.getMatchingInfo = responseData as! JSON
                            print("Request Finished")
                            if (self.getMatchingInfo!["userInfo"] != nil){
                                print("Found a Match")
                                usrId = self.getMatchingInfo!["userInfo"]["userId"].stringValue
                                self.previousIds.append(usrId)
                                self.matchingInfoDict[Int(usrId)!] = self.getMatchingInfo
                                self.foundFacematch = true
                            }
                            group.leave()
                    }
                        else {
                            print("Error: Resposne Data is nil")
                    }
                }
            }
            
            group.notify(queue: .main) {
                if self.foundFacematch {
                    print("Left")
                    self.imageView.tag = Int(usrId)!
                    self.imageView.frame = CGRect.init(x: 0, y: 0, width: 100, height: 100)
                    
                    self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2
                    self.imageView.layer.masksToBounds = true
                    self.imageView.layer.borderColor = UIColor.white.cgColor
                    self.imageView.layer.borderWidth = 5
                    
                    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(sender:)))
                    
                    self.imageView.isUserInteractionEnabled = true
                    
                    self.imageView.addGestureRecognizer(tapGestureRecognizer)
                    
                    self.changeSubView()
                    
                    self.isPending = false
                    self.foundFacematch = false
                }
                else {
                    self.isPending = false
                }
                
            }


        }
    }

    func changeSubView(){
        let subViews:[UIView] = self.scrollView.subviews
        let count = subViews.count
        for i in 0..<count{
            if let imageViewTypeCheck = subViews[i] as? UIImageView{
                imageViewTypeCheck.frame = CGRect.init(x: 110*i-110, y: 0, width: 100, height: 100)
                print(subViews[i].tag)
            }
            else{
                print("Not a image view")
            }
            
        }
        self.scrollView.addSubview(self.imageView)
        self.scrollView.contentSize = CGSize(width: 110 * (count-1), height: 110)
    }

    
    //setup a request and perform request for each frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //make sure pixel buffer can be converted
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption : Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }
        
        // perform image request for face recognition
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
            tempCIImage = CIImage(cvImageBuffer: pixelBuffer)
        }
            
        catch {
            print(error)
        }
        
    }
 
    
    private func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            //perform all the UI updates on the main queue
            guard let results = request.results as? [VNFaceObservation] else { return }
            
            //get rid of last frame's boxes
            self.removeMask()
            
            for face in results {
                self.drawFaceboundingBox(face: face)
            }
            
            self.showFaces()
        }
    }

    
    func drawFaceboundingBox(face : VNFaceObservation) {
        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
        
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -cameraView.bounds.height)
        
        let scale = CGAffineTransform.identity.scaledBy(x: cameraView.bounds.width, y: cameraView.bounds.height)

        let facebounds = face.boundingBox.applying(scale).applying(transform)
        
        //draw the box if within bounds
        if (facebounds.maxY <= (previewLayer.bounds.height - scrollView.bounds.height)){
            _ = createLayer(in: facebounds)
            
//            let temp = CGRect(x: 0, y: 0, width: 100, height: 100)
            let tempImage = tempCIImage.oriented(forExifOrientation: 6)
            
            let cropScale = CGAffineTransform.identity.scaledBy(x: tempImage.extent.width, y: tempImage.extent.height)
            let cropFaceBounds = face.boundingBox.applying(cropScale)
//            let cropFaceBounds = increaseRect(rect: face.boundingBox.applying(cropScale),byPercentage: 0.1)
            
            faceArray.append(tempImage.cropped(to: cropFaceBounds))
        }
    }
    
    
    
    
    @objc
    func imageTapped(sender: UITapGestureRecognizer)
    {
        let tappedImage = sender.view as! UIImageView
        
        let matchingInfo = self.matchingInfoDict[tappedImage.tag]
        
        if (matchingInfo != nil){
            performSegue(withIdentifier: "showProfileInfo", sender: matchingInfo)
        }
        else {
            print("Error: matchingInfo is nil")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfileInfo" {
            let profileVC = segue.destination as! ProfileViewController
            let matchingInfo = sender as! JSON
            profileVC.matchingInfo = matchingInfo
            
            let backItem = UIBarButtonItem()
            backItem.title = "Camera"
            
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    
    func convertCIImageToUIImage(inputImage: CIImage) -> UIImage? {
        if let cgImage = self.context.createCGImage(inputImage, from: inputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func setupVision() {
        self.requests = [faceDetectionRequest]
    }
    
    // Create a new layer drawing the bounding box
    private func createLayer(in rect: CGRect) -> CAShapeLayer {
        
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 10
        mask.opacity = 0.75
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0
        
        //keeping track of faces so we can remove them in next frame
        maskLayer.append(mask)
        cameraView.layer.insertSublayer(mask, at: 1)

        return mask
    }
    
    @objc
    func pinchToZoom(sender:UIPinchGestureRecognizer) {
        let vZoomFactor = ((sender ).scale)
        setZoom(zoomFactor: vZoomFactor, sender: sender)
    }
    
    func setZoom(zoomFactor:CGFloat, sender:UIPinchGestureRecognizer) {
        var device: AVCaptureDevice = self.videoCaptureDevice!
        var error:NSError!
        do{
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()}
            if (zoomFactor <= device.activeFormat.videoMaxZoomFactor) {
                
                let desiredZoomFactor:CGFloat = zoomFactor + atan2(sender.velocity, 5.0);
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor));
            }
            else {
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, zoomFactor);
            }
        }
        catch error as NSError{
            NSLog("Unable to set videoZoom: %@", error.localizedDescription);
        }
        catch _{
        }
    }
    
    
    func clearSubviewsFromScrollView()
    {
        for subview in scrollView.subviews {
            subview.removeFromSuperview();
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "We can't find the camera on your device.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        
        //        scanTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(showFaces), userInfo: nil, repeats: true)
        
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
        faceArray.removeAll()

    }
    
    func increaseRect(rect: CGRect, byPercentage percentage: CGFloat) -> CGRect {
        let startWidth = rect.width
        let startHeight = rect.height
        let adjustmentWidth = (startWidth * percentage) / 2.0
        let adjustmentHeight = (startHeight * percentage) / 2.0
        return rect.insetBy(dx: -adjustmentWidth, dy: -adjustmentHeight)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

