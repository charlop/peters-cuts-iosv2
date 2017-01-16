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
    let userDefaults = User()
    var uName = ""
    var uPhone = ""
    
    var reservationsDisabled = false
    
    var reservationData:Array<String> = Array<String>()
    var reservationIdDictionary = [String: Int]()
    let postController = PostController()
    
    func sendNotification(titleText:String, messageText:String, goBack:Bool) {
        dispatch_async(
            dispatch_get_main_queue(), {
                let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .Alert  )
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                    if(goBack) {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
                alertController.addAction(OKAction)
                self.presentViewController(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // TODO: this should return something better...
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservationData.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reservationCell", forIndexPath: indexPath)
        
        let resTime = reservationData[indexPath.row]
        cell.textLabel?.text = resTime
        cell.textLabel?.backgroundColor = UIColor.clearColor()
        
        // new -- take advantage of this in other spots
        cell.tag = reservationIdDictionary[resTime]!
        
        return cell
    }
    
    func refreshTable() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if(userDefaults.name != nil) {
            self.uName = userDefaults.name!
            
            if(userDefaults.phone != nil) {
                self.uPhone = userDefaults.phone!
            } else {
                self.reservationsDisabled = true
            }
        } else {
            self.reservationsDisabled = true
            
        }
        
        // Inform the user that there is an additional fee for reservations
        
        let alertController = UIAlertController(title: "Important", message: "There is an additional fee for reservations, paid when you receive your haircut. Continue?", preferredStyle: .Alert  )
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
            //let vc : AnyObject! = self.storyboard!.instantiateViewControllerWithIdentifier("ViewController")
            //self.showViewController(vc as! UIViewController, sender: vc)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(),
                       {
                        self.presentViewController(alertController, animated: true, completion: nil)
        }) // end of dispatch
        
        self.getOpenSpots()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func makeReservationWithSender(sender: UIButton) {
        // Reservations disabled because no user info is available
        if(reservationsDisabled) {
            self.sendNotification("Can't Make Reservations", messageText: "Please go back and enter your name and number before you can make reservations", goBack: false)
        } else {
            // Allow the user to make a reservation
            let buttonPosition = sender.convertPoint(CGPointZero, toView: self.tableView)
            if let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition) {
                // TODO -- this is probably not the safest way to get text:
                if let start_time = tableView.cellForRowAtIndexPath(indexPath)?.textLabel!.text {
                    
                    postController.getNumber(reservationIdDictionary[start_time]!,
                                             inName: uName, inPhone: uPhone, completionHandler: {(getNumResponse:[String: AnyObject])->Void in
                                                if let idRet = getNumResponse["id"] {
                                                    if(idRet as! Int > 0) {
                                                        // Reservation Success!!
                                                        self.userDefaults.addSingleEta(idRet as! Double)
                                                        self.sendNotification("Nice", messageText: "Your appointment is saved for \(start_time)", goBack: true)
                                                        return
                                                    }
                                                }
                                                
                                                // If we got to here, there was an error...
                                                // TODO: handle error (look up error key in getNumResponse
                                                self.sendNotification("Error", messageText: "Unable to reserve spot, try again!", goBack: false)
                    })
                }
                
            }
        }
    }
    func getOpenSpots() {
        // possible values (-2, -8, -3)
        postController.getOpenings({(etaResponse:[String: AnyObject])->Void in
            if let retError = etaResponse["error"] {
                self.reservationData.removeAll()
                
                // check if fatal, etc...
                let (errorFatalBool, _ ) = CONSTS.GET_ERROR_ACTION(retError as! Int)
                if(errorFatalBool) { // i.e. error codes -1,2,9
                    self.sendNotification("Unavailable", messageText: CONSTS.GET_ERROR_TEXT(retError as! Int), goBack: true)
                } else {
                    self.sendNotification("Hey!", messageText: CONSTS.GET_ERROR_TEXT(retError as! Int), goBack: false)
                }
            } else {
                // Success! Store the id's for associated start_time and display the data
                if let tmpReservationDictionary = etaResponse["availableSpots"] {
                    self.reservationIdDictionary = tmpReservationDictionary as! [String : Int]
                    self.reservationData = etaResponse["availableSpotsArray"] as! [String]
                    self.refreshTable()
                }
            }
            
        })
    }
}
