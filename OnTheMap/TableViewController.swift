//
//  TableViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/23/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreatePin, AlertController {

    @IBOutlet weak var tableView: UITableView!

    let refreshControl = UIRefreshControl()

    let parseSession = ParseClient.sharedInstance
    var studentLocationsModel = StudentLocationsArray.sharedInstance

    var students: [StudentInformation]?

    override func viewDidLoad() {
        super.viewDidLoad()

        students = studentLocationsModel.fetchStudents()

        refreshControl.addTarget(self, action: #selector(reloadStudents), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
    }

    // MARK: Table Management
    @IBAction func reloadStudents() {
        parseSession.getLast100UserLocations() { (success, students, error) in
            guard error == nil && success == true else {
                #if DEBUG
                    print(error?.localizedDescription)
                #endif
                return
            }

            if let students = students {
                self.studentLocationsModel.setStudents(students)
                self.students = self.studentLocationsModel.fetchStudents()
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()

                if self.refreshControl.refreshing { self.refreshControl.endRefreshing() }
            }
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students!.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("location", forIndexPath: indexPath)

        let name = "\(students![indexPath.row].firstName) \(students![indexPath.row].lastName)"
        cell.imageView!.image = UIImage(named: "pin.pdf")
        cell.textLabel?.text = name

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row

        guard let student = students?[row] else {
            #if DEBUG
                print("There is a problem with the student at row \(row)")
            #endif
            return
        }

        let urlString = student.mediaURL

        let url: NSURL
        do {
            url = try urlString.createValidURL()
        } catch {
            showAlertOnMain("That link is not valid")
            return
        }

        UIApplication.sharedApplication().openURL(url)
    }

    // MARK: Navigation Management
    @IBAction func createNewPin(sender: UIBarButtonItem) {
        checkForExistingLocation()
    }

    // Required to exit from CreatePinViewController
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "unwindToLogout" {
            let udacitySession = UdacityClient.sharedInstance
            udacitySession.logout() { (success, error) in
                guard error == nil else {
                    #if DEBUG
                        print("Error")
                    #endif
                    return false
                }
                return true
            }
        }
    }
}
