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
    
    init() {
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
        if let tmpDict :[Int: Double] = (newIds as! [Int : Double]) {
            var tmpUdNSDict : [String: NSDate] = Dictionary()
            //let udNSDict = [String: AnyObject]() as NSDictionary
            for(key,value) in tmpDict {
                // This is the appointment start time adjusting for hour shift
                let date = NSDate(timeIntervalSinceNow: value * 60)
                cust_ids.updateValue(date, forKey: key)
                tmpUdNSDict.updateValue(date, forKey: String(key))
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
    func addSingleEta(nextEtaMin: Double) {
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
        userDefaults.synchronize()

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
}
