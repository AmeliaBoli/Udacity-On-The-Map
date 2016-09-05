//
//  CreatePin.swift
//  OnTheMap
//
//  Created by Amelia Boli on 9/5/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

protocol CreatePin {
    func checkForExistingLocation()
    func alertUserToExistingLocation()
    func segueToCreatePinVC()
}

extension CreatePin where Self: UIViewController {
    func checkForExistingLocation() {
        let parseSession = ParseClient.sharedInstance()
        
        if parseSession.objectID != nil {
            alertUserToExistingLocation()
            return
        }
        
        ParseClient.sharedInstance().fetchLocationForUser() { (success, locationExists, error) in
            if error != nil {
                print(error)
                return
            } else if success == false {
                print("There is no error with retrieving previous locations")
                return
            } else if let locationExists = locationExists {
                if locationExists {
                    dispatch_async(dispatch_get_main_queue()) { self.alertUserToExistingLocation() }
                    return
                } else {
                    dispatch_async(dispatch_get_main_queue()) { self.segueToCreatePinVC() }
                    return
                }
            }
        }
    }
    
    func alertUserToExistingLocation() {
        let alert = UIAlertController(title: "You Already Exist!", message: "It looks like you already have a location posted. Would you like to update it?", preferredStyle: .Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: { alert in self.segueToCreatePinVC() })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alert in return false })
        
        alert.addAction(yesAction)
        alert.addAction(cancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func segueToCreatePinVC() {
        let createPinVC = self.storyboard?.instantiateViewControllerWithIdentifier("createPin") as! CreatePinViewController
        self.presentViewController(createPinVC, animated: true, completion: nil)
    }
}
