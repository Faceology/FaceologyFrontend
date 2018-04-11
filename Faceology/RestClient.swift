//
//  RestClient.swift
//  Faceology
//
//  Created by Tianyi Zheng on 4/5/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import SwiftClient
import SwiftyJSON

class RestClient: NSObject {
    let baseUrl: String = "http://ec2-34-203-205-241.compute-1.amazonaws.com:5000"
    
    var urlRequest: Any
    var session: URLSession
    
    override init(){
        guard let url = URL(string: baseUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        self.urlRequest = URLRequest(url: url)
        self.session = URLSession.shared
    }
    
    func postLinkedInInformation(dic: JSON){
        let addUrl: String = baseUrl + "/api/userInfo"
        guard let guardAddURL = URL(string: addUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        var addUrlRequest = URLRequest(url: guardAddURL)
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        addUrlRequest.httpMethod = "POST"

        do {
         try addUrlRequest.httpBody = dic.rawData() as Data
        }
        catch {
            print("Error")
        }
        
        let task = session.dataTask(with: addUrlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST")
                print(error)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
//            // parse the result as JSON, since that's what the API provides
//            do {
//                guard let receivedData = try JSONSerialization.jsonObject(with: responseData,
//                                                                          options: []) as? [String: Any] else {
//                                                                            print("Could not get JSON from responseData as dictionary")
//                                                                            return
//                }
//                guard let dataID = receivedData["id"] as? String else {
//                    print("Could not get ID as int from JSON")
//                    return
//                }
//                print("The ID is: \(dataID)")
//                returnData = dataID
//                return
//            } catch  {
//                print("error parsing response from POST")
//                return
//            }
        }
        task.resume()
        
    }
}
