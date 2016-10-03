//
//  CreatePinViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import MapKit

class CreatePinViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, AlertController {

    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var mediaURLTextField: UITextField!
    @IBOutlet weak var whatAreYouStudyingLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewCoveringMap: UIView!
    @IBOutlet weak var findLocationButton: UIButton!
    @IBOutlet weak var submitLocationButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var maskingView: UIView!

    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitLocationButton.layer.cornerRadius = 10
        submitLocationButton.clipsToBounds = true
        
        findLocationButton.layer.cornerRadius = 10
        findLocationButton.clipsToBounds = true
    }
    
    @IBAction func findLocation(sender: UIButton?) {        
        locationTextField.resignFirstResponder()
        
        if locationTextField.text == "" {
            createAlertControllerWithNoActions(nil, message: "No location was provided.")
        }
        
        activityIndicator.startAnimating()
        maskingView.hidden = false
        
        CLGeocoder().geocodeAddressString(locationTextField.text!) { (placemarks, error) in
            guard error == nil else {
                print("There was an error with geocoding the location: \(error?.localizedDescription)")
                
                self.locationTextField.text = ""
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.maskingView.hidden = true
                    self.createAlertControllerWithNoActions(nil, message: "There was an error finding your location")
                }
                
                return
            }
            
            guard let placemarks = placemarks else {
                print("there is an error placemark")
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.maskingView.hidden = true
                }

                return
            }
            
            self.latitude = placemarks[0].location?.coordinate.latitude
            self.longitude = placemarks[0].location?.coordinate.longitude
            
            let latitude = CLLocationDegrees(floatLiteral: self.latitude!)
            let longitude = CLLocationDegrees(floatLiteral: self.longitude!)
            
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            dispatch_async(dispatch_get_main_queue()) {
                self.locationTextField.hidden = true
                self.mediaURLTextField.hidden = false
                self.whatAreYouStudyingLabel.hidden = false
                self.viewCoveringMap.hidden = true
                self.findLocationButton.hidden = true
                self.submitLocationButton.hidden = false
                
                self.topView.backgroundColor = UIColor(red: 65/255, green: 117/255, blue: 164/255, alpha: 1.0)
                self.bottomView.alpha = 0.5
                self.cancelButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                
                self.mapView.addAnnotation(annotation)
                
                // Zooming code based on this StackOverflow post: http://stackoverflow.com/questions/4189621/setting-the-zoom-level-for-a-mkmapview
                let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 30000, 30000)
                let adjustedRegion = self.mapView.regionThatFits(viewRegion)
                self.mapView.setRegion(adjustedRegion, animated: false)
                
                self.activityIndicator.stopAnimating()
                self.maskingView.hidden = true
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pinView?.canShowCallout = true
            pinView?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.pinTintColor = UIColor.blueColor()
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    @IBAction func submitLocation(sender: UIButton?) {
        mediaURLTextField.resignFirstResponder()
        
        guard let urlString = self.mediaURLTextField.text where !urlString.isEmpty else {
            createAlertControllerWithNoActions(nil, message: "There was no webpage listed.")
            return
        }
        
        let url: NSURL
        do {
            url = try urlString.createValidURL()
        } catch String.UrlErrors.invalidString {
            print("invalidString")
            createAlertControllerWithNoActions(nil, message: "I can't seem to make a valid URL from what was inputted")
            return
        } catch String.UrlErrors.invalidComponents {
            print("invalidComponents")
            createAlertControllerWithNoActions(nil, message: "I can't seem to make a valid URL from what was inputted")
            return
        } catch String.UrlErrors.noDataDetector {
            print("noDataDetector")
            createAlertControllerWithNoActions(nil, message: "There was an internal error")
            return
        } catch String.UrlErrors.noHost {
            print("noHost")
            createAlertControllerWithNoActions(nil, message: "There seems to be no host- https://")
            return
        } catch String.UrlErrors.wrongNumberOfLinks {
            print("wrongNumberOfLinks")
            showAlertOnMain("You might be missing the domain- .com")
            return
        } catch String.UrlErrors.invalidCharacter(let character) {
            print("invalidCharacter")
            createAlertControllerWithNoActions(nil, message: "There was a character in the URL that is not allowed: \(character)")
            return
        } catch {
            print("some other error")
            createAlertControllerWithNoActions(nil, message: "Hmm...something went wrong")
            return
        }

        let udacitySession = UdacityClient.sharedInstance()
        
        activityIndicator.startAnimating()
        maskingView.hidden = false
        
        udacitySession.fetchUserData() { (success, error) in
            guard error == nil && success == true else {
                print("there is an error fetchUserData")
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.maskingView.hidden = true
                }
                return
            }
            
            let parseSession = ParseClient.sharedInstance()
            
            if parseSession.objectID == nil {
                
                parseSession.postLocation(self.locationTextField.text!, mediaURL: url.absoluteString, latitude: self.latitude!, longitude: self.longitude!) { (success, error) in
                    guard error == nil && success == true else {
                        print("There is an error with postLocation")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.activityIndicator.stopAnimating()
                            self.maskingView.hidden = true
                            self.createAlertControllerWithNoActions(nil, message: error?.localizedDescription)
                        }
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.maskingView.hidden = true
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
                
            } else {
                parseSession.updateLocation(self.locationTextField.text!, mediaURL: url.absoluteString, latitude: self.latitude!, longitude: self.longitude!) { (sucess, error) in
                    guard error == nil && success == true else {
                        print("There is an error with updateLocation")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.activityIndicator.stopAnimating()
                            self.maskingView.hidden = true
                            self.createAlertControllerWithNoActions(nil, message: error?.localizedDescription)
                        }
                        return
                    }
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.maskingView.hidden = true
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {        
        if textField == locationTextField {
            findLocation(nil)
        } else if textField == mediaURLTextField {
            submitLocation(nil)
        }
        
        return true
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}
