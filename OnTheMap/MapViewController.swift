//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import MapKit
import FBSDKLoginKit

class MapViewController: UIViewController, MKMapViewDelegate, CreatePin, AlertController {

    @IBOutlet weak var mapView: MKMapView!

    let parseSession = ParseClient.sharedInstance()
    var annotations = [MKPointAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMap(nil)
    }

    // MARK: Map Management
    @IBAction func loadMap(sender: UIBarButtonItem?) {
        parseSession.getLast100UserLocations() { (success, error) in
            guard error == nil && success == true else {
                let errorString = error?.localizedDescription
                print(errorString)

                dispatch_async(dispatch_get_main_queue()) {
                    self.alertUserToFailure(errorString!)
                }
                return
            }

            let annotationsToRemove = self.annotations
            self.createMapAnotations()

            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.removeAnnotations(annotationsToRemove)
                self.mapView.addAnnotations(self.annotations)
            }
        }
    }

    func createMapAnotations() {
        annotations.removeAll()
        let students = parseSession.students

        for student in students {
            let latitude = CLLocationDegrees(floatLiteral: student.latitude)
            let longitude = CLLocationDegrees(floatLiteral: student.longitude)

            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(student.firstName) \(student.lastName)"
            annotation.subtitle = student.mediaURL

            annotations.append(annotation)
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

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let urlString = view.annotation?.subtitle else {
            showAlertOnMain("Something went wrong")
            print("There is a problem with \(view) annotation")
            return
        }

        let url: NSURL
        do {
            url = try urlString!.createValidURL()
        } catch {
            showAlertOnMain("That link is not valid")
            return
        }

        UIApplication.sharedApplication().openURL(url)
    }

    // MARK: Alert Management
    func alertUserToFailure(errorMessage: String) {
        let alert = UIAlertController(title: "Sorry!", message: errorMessage, preferredStyle: .Alert)

        let tryAgainAction = UIAlertAction(title: "Try Again", style: .Default, handler: { alert in self.loadMap(nil) })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

        alert.addAction(cancel)
        alert.addAction(tryAgainAction)

        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: Navigation Management
    @IBAction func createNewPin(sender: UIBarButtonItem) {
        checkForExistingLocation()
    }

    // Required to exit from CreatePinViewController
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "unwindToLogout" {

            if FBSDKAccessToken.currentAccessToken() != nil {
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()

                if FBSDKAccessToken.currentAccessToken() == nil {
                    return true
                } else {
                    return false
                }
            } else {
                let udacitySession = UdacityClient.sharedInstance()
                udacitySession.logout() { (success, error) in
                    if error != nil {
                        print(error)
                        return false
                    } else if success == false {
                        print("There is no error with logging out but it failed")
                        return false
                    } else {
                        return true
                    }
                }
                parseSession.logout()
            }
        }
        return true
    }
}
