//
//  User.swift
//  Peters816
//
//  Created by Chris on 2016-10-12.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation

class User {
    var name :String?
    var phone :String?
    var email :String?
    var cust_ids = [Int: NSDate]()
    var expireAfter :Int? // only storing day of the month
    var idsValidBool:Bool = false
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    func getUserDetails() {
            name = userDefaults.stringForKey("name")
            phone = userDefaults.stringForKey("number")
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
        }
    }
    
    // receive eta in seconds preferably
    func addNumber(newIds :NSDictionary) {
        // Clear out anything stored locally
        userDefaults.removeObjectForKey("cust_id_dict")
        
        if let tmpDict :[Int: Double] = (newIds as! [Int : Double]) {
            let udNSDict = [String: NSDate]() as NSDictionary
            for(key,value) in tmpDict {
                // This is the appointment start time adjusting for hour shift
                let date = NSDate(timeIntervalSinceNow: value)
                cust_ids.updateValue(date, forKey: key)
                udNSDict.setValue(date, forKey: String(key))
            }
            idsValidBool = true
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            expireAfter = calendar.components([.Day], fromDate: date).day
            userDefaults.setObject(expireAfter, forKey: "expiryDate")
            userDefaults.setObject(udNSDict, forKey: "cust_id_dict")
        }
    }
    // TODOs
    func removeAllNumbers() {
        //after haircut finishes (could have more numbers)
        // after delete
        // delete everyone!!
        
        self.cust_ids.removeAll()
        self.expireAfter = 0
        userDefaults.setObject(nil, forKey: "cust_id_dict")
        userDefaults.setObject(0, forKey: "expiryDate")
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
        name = inName
        phone = inPhone
        email = inEmail
        userDefaults.setObject(name, forKey: "name")
        userDefaults.setObject(phone, forKey: "phone")
        userDefaults.setObject(email, forKey: "email")
    }
}
