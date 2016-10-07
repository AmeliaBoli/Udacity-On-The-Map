//
//  StudentLocationsArray.swift
//  OnTheMap
//
//  Created by Amelia Boli on 10/6/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

class StudentLocationsArray {
    
    static var sharedInstance = StudentLocationsArray()
    
    private var students = [StudentInformation]()
    
    func setStudents(students: [StudentInformation]) {
        self.students = students
    }
    
    func fetchStudents() -> [StudentInformation] {
        return students
    }
}
