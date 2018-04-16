//
//  EventViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/20/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {

    var qrCode: String!
    
    @IBOutlet var messageLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func goNext(sender: Any?) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showFaceDetection", sender: self.qrCode)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFaceDetection" {
            let showFaceDetectionVC = segue.destination as! FaceDetectionViewController
            let qrCode = sender as! String
            showFaceDetectionVC.qrCode = qrCode
        }
    }

}
