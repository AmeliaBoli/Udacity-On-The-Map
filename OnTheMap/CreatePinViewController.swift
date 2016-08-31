//
//  CreatePinViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import MapKit

class CreatePinViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {

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
    @IBOutlet weak var geocodeFailedLabel: UILabel!
    @IBOutlet weak var postErrorLabel: UILabel!

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
        
        activityIndicator.startAnimating()
        maskingView.hidden = false
        
        CLGeocoder().geocodeAddressString(locationTextField.text!) { (placemarks, error) in
            guard error == nil else {
                print("There was an error with geocoding the location: \(error?.localizedDescription)")
                
                self.geocodeFailedLabel.hidden = false
                self.locationTextField.text = ""
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.maskingView.hidden = true
                }
                
                return
            }
            
            guard let placemarks = placemarks else {
                print("there is an error placemark")
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
        
        // Grab user data
        
        guard let urlString = self.mediaURLTextField.text else {
            return
        }
        
        let url: NSURL
        do {
            url = try urlString.createValidURL()
        } catch String.UrlErrors.invalidString {
            print("invalidString")
            postErrorLabel.text = "I can't seem to make a valid URL from what was inputted"
            return
        } catch String.UrlErrors.invalidComponents {
            print("invalidComponents")
            postErrorLabel.text = "I can't seem to make a valid URL from what was inputted"
            return
        } catch String.UrlErrors.noDataDetector {
            print("noDataDetector")
            postErrorLabel.text = "There was an internal error"
            return
        } catch String.UrlErrors.noHost {
            print("noHost")
            postErrorLabel.text = "There seems to be no host- https://"
            return
        } catch String.UrlErrors.wrongNumberOfLinks {
            print("wrongNumberOfLinks")
            postErrorLabel.text = "You might be missing the domain- .com"
            return
        } catch String.UrlErrors.invalidCharacter {
            print("invalidCharacter")
            // FIXME: Have the actual bad character pass through to here and add it to the error message to the user
            postErrorLabel.text = "There was a character in the URL that is not allowed"
            return
        } catch {
            print("some other error")
            postErrorLabel.text = "Hmm...something went wrong"
            return
        }

        let udacitySession = UdacityClient.sharedInstance()
        
        udacitySession.fetchUserData() { (success, error) in
            guard error == nil && success == true else {
                print("there is an error fetchUserData")
                
                return
            }
            
            let parseSession = ParseClient.sharedInstance()
            
            // FIXME: grab location description from placemark
            parseSession.postLocation(self.locationTextField.text!, mediaURL: url.absoluteString, latitude: self.latitude!, longitude: self.longitude!) { (success, error) in
                guard error == nil && success == true else {
                    print("There is an error with postLocation")
                    self.geocodeFailedLabel.text = error?.localizedDescription
                    return
                }
                
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }

    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == locationTextField {
            geocodeFailedLabel.hidden = true
        } else if textField == mediaURLTextField {
            postErrorLabel.text = ""
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
