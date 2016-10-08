//
//  StudentLocationModel.swift
//  OnTheMap
//
//  Created by Amelia Boli on 10/6/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

struct StudentInformation   {
    
    // MARK: Properties
    var firstName: String
    var lastName: String
    var latitude: Double
    var longitude: Double
    var mediaURL: String
    
    // MARK: Initializers
    init(dictionary: [String:AnyObject]) {
        guard let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let latitude = dictionary["latitude"] as? Double,
            let longitude = dictionary["longitude"] as? Double,
            let mediaURL = dictionary["mediaURL"] as? String else {
                #if DEBUG
                    print("There was an error extracting the data to create a Student")
                #endif
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

