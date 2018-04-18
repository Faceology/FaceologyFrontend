//
//  RestClient.swift
//  Faceology
//
//  Created by Tianyi Zheng on 4/5/18.
//  Copyright © 2018 Tianyi Zheng. All rights reserved.
//

import UIKit
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
    
    func getObjects(previousIds: Any, eventKey: String, image: String, completion:@escaping (Any?)->()){
        var returnData: Any? = nil
        let addUrl: String = baseUrl + "/api/userInfo"
        guard let guardAddURL = URL(string: addUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        
        var addUrlRequest = URLRequest(url: guardAddURL)
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addUrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        addUrlRequest.httpMethod = "PUT"
        
        var dic: JSON = JSON()
        dic["previousIds"] = JSON(previousIds)
        
        dic["eventKey"] = JSON(eventKey)
        dic["image"] = JSON(image)

        do {
            try addUrlRequest.httpBody = dic.rawData() as Data
        }
        catch {
            print("Error: could not add url request")
        }
        
        let task = session.dataTask(with: addUrlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("ERROR ERROR ERROR!!!!!!")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            print("data")
//            print(data)
            returnData = data
            completion(JSON(returnData))
        }
        task.resume()
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
            print("Error: could not add url request")
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
            
        }
        task.resume()
    }
    
    func getEventName(eventKey: String, completion:@escaping (Any?)->()){
        var returnData: Any? = nil
        let getUrl: String = baseUrl + "/api/event" + "?eventKey=\(eventKey)"
        guard let guardGetUrl = URL(string: getUrl) else {
            print("Error: cannot create URL")
            fatalError("Something went wrong!")
        }
        
        var getUrlRequest = URLRequest(url: guardGetUrl)
        getUrlRequest.httpMethod = "GET"
        
        let task = session.dataTask(with: getUrlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("ERROR ERROR ERROR!!!!!!")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            returnData = data
            completion(JSON(returnData))
        }
        task.resume()
    }
    
}
