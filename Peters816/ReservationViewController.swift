//
//  ReservationViewController.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/18/16.
//  Copyright © 2016 Chris Charlopov. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import UIKit

class ReservationViewController: UITableViewController {
    var GET_OPEN_SPOTS_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request2.php")!
    var GET_OPEN_SPOTS_REQUEST:NSMutableURLRequest!
    var GET_OPEN_SPOTS_SESSION:NSURLSession!
    var POST_PARAMS:String = "get_available=1"

    
    var reservationData:Array<String> = Array<String>()
    
    func getOpeningsPostRequest() -> NSMutableURLRequest {
        if(GET_OPEN_SPOTS_REQUEST == nil) {
            GET_OPEN_SPOTS_REQUEST = NSMutableURLRequest(URL: GET_OPEN_SPOTS_URL)
            GET_OPEN_SPOTS_REQUEST.HTTPMethod = "POST"
        }
        return GET_OPEN_SPOTS_REQUEST
    }
    func getOpeningsPostSession() -> NSURLSession {
        if(GET_OPEN_SPOTS_SESSION == nil) {
            GET_OPEN_SPOTS_SESSION = NSURLSession.sharedSession()
        }
        return GET_OPEN_SPOTS_SESSION
    }

    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // TODO: this should return something better...
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservationData.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("reservationCell", forIndexPath: indexPath)
        cell.textLabel?.text = reservationData[indexPath.row]
        
        return cell
    }
    
    func refreshTable() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getOpenSpots()
        
        // TODO: here is where JSON get/post request is made
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getOpenSpots() {
        getOpeningsPostRequest().HTTPBody = POST_PARAMS.dataUsingEncoding(NSUTF8StringEncoding)
        let task = getOpeningsPostSession().dataTaskWithRequest(getOpeningsPostRequest()) { data,response, error in
            if error != nil {
                // TODO: handle error
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]
                let initId = responseJSON[0]["id"] as! Int
                if(initId < 0) {
                    // TODO: error of some sort
                } else if(initId > 0) {
                    for i in 1...responseJSON.count {
                        let curStartTime = responseJSON[i-1]["start_time"] as! String
                        self.reservationData.append(curStartTime)
                    }
                    self.refreshTable()
                } else {
                    // TODO: initId invalid -- 0 or not an integer
                }
                
            } catch {
                // TODO: handle error
            }
        }
        task.resume()
    }
    
}
