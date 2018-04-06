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

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {
    
    private var imageView: UIImageView!
    private var scrollView: UIScrollView!
    
    //add a custome view
    @IBOutlet private weak var cameraView: UIView!
    //define layer for faces
    private var maskLayer = [CAShapeLayer]()
    
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
    
    private var context: CIContext!
    
    private var videoCaptureDevice: AVCaptureDevice?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: screenHeight-130, width: screenWidth, height: 130))
        
        scrollView.contentSize = CGSize(width: screenWidth, height: 130)
        view.addSubview(scrollView)
        
        self.captureSession.startRunning()

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
    
    @objc
    private func showFaces() {
        if (self.faceArray.isEmpty == false) {

            var newImage : UIImage? = nil
            var uiImage : UIImage? = nil
            var tapGestureRecognizer : UITapGestureRecognizer!
            var imageView: UIImageView!
            var tempCIImage: CIImage!
            var transform: CGAffineTransform!
            
            let group = DispatchGroup()
            
            //define transformation
            
            
            scrollView.contentSize = CGSize(width: 130 * faceArray.count, height: 130)
            
            for i in 0 ..< faceArray.count {
                
                //get the cropped ci image from facearray
                tempCIImage = self.faceArray[i]
                
                transform = CGAffineTransform(translationX: -tempCIImage.extent.origin.x, y: -tempCIImage.extent.origin.y)
                
                //init sync
                group.enter()
                
                //create ui image from tempCIImage
                uiImage = UIImage(ciImage: tempCIImage.transformed(by: transform))
                
                //create new bitmap based image
                if uiImage?.ciImage != nil {
                    
                    newImage = self.convertCIImageToUIImage(inputImage: uiImage!.ciImage!)
                    
                    imageView = UIImageView.init(image: newImage)
                    imageView.frame = CGRect.init(x: 130 * i, y: 10, width: 130, height: 130)
                    
                    imageView.layer.cornerRadius = imageView.frame.size.height/2
                    imageView.layer.masksToBounds = true
                    imageView.layer.borderColor = UIColor.white.cgColor
                    imageView.layer.borderWidth = 5
                    
                    
                    
                    group.leave()
                }
                
                group.notify(queue: .main) {
                    
                    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(sender:)))
                    
                    imageView.isUserInteractionEnabled = true
                    
                    imageView.addGestureRecognizer(tapGestureRecognizer)
                    
                    self.scrollView.addSubview(imageView)
                    
                }
            }

        }
    }
    
    @objc
    func imageTapped(sender: UITapGestureRecognizer)
    {
        let tappedImage = sender.view as! UIImageView
        
        let imageData = UIImagePNGRepresentation(tappedImage.image!)
        
        let strBase64 = imageData?.base64EncodedString(options: .lineLength64Characters)
        
        performSegue(withIdentifier: "showProfileInfo", sender: strBase64)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfileInfo" {
            
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
        
        scanTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(showFaces), userInfo: nil, repeats: true)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
            captureSession = nil
        }
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
    
    func convertCIImageToUIImage(inputImage: CIImage) -> UIImage? {
        if let cgImage = self.context.createCGImage(inputImage, from: inputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func setupVision() {
        self.requests = [faceDetectionRequest]
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

            
            faceArray.append(tempImage.cropped(to: cropFaceBounds))
        }
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
    
    
    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
        faceArray.removeAll()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

