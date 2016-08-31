//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton?) {
        // Get session ID from Udacity
        guard let username = usernameField.text,
            let password = passwordField.text where !username.isEmpty && !password.isEmpty else {
                let errorString = "There seems to be no username or password"
                print(errorString)
                errorMessageLabel.text = errorString
                return
        }
        
        let udacitySession = UdacityClient.sharedInstance()
        
        udacitySession.getSessionID(username, password: password) { (success, error) in
            guard error == nil && success == true else {
                print("error with getSesssionID")
                dispatch_async(dispatch_get_main_queue()) {
                    self.errorMessageLabel.text = error!
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.performSegueWithIdentifier("loggedin", sender: self)
            }
          }
    }
    
    @IBAction func showUdacityPage(sender: UIButton) {
        let escapedURLString = ("https://www.udacity.com/account/auth#!/signup")
        guard let url = NSURL(string: escapedURLString) else {
            let errorString = "There was a problem with the Udacity sign in page"
            print(errorString)
            errorMessageLabel.text = errorString
            return
        }
        UIApplication.sharedApplication().openURL(url)
    }
    
    // MARK: Text Field and Keyboard Management
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            usernameField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            passwordField.resignFirstResponder()
            login(nil)
        }
        return true
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        errorMessageLabel.text = ""
    }
}

