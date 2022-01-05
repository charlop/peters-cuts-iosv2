//
//  PostController.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/22/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation

class PostController {
    var GET_ETA_REQUEST:URLRequest!
    var GET_ETA_SESSION:URLSession!
    var GET_NUMBER_POST_REQUEST:URLRequest!
    var GET_NUMBER_POST_SESSION:URLSession!
    
    var GET_GREETING_MESSAGE_POST_REQUEST:URLRequest!
    var GET_GREETING_MESSAGE_POST_SESSION:URLSession!
    var GET_NEW_HOURS_POST_REQUEST:URLRequest!
    var GET_NEW_HOURS_POST_SESSION:URLSession!
    
    var GET_NEW_ADDR_POST_REQUEST:URLRequest!
    var GET_NEW_ADDR_POST_SESSION:URLSession!
    
    var GET_CLOSED_MESSAGE_POST_REQUEST:URLRequest!
    var GET_CLOSED_MESSAGE_POST_SESSION:URLSession!
    
    var APP_REQUEST_URL:URL = URL(string: "http://peterscuts.com/lib/app_request2.php")!
    var GET_MESSAGE_PARM:String = "getClosedMessage=1"
    var GET_GREETING_PARM:String = "getGreetingMessage=GREETING"
    var NEW_HOURS_PARM:String = "getGreetingMessage=HOURS"
    var NEW_ADDR_PARM:String = "getGreetingMessage=ADDR"
    
    // Kind of unrelated, do they need their own methods?
    var GET_OPEN_SPOTS_REQUEST:URLRequest!
    var GET_OPEN_SPOTS_SESSION:URLSession!
    var GET_QUEUE_PARAMS:String = "get_available=1" // returns open spots with id and start_time
    
    func getOpeningsPostRequest() -> URLRequest {
        if(GET_OPEN_SPOTS_REQUEST == nil) {
            GET_OPEN_SPOTS_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_OPEN_SPOTS_REQUEST.httpMethod = "POST"
        }
        return GET_OPEN_SPOTS_REQUEST
    }
    func getOpeningsPostSession() -> URLSession {
        if(GET_OPEN_SPOTS_SESSION == nil) {
            GET_OPEN_SPOTS_SESSION = URLSession.shared
        }
        return GET_OPEN_SPOTS_SESSION
    }
    // end reservation methods
    
    
    func getEtaPostRequest() -> URLRequest {
        if(GET_ETA_REQUEST == nil) {
            GET_ETA_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_ETA_REQUEST.httpMethod = "POST"
        }
        return GET_ETA_REQUEST
    }
    func getEtaPostSession() -> URLSession {
        if(GET_ETA_SESSION == nil) {
            GET_ETA_SESSION = URLSession.shared
        }
        return GET_ETA_SESSION
    }
    func getNumberPostRequest() -> URLRequest {
        if(GET_NUMBER_POST_REQUEST == nil) {
            GET_NUMBER_POST_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_NUMBER_POST_REQUEST.httpMethod = "POST"
        }
        return GET_NUMBER_POST_REQUEST
    }
    func getNumberPostSession() -> URLSession {
        if(GET_NUMBER_POST_SESSION == nil) {
            GET_NUMBER_POST_SESSION = URLSession.shared
        }
        return GET_NUMBER_POST_SESSION
    }
    func getClosedMessagePostRequest() -> URLRequest {
        if(GET_CLOSED_MESSAGE_POST_REQUEST == nil) {
            GET_CLOSED_MESSAGE_POST_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_CLOSED_MESSAGE_POST_REQUEST.httpMethod = "POST"
            
        }
        return GET_CLOSED_MESSAGE_POST_REQUEST
    }
    func getClosedMessagePostSession() -> URLSession {
        if(GET_CLOSED_MESSAGE_POST_SESSION == nil) {
            GET_CLOSED_MESSAGE_POST_SESSION = URLSession.shared
        }
        return GET_CLOSED_MESSAGE_POST_SESSION
    }
    func getGreetingMessagePostRequest() -> URLRequest {
        if(GET_GREETING_MESSAGE_POST_REQUEST == nil) {
            GET_GREETING_MESSAGE_POST_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_GREETING_MESSAGE_POST_REQUEST.httpMethod = "POST"
        }
        return GET_GREETING_MESSAGE_POST_REQUEST
    }
    func getGreetingMessagePostSession() -> URLSession {
        if(GET_GREETING_MESSAGE_POST_SESSION == nil) {
            GET_GREETING_MESSAGE_POST_SESSION = URLSession.shared
        }
        return GET_GREETING_MESSAGE_POST_SESSION
    }
    func getNewHoursPostRequest() -> URLRequest {
        if(GET_NEW_HOURS_POST_REQUEST == nil) {
            GET_NEW_HOURS_POST_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_NEW_HOURS_POST_REQUEST.httpMethod = "POST"
        }
        return GET_NEW_HOURS_POST_REQUEST
    }
    func getNewHoursPostSession() -> URLSession {
        if(GET_NEW_HOURS_POST_SESSION == nil) {
            GET_NEW_HOURS_POST_SESSION = URLSession.shared
        }
        return GET_NEW_HOURS_POST_SESSION
    }
    func getNewAddrPostSession() -> URLSession {
        if(GET_NEW_ADDR_POST_SESSION == nil) {
            GET_NEW_ADDR_POST_SESSION = URLSession.shared
        }
        return GET_NEW_ADDR_POST_SESSION
    }
    func getNewAddrPostRequest() -> URLRequest {
        if(GET_NEW_ADDR_POST_REQUEST == nil) {
            GET_NEW_ADDR_POST_REQUEST = URLRequest(url: APP_REQUEST_URL)
            GET_NEW_ADDR_POST_REQUEST.httpMethod = "POST"
        }
        return GET_NEW_ADDR_POST_REQUEST
    }
    // Returns the request parms to get ETA
    func getEtaPostParam(userDefaults:User) -> String {
        if(userDefaults.userInfoExists()) {
            return "etaName=\(userDefaults.getUserName())&etaPhone=\(userDefaults.getUserPhone())"
        } else {
            return "get_next_num=1"
        }
    }
    
    func getKeyedValueOrDefault(forKey: String, inDict: [String : AnyObject]) -> Int {
        return inDict[forKey] as? Int ?? 0
    }
    
    // Check if user has an existing appointment
    // Possible errors returned:
    //      <1,2,9>,<34,35,37,38>
    func getEta(userDefaults:User, completionHandler:@escaping (_ etaResponse:Appointment) -> Void?) {
        let etaResponse = Appointment()
        
        if(!Reachability.isConnectedToNetwork()) {
            etaResponse.updateError(newError: CONSTS.ErrorNum.NO_INTERNET.rawValue)
            userDefaults.addOrUpdateAppointment(newAppointment: etaResponse)
            completionHandler(etaResponse)
            return
        }
        var getEtaPost = getEtaPostRequest()
        getEtaPost.httpBody = self.getEtaPostParam(userDefaults: userDefaults).data(using: String.Encoding.utf8)
        
        let task = getEtaPostSession().dataTask(with: getEtaPost, completionHandler: { data,response,error in
            if(error != nil || data == nil) { // 1. Check for comm errors
                etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            } else {
                do { // 2. Decode JSON response to [[String:AnyObject]]
                    var etaResponseArray:[[String:AnyObject]]?
                    // we have already checked if data is nil above
                    if let responseJSONWrapped = try JSONSerialization.jsonObject(with: data! , options: []) as? [AnyObject] {
                        if(responseJSONWrapped.count > 1) { // Second array object is probably an error
                            if let responseJSONSecondError = responseJSONWrapped[1] as? [[String:AnyObject]] {
                                // Try to get the error value, if it exists
                                etaResponse.updateError(newError: self.getKeyedValueOrDefault(forKey: "error", inDict: responseJSONSecondError[0]))
                            } else if let responseJSONSecondElement = responseJSONWrapped[1] as? [String:AnyObject] { // second object is just dictionary
                                if(responseJSONSecondElement["etaArray"] != nil) {
                                    // user dose not have a number, but valid eta response has been received
                                    etaResponseArray = responseJSONSecondElement["etaArray"] as? [[String:AnyObject]]
                                    // try to get the error in array object 1
                                    if let responseJSONFirstElement = responseJSONWrapped[0] as? [String:AnyObject] {
                                        etaResponse.updateError(newError: self.getKeyedValueOrDefault(forKey: "error", inDict: responseJSONFirstElement))
                                    }
                                } else { // try to get the error value
                                    etaResponse.updateError(newError: self.getKeyedValueOrDefault(forKey: "error", inDict: responseJSONSecondElement))
                                }
                            } // else block not needed; checking if etaResponseArray isEmpty later
                        } else if let responseJSONCheckForNumber = responseJSONWrapped[0] as? [String:AnyObject] {// user has a number?
                            if(responseJSONCheckForNumber["etaArray"] != nil) { // user def has a number
                                etaResponseArray = responseJSONCheckForNumber["etaArray"] as? [[String:AnyObject]]
                            } else {
                                etaResponse.updateError(newError: self.getKeyedValueOrDefault(forKey: "error", inDict: responseJSONCheckForNumber))
                            }
                        }
                    }
                    if let etaResponseUnwrapped = etaResponseArray {
                        var closestEtaResponse = etaResponseUnwrapped[0]
                        for i in 1..<etaResponseUnwrapped.count {
                            if( self.getKeyedValueOrDefault(forKey:"etaMins", inDict:closestEtaResponse) >
                                self.getKeyedValueOrDefault(forKey:"etaMins", inDict:etaResponseUnwrapped[i])) {
                                closestEtaResponse = etaResponseUnwrapped[i]
                            }
                        }
                        // etaResponseArray contains values
                        etaResponse.updateError(newError: self.getKeyedValueOrDefault(forKey: "error", inDict: closestEtaResponse))
                        etaResponse.setIsReservation(isReservation: self.getKeyedValueOrDefault(forKey: "reservation", inDict: closestEtaResponse) == 1)
                        etaResponse.setHasNumber(hasNumber: self.getKeyedValueOrDefault(forKey: "hasNum", inDict: closestEtaResponse) == 1)
                        
                        etaResponse.setAppointmentStartTime(etaMinVal: Double(self.getKeyedValueOrDefault(forKey:"etaMins", inDict: closestEtaResponse)))
                        etaResponse.setNextAvailableId(nextId: self.getKeyedValueOrDefault(forKey:"id", inDict:closestEtaResponse))
                        etaResponse.setCurrentId(currentId: self.getKeyedValueOrDefault(forKey:"curNum", inDict:closestEtaResponse))
                    } else {
                        if(etaResponse.getError() == CONSTS.ErrorNum.NO_ERROR.rawValue) {
                            etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
                        }
                        etaResponse.setHasNumber(hasNumber: false)
                    }
                } catch {
                }
            }
            userDefaults.addOrUpdateAppointment(newAppointment: etaResponse)
            completionHandler(etaResponse)
            return
        })
        task.resume()
    }
    
    // Get a number
    // Possible errors returned: <2,5,7>
    func getNumber(_ userDefaults:User, numRes:Int?=1, reservationInd:Bool, inId:Int?=0,
                   completionHandler:@escaping (_ userDefaults:User) -> Void?) {
        var GET_NUM_PARAM = "user_name=\(userDefaults.getUserName())&user_phone=\(userDefaults.getUserPhone())&numRes=\(numRes!)"
        
        // User is making a reservation
        if(reservationInd && inId != 0) {
            GET_NUM_PARAM += "&get_res=\(String(inId!))"
        }
        
        if(userDefaults.getUserEmail() != "") {
            GET_NUM_PARAM += "&user_email=\(userDefaults.getUserEmail())"
        }
        var getNumPostReq = getNumberPostRequest()
        getNumPostReq.httpBody = GET_NUM_PARAM.data(using: String.Encoding.utf8)
        
        let getNumResponse = [Appointment()]
        
        let task = getNumberPostSession().dataTask(with: getNumPostReq, completionHandler: { data,response,error in
            if error != nil {
                getNumResponse[0].updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
                // changed following 2 lines 11/16
                userDefaults.removeAppointmentAtIndex(aptIndex: -1)
                //userDefaults.removeAllAppointments()
                userDefaults.addAppointment(newAppointment: getNumResponse[0])
            } else { // No http error
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String: AnyObject]]
                    
                    // First make sure an expected response was received
                    if let getNumError = responseJSON[0]["error"] {
                        getNumResponse[0].updateError(newError: getNumError as! Int)
                        userDefaults.addAppointment(newAppointment: getNumResponse[0])
                    } else { // no error was hit
                        // User does have an appointment at this point
                        var minEtaMins = (60.0 * 24) // used to find first ETA in response
                        for i in 0..<responseJSON.count {
                            let etaMinsResponse = responseJSON[i]["etaMins"] as! Double
                            if(etaMinsResponse < minEtaMins) {
                                minEtaMins = etaMinsResponse
                                
                                getNumResponse[0].setNextAvailableId(nextId: responseJSON[i]["id"] as! Int)
                                getNumResponse[0].setAppointmentStartTime(etaMinVal: etaMinsResponse)
                                getNumResponse[0].setIsReservation(isReservation: reservationInd)
                                getNumResponse[0].setHasNumber(hasNumber: !reservationInd)
                                
                                userDefaults.addAppointment(newAppointment: getNumResponse[i])
                            }
                        }
                    }
                } catch {
                    getNumResponse[0].updateError(newError: CONSTS.ErrorNum.EXCEPTION.rawValue)
                    userDefaults.addAppointment(newAppointment: getNumResponse[0])
                }
            }

            completionHandler(userDefaults)
            return
        })
        task.resume()
    }
    
    // Cancel Appointment
    func cancelAppointment(_ userDefaults: User, completionHandler:@escaping (_ delResponse:CONSTS.ErrorNum.RawValue) -> Void?) {
        let DEL_NUM_PARAM = "deleteName=\(userDefaults.getUserName())&deletePhone=\(userDefaults.getUserPhone())"
        var getNumPostReq = getNumberPostRequest()
        getNumPostReq.httpBody = DEL_NUM_PARAM.data(using: String.Encoding.utf8)
        
        var retVal = CONSTS.ErrorNum.NO_ERROR.rawValue
        let task = getNumberPostSession().dataTask(with: getNumPostReq, completionHandler: { data,response,error in
            if error != nil {
                retVal = CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
            } else {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []  ) as! [[String: AnyObject]]
                    
                    // Delete successful
                    if responseJSON[0]["delResult"] != nil {
                        retVal = CONSTS.ErrorNum.NO_ERROR.rawValue
                    } else if let delResultRaw = responseJSON[0]["error"] {
                        retVal = delResultRaw as! Int
                    }
                } catch {
                    retVal = CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
                }
            }
            
            let fatalErrorHit = CONSTS.isFatal(errorId: retVal)
            if(!fatalErrorHit) {
                // changed below 2 lines on 11/16
                userDefaults.removeAppointmentAtIndex(aptIndex: -1)
                //userDefaults.removeAllAppointments()
            }
            
            completionHandler(retVal)
            return
        })
        task.resume()
    }
    
    // TODO: this has not been modified yet!!
    // Get available reservations
    func getOpenings(_ completionHandler:@escaping (_ openingsArray:[String: AnyObject]) -> Void?)  {
        var getOpeningsPostReq = getOpeningsPostRequest()
        getOpeningsPostReq.httpBody = GET_QUEUE_PARAMS.data(using: String.Encoding.utf8)
        
        var openingsArray = [String: AnyObject]()
        let task = getOpeningsPostSession().dataTask(with: getOpeningsPostReq, completionHandler: { data,response, error in
            if error != nil {
                openingsArray.updateValue(-500 as AnyObject, forKey: "error")
                completionHandler(openingsArray)
                return
            }
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String: AnyObject]]
                if let errorId = responseJSON[0]["error"] {
                    let errorFatalInd = responseJSON[0]["fatal"] as! Int
                    if(errorFatalInd == 1) { // presently only fatal errors are being thrown
                        openingsArray.updateValue(errorId as AnyObject, forKey: "error")
                        completionHandler(openingsArray)
                        return
                    }
                }
                
                var availableSpots = [String:Int]()
                var availableSpotsArray = [String]()
                for i in 1...responseJSON.count {
                    let curStartTime = responseJSON[i-1]["start_time"] as! String
                    let curId = responseJSON[i-1]["id"] as! Int
                    availableSpots.updateValue(curId, forKey: curStartTime)
                    availableSpotsArray.append(curStartTime)
                }
                openingsArray.updateValue(availableSpotsArray as AnyObject, forKey: "availableSpotsArray")
                openingsArray.updateValue(availableSpots as AnyObject, forKey: "availableSpots")
                completionHandler(openingsArray)
                return
            } catch {
                openingsArray.updateValue(-500 as AnyObject, forKey: "error")
                completionHandler(openingsArray)
            }
        }) 
        task.resume()
    }
 
    func getClosedMessage(_ completionHandler:@escaping (_ closedMessage:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void?) {
        var getClosedMessagePostReq = getClosedMessagePostRequest()
        getClosedMessagePostReq.httpBody = GET_MESSAGE_PARM.data(using: String.Encoding.utf8)
        
        let task = getClosedMessagePostSession().dataTask(with: getClosedMessagePostReq, completionHandler: { data,response, error in
            if error != nil {
                completionHandler((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR, messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
            } else if let retString = String(data: data!, encoding: String.Encoding.utf8) {
                completionHandler((errorNum: CONSTS.ErrorNum.NO_ERROR, messageText: retString))
            }
            return
        }) 
        task.resume()
    }
    func getGreetingMessage(_ completionHandler:@escaping (_ greetingMessage:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void?) {
        var getGreetingMessagePostReq = getGreetingMessagePostRequest()
        getGreetingMessagePostReq.httpBody = GET_GREETING_PARM.data(using: String.Encoding.utf8)
        
        let task = getGreetingMessagePostSession().dataTask(with: getGreetingMessagePostReq, completionHandler: { data,response, error in
            if error != nil {
                completionHandler((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR, messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
            } else if let retString = String(data: data!, encoding: String.Encoding.utf8) {
                completionHandler((errorNum: CONSTS.ErrorNum.NO_ERROR, messageText: retString))
            }
            return
        })
        task.resume()
    }
    
    func getNewHours(_ completionHandler:@escaping (_ newHours:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void?) {
        var getNewHoursPostReq = getNewHoursPostRequest()
        getNewHoursPostReq.httpBody = NEW_HOURS_PARM.data(using: String.Encoding.utf8)
        
        let task = getNewHoursPostSession().dataTask(with: getNewHoursPostReq, completionHandler: { data,response, error in
            if error != nil {
                completionHandler((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR, messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
            } else if let retString = String(data: data!, encoding: String.Encoding.utf8) {
                completionHandler((errorNum: CONSTS.ErrorNum.NO_ERROR, messageText: retString))
            }
            return
        })
        task.resume()
    }
    func getNewAddr(_ completionHandler:@escaping (_ newAddr:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void?) {
        var getNewAddrPostReq = getNewAddrPostRequest()
        getNewAddrPostReq.httpBody = NEW_ADDR_PARM.data(using: String.Encoding.utf8)
        
        let task = getNewAddrPostSession().dataTask(with: getNewAddrPostReq, completionHandler: { data,response, error in
            if error != nil {
                completionHandler((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR, messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
            } else if let retString = String(data: data!, encoding: String.Encoding.utf8) {
                completionHandler((errorNum: CONSTS.ErrorNum.NO_ERROR, messageText: retString))
            }
            return
        })
        task.resume()
    }
}
