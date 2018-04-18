//
//  DisclaimerViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/20/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit

class DisclaimerViewController: UIViewController {

    @IBOutlet var agreeButton : UIButton!
    
    var restClient: RestClient!
    var profileInfo: LISDKAPIResponse!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func goNext(sender: Any?) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showQRCode", sender: self.profileInfo)
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQRCode" {
            let navController = segue.destination as! UINavigationController
            let qrCodeVC = navController.topViewController as! QRCodeViewController
            let profileInfo = sender as! LISDKAPIResponse
            qrCodeVC.profileInfo = profileInfo
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            
            navigationItem.backBarButtonItem = backItem
        }
    }

  

}
