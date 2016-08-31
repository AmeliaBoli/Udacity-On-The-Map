//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let parseSession = ParseClient.sharedInstance()
    var annotations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMap(nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        // 1. Get info from Parse
        
            }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loadMap(sender: UIBarButtonItem?) {
        parseSession.getLast100UserLocations() { (success, error) in
            guard error == nil && success == true else {
                print(error?.localizedDescription)
                return
            }
            
            self.createMapAnotations()
            
            dispatch_async(dispatch_get_main_queue()) {
                // 2. Load info into map
                self.mapView.addAnnotations(self.annotations)
            }
        }
    }
    
    func createMapAnotations() {
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
            print("There is a problem with \(view) annotation")
            return
        }
        
        let url: NSURL
        do {
            url = try urlString!.createValidURL()
        } catch String.UrlErrors.invalidString {
            print("invalidString")
            //postErrorLabel.text = "I can't seem to make a valid URL from what was inputted"
            return
        } catch String.UrlErrors.invalidComponents {
            print("invalidComponents")
            //postErrorLabel.text = "I can't seem to make a valid URL from what was inputted"
            return
        } catch String.UrlErrors.noDataDetector {
            print("noDataDetector")
            //postErrorLabel.text = "There was an internal error"
            return
        } catch String.UrlErrors.noHost {
            print("noHost")
            //postErrorLabel.text = "There seems to be no host- https://"
            return
        } catch String.UrlErrors.wrongNumberOfLinks {
            print("wrongNumberOfLinks")
            //postErrorLabel.text = "You might be missing the domain- .com"
            return
        } catch String.UrlErrors.invalidCharacter {
            print("invalidCharacter")
            // FIXME: Have the actual bad character pass through to here and add it to the error message to the user
            //postErrorLabel.text = "There was a character in the URL that is not allowed"
            return
        } catch {
            print("some other error")
            //postErrorLabel.text = "Hmm...something went wrong"
            return
        }
        
        UIApplication.sharedApplication().openURL(url)
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
    }
 }
