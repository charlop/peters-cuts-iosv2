//
//  CONSTS.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/22/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation


class CONSTS {
    enum AppointmentStatus {
        case NO_APPOINTMENT
        case HAS_NUMBER
        case HAS_RESERVATION
        case SHOP_CLOSED
        case NO_USER_INFO
        case LOADING_VIEW
    }
    enum ErrorNum:Int {
        case UNK = -999
        case EXCEPTION = -888
        case NO_INTERNET = -777
        case NON_SERVER_ERROR = -500
        case NO_NUMBER = -38 // Should be NO_ERROR
        case ACTIVE = -37
        case RETURNING_MISSED = -36
        case DELETED = -35
        case RETURNING_SUCCESS = -34
        case CANCEL_FAIL = -10
        case SERVER_ERROR = -9
        case INVALID_TIME = -8
        case DUPLICATE = -7
        case GET_NUMBER_FAIL = -5
        case GET_RESERVATION_FAIL = -3
        case SHOP_CLOSED = -2
        case NO_SPOTS_AVAILABLE = -1
        case NO_ERROR = 0
    }
    enum ErrorDescription:String {
        case UNK = "Whoa, something is very wrong. Call Peter and let him know. Sorry aboutt that." // non-fatal, NON-SERVER response
        case NO_INTERNET = "Trying to connect..." // non-fatal, non-server response
        case EXCEPTION = "Exception hit. We'd really appreciate if you call Peter and tell him how it happened." // fatal, non-server response
        case NON_SERVER_ERROR = "Can't get any information. Call Peter to see what's up." // fatal, non-server response
        case NO_NUMBER = "Looks like you don't have a number yet." // non-fatal
        case ACTIVE = "You're haircut is now" // non-fatal
        case RETURNING_MISSED = "Did you miss your appointment?" // non-fatal
        case DELETED = "Are you sure you want a haircut this time?" // non-fatal
        case RETURNING_SUCCESS = "Welcome back" // non-fatal
        case CANCEL_FAIL = "Cancel unsuccessful, call Peter to cancel" // fatal
        case SERVER_ERROR  = "Unknown response, restart the app or call Peter" // fatal
        case INVALID_TIME  = "Invalid time requested, try again or call Peter" // fatal
        case DUPLICATE  = "You already have an appointment" // non-fatal
        case GET_NUMBER_FAIL  = "Get Number Failed. Call Peter." // fatal
        case GET_RESERVATION_FAIL  = "Sorry, no longer available. Someone just took that spot" // fatal
        case SHOP_CLOSED  = "Barber shop is closed. General hours: 11AM - 9PM Mon - Sat. You can reserve a spot starting at 9AM." // fatal
        case NO_SPOTS_AVAILABLE = "No more spots available" // fatal
        case NO_ERROR = ""
    }

    class func isFatal(errorId:Int)->Bool {
        return (errorId == ErrorNum.EXCEPTION.rawValue ||
            errorId == ErrorNum.NON_SERVER_ERROR.rawValue ||
            errorId == ErrorNum.CANCEL_FAIL.rawValue ||
            errorId == ErrorNum.GET_NUMBER_FAIL.rawValue ||
            errorId == ErrorNum.SERVER_ERROR.rawValue ||
            errorId == ErrorNum.INVALID_TIME.rawValue ||
            errorId == ErrorNum.GET_RESERVATION_FAIL.rawValue ||
            errorId == ErrorNum.SHOP_CLOSED.rawValue ||
            errorId == ErrorNum.NO_SPOTS_AVAILABLE.rawValue)
    }
    class func getErrorDescription(errorId:Int) -> ErrorDescription {
        switch errorId {
        case ErrorNum.NO_INTERNET.rawValue:
            return .NO_INTERNET
        case ErrorNum.EXCEPTION.rawValue:
            return .EXCEPTION
        case ErrorNum.NON_SERVER_ERROR.rawValue:
            return .NON_SERVER_ERROR
        case ErrorNum.NO_NUMBER.rawValue:   // considering this no_error. TODO: need to update any impacted areas
            return .NO_NUMBER
        case ErrorNum.ACTIVE.rawValue:
            return .ACTIVE
        case ErrorNum.RETURNING_MISSED.rawValue:
            return .RETURNING_MISSED
        case ErrorNum.DELETED.rawValue:
            return .DELETED
        case ErrorNum.RETURNING_SUCCESS.rawValue:
            return .RETURNING_SUCCESS
        case ErrorNum.CANCEL_FAIL.rawValue:
            return .CANCEL_FAIL
        case ErrorNum.SERVER_ERROR.rawValue:
            return .SERVER_ERROR
        case ErrorNum.INVALID_TIME.rawValue:
            return .INVALID_TIME
        case ErrorNum.DUPLICATE.rawValue:
            return .DUPLICATE
        case ErrorNum.GET_NUMBER_FAIL.rawValue:
            return .GET_NUMBER_FAIL
        case ErrorNum.GET_RESERVATION_FAIL.rawValue:
            return .GET_RESERVATION_FAIL
        case ErrorNum.SHOP_CLOSED.rawValue:
            return .SHOP_CLOSED
        case ErrorNum.NO_SPOTS_AVAILABLE.rawValue:
            return .NO_SPOTS_AVAILABLE
        case ErrorNum.NO_ERROR.rawValue:
            return .NO_ERROR
        default: // this is ErrorNum.UNK.rawValue (-999)
            return .UNK
        }
    }
    
    
    /*
    // TBD: this needs to do something (isFatal, Action)
    // NON-SERVER RESPONSE CODES MUST BE FATAL
    class func GET_ERROR_ACTION(_ errorId : Int) -> (Bool, String) {
        switch errorId {
        case -888: return (true, "EXCEPTION")       // non-server response
        case -500: return (true, "UNEXPECTED_VAL") // non-server response code
        case -38: return (false, "NO_NUMBER")
        case -37: return (false, "ACTIVE")
        case -36: return (false, "RETURNING")
        case -35: return (false, "DELETED")
        case -34: return (false, "RETURNING")
            
        case -10: return (true, "FAIL")
        case -9:  return (true, "UNEXPECTED_VAL")
        case -8:  return (true, "UNEXPECTED_VAL")
            
        case -7:  return (false, "DUPLICATE")
        case -5:  return (true, "FAIL")
        case -3:  return (true, "FAIL")
        case -2:  return (true, "CLOSED")
        case -1:  return (true, "CLOSED")
        default:  return (false, "UNK")          // non-server response code
        }
    }
     */
    
}
