//
//  TableViewController.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/23/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import UIKit

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()

    let parseSession = ParseClient.sharedInstance()
    var students: [ParseClient.StudentInformation]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        students = parseSession.students
        
        refreshControl.addTarget(self, action: #selector(reloadStudents), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func reloadStudents() {
        parseSession.getLast100UserLocations() { (success, error) in
            guard error == nil && success == true else {
                print(error?.localizedDescription)
                return
            }
            
            self.students = self.parseSession.students
            
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
            print("There is a problem with the student at row \(row)")
            return
        }
        
        let urlString = student.mediaURL
        
        let url: NSURL
        do {
            url = try urlString.createValidURL()
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
    
//    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
//        if segue.
//    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "unwindToLogout" {
            let udacitySession = UdacityClient.sharedInstance()
            udacitySession.logout() { (success, error) in
                guard error == nil else {
                    print("Error")
                    return false
                }
                return true
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
