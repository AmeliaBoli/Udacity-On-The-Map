//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton) {
        // Get session ID from Udacity
        guard let username = usernameField.text,
            let password = passwordField.text else {
                print("there is an error username or password")
                return
        }
        
        let udacitySession = UdacityClient.sharedInstance()
        
        udacitySession.getSessionID(username, password: password) { (success, error) in
            guard error == nil && success == true else {
                print("error with getSesssionID")
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.performSegueWithIdentifier("loggedin", sender: self)
            }
          }
    }
}

