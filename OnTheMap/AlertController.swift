//
//  AlertController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 9/5/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

protocol AlertController {
    func createAlertControllerWithNoActions(title: String?, message: String?)
    func showAlertOnMain(message: String)
}

extension AlertController where Self: UIViewController {
    func showAlertOnMain(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.createAlertControllerWithNoActions(nil, message: message)
        }
    }

    func createAlertControllerWithNoActions(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let cancel = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        alert.addAction(cancel)

        self.presentViewController(alert, animated: true, completion: nil)
    }
}
