//
//  NetworkingProtocol.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/30/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

protocol Networking {
    func substituteKeyInMethod(method: String, key: String, value: String) -> String?
    func urlFromComponents(scheme scheme: String, host: String, path: String?, withPathExtension: String?, parameters: [String:AnyObject]?) -> NSURL
    func taskForHTTPMethod(request: NSURLRequest, completionHandlerForMethod: (result: NSData!, error: NSError?) -> Void) -> NSURLSessionDataTask
     func deserializeJSONWithCompletionHandler(data: NSData, completionHandlerForDeserializeJSON: (result: AnyObject!, error: NSError?) -> Void)
     func sendError(error: String, domain: String, completionHandlerForSendError: (result: NSData!, error: NSError?) -> Void)
}

extension Networking {
    // MARK: Protocol Methods
    func substituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    func urlFromComponents(scheme scheme: String, host: String, path: String?, withPathExtension: String?, parameters: [String:AnyObject]?) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = scheme
        components.host = host
        
        if let path = path {
            components.path = path + (withPathExtension ?? "")
        }
        
        components.queryItems = [NSURLQueryItem]()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                let queryItem = NSURLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        guard let url = components.URL else {
            print("There was a problem creating the URL")
            return NSURL()
        }
        
        return url
    }

    func taskForHTTPMethod(request: NSURLRequest, completionHandlerForMethod: (result: NSData!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            let domain = "taskForHTTPMethod"
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                var errorString = "There was an error with your request: \(error)"
                if error?.code == -1001 {
                    errorString = "We couldn't log you in. There seems to be a problem with your network connection."
                }
                self.sendError(errorString, domain: domain, completionHandlerForSendError: completionHandlerForMethod)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode else {
                self.sendError("There seems to be no status code", domain: domain, completionHandlerForSendError: completionHandlerForMethod)
                return
            }
            
            guard statusCode >= 200 && statusCode <= 299 else {
                var errorString = "Your request returned a status code other than 2xx!: \(statusCode)"
                
                if statusCode == 403 {
                    errorString = "We couldn't log you in. Your username or password seem incorrect."
                }
                
                self.sendError(errorString, domain: domain, completionHandlerForSendError: completionHandlerForMethod)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.sendError("No data was returned by the request!", domain: domain, completionHandlerForSendError: completionHandlerForMethod)
                return
            }
            
            completionHandlerForMethod(result: data, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        return task
    }
    
    func deserializeJSONWithCompletionHandler(data: NSData, completionHandlerForDeserializeJSON: (result: AnyObject!, error: NSError?) -> Void) {
        var parsedData: AnyObject?
        
        do {
            parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            sendError("There is an error deserializing the JSON file", domain: "deserializeJSON", completionHandlerForSendError: completionHandlerForDeserializeJSON)
        }
        completionHandlerForDeserializeJSON(result: parsedData, error: nil)
    }
    
    // MARK: Extension Helpers
    func sendError(error: String, domain: String, completionHandlerForSendError: (result: NSData!, error: NSError?) -> Void) {
        print(error)
        let userInfo = [NSLocalizedDescriptionKey : error]
        let nsError = NSError(domain: domain, code: 1, userInfo: userInfo)
        completionHandlerForSendError(result: nil, error: nsError)
    }
}
