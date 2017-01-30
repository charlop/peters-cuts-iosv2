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
    
    func sendNotification(_ titleText:String, messageText:String, goBack:Bool) {
        DispatchQueue.main.async(execute: {
                let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert  )
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    if(goBack) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO: this should return something better...
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservationData.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reservationCell", for: indexPath)
        
        let resTime = reservationData[indexPath.row]
        cell.textLabel?.text = resTime
        cell.textLabel?.backgroundColor = UIColor.clear
        
        // new -- take advantage of this in other spots
        cell.tag = reservationIdDictionary[resTime]!
        
        return cell
    }
    
    func refreshTable() {
        DispatchQueue.main.async(execute: {
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
        
        let alertController = UIAlertController(title: "Important", message: "Please be on time for your appointment or give at least 1 hour notice if you can't make it.", preferredStyle: .alert  )
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            //let vc : AnyObject! = self.storyboard!.instantiateViewControllerWithIdentifier("ViewController")
            //self.showViewController(vc as! UIViewController, sender: vc)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: {
                        self.present(alertController, animated: true, completion: nil)
        }) // end of dispatch
        
        self.getOpenSpots()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func makeReservationWithSender(_ sender: UIButton) {
        // Reservations disabled because no user info is available
        if(reservationsDisabled) {
            self.sendNotification("Can't Make Reservations", messageText: "Please go back and enter your name and number before you can make reservations", goBack: false)
        } else {
            // Allow the user to make a reservation
            let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: buttonPosition) {
                // TODO -- this is probably not the safest way to get text:
                if let start_time = tableView.cellForRow(at: indexPath)?.textLabel!.text {
                    
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
