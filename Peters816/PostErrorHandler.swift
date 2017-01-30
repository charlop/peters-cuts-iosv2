//
//  PostErrorHandler.swift
//  Peters816
//
//  Handles network errors
//  Created by Chris Charlopov on 10/25/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation

class PostErrorHandler {
    var errFlag = 0
    // Handle errors here whenever possible
    func handleError(_ errorId : Int, errorAction : String) {
        if(errFlag > 2) {
            // this should to be done in the main class
            //self.sendNotification("Fail", messageText: CONSTS.GET_ERROR_TEXT(errorId))
            errFlag = 0
        }
        errFlag += 1
        
        
        return
        
        // THOUGHT STARTERS
        // THIS NEEDS TO BE AN INTEGER RESPONSE PERHAPS??
        // TODO: error hadnling
        //self.sendNotification("Fail...", messageText: getNumResponseError as! Int)
        // TODO: set the wait time or any session parameters here??
        //self.sendNotification("Hey!", messageText: "")
        //userDefaults.removeAllNumbers()
        //return
    }
}
