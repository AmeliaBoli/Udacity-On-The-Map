//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

class UdacityClient: Networking {
    
    // MARK: Singleton
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var sharedInstance = UdacityClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Properties
    let session = NSURLSession.sharedSession()
    
    // Constants
    struct Constants {
        static let Scheme = "https"
        static let Host = "www.udacity.com"
        static let Path = "/api"
    }
    
    // Methods
    struct Methods {
        static let Session = "/session"
        static var Users = "/users/{accountKey}"
    }
    
    // JSON Body Keys
    struct JSONBodyKeys {
        static let Udacity = "udacity"
        static let Username = "username"
        static let Password = "password"
    }

    // User info
    var sessionID: String? = nil
    var accountKey: String? = nil
    var firstName: String? = nil
    var lastName: String? = nil
    
    
    // MARK: Methods
    
    func getSessionID(username: String, password: String, completionHandlerForSession: (success: Bool, errorString: String?) -> Void) {
        
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.Session, parameters: nil)
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDict: [String: AnyObject] = [JSONBodyKeys.Udacity: [JSONBodyKeys.Username: username, JSONBodyKeys.Password: password]]
        
        let jsonBody: NSData
        do {
            jsonBody = try NSJSONSerialization.dataWithJSONObject(bodyDict, options: .PrettyPrinted)
        } catch {
            return
        }
        
        request.HTTPBody = jsonBody
        
        self.taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                completionHandlerForSession(success: false, errorString: error?.localizedDescription)
                return
            }
            
            let data = result.subdataWithRange(NSMakeRange(5, (result.length) - 5))
            
            self.deserializeJSONWithCompletionHandler(data) { (data, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForSession(success: false, errorString: error?.localizedDescription)
                    return
                }
                
                guard let session = data?["session"] as? [String: AnyObject],
                    let id = session["id"] as? String else {
                        print("there is an error session/id")
                        completionHandlerForSession(success: false, errorString: "session/id")
                        return
                }
                
                guard let account = data?["account"] as? [String: AnyObject],
                    let key = account["key"] as? String else {
                        print("there is an error account/key")
                        completionHandlerForSession(success: false, errorString: "account/key")
                        return
                }
                
                self.sessionID = id
                self.accountKey = key
                completionHandlerForSession(success: true, errorString: nil)

            }
        }
    }
    
    func fetchUserData(completionHandlerForFetchUserData: (success: Bool, errorString: String?) -> Void) {
        let methodWithoutAccountKey = Methods.Users
        
        guard let accountKey = accountKey,
            let completeMethod = substituteKeyInMethod(methodWithoutAccountKey, key: "accountKey", value: String(accountKey)) else {
                print("There is a problem with the account key and/or method to fetch user data")
                return
        }
        
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: completeMethod, parameters: nil)
        
        let request = NSURLRequest(URL: url)
        
        taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                completionHandlerForFetchUserData(success: false, errorString: error?.localizedDescription)
                return
            }
            
            let data = result.subdataWithRange(NSMakeRange(5, (result.length) - 5))
            
            self.deserializeJSONWithCompletionHandler(data) { (data, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForFetchUserData(success: false, errorString: error?.localizedDescription)
                    return
                }

                
                guard let user = data?["user"] as? [String: AnyObject],
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
        }
    }
    
    func logout() {
        sessionID = ""
        accountKey = ""
        firstName = ""
        lastName = ""
    }
}
