//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

class UdacityClient {
    
    // MARK: Singleton
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var sharedInstance = UdacityClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Properties
    
    let session = NSURLSession.sharedSession()

    // User info
    var sessionID: String? = nil
    var accountKey: String? = nil
    var firstName: String? = nil
    var lastName: String? = nil
    
    
    // MARK: Methods
    
    func getSessionID(username: String, password: String, completionHandlerForSession: (success: Bool, errorSTring: String?) -> Void) {
        
        let url = NSURL(string: "https://www.udacity.com/api/session")!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}"
        
        request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                print("there is an error \(error?.localizedDescription)")
                completionHandlerForSession(success: false, errorSTring: "\(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("there is an error status code")
                completionHandlerForSession(success: false, errorSTring: "status code")
                return
            }
            
            guard let data = data?.subdataWithRange(NSMakeRange(5, (data?.length)! - 5)) else {
                print("there is an error data")
                completionHandlerForSession(success: false, errorSTring: "data")
                return
            }
            
            var parsedData: AnyObject?
            
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("there is an error parsing")
                completionHandlerForSession(success: false, errorSTring: "parsing")
                return
            }
            
            guard let session = parsedData?["session"] as? [String: AnyObject],
                let id = session["id"] as? String else {
                    print("there is an error session/id")
                    completionHandlerForSession(success: false, errorSTring: "session/id")
                    return
            }
            
            guard let account = parsedData?["account"] as? [String: AnyObject],
                let key = account["key"] as? String else {
                    print("there is an error account/key")
                    completionHandlerForSession(success: false, errorSTring: "account/key")
                    return
            }
            
            self.sessionID = id
            self.accountKey = key
            completionHandlerForSession(success: true, errorSTring: nil)
        }
        
        task.resume()

    }
    
    func fetachUserData(completionHandlerForFetchUserData: (success: Bool, errorString: String?) -> Void) {
        let url = NSURL(string: "https://www.udacity.com/api/users/\(accountKey!)")!
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                print("there is an error \(error?.localizedDescription)")
                completionHandlerForFetchUserData(success: false, errorString: "\(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("there is an error status code")
                completionHandlerForFetchUserData(success: false, errorString: "status code")
                return
            }
            
            guard let data = data?.subdataWithRange(NSMakeRange(5, (data?.length)! - 5)) else {
                print("there is an error data")
                completionHandlerForFetchUserData(success: false, errorString: "data")
                return
            }
            
            var parsedData: AnyObject?
            
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("there is an error parsing")
                completionHandlerForFetchUserData(success: false, errorString: "parsing")
                return
            }
            
            guard let user = parsedData?["user"] as? [String: AnyObject],
            let firstName = user["first_name"] as? String,
                let lastName = user["last_name"] as? String else {
                    print("there is an error user/first/lastname")
                    completionHandlerForFetchUserData(success: false, errorString: "user/first/last_name")
                    return
            }
            
            self.firstName = firstName
            self.lastName = lastName
            completionHandlerForFetchUserData(success: true, errorString: nil)
        }
        task.resume()
    }
}
