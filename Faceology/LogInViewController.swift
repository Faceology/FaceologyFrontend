//
//  ViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/17/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import SwiftyJSON

class LogInViewController: UIViewController {

    enum unkownError: Error {
        case unknown
    }
    
    @IBAction func doLogin(sender: AnyObject) {
        LISDKSessionManager.createSession(withAuth: [LISDK_BASIC_PROFILE_PERMISSION, LISDK_EMAILADDRESS_PERMISSION], state: nil, showGoToAppStoreDialog: true, successBlock: {
            
            (returnState) -> Void in
//            print("success called!")
//            print(LISDKSessionManager.sharedInstance().session)
            
            let url = "https://api.linkedin.com/v1/people/~:(formattedName,emailAddress,headline,summary,specialties,pictureUrls::(original),location:(name),publicProfileUrl,positions)?format=json"
            
            if LISDKSessionManager.hasValidSession() {
                LISDKAPIHelper.sharedInstance().getRequest(url, success: { (response) -> Void in
                    if response != nil {
                        self.goNext(profileInfo: response!)
                    }
                    else {
                        self.failed()
                    }
                }, error: { (error) -> Void in
                    print(error as Any)
                })
            }

        }, errorBlock: {
            (error) -> Void in
            print("Error: \(error ?? unkownError.unknown)")
        }) 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    func goNext(profileInfo: LISDKAPIResponse!) {
        DispatchQueue.main.async {
            
            
            self.performSegue(withIdentifier: "showDisclaimer", sender: profileInfo)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDisclaimer" {
            let disclaimerVC = segue.destination as! DisclaimerViewController
            let profileInfo = sender as! LISDKAPIResponse
            disclaimerVC.profileInfo = profileInfo
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Cannot find profile", message: "We can't locate your LinkedIn information Please try again.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

}

