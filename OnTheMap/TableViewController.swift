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
    
    let parseSession = ParseClient.sharedInstance()
    var students: [ParseClient.StudentInformation]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        students = parseSession.students
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
