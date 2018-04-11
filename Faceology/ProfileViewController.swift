//
//  ProfileViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 4/6/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    var strBase64: String?
    
    private var profileImage: UIImage!
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var profileImageView: UIImageView!
    
    @IBOutlet var coverView: UIView!
    
    @IBOutlet var mainInfoView: UIView!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var headlineLabel: UILabel!
    @IBOutlet var summaryText: UITextView!
    @IBOutlet var companyLabel: UILabel!
    
    @IBOutlet var profileLinkLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var contactView: UIView!
    
    @IBOutlet var companyInfo: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
//        let screenHeight = screensize.height
        
        let decodedImageData = Data.init(base64Encoded: strBase64!, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)
        
        profileImage = UIImage.init(data: decodedImageData!)
        
        
        profileImageView.image = profileImage
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height/2
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.borderWidth = 5
        profileImageView.clipsToBounds = true

        mainInfoView.layer.cornerRadius = 5
        contactView.layer.cornerRadius = 5

        scrollView.contentSize = CGSize(width: screenWidth, height: 1000)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addShadow(outerView: UIView!){
        outerView.clipsToBounds = false
        outerView.layer.shadowColor = UIColor.black.cgColor
        outerView.layer.shadowOpacity = 1
        outerView.layer.shadowOffset = CGSize.zero
        outerView.layer.shadowPath = UIBezierPath(rect: outerView.bounds).cgPath
    }


}
