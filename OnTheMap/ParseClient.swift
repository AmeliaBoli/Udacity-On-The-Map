//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

class ParseClient {
    
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
            
            // iterate through array of dictionaries, each Movie is a dictionary
            for result in results {
                students.append(StudentInformation(dictionary: result))
            }
            
            return students
        }

    }
    
    var students = [StudentInformation]()
    
    // MARK: Methods
    func getLast100UserLocations(completionHandlerForLocations: (success: Bool, errorString: String?) -> Void) {
        let url = NSURL(string: "https://parse.udacity.com/parse/classes/StudentLocation?limit=100&order=-updatedAt")!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                print("there is an error \(error?.localizedDescription)")
                completionHandlerForLocations(success: false, errorString: error?.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("there is an error status code")
                completionHandlerForLocations(success: false, errorString: "statusCode")
                return
            }
            
            guard let data = data else {
                print("there is an error with the data")
                completionHandlerForLocations(success: false, errorString: "data")
                return
            }
            
            var parsedData: AnyObject?
            
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("there is an error parsedData")
                completionHandlerForLocations(success: false, errorString: "parsedData")
            }
            
            guard let locations = parsedData?["results"] as? [[String: AnyObject]] else {
                print("there is an error results")
                completionHandlerForLocations(success: false, errorString: "results")
                return
            }
            
//            for location in locations {
//                guard let firstName = location["firstName"] as? String,
//                let lastName = location["lastName"] as? String,
//                let latitude = location["latitude"] as? Double,
//                let longitude = location["longitude"] as? Double,
//                    let mediaURL = location["mediaURL"] as? String else {
//                        print("there is an error locations")
//                        completionHandlerForLocations(success: false, errorString: "locations")
//                        return
//                }
            
            self.students = StudentInformation.studentsFromResults(locations)
            //StudentInformation(firstName: firstName, lastName: lastName, latitude: latitude, longitude: longitude, mediaURL: mediaURL)
                //self.students.append(student)
            //}
                        
            completionHandlerForLocations(success: true, errorString: nil)
        }
        task.resume()
    }
    
    func postLocation(mapString: String, mediaURL: String, latitude: Double, longitude: Double, completionHandlerForPostingLocations: (success: Bool, errorString: String?) -> Void) {
        let url = NSURL(string: "https://parse.udacity.com/parse/classes/StudentLocation")!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        
        request.addValue("\(self.parseApplicationID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(self.restAPIKey)", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "{\"uniqueKey\": \"\(udacitySession.accountKey!)\", \"firstName\": \"\(udacitySession.firstName!)\", \"lastName\": \"\(udacitySession.lastName!)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}"
        request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                print("there is an error \(error?.localizedDescription)")
                completionHandlerForPostingLocations(success: false, errorString: (error?.localizedDescription)!)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("there is an error status code")
                completionHandlerForPostingLocations(success: false, errorString: "statusCode")
                return
            }
            
            guard let data = data else {
                print("there is an error with the data")
                completionHandlerForPostingLocations(success: false, errorString: "data")
                return
            }
            
            var parsedData: AnyObject?
            
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("there is an error parsing")
                completionHandlerForPostingLocations(success: false, errorString: "parsing")
                return
            }
            
            guard let creationDate = parsedData?["createdAt"],
                let objectID = parsedData?["objectId"] else {
                    print("there is an error createdAt/objectId")
                    completionHandlerForPostingLocations(success: false, errorString: "createdAt/objectId")
                    return
            }
            completionHandlerForPostingLocations(success: true, errorString: nil)
        }
        task.resume()
    }
}
