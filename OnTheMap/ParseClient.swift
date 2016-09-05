//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

class ParseClient: Networking {
    
    // MARK: Singleton
    class func sharedInstance() -> ParseClient {
        struct Singleton {
            static var sharedInstance = ParseClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Properties
    let parseApplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    let restAPIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    
    let session = NSURLSession.sharedSession()
    let udacitySession = UdacityClient.sharedInstance()
    
    var objectID: String? = nil
    
    // Constants
    struct Constants {
        static let Scheme = "https"
        static let Host = "parse.udacity.com"
        static let Path = "/parse/classes"
    }
    
    // Methods
    struct Methods {
        static let StudentLocation = "/StudentLocation"
        //static var Users = "/users/{accountKey}"
    }
    
    // Parameter Keys
    struct ParameterKeys {
        static let Limit = "limit"
        static let Order = "order"
    }
    
    // Parameter Values
    struct ParameterValues {
        static let NumberOfEntries = 100
        static let ReverseChronological = "-updatedAt"
    }
    
    // JSON Body Keys
    struct JSONBodyKeys {
        static let UniqueKey = "uniqueKey"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let MapString = "mapString"
        static let MediaURL = "mediaURL"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    // MARK: Location Model
    struct StudentInformation   {
        
        // MARK: Properties
        var firstName: String
        var lastName: String
        var latitude: Double
        var longitude: Double
        var mediaURL: String
        
        // MARK: Initializers
        
        // construct a TMDBMovie from a dictionary
        init(dictionary: [String:AnyObject]) {
            guard let firstName = dictionary["firstName"] as? String,
                let lastName = dictionary["lastName"] as? String,
                let latitude = dictionary["latitude"] as? Double,
                let longitude = dictionary["longitude"] as? Double,
                let mediaURL = dictionary["mediaURL"] as? String else {
                    print("There was an error extracting the data to create a Student")
                    self.firstName = ""
                    self.lastName = ""
                    self.latitude = 0
                    self.longitude = 0
                    self.mediaURL = ""
                    return
            }
            
            self.firstName = firstName
            self.lastName = lastName
            self.latitude = latitude
            self.longitude = longitude
            self.mediaURL = mediaURL
        }
        
        static func studentsFromResults(results: [[String:AnyObject]]) -> [StudentInformation] {
            
            var students = [StudentInformation]()
            for result in results {
                students.append(StudentInformation(dictionary: result))
            }
            return students
        }
    }
    
    var students = [StudentInformation]()
    
    // MARK: Methods
    func getLast100UserLocations(completionHandlerForLocations: (success: Bool, errorString: NSError?) -> Void) {
        let paramaters: [String: AnyObject] = [ParameterKeys.Limit: ParameterValues.NumberOfEntries, ParameterKeys.Order: ParameterValues.ReverseChronological]
        
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.StudentLocation, parameters: paramaters)
        
        let request = NSMutableURLRequest(URL: url)
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                print("There was an error with taskForHTTPMethod")
                completionHandlerForLocations(success: false, errorString: error)
                return
            }
            
            self.deserializeJSONWithCompletionHandler(result) { (result, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForLocations(success: false, errorString: error)
                    return
                }
                
                guard let locations = result["results"] as? [[String: AnyObject]] else {
                    print("There was an error with results key in \(result)")
                    let nsError = NSError(domain: "getLast100UserLocations", code: 1, userInfo: nil)
                    completionHandlerForLocations(success: false, errorString: nsError)
                    return
                }
                self.students = StudentInformation.studentsFromResults(locations)
                
                completionHandlerForLocations(success: true, errorString: nil)
            }
        }
    }
    
    func fetchLocationForUser(completionHandlerForFetchLocationForUser: (success: Bool, locationExists: Bool?, errorString: String?) -> Void) {
        guard let accountKey = udacitySession.accountKey else {
            let errorString = "There was a problem fetching the user location: no account key"
            print(errorString)
            completionHandlerForFetchLocationForUser(success: false, locationExists: nil, errorString: errorString)
            return
        }
        
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.StudentLocation, parameters: ["where": "{\"uniqueKey\": \"\(accountKey)\"}"])
        
        let request = NSMutableURLRequest(URL: url)
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        self.taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                print("There was an error with fetching the user location")
                completionHandlerForFetchLocationForUser(success: false, locationExists: nil, errorString: error?.localizedDescription)
                return
            }
            
            self.deserializeJSONWithCompletionHandler(result) { (result, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForFetchLocationForUser(success: false, locationExists: nil, errorString: error?.localizedDescription)
                    return
                }
                                
                guard let results = result["results"] as? [[String: AnyObject]] else {
                    let errorString = "There was a problem with the results received for an existing location."
                    print(errorString)
                    completionHandlerForFetchLocationForUser(success: false, locationExists: nil, errorString: errorString)
                    return
                }
                
                if results.isEmpty {
                    completionHandlerForFetchLocationForUser(success: true, locationExists: false, errorString: nil)
                    return
                }
               
                guard let objectID = results.last?["objectId"] as? String else {
                    let errorString = "There was a problem fetching the user location: results/objectID key in \(result)"
                    print(errorString)
                    completionHandlerForFetchLocationForUser(success: false, locationExists: nil, errorString: errorString)
                    return
                }
                
                self.objectID = objectID
                completionHandlerForFetchLocationForUser(success: true, locationExists: true, errorString: nil)
            }
        }
    }
    
    func postLocation(mapString: String, mediaURL: String, latitude: Double, longitude: Double, completionHandlerForPostingLocations: (success: Bool, errorString: NSError?) -> Void) {
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: Methods.StudentLocation, parameters: nil)
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDict: [String: AnyObject] = [JSONBodyKeys.UniqueKey: udacitySession.accountKey!, JSONBodyKeys.FirstName: udacitySession.firstName!, JSONBodyKeys.LastName: udacitySession.lastName!, JSONBodyKeys.MapString: mapString, JSONBodyKeys.MediaURL: mediaURL, JSONBodyKeys.Latitude: latitude, JSONBodyKeys.Longitude: longitude]
        
        let jsonBody: NSData
        do {
            jsonBody = try NSJSONSerialization.dataWithJSONObject(bodyDict, options: .PrettyPrinted)
        } catch {
            return
        }
        
        request.HTTPBody = jsonBody
        
        self.taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                print("There was an error with taskForHTTPMethod")
                completionHandlerForPostingLocations(success: false, errorString: error)
                return
            }
            
            self.deserializeJSONWithCompletionHandler(result) { (result, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForPostingLocations(success: false, errorString: error)
                    return
                }
                
                guard let creationDate = result?["createdAt"],
                    let objectID = result?["objectId"] else {
                        let errorString = "There is an error grabbing the creation date or object ID"
                        print(errorString)
                         let nsError = NSError(domain: "postLocation", code: 1, userInfo: nil)
                        completionHandlerForPostingLocations(success: false, errorString: nsError)
                        return
                }
                completionHandlerForPostingLocations(success: true, errorString: nil)
            }   
        }
    }
    
    func updateLocation(mapString: String, mediaURL: String, latitude: Double, longitude: Double, completionHandlerForUpdateLocation: (success: Bool, errorString: NSError?) -> Void) {
        guard let objectID = objectID else {
            let errorString = "There was no object id while trying to update the location"
            print(errorString)
            let nsError = NSError(domain: "updateLocation", code: 1, userInfo: nil)
            completionHandlerForUpdateLocation(success: false, errorString: nsError)
            return
        }
        let pathExtension = Methods.StudentLocation + "/" + objectID
        
        let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: pathExtension, parameters: nil)
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "PUT"
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDict: [String: AnyObject] = [JSONBodyKeys.UniqueKey: udacitySession.accountKey!, JSONBodyKeys.FirstName: udacitySession.firstName!, JSONBodyKeys.LastName: udacitySession.lastName!, JSONBodyKeys.MapString: mapString, JSONBodyKeys.MediaURL: mediaURL, JSONBodyKeys.Latitude: latitude, JSONBodyKeys.Longitude: longitude]
        
        let jsonBody: NSData
        do {
            jsonBody = try NSJSONSerialization.dataWithJSONObject(bodyDict, options: .PrettyPrinted)
        } catch {
            return
        }
        
        request.HTTPBody = jsonBody
        
        self.taskForHTTPMethod(request) { (result, error) in
            guard error == nil else {
                print("There was an error with taskForHTTPMethod")
                completionHandlerForUpdateLocation(success: false, errorString: error)
                return
            }
            
            self.deserializeJSONWithCompletionHandler(result) { (result, error) in
                guard error == nil else {
                    print("There was an error with deserializing the JSON")
                    completionHandlerForUpdateLocation(success: false, errorString: error)
                    return
                }
                
                guard let updatedAt = result?["updatedAt"] else {
                        let errorString = "There is an error grabbing the updated date"
                        print(errorString)
                        let nsError = NSError(domain: "updateLocation", code: 1, userInfo: nil)
                        completionHandlerForUpdateLocation(success: false, errorString: nsError)
                        return
                }
                completionHandlerForUpdateLocation(success: true, errorString: nil)
            }
        }
    }

    func logout() {
        objectID = nil
    }
}
