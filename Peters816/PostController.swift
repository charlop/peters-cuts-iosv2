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
    
    var GET_CLOSED_MESSAGE_POST_REQUEST:URLRequest!
    var GET_CLOSED_MESSAGE_POST_SESSION:URLSession!
    
    var APP_REQUEST_URL:URL = URL(string: "http://peterscuts.com/lib/app_request2.php")!
    var GET_ETA_PARAM:String = "get_next_num=1"
    var GET_MESSAGE_PARM:String = "getClosedMessage=1"
    var postHasNumber = 0
    
    
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
    
    // Set the request parms
    func setEtaPostParam(_ nameParam:String?=nil, phoneParam:String?=nil) {
        if let nameUnwrapped = nameParam {
            if let phoneUnwrapped = phoneParam {
                GET_ETA_PARAM = "etaName=\(nameUnwrapped)&etaPhone=\(phoneUnwrapped)"
                postHasNumber = 1
                return
            }
        }
        
        // Fall through -- name or phone input was nil
        GET_ETA_PARAM = "get_next_num=1"
        postHasNumber = 0
    }
    
    // Check if user has an existing appointment
    // Possible errors returned:
    //      <1,2,9>,<34,35,37,38>
    func getEta(_ completionHandler:@escaping (_ etaResponse:[String: AnyObject]) -> Void!) {
        var etaResponse = [String: AnyObject]()
        
        var getEtaPost = getEtaPostRequest()
        getEtaPost.httpBody = self.GET_ETA_PARAM.data(using: String.Encoding.utf8)
        
        let task = getEtaPostSession().dataTask(with: getEtaPost, completionHandler: { data,response,error in
            if error != nil {
                etaResponse.updateValue(-500 as AnyObject, forKey: "error")
                completionHandler(etaResponse)
                return
            } else {
                do {
                    
                    var responseJSON:[Dictionary<String,AnyObject>] = [[:],[:]]
                    if let dataUnwrapped = data {
                        let responseJSONWrapped = try JSONSerialization.jsonObject(with: dataUnwrapped, options: []) as? [[String:AnyObject]]
                        
                        if(responseJSONWrapped == nil) {
                            // fatal error was hit...
                            
                            responseJSON[0]["error"] = -38 as AnyObject
                            responseJSON[0]["fatal"] = 0 as AnyObject
                            responseJSON[1]["error"] = -2 as AnyObject
                            responseJSON[1]["fatal"] = 1 as AnyObject
                        } else {
                            responseJSON = responseJSONWrapped!
                        }
                    }
                    
                    var errorHit = false
                    if let errorVal = responseJSON[0]["error"] {
                        self.setEtaPostParam()
                        etaResponse.updateValue(errorVal as AnyObject, forKey: "error")
                        errorHit = true
                        
                        let fatalInd = responseJSON[0]["fatal"] as! Int
                        if(fatalInd == 1) {
                            // Fatal error -- 1,2,9 -- these are only returned when user does not have a number (i.e. getNextNum)
                            completionHandler(etaResponse)
                            return
                        } else {  // Non-fatal error from etaName and etaPhone (user does not have a number)
                            // User does not have a number, still got a valid eta response
                            if let getNextNumErrorVal = responseJSON[1]["error"] { // these would only be returned by getNextNum and should always be fatal
                                etaResponse.updateValue(getNextNumErrorVal, forKey: "error2") // this is ONLY used in the fatalErrorHandler
                                let getNextNumFatalInd = responseJSON[1]["fatal"] as! Int
                                if(getNextNumFatalInd == 1) {
                                    // Fatal error -- 1,2,9
                                    completionHandler(etaResponse)
                                    return
                                } else {
                                    // Currently cannot reach this spot, as the second-level errors are always fatal. Treat as fatal, may be changed in the future as needed
                                }
                                completionHandler(etaResponse)
                                return
                            } else {
                                // Non-fatal error -- 34,35,37,38; received valid eta response from getNextNum
                            }
                        }
                        etaResponse.updateValue(0 as AnyObject, forKey: "hasNumBool")
                    } else {
                        etaResponse.updateValue(self.postHasNumber as AnyObject, forKey: "hasNumBool")
                    }
                    
                    if(errorHit == false) { // this means NO error was found
                        let etaResponseArray = responseJSON[0]["etaArray"] as! [[String: AnyObject]]
                        
                        // TODO: replace this with the commented code below, currently only using the first number even if customer has multiple appointments
                        let etaMinVal = etaResponseArray[0]["etaMins"] as! Double
                        let custEtaId = etaResponseArray[0]["id"] as! Int
                        let curId = etaResponseArray[0]["curNum"] as! Int
                        
                        // Todo: the next 4 lines should be handled with a try/catch or something?
                        etaResponse.updateValue(0 as AnyObject, forKey: "isReservation")
                        if let isReservationUnwrapped = etaResponseArray[0]["reservation"] {
                            let isReservation = isReservationUnwrapped as! Int
                            etaResponse.updateValue(isReservation as AnyObject, forKey: "isReservation")
                        }
                        etaResponse.updateValue(etaMinVal as AnyObject, forKey: "etaMinsSingle")
                        etaResponse.updateValue(custEtaId as AnyObject, forKey: "custEtaSingle")
                        etaResponse.updateValue(curId as AnyObject, forKey: "curCustNum")
                        
                    // TODO: previous code (commented below) stores only the LAST appointment; would not give accurate ETA
                    /*
                        for i in 1...etaResponseArray.count {
                            let etaMinVal = etaResponseArray[i-1]["etaMins"] as! Double
                            //let etaId = etaResponseArray[i-1]["id"] as! Int
                            etaResponse.updateValue(etaMinVal as AnyObject, forKey: "etaMinsSingle")
                        }
                    */
                    } else { // non-fatal error was hit (customer does not have a number)
                        self.setEtaPostParam()
                        var responseRecord:[[String: AnyObject]]
                        responseRecord = responseJSON[1]["etaArray"] as! [[String: AnyObject]]
                        let etaMinVal = responseRecord[0]["etaMins"] as! Double
                        let custEtaId = responseRecord[0]["id"] as! Int // this is the next available #
                        let curId = responseRecord[0]["curNum"] as! Int
                        etaResponse.updateValue(etaMinVal as AnyObject, forKey: "etaMinsSingle")
                        etaResponse.updateValue(custEtaId as AnyObject, forKey: "custEtaSingle")
                        etaResponse.updateValue(curId as AnyObject, forKey: "curCustNum")
                        etaResponse.updateValue(0 as AnyObject, forKey: "isReservation") // will be accessed in the completionHandler whether customer has num or not.
                    }
                    completionHandler(etaResponse)
                    return
                } catch {
                    print("error hit in PostController.getEta()")
                }
                
            }
        })
        task.resume()
    }
    
    // Get a number
    // Possible errors returned: <2,5,7>
    func getNumber(_ inId:Int?=nil, inName:String, inPhone:String, numRes:Int?=1, inEmailParm:String?=nil, completionHandler:@escaping (_ getNumResponse:[String: AnyObject]) -> Void!) {
        var reservationInd = false
        var GET_NUM_PARAM = "user_name=\(inName)&user_phone=\(inPhone)&numRes=\(numRes!)"
        
        // User is making a reservation
        if let inIdUnwrapped = inId {
            GET_NUM_PARAM += "&get_res=\(String(inIdUnwrapped))"
            reservationInd = true
        }
        var getNumPostReq = getNumberPostRequest()
        getNumPostReq.httpBody = GET_NUM_PARAM.data(using: String.Encoding.utf8)
        
        var getNumResponse = [String: AnyObject]()
        
        let task = getNumberPostSession().dataTask(with: getNumPostReq, completionHandler: { data,response,error in
            if error != nil {
                getNumResponse.updateValue(-500 as AnyObject, forKey: "error")
                self.setEtaPostParam()
                completionHandler(getNumResponse)
                return
            } else { // No http error
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String: AnyObject]]
                    
                    // First make sure an expected response was received
                    if let getNumError = responseJSON[0]["error"] {
                        let getNumFatal = responseJSON[0]["fatal"] as! Int
                        getNumResponse.updateValue(getNumError as AnyObject, forKey: "error")
                        if(getNumFatal == 1) {
                            self.setEtaPostParam()
                            completionHandler(getNumResponse)
                            return
                        }
                    }
                    
                    // User does have a number at this point
                    self.setEtaPostParam(inName, phoneParam: inPhone)
                    
                    if(reservationInd) {
                        getNumResponse.updateValue(responseJSON[0]["id"] as AnyObject, forKey: "id")
                        // TODO: add etaMins here?
                        completionHandler(getNumResponse)
                    } else {
                        var getNumArray = [Int: Double]()
                        for i in 1...responseJSON.count {
                            getNumArray.updateValue(responseJSON[i-1]["etaMins"] as! Double, forKey: responseJSON[i-1]["id"] as! Int)
                        }
                        getNumResponse.updateValue(getNumArray as AnyObject, forKey: "getNumArray")
                        completionHandler(getNumResponse)
                    }
                    return
                } catch {
                    getNumResponse.updateValue(-888 as AnyObject, forKey: "error")
                    completionHandler(getNumResponse)
                    return
                }
            }
        }) 
        task.resume()
    }
    
    // Cancel Appointment
    // Possible Errors returned: <-10>
    
    func cancelAppointment(_ delName: String, delPhone: String, completionHandler:@escaping (_ delResponse:[String:AnyObject]) -> Void!) {
        let DEL_NUM_PARAM = "deleteName=\(delName)&deletePhone=\(delPhone)"
        var getNumPostReq = getNumberPostRequest()
        getNumPostReq.httpBody = DEL_NUM_PARAM.data(using: String.Encoding.utf8)
        
        var cancelResponse = [String: AnyObject]()
        
        let task = getNumberPostSession().dataTask(with: getNumPostReq, completionHandler: { data,response,error in
            if error != nil{
                cancelResponse.updateValue(-500 as AnyObject, forKey: "error")
                completionHandler(cancelResponse)
                return
            } else {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []  ) as! [[String: AnyObject]]
                    
                    var delResult:Int = 0
                    
                    if let delResultRaw = responseJSON[0]["delResult"] {
                        delResult = delResultRaw as! Int
                    } else if let delResultRaw = responseJSON[0]["error"] {
                        delResult = delResultRaw as! Int
                    }
                    
                    self.setEtaPostParam()
                    cancelResponse.updateValue(delResult as AnyObject, forKey: "error")
                    completionHandler(cancelResponse)
                    return
                } catch {
                    cancelResponse.updateValue(-500 as AnyObject, forKey: "error")
                    completionHandler(cancelResponse)
                    return
                }
            }
        })
        task.resume()
    }
    
    // Get available reservations
    func getOpenings(_ completionHandler:@escaping (_ openingsArray:[String: AnyObject]) -> Void!)  {
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
    
    func getClosedMessage(_ completionHandler:@escaping (_ closedMessage:String) -> Void!) {
        var getClosedMessagePostReq = getClosedMessagePostRequest()
        getClosedMessagePostReq.httpBody = GET_MESSAGE_PARM.data(using: String.Encoding.utf8)
        
        let task = getClosedMessagePostSession().dataTask(with: getClosedMessagePostRequest(), completionHandler: { data,response, error in
            if error != nil {
                completionHandler("-500")
                return
            }
            if let retString = String(data: data!, encoding: String.Encoding.utf8) {
                completionHandler(retString)
            }
            return
        }) 
        task.resume()
    }
    // Make a reservation
    // Possible errors: <2,3,8>
    /* THIS SHOULDN'T EXIST!!!
     func getReservation(inId:Int, inName:String, inPhone:String, completionHandler:(reservationSuccess:Bool) -> Void!) {
     let getResParam = "get_res=\(String(inId))&user_name=\(inName)&user_phone=\(inPhone)"
     getOpeningsPostRequest().HTTPBody = getResParam.dataUsingEncoding(NSUTF8StringEncoding)
     
     let task = getOpeningsPostSession().dataTaskWithRequest(getOpeningsPostRequest()) { data,response, error in
     if error != nil {
     completionHandler(reservationSuccess: false)
     return
     }
     do {
     let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
     if let gotId = responseJSON["id"] {
     if(gotId as! Int > 0) {
     completionHandler(reservationSuccess: true)
     return
     }
     }
     
     // Fall-through, anything beyond here failed.
     completionHandler(reservationSuccess: false)
     return
     
     /* --- this may be a good idea ot include in the future
     if let errorId = responseJSON[0]["error"] {
     let errorFatalInd = responseJSON[0]["fatal"] as! Int
     if(errorFatalInd == 1) { // presently only fatal errors are being thrown
     completionHandler(reservationSuccess: false)
     completionHandler(openingsArray: openingsArray)
     }
     }
     
     var availableSpots = [String]()
     for i in 1...responseJSON.count {
     let curStartTime = responseJSON[i-1]["start_time"] as! String
     //let curId = responseJSON[i-1]["id"] as! Int
     availableSpots.append(curStartTime)
     }
     openingsArray.updateValue(availableSpots, forKey: "availableSpots")
     completionHandler(openingsArray: openingsArray)
     */
     
     
     
     } catch {
     // TODO: handle error
     print("Exception in PostController -- getOpenings")
     }
     }
     task.resume()
     }
     */
}
