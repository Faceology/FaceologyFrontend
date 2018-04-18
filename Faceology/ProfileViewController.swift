//
//  ProfileViewController.swift
//  Faceology
//
//  Created by Tianyi Zheng on 4/6/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import SwiftyJSON


class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "PositionsCell"
   
    
    var matchingInfo: JSON?
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var profileImageView: UIImageView!

    @IBOutlet var coverView: UIView!
    
    @IBOutlet var mainInfoView: UIView!
    @IBOutlet var positionsUiView: UIView!
    @IBOutlet var positionsTableView: UITableView!
 
    @IBOutlet weak var positionTableViewHeight: NSLayoutConstraint!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var headlineLabel: UILabel!
    @IBOutlet var summaryText: UITextView!
    
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var contactView: UIView!
    
    @IBOutlet var summaryInfo: UIView!
    
    private var profileUrl: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
//        let screenHeight = screensize.height
        
        let profileImageUrl: String! = matchingInfo!["userInfo"]["photo"].stringValue
        profileUrl = matchingInfo!["profileLink"].stringValue

        nameLabel.text = matchingInfo!["userInfo"]["name"].stringValue
        headlineLabel.text = matchingInfo!["headline"].stringValue
        summaryText.text = matchingInfo!["bio"].stringValue
        emailLabel.text = matchingInfo!["email"].stringValue

        
        if let url = URL(string: profileImageUrl) {
            downloadImage(url: url)
        }
        else {
            print("Error: cannot load url")
        }
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height/2
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.borderWidth = 5
        profileImageView.clipsToBounds = true

        mainInfoView.layer.cornerRadius = 5
        contactView.layer.cornerRadius = 5
        

        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        positionsTableView.delegate = self
        positionsTableView.dataSource = self
        
        
        positionsTableView.rowHeight = 106
        positionTableViewHeight.constant =  CGFloat(self.matchingInfo!["userJobs"].count*106)
        positionsTableView.estimatedRowHeight = 100
        
        let coverViewHeight = coverView.frame.size.height
        let mainInfoViewHeight = mainInfoView.frame.size.height
        let positionsUiViewHeight = positionsUiView.frame.size.height
        let contactViewHeight = contactView.frame.size.height
        let summaryInfoViewHeight = summaryInfo.frame.size.height
        let contentHeight = coverViewHeight + mainInfoViewHeight + positionsUiViewHeight + contactViewHeight + summaryInfoViewHeight
        
        scrollView.contentSize = CGSize(width: screenWidth, height: contentHeight)

    }
    //MARK: Actions
    
    
    @IBAction func openURL (sender: AnyObject){
        if let url = NSURL(string: self.profileUrl){
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchingInfo!["userJobs"].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:CompanyInfoTableCell = self.positionsTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! CompanyInfoTableCell
        
        // set the text from the data model

        cell.companyName.text = self.matchingInfo!["userJobs"][indexPath.row]["companyName"].stringValue
        cell.position.text = self.matchingInfo!["userJobs"][indexPath.row]["title"].stringValue
        let startDate = self.matchingInfo!["userJobs"][indexPath.row]["dateStart"].stringValue
        let endDate : String
        if (self.matchingInfo!["userJobs"][indexPath.row]["dateEnd"] != JSON.null){
            endDate = self.matchingInfo!["userJobs"][indexPath.row]["dateEnd"].stringValue
        }
        else {
            endDate = "Present"
        }
        cell.startDate.text = startDate + "-" + endDate
        cell.location.text = self.matchingInfo!["userJobs"][indexPath.row]["location"].stringValue
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }

    func addShadow(outerView: UIView!){
        outerView.clipsToBounds = false
        outerView.layer.shadowColor = UIColor.black.cgColor
        outerView.layer.shadowOpacity = 1
        outerView.layer.shadowOffset = CGSize.zero
        outerView.layer.shadowPath = UIBezierPath(rect: outerView.bounds).cgPath
    }
    
    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.profileImageView.contentMode = UIViewContentMode.scaleAspectFill
                
                self.profileImageView.image = UIImage(data: data)
                
            }
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }

}

