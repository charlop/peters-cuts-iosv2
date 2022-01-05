//
//  User.swift
//  Peters816
//
//  Created by Chris on 2016-10-12.
//  Copyright © 2016 Chris Charlopov. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class User {
    private var name :String
    private var phone :String
    private var email :String
    //private var expireAfter :Int // only storing day of the month
    //private var hasAppointment:Bool
    
    private var appointmentArray = [Appointment()]
    
    var userDefaults = UserDefaults.standard
    
    init() {
        name = ""
        phone = ""
        email = ""
        
        if(userDefaults.string(forKey: "name") != nil) {
            name = userDefaults.string(forKey: "name")!
        }
        if(userDefaults.string(forKey: "phone") != nil) {
            phone = userDefaults.string(forKey: "phone")!
        }
        if(userDefaults.string(forKey: "email") != nil) {
            email = userDefaults.string(forKey: "email")!
        }

        if let restoredAppointmentArray = userDefaults.object(forKey: "appointment") as? NSData {
            //return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, CKServerChangeToken.self], from: tokenData) as? [String : CKServerChangeToken]
            do {
            if let unwrappedAppointmentArray = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(restoredAppointmentArray as Data) as? [Appointment] {
                appointmentArray = unwrappedAppointmentArray
            }
            } catch {}
        }

        self.validateIds()
    }
    // if appointmentStatus and nextId are the same, appointment has not been changed
    // constantly varying: lastErrorReceived, currentId
    // constant regardless: startTimeUTCSeconds -- will change if user does not have appointment
    
    func addOrUpdateAppointment(newAppointment:Appointment) {
        if(newAppointment.getAppointmentStatus() == CONSTS.AppointmentStatus.NO_APPOINTMENT) {
            if(appointmentArray[0].getAppointmentStatus() != CONSTS.AppointmentStatus.NO_APPOINTMENT) {
                self.removeAppointmentAtIndex(aptIndex: -1)
            }
            appointmentArray = [newAppointment]
        } else { // newAppointment has number
            if(appointmentArray.count > 1) {
                self.validateIds()
            }
            if(!newAppointment.appointmentUnchanged(newAppointment: appointmentArray[0])) { // appointments are different
                self.removeAppointmentAtIndex(aptIndex: -1)
                self.addAppointment(newAppointment: newAppointment)
            } else {
                // these updates only happen if the user has a number, and local info matches server response
                appointmentArray[0].setCurrentId(currentId: newAppointment.getCurrentId())
                appointmentArray[0].updateError(newError: newAppointment.getError())
                appointmentArray[0].setAppointmentStartTime(etaMinVal: newAppointment.getEtaMins())
            }
        }
    }
 
    func addAppointment(newAppointment:Appointment) {
        // check if user has existing appointments
        if(self.userHasAppointment()) {
            if(appointmentArray[0].getEtaMins() > newAppointment.getEtaMins()) {
                appointmentArray = [newAppointment] + appointmentArray
                self.createLocalNotification(newAppointment.getEtaMins())
            } else {
                appointmentArray.append(newAppointment)
            }
            /*
            var newArray:[Appointment] = []
            let originalFirstAppointment = appointmentArray[0]
            while(!appointmentArray.isEmpty) {
                if(appointmentArray[0].getEtaMins() <= 0) {
                    removeFirstAppointment()
                    continue
                } else if(appointmentArray[0].getEtaMins() > newAppointment.getEtaMins()) {
                    newArray.append(newAppointment)
                }
                newArray.append(appointmentArray.removeFirst())
            }
            appointmentArray = newArray
            // Earlier start time was entered...update notification time
            if(appointmentArray[0].getEtaMins() != originalFirstAppointment.getEtaMins()) {
                self.createLocalNotification(appointmentArray[0].getEtaMins())
            }
 */
        } else {
            appointmentArray = [newAppointment]
            self.createLocalNotification(newAppointment.getEtaMins())
        }
/*
        let date = Date()
        let calendar = Calendar.current
        expireAfter = (calendar as NSCalendar).components([.day], from: date).day!
        userDefaults.set(expireAfter, forKey: "expiryDate")
 */
        
        let appointmentArrayAsNSData = arrayToNSData(arrayIn: appointmentArray)
        userDefaults.set(appointmentArrayAsNSData, forKey:"appointment")
        userDefaults.synchronize()
    }
    func arrayToNSData(arrayIn:[Appointment]) -> NSData? {
        do {
        return try NSKeyedArchiver.archivedData(withRootObject: arrayIn as NSArray, requiringSecureCoding: false) as NSData
        } catch {}
        return nil
    }
    
    // -1 indicates remove all
    func removeAppointmentAtIndex(aptIndex:Int) {
        if(aptIndex == -1) {
            self.appointmentArray = [Appointment()]
        } else if(aptIndex >= self.appointmentArray.count) {
            self.appointmentArray.remove(at: aptIndex)
        }
        
        /*
         self.hasAppointment = false
         self.expireAfter = 0
         userDefaults.removeObject(forKey: "expiryDate")
         */
        userDefaults.removeObject(forKey: "appointment")
        userDefaults.synchronize()
    }
    func getFirstUpcomingEta() -> (CONSTS.ErrorNum.RawValue, String) {
        var retStr = ""
        var errorNum = CONSTS.ErrorNum.NO_NUMBER.rawValue
        
        let etaMins = appointmentArray[0].getEtaMins()

        if(self.userHasAppointment()) {
            errorNum = CONSTS.ErrorNum.NO_ERROR.rawValue
        }
        
        if(etaMins < 0) {
            errorNum = appointmentArray[0].getError()
        } else {
            if(etaMins > 60) {
                retStr += String(Int(floor(Double(etaMins / 60)))) + " hours "
            }
            retStr += String(Int(etaMins) % 60) + " minutes"
        }
        return (errorNum,retStr)
    }
    
    // Checks if appointments in array are valid and remove any invalid ones
    func validateIds() {
        for var i in 0..<self.appointmentArray.count {
            if(!appointmentArray[0].isValid()) {
                self.removeAppointmentAtIndex(aptIndex: i)
            }
        }
    }
    
    func saveUserDetails(_ inName: String, inPhone: String, inEmail: String?="") {
        removeAppointmentAtIndex(aptIndex: -1) // called because userInfo was changed, cannot track appointment status
        self.name = inName
        self.phone = inPhone
        self.email = inEmail!
        self.userDefaults.set(inName, forKey: "name")
        self.userDefaults.set(inPhone, forKey: "phone")
        self.userDefaults.set(inEmail, forKey: "email")
        self.userDefaults.synchronize()
    }
    func saveHoursText(hoursText: String) {
        self.userDefaults.set(hoursText, forKey: "hoursText")
        self.userDefaults.synchronize()
    }
    func getHoursText() -> String {
        if let hoursText = userDefaults.string(forKey: "hoursText") {
            if hoursText.isEmpty {
                self.saveHoursText(hoursText: "Please call/text Peter for current shop hours.")
            }
        } else {
            self.saveHoursText(hoursText: "Please call/text Peter for current shop hours.")
        }
        
        return userDefaults.string(forKey: "hoursText")!
    }
    func saveAddrUrl(addrUrl: String) {
        self.userDefaults.set(addrUrl, forKey: "addrUrl")
        self.userDefaults.synchronize()
    }
    func getAddrUrl() -> String {
        if let shopAddr = userDefaults.string(forKey: "addrUrl") {
            if shopAddr.isEmpty {
                self.saveAddrUrl(addrUrl: "")
            }
        } else {
            self.saveAddrUrl(addrUrl: "")
        }
        return userDefaults.string(forKey: "addrUrl")!
    }
    
    // NOTIFICATIONS
    // Input is a date for 40 minutes prior to appointment
    func createLocalNotification(_ etaMin : Double) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { (notifications) in
            if notifications.count > 0 {
                self.removeAppointmentAtIndex(aptIndex: -1)
                
            }

        }

        
        if(etaMin > 20) {
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Message from Peter", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "Your haircut is in 20 minutes!", arguments: nil)
            // Deliver the notification in 60 seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: (etaMin - 20) * 60, repeats: false)
            let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)

            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request)
        }
        
        if(etaMin > 40) {
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Message from Peter", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "Your haircut is in 40 minutes!", arguments: nil)
            // Deliver the notification in 60 seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: (etaMin - 40) * 60, repeats: false)
            let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)

            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request)
        }
    }

    func userInfoExists() -> Bool {
        return name != "" && phone != ""
    }
    func getUserName() -> String {
        return name
    }
    func getUserPhone() -> String {
        return phone
    }
    func getUserEmail() -> String {
        return email
    }
    func getFirstAppointment() -> Appointment {
        self.validateIds()
        return appointmentArray[0]
    }
    func userHasAppointment() -> Bool {
        self.validateIds()
        return !(appointmentArray[0].getAppointmentStatus() == CONSTS.AppointmentStatus.NO_APPOINTMENT)
    }
}
