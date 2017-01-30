//
//  CONSTS.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/22/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation


class CONSTS {
    class func GET_ERROR_TEXT(_ errorId : Int) -> String {
        switch errorId {
        case -888: return "Exception hit. We'd really appreciate if you call Peter and tell him how it happened."
        case -500: return "Can't get any information. Call Peter to see what's up."
        case -38: return "Looks like you don't have a number yet."
        case -37: return "You're haircut is now"
        case -36: return "Did you miss your appointment?"
        case -35: return "Are you sure you want a haircut this time?"
        case -34: return "Welcome back"
        case -10: return "Cancel unsuccessful, call Peter to cancel"
        case -9:  return "Unknown response, restart the app or call Peter"
        case -8:  return "Invalid time requested, try again or call Peter"
        case -7:  return "You already have an appointment"
        case -5:  return "Get Number Failed. Call Peter."
        case -3:  return "Sorry, no longer available. Someone just took that spot"
        case -2:  return "Barber shop is closed. General hours: 11AM - 9PM Mon - Sat. You can reserve a spot starting at 9AM."
        case -1:  return "No more spots available"
        default:  return "Whoa, something is very wrong. Call Peter and let him know. Sorry aboutt that." // NON-SERVER response
        }
    }
    
    
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
    
    // Only for the ones that need this!
    class func GET_ERROR_CODE(_ errorAction : String) -> Int {
        switch errorAction {
        case "GET_NUM_FAIL": return -5
        case "DEL_NUM_FAIL": return -10
        case "UNEXPECTED_VAL": return -500      // non-server response code
        case "EXCEPTION": return -888           // non-server response
            
        default: return -888                    // non-server response
        }
    }
    
    
}
