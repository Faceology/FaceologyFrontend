//
//  QRCodeViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/20/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var profileInfo: LISDKAPIResponse!
    var restClient: RestClient!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var defaultInfo : LISDKAPIResponse!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()
        
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
        
        //init a AVCaptureMetadataOutput and set it as the output device
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            //set delegate and use the default queue
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
    }
    
    func found(code: String) {
        print(code)
        if profileInfo != nil {
            performSegue(withIdentifier: "finishScanning", sender: profileInfo)
        }
        else {
            let dataInfo = "{\n  \"formattedName\": \"Tianyi Zheng\",\n  \"headline\": \"Interested in Backend Development and Computer Vision.  \",\n  \"location\": {\"name\": \"Greater Atlanta Area\"},\n  \"pictureUrls\": {\n    \"_total\": 1,\n    \"values\": [\"https://media.licdn.com/dms/image/C4E04AQFRRmVw-PTV2g/profile-originalphoto-shrink_450_600/0?e=1528088400&v=alpha&t=fUm36z8IoXkeXWTBlzDebLLIA5jfUFiEL3rEXl5iOJw\"]\n  },\n  \"summary\": \"Proficient in Python, C/C++, Swift, Java and Matlab. Familiar with Django, Spring, J2EE, Flask, Postgres, MongoDb, React Native.\\n\\nhttps://tianyizheng.github.io\"\n}"
            
            let defaultInfo = LISDKAPIResponse.init(data: dataInfo, headers: [AnyHashable("Content-Type"): "application/json;charset=UTF-8"], statusCode: 200)

            performSegue(withIdentifier: "finishScanning", sender: defaultInfo)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "finishScanning" {
            let navController = segue.destination as! UINavigationController
            let eventVC = navController.topViewController as! EventViewController
            let profileInfo = sender as! LISDKAPIResponse
            eventVC.profileInfo = profileInfo
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
            captureSession = nil
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "We can't find the camera on your device.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

}
