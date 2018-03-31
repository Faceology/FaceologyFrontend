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

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet private var numFaces: UILabel!
    @IBOutlet private var faceView: UIView!
    @IBOutlet private var imageView: UIImageView!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
        
        setupVision()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the device object.
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
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
        
        self.captureSession.startRunning()

    }

    @objc
    private func showFaces() {
        DispatchQueue.main.async {
            if (self.faceArray.isEmpty == false) {
                
                let tempCIImage = self.faceArray.first!
                
                let transform = CGAffineTransform(translationX: -tempCIImage.extent.origin.x, y: -tempCIImage.extent.origin.y)
                
                self.imageView.image = UIImage(ciImage: tempCIImage.transformed(by: transform))
                
            }
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
    
    func setupVision() {
        self.requests = [faceDetectionRequest]
    }
    
    private func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            //perform all the UI updates on the main queue
            guard let results = request.results as? [VNFaceObservation] else { return }
            
            self.numFaces.text = String(results.count)
            
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
        if (facebounds.maxY <= (previewLayer.bounds.height - faceView.bounds.height)){
            _ = createLayer(in: facebounds)
            
//            let temp = CGRect(x: 0, y: 0, width: 100, height: 100)
            let tempImage = tempCIImage.oriented(forExifOrientation: 6)
//
            
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

