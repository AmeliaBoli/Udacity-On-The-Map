//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/22/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var maskingView: UIView!
    
    let application = UIApplication.sharedApplication()
    
    let purpleView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Facebook Login Button
        let loginButton = FBSDKLoginButton()
        loginButton.delegate = self
        
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        loginButton.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.bottomAnchor, constant: -20).active = true
        loginButton.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
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
        
        getSessionID(username, password: password)
    }
    
    func getSessionID(username: String?, password: String?) {
        var usernameForSession: String? = nil
        var passwordForSession: String? = nil
        
        if let username = username, password = password {
            usernameForSession = username
            passwordForSession = password
        } else if FBSDKAccessToken.currentAccessToken() == nil {
            print("There was a problem with parameters to get a session ID")
            errorMessageLabel.text = "It looks like you either need to login with a Udacity account or a Facebook account"
        }

        let udacitySession = UdacityClient.sharedInstance()
        
        maskingView.hidden = false
        
        udacitySession.getSessionID(usernameForSession, password: passwordForSession) { (success, error) in
            
            self.maskingView.hidden = true
            
            guard error == nil && success == true else {
                print("error with getSesssionID")
                dispatch_async(dispatch_get_main_queue()) {
                    self.maskingView.hidden = true
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
    
    // MARK: Facebook Login/out Management
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if error != nil {
            print(error.localizedDescription)
            errorMessageLabel.text = "There was a problem logging into Facebook"
            return
        }
        getSessionID(nil, password: nil)
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
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
    
    func textFieldDidBeginEditing(textField: UITextField) {
        errorMessageLabel.text = ""
    }
    
    @IBAction func prepareForUnwindToLogout(segue: UIStoryboardSegue) {
        usernameField.text = ""
        passwordField.text = ""
        maskingView.hidden = true
    }
}


