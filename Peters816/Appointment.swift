//
//  Appointment.swift
//  Peters816
//
//  Created by Chris Charlopov on 7/22/17.
//  Copyright © 2017 spandan. All rights reserved.
//

import Foundation

class Appointment:NSObject, NSCoding {
    private var lastErrorReceived:Int
    private var hasNumber:Bool
    private var hasReservation:Bool
    private var startTimeUTCSeconds:Date
    private var currentId:Int, nextId:Int // nextId is the next available number or customer's number
    
    private var initPerformed = false
    
    override init() {
        lastErrorReceived = CONSTS.ErrorNum.NO_ERROR.rawValue
        hasNumber = false
        hasReservation = false
        currentId = 0
        nextId = 0
        startTimeUTCSeconds = Date()
    }
    required convenience init?(coder aDecoder:NSCoder) {
        self.init()
        lastErrorReceived = CONSTS.ErrorNum.NO_ERROR.rawValue
        hasNumber = aDecoder.decodeBool(forKey: "hasNumber")
        hasReservation = aDecoder.decodeBool(forKey: "hasReservation")
        currentId = Int(aDecoder.decodeInt32(forKey: "currentId"))
        nextId = Int(aDecoder.decodeInt32(forKey: "nextId"))
        
        if let loadStartTimeUTCSeconds = aDecoder.decodeObject(forKey: "startTimeUTCSeconds")  {
            startTimeUTCSeconds = loadStartTimeUTCSeconds as! Date
        } else {
            startTimeUTCSeconds = Date()
        }
    }
    func encode(with aCoder:NSCoder) {
        aCoder.encode(hasNumber, forKey: "hasNumber")
        aCoder.encode(hasReservation, forKey: "hasReservation")
        aCoder.encode(startTimeUTCSeconds, forKey:"startTimeUTCSeconds")
        aCoder.encode(currentId, forKey:"currentId")
        aCoder.encode(nextId, forKey:"nextId")
    }
    
    func updateError(newError:Int) {
        lastErrorReceived = newError
    }
    func setHasNumber(hasNumber:Bool) {
        self.hasNumber = hasNumber
    }
    func setIsReservation(isReservation:Bool) {
        self.hasReservation = isReservation
    }
    func setAppointmentStartTime(etaMinVal:Double) {
        self.startTimeUTCSeconds = Date(timeIntervalSinceNow: etaMinVal * 60)

        // need to find closest 20-minute interval
        let minuteOffset = Double((Calendar.current.component(.minute, from: startTimeUTCSeconds)) % 20)
        if(minuteOffset > 10) {
            self.startTimeUTCSeconds = self.startTimeUTCSeconds.addingTimeInterval((20.0 - minuteOffset) * 60)
        } else {
            self.startTimeUTCSeconds = self.startTimeUTCSeconds.addingTimeInterval((0.0 - minuteOffset) * 60)
        }
    }
    func setCurrentId(currentId:Int) {
        if(currentId >= 0) {
            self.currentId = currentId
        } else {
            self.currentId = 0
        }
    }
    func setNextAvailableId(nextId:Int) {
        if(nextId >= 0) {
            self.nextId = nextId
        } else {
            self.nextId = 0
        }
    }
    func getError()->Int {
        return lastErrorReceived
    }
    func getEtaMins()->Double {
        let etaMinsRet = floor(self.startTimeUTCSeconds.timeIntervalSinceNow / 60) + 1
        if(etaMinsRet < 0) {
            // right?
            if(self.getAppointmentStatus() != .NO_APPOINTMENT) {
                self.lastErrorReceived = CONSTS.ErrorNum.RETURNING_MISSED.rawValue
            } else {
                self.lastErrorReceived = CONSTS.ErrorNum.NO_SPOTS_AVAILABLE.rawValue
            }
            self.setHasNumber(hasNumber: false)
            self.setIsReservation(isReservation: false)
        }
        return etaMinsRet
        
    }
    func getCurrentId()->Int {
        return currentId
    }
    func getUpcomingId()->Int {
        return nextId;
    }
    
    func getIsNumber()->Bool {
        return hasNumber
    }
    func getIsReservation()->Bool {
        return hasReservation
    }
    func getAppointmentStatus()->CONSTS.AppointmentStatus {
        if(hasReservation) {
            return .HAS_RESERVATION
        } else if(hasNumber) {
            return .HAS_NUMBER
        } else {
            return .NO_APPOINTMENT
        }
    }
    func appointmentUnchanged(newAppointment:Appointment) -> Bool {
        if(self.getAppointmentStatus() == newAppointment.getAppointmentStatus()
            && self.getUpcomingId() == newAppointment.getUpcomingId()
            ) {
            return true
        } else {
            return false
        }
    }
    func isValid() -> Bool {
        return self.startTimeUTCSeconds > Date()
    }
}
