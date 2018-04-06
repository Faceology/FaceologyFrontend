//
//  DisclaimerViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 3/20/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit

class DisclaimerViewController: UIViewController {

    var restClient: RestClient!
    var profileInfo: LISDKAPIResponse!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQRCode" {
            let qrCodeVC = segue.destination as! QRCodeViewController
            let profileInfo = sender as! LISDKAPIResponse
            qrCodeVC.profileInfo = profileInfo
        }
    }

  

}
