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
    var cust_ids = [Int: Date]()
    var expireAfter :Int? // only storing day of the month
    var idsValidBool:Bool = false
    
    var userDefaults = UserDefaults.standard
    
    init() {
        userDefaults = UserDefaults.standard
        name = userDefaults.string(forKey: "name")
        phone = userDefaults.string(forKey: "phone")
        email = userDefaults.string(forKey: "email")
        expireAfter = userDefaults.integer(forKey: "expiryDate")
        
        if(idsValid()) {
            // Retrieve the Id, start_hr, start_min
            if let localIds = userDefaults.dictionary(forKey: "cust_id_dict") {
                cust_ids.removeAll()
                for (key,value) in localIds {
                    // Loading the customer IDs and app_start_time -- needs to be in UTC
                    cust_ids.updateValue(value as! Date, forKey: Int(key)!)
                }
            }
            idsValidBool = true
        } else {
            // No recent appointments, clear out the local data
            userDefaults.removeObject(forKey: "expiryDate")
            userDefaults.synchronize()
        }
    }
    
    // receive eta in seconds preferably -- just take it in minutes
    func addNumber(_ newIds :NSDictionary) {
        // Clear out anything stored locally
        userDefaults.removeObject(forKey: "cust_id_dict")
        self.cancelLocalNotification() // cancel notification
        if let tmpDict = (newIds as? [Int : Double]) {
            var tmpUdNSDict : [String: Date] = Dictionary()
            
            var firstNumberFlag = true
            for(key,value) in tmpDict {
                // This is the appointment start time adjusting for hour shift
                let date = Date(timeIntervalSinceNow: value * 60)
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
            let date = Date()
            let calendar = Calendar.current
            expireAfter = (calendar as NSCalendar).components([.day], from: date).day
            userDefaults.set(expireAfter, forKey: "expiryDate")
            
            let udNSDict = tmpUdNSDict as NSDictionary
            userDefaults.set(udNSDict, forKey: "cust_id_dict")
            userDefaults.synchronize()
        }
    }
    // This is just a stop-gap solution, should be using the addNumber function
    // 95% identical code to addNumber, but less efficient
    // TODO: this is full-on retardnation
    func addSingleEta(_ nextEtaMin: Double) {
        // Clear out anything stored locally
        userDefaults.removeObject(forKey: "cust_id_dict")
        self.cancelLocalNotification() // cancel notification
        
        let date = Date(timeIntervalSinceNow: nextEtaMin * 60)
        var tmpUdNSDict : [String: Date] = Dictionary()
        tmpUdNSDict.updateValue(date, forKey: "50") // 50 is an arbitrary number. really being lazy here
        cust_ids.updateValue(date, forKey: 50) // again, arbitrary id
        
        idsValidBool = true
        let date2 = Date()
        let calendar = Calendar.current
        expireAfter = (calendar as NSCalendar).components([.day], from: date2).day
        userDefaults.set(expireAfter, forKey: "expiryDate")
        
        let udNSDict = tmpUdNSDict as NSDictionary
        userDefaults.set(udNSDict, forKey: "cust_id_dict")
        userDefaults.synchronize()
        
        self.createLocalNotification(nextEtaMin)
    }
    // TODOs after haircut finishes (could have more numbers)
    func removeAllNumbers() {
        self.cust_ids.removeAll()
        self.expireAfter = 0
        userDefaults.set(nil, forKey: "cust_id_dict")
        userDefaults.set(0, forKey: "expiryDate")
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
            let date = Date()
            let calendar = Calendar.current
            let curDate = (calendar as NSCalendar).components([.day], from: date).day
            if let unwrappedExpireAfter = expireAfter {
                if(unwrappedExpireAfter == curDate && cust_ids.count > 0) {
                    // Customer has gotten a number recently
                    self.idsValidBool = true
                    return self.idsValidBool
                }
            }
            expireAfter = nil
            self.idsValidBool = false
            self.cust_ids = [Int: Date]()
        }
        return self.idsValidBool
    }
    
    func saveUserDetails(_ inName: String, inPhone: String, inEmail: String?=nil) {
        removeAllNumbers()
        self.name = inName
        self.phone = inPhone
        self.email = inEmail
        self.userDefaults.set(inName, forKey: "name")
        self.userDefaults.set(inPhone, forKey: "phone")
        self.userDefaults.set(inEmail, forKey: "email")
        self.userDefaults.synchronize()
    }
    
    // NOTIFICATIONS
    
    // Input is a date for 40 minutes prior to appointment
    func createLocalNotification(_ etaMin : Double) {
        
        if(etaMin <= 20) {
            return
        } else {
            let localNotification = UILocalNotification()
            
            if(etaMin > 40) {
                localNotification.fireDate = Date(timeIntervalSinceNow: (etaMin - 40) * 60)
                localNotification.alertBody = "Your haircut is in 40 minutes!"
                
            }else {
                // > 20 mins
                localNotification.fireDate = Date(timeIntervalSinceNow: (etaMin - 20) * 60)
                localNotification.alertBody = "Your haircut is in 20 minutes!"
                
            }
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.alertTitle = "Message From Peter"
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
        
    }
    func cancelLocalNotification() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
}
