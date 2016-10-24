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
    
    var reservationData:Array<String> = Array<String>()
    let postController = PostController()
    
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
        //postController.getOpenings()
        //self.reservationData.append(curStartTime)
        self.refreshTable()
    }
    
}
