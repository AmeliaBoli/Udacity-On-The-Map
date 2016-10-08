//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation
import FBSDKLoginKit

class UdacityClient: Networking {

    // MARK: Singleton
    static var sharedInstance = UdacityClient()
    private init() {}
    
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
    func getSessionID(username: String?, password: String?, completionHandlerForSession: (success: Bool, errorString: String?) -> Void) {

        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.Session, parameters: nil)

        let request = NSMutableURLRequest(URL: url)

        request.HTTPMethod = "POST"

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var bodyDict: [String:AnyObject] = [:]

        if let username = username, let password = password {
            bodyDict = [JSONBodyKeys.Udacity: [JSONBodyKeys.Username: username, JSONBodyKeys.Password: password]]
        } else if let token = FBSDKAccessToken.currentAccessToken().tokenString {
            bodyDict = ["facebook_mobile": ["access_token": token]]
        } else {
            let errorString = "There was an error creating the body for get session ID"
            #if DEBUG
                print(errorString)
            #endif
            completionHandlerForSession(success: false, errorString: errorString)
        }

        let jsonBody: NSData
        do {
            jsonBody = try NSJSONSerialization.dataWithJSONObject(bodyDict, options: .PrettyPrinted)
        } catch {
            return
        }

        request.HTTPBody = jsonBody

        self.taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                guard let error = error else {
                    let errorString = "There is an internal problem: get session id error"
                    #if DEBUG
                        print("errorString")
                    #endif
                    completionHandlerForSession(success: false, errorString: errorString)
                    return
                }
                completionHandlerForSession(success: false, errorString: error.localizedDescription)
                return
            }

            let data = result.subdataWithRange(NSMakeRange(5, (result.length) - 5))

            self.deserializeJSONWithCompletionHandler(data) { (data, error) in
                guard error == nil else {
                    #if DEBUG
                        print("There was an error with deserializing the JSON")
                    #endif
                    completionHandlerForSession(success: false, errorString: error?.localizedDescription)
                    return
                }

                guard let session = data?["session"] as? [String: AnyObject],
                    let id = session["id"] as? String else {
                        #if DEBUG
                            print("there is an error session/id")
                        #endif
                        completionHandlerForSession(success: false, errorString: "session/id")
                        return
                }

                guard let account = data?["account"] as? [String: AnyObject],
                    let key = account["key"] as? String else {
                        #if DEBUG
                            print("there is an error account/key")
                        #endif
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
                #if DEBUG
                    print("There is a problem with the account key and/or method to fetch user data")
                #endif
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
                    #if DEBUG
                        print("There was an error with deserializing the JSON")
                    #endif
                    completionHandlerForFetchUserData(success: false, errorString: error?.localizedDescription)
                    return
                }


                guard let user = data?["user"] as? [String: AnyObject],
                    let firstName = user["first_name"] as? String,
                    let lastName = user["last_name"] as? String else {
                        #if DEBUG
                            print("there is an error user/first/lastname")
                        #endif
                        completionHandlerForFetchUserData(success: false, errorString: "user/first/last_name")
                        return
                }

                self.firstName = firstName
                self.lastName = lastName
                completionHandlerForFetchUserData(success: true, errorString: nil)
            }
        }
    }

    func logout(completionHandlerForLogout: (success: Bool, errorString: String?) -> Bool) {
        // MARK: Clear Model
        sessionID = nil
        accountKey = nil
        firstName = nil
        lastName = nil

        // MARK: Delete Session ID with Udacity Server
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.Session, parameters: nil)

        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "DELETE"

        var xsrfCookie: NSHTTPCookie? = nil
        let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
            break
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }

        taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                completionHandlerForLogout(success: false, errorString: error?.localizedDescription)
                return
            }

            let data = result.subdataWithRange(NSMakeRange(5, (result.length) - 5))

            self.deserializeJSONWithCompletionHandler(data) { (data, error) in
                guard error == nil else {
                    #if DEBUG
                        print("There was an error with deserializing the JSON")
                    #endif
                    completionHandlerForLogout(success: false, errorString: error?.localizedDescription)
                    return
                }

                guard let session = data?["session"] as? [String: AnyObject],
                    let _ = session["id"] as? String,
                    let _ = session["expiration"] as? String else {
                        let errorString = "There was an error logging out: session/id/expiration keys."
                        #if DEBUG
                            print(errorString)
                        #endif
                        completionHandlerForLogout(success: false, errorString: errorString)
                        return
                }
                completionHandlerForLogout(success: true, errorString: nil)
            }
        }
    }
}
