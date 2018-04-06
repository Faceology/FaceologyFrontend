//
//  RestClient.swift
//  Faceology
//
//  Created by Tianyi Zheng on 4/5/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
import SwiftClient

class RestClient: NSObject {
    let baseUrl: String = "http://ec2-34-203-205-241.compute-1.amazonaws.com"
    
    func connect() -> (Any, URLSession) {
        guard let url = URL(string: baseUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        return (urlRequest, session)
    }
    
    func postLinkedInInformation(urlRequest: Any, session: URLSession, dic: Dictionary<String, String>){
        var returnData: String = ""
        let addUrl: String = baseUrl + "/add_object"
        guard let guardAddURL = URL(string: addUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        var addUrlRequest = URLRequest(url: guardAddURL)
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        addUrlRequest.httpMethod = "POST"
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
            addUrlRequest.httpBody = jsonData
        } catch {
            print("Error: cannot create JSON from todo")
            fatalError("Something went wrong!")
        }
    }
}
