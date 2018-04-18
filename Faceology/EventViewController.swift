//
//  EventViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/20/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import SwiftyJSON


class EventViewController: UIViewController {

    var qrCode: String!
    var eventName: String!
    
    @IBOutlet var messageLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let group = DispatchGroup()
        group.enter()
        let restClient : RestClient = RestClient()
        
        restClient.getEventName(eventKey: qrCode){
            (responseData: Any?) in
            if (responseData != nil){
                let getMatchingInfo = responseData as! JSON
                print(getMatchingInfo)
                print("Request Finished")
                if (getMatchingInfo["name"] != JSON.null){
                    print("Found event")
                    self.eventName = getMatchingInfo["name"].stringValue
                }
                group.leave()
            }
            else {
                print("Error: Resposne Data is nil")
            }
        }
         group.notify(queue: .main) {
            self.messageLabel.text = "Welcome to " + self.eventName
        }
        
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
