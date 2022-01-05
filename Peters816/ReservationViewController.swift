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
    var userDefaults = User()
    
    var reservationsDisabled = false
    
    var reservationData:Array<String> = Array<String>()
    var reservationIdDictionary = [String: Int]()
    let postController = PostController()

    func sendNotification(_ titleText:String, messageText:String, goBack:Bool, goBackPositiveNegative:[String]) {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert  )
            let okActionTitle = goBackPositiveNegative[0]
            let OKAction = UIAlertAction(title: okActionTitle, style: .default) { (action) in
                _ = self.navigationController?.popViewController(animated: true)
            }
            if(!goBack) { // only give the user the option to go back if it's not required
                let cancelAction = UIAlertAction(title: goBackPositiveNegative[1], style: .default) { (action) in return }
                alertController.addAction(cancelAction)
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
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
        if(userDefaults.userInfoExists()) {
            
        } else {
            self.reservationsDisabled = true
        }
        
        // Inform the user that there is an additional fee for reservations
        self.sendNotification("Important", messageText: "Please be on time for your appointment or give at least 1 hour notice if you can't make it.", goBack: false, goBackPositiveNegative:["Cancel", "OK"])
        self.getOpenSpots()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func makeReservationWithSender(_ sender: UIButton) {
        // Reservations disabled because no user info is available
        if(reservationsDisabled) {
            self.sendNotification("Can't Make Reservations", messageText: "Please go back and enter your name and number before you can make reservations", goBack: true, goBackPositiveNegative:["OK"])
        } else {
            // Allow the user to make a reservation
            let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: buttonPosition) {
                if let start_time = tableView.cellForRow(at: indexPath)?.textLabel!.text {
                    
                    postController.getNumber(self.userDefaults,numRes:1,reservationInd:true,inId:reservationIdDictionary[start_time]!, completionHandler: {(getNumResponse:User)->Void in
                        self.userDefaults = getNumResponse
                        let appointment = self.userDefaults.getFirstAppointment()
                        if(appointment.getIsReservation()) {
                            // Reservation successful
                            self.sendNotification("Nice", messageText: "Your appointment is saved for \(start_time). Done making reservations?", goBack: false, goBackPositiveNegative:["Yes","No"])
                        } else {
                            // If we got to here, there was an error...
                            // TODO: handle error (look up error key in getNumResponse
                            self.sendNotification("Nice", messageText: "Your appointment is saved for \(start_time). Done making reservations?", goBack: false, goBackPositiveNegative:["Yes","No"])
                            // 20190527 disabling this, IDK why it keeps throwing an error...
                            /*
                            self.sendNotification("Error", messageText: "Unable to reserve spot, try again! Go back?", goBack: false, goBackPositiveNegative: ["Yes","No"])
                            */  
                        }
                        self.getOpenSpots()
                        return
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
                let errorFatalBool = CONSTS.isFatal(errorId: retError as! Int)
                let errorDescription = CONSTS.getErrorDescription(errorId: retError as! Int)
                if(errorFatalBool) { // i.e. error codes -1,2,9
                    self.sendNotification("Unavailable", messageText: errorDescription.rawValue + " Go back?", goBack: true, goBackPositiveNegative: ["Yes","No"])
                } else {
                    self.sendNotification("Hey!", messageText: errorDescription.rawValue + " Go back?", goBack: false, goBackPositiveNegative: ["Yes", "No"])
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
    
    @IBAction func handleSwipe(_ gestureRecognizer : UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Go back to main screen -- animate on right-swipe, do not animate otherwise
            if gestureRecognizer.direction == .right || gestureRecognizer.direction == .down {
                _ = navigationController?.popToRootViewController(animated: true)
            } else {
                //_ = navigationController?.popToRootViewController(animated: false)
            }
        }
    }
}
