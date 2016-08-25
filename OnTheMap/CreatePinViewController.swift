//
//  CreatePinViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import MapKit

class CreatePinViewController: UIViewController {

    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var mediaURL: UITextField!
    
    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func findLocation(sender: UIButton) {
        CLGeocoder().geocodeAddressString(locationTextField.text!) { (placemarks, error) in
            guard error == nil else {
                print("there is an error \(error?.localizedDescription)")
                return
            }
            
            guard let placemarks = placemarks else {
                print("there is an error placemark")
                return
            }
            
            self.latitude = placemarks[0].location?.coordinate.latitude
            self.longitude = placemarks[0].location?.coordinate.longitude
                        
            // Grab user data
            let udacitySession = UdacityClient.sharedInstance()
            
            udacitySession.fetachUserData() { (success, error) in
                guard error == nil && success == true else {
                    print("there is an error fetchUserData")
                    return
                }
                
                let parseSession = ParseClient.sharedInstance()
                
                // FIXME: grab location description from placemark
                parseSession.postLocation(self.locationTextField.text!, mediaURL: self.mediaURL.text!, latitude: self.latitude!, longitude: self.longitude!) { (success, error) in
                    guard error == nil && success == true else {
                        print("there is an error postLocation")
                        return
                    }
                    
                    parseSession.getLast100UserLocations() { (success, error) in
                        if success == true {
                            print(parseSession.students)
                        } else {
                            print(error)
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
