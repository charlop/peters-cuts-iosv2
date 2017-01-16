//
//  User.swift
//  Peters816
//
//  Created by Chris on 2016-10-12.
//  Copyright © 2016 Chris Charlopov. All rights reserved.
//

import Foundation
import UIKit

class User {
    var name :String?
    var phone :String?
    var email :String?
    var cust_ids = [Int: NSDate]()
    var expireAfter :Int? // only storing day of the month
    var idsValidBool:Bool = false
    
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    init() {
        userDefaults = NSUserDefaults.standardUserDefaults()
        name = userDefaults.stringForKey("name")
        phone = userDefaults.stringForKey("phone")
        email = userDefaults.stringForKey("email")
        expireAfter = userDefaults.integerForKey("expiryDate")
        
        if(idsValid()) {
            // Retrieve the Id, start_hr, start_min
            if let localIds = userDefaults.dictionaryForKey("cust_id_dict") {
                cust_ids.removeAll()
                for (key,value) in localIds {
                    // Loading the customer IDs and app_start_time -- needs to be in UTC
                    cust_ids.updateValue(value as! NSDate, forKey: Int(key)!)
                }
            }
            idsValidBool = true
        } else {
            // No recent appointments, clear out the local data
            userDefaults.removeObjectForKey("expiryDate")
            userDefaults.synchronize()
        }
    }
    
    // receive eta in seconds preferably -- just take it in minutes
    func addNumber(newIds :NSDictionary) {
        // Clear out anything stored locally
        userDefaults.removeObjectForKey("cust_id_dict")
        self.cancelLocalNotification() // cancel notification
        if let tmpDict :[Int: Double] = (newIds as! [Int : Double]) {
            var tmpUdNSDict : [String: NSDate] = Dictionary()
            
            var firstNumberFlag = true
            for(key,value) in tmpDict {
                // This is the appointment start time adjusting for hour shift
                let date = NSDate(timeIntervalSinceNow: value * 60)
                cust_ids.updateValue(date, forKey: key)
                tmpUdNSDict.updateValue(date, forKey: String(key))
                
                // Create a single notification for the first haircut
                if(firstNumberFlag) {
                    // Just pass in the eta in minutes...logic is handled there
                    self.createLocalNotification(value)
                    firstNumberFlag = false
                }
            }
            idsValidBool = true
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            expireAfter = calendar.components([.Day], fromDate: date).day
            userDefaults.setObject(expireAfter, forKey: "expiryDate")
            
            let udNSDict = tmpUdNSDict as NSDictionary
            userDefaults.setObject(udNSDict, forKey: "cust_id_dict")
            userDefaults.synchronize()
        }
    }
    // This is just a stop-gap solution, should be using the addNumber function
    // 95% identical code to addNumber, but less efficient
    // TODO: this is full-on retardnation
    func addSingleEta(nextEtaMin: Double) {
        // Clear out anything stored locally
        userDefaults.removeObjectForKey("cust_id_dict")
        self.cancelLocalNotification() // cancel notification
        
        let date = NSDate(timeIntervalSinceNow: nextEtaMin * 60)
        var tmpUdNSDict : [String: NSDate] = Dictionary()
        tmpUdNSDict.updateValue(date, forKey: "50") // 50 is an arbitrary number. really being lazy here
        cust_ids.updateValue(date, forKey: 50) // again, arbitrary id
        
        idsValidBool = true
        let date2 = NSDate()
        let calendar = NSCalendar.currentCalendar()
        expireAfter = calendar.components([.Day], fromDate: date2).day
        userDefaults.setObject(expireAfter, forKey: "expiryDate")
        
        let udNSDict = tmpUdNSDict as NSDictionary
        userDefaults.setObject(udNSDict, forKey: "cust_id_dict")
        userDefaults.synchronize()
        
        self.createLocalNotification(nextEtaMin)
    }
    // TODOs after haircut finishes (could have more numbers)
    func removeAllNumbers() {
        self.cust_ids.removeAll()
        self.expireAfter = 0
        userDefaults.setObject(nil, forKey: "cust_id_dict")
        userDefaults.setObject(0, forKey: "expiryDate")
        userDefaults.synchronize()
        
        self.cancelLocalNotification()
        
        idsValidBool = false
    }
    func getEta() -> (Int, Int) {
        // need to get first valid value
        if let firstApt = cust_ids.first {
            let curDate = firstApt.1
            let etaSec = curDate.timeIntervalSinceNow
            if(etaSec <= 0) {
                // TODO:: SOME ERROR --- see how it's done in viewcontroller
            } else { // actual eta returned
                let hrs = Int(floor(etaSec / 60))
                let mins = Int(etaSec) % 60
                return (hrs,mins)
            }
        }
        // No number received
        return (0,0)
    }
    
    func idsValid()->Bool {
        if(self.idsValidBool == false) {
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let curDate = calendar.components([.Day], fromDate: date).day
            if let unwrappedExpireAfter = expireAfter {
                if(unwrappedExpireAfter == curDate && cust_ids.count > 0) {
                    // Customer has gotten a number recently
                    self.idsValidBool = true
                    return self.idsValidBool
                }
            }
            expireAfter = nil
            self.idsValidBool = false
            self.cust_ids = [Int: NSDate]()
        }
        return self.idsValidBool
    }
    
    func saveUserDetails(inName: String, inPhone: String, inEmail: String?=nil) {
        removeAllNumbers()
        self.name = inName
        self.phone = inPhone
        self.email = inEmail
        self.userDefaults.setObject(inName, forKey: "name")
        self.userDefaults.setObject(inPhone, forKey: "phone")
        self.userDefaults.setObject(inEmail, forKey: "email")
        self.userDefaults.synchronize()
    }
    
    // NOTIFICATIONS
    
    // Input is a date for 40 minutes prior to appointment
    func createLocalNotification(etaMin : Double) {
        
        if(etaMin <= 20) {
            return
        } else {
            let localNotification = UILocalNotification()
            
            if(etaMin > 40) {
                localNotification.fireDate = NSDate(timeIntervalSinceNow: (etaMin - 40) * 60)
                localNotification.alertBody = "Your haircut is in 40 minutes!"
                
            }else {
                // > 20 mins
                localNotification.fireDate = NSDate(timeIntervalSinceNow: (etaMin - 20) * 60)
                localNotification.alertBody = "Your haircut is in 20 minutes!"
                
            }
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.alertTitle = "Message From Peter"
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        }
        
    }
    func cancelLocalNotification() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
}
