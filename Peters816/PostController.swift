//
//  PostController.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/22/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation

class PostController {
    var GET_ETA_REQUEST:NSMutableURLRequest!
    var GET_ETA_SESSION:NSURLSession!
    var GET_NUMBER_POST_REQUEST:NSMutableURLRequest!
    var GET_NUMBER_POST_SESSION:NSURLSession!
    var APP_REQUEST_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request2.php")!
    var GET_ETA_PARAM:String = "get_next_num=1"
    var postHasNumber = false


    // Kind of unrelated, do they need their own methods?
    var GET_OPEN_SPOTS_REQUEST:NSMutableURLRequest!
    var GET_OPEN_SPOTS_SESSION:NSURLSession!
    var GET_QUEUE_PARAMS:String = "get_available=1" // returns open spots with id and start_time
    
    func getOpeningsPostRequest() -> NSMutableURLRequest {
        if(GET_OPEN_SPOTS_REQUEST == nil) {
            GET_OPEN_SPOTS_REQUEST = NSMutableURLRequest(URL: APP_REQUEST_URL)
            GET_OPEN_SPOTS_REQUEST.HTTPMethod = "POST"
        }
        return GET_OPEN_SPOTS_REQUEST
    }
    func getOpeningsPostSession() -> NSURLSession {
        if(GET_OPEN_SPOTS_SESSION == nil) {
            GET_OPEN_SPOTS_SESSION = NSURLSession.sharedSession()
        }
        return GET_OPEN_SPOTS_SESSION
    }
    // end reservation methods
    
    
    func getEtaPostRequest() -> NSMutableURLRequest {
        if(GET_ETA_REQUEST == nil) {
            GET_ETA_REQUEST = NSMutableURLRequest(URL: APP_REQUEST_URL)
            GET_ETA_REQUEST.HTTPMethod = "POST"
        }
        return GET_ETA_REQUEST
    }
    func getEtaPostSession() -> NSURLSession {
        if(GET_ETA_SESSION == nil) {
            GET_ETA_SESSION = NSURLSession.sharedSession()
        }
        return GET_ETA_SESSION
    }
    func getNumberPostRequest() -> NSMutableURLRequest {
        if(GET_NUMBER_POST_REQUEST == nil) {
            GET_NUMBER_POST_REQUEST = NSMutableURLRequest(URL: APP_REQUEST_URL)
            GET_NUMBER_POST_REQUEST.HTTPMethod = "POST"
        }
        return GET_NUMBER_POST_REQUEST
    }
    func getNumberPostSession() -> NSURLSession {
        if(GET_NUMBER_POST_SESSION == nil) {
            GET_NUMBER_POST_SESSION = NSURLSession.sharedSession()
        }
        return GET_NUMBER_POST_SESSION
    }
    //TODO::: CHECK FOR DATA CONNECTION; ALERT IF FALSE
    
    // Set the request parms
    func setEtaPostParam(nameParam:String?=nil, phoneParam:String?=nil) {
        if let nameUnwrapped = nameParam {
            if let phoneUnwrapped = phoneParam {
                GET_ETA_PARAM = "etaName=\(nameUnwrapped)&etaPhone=\(phoneUnwrapped)"
                postHasNumber = true
                return
            }
        }

        // Fall through -- name or phone input was nil
        GET_ETA_PARAM = "get_next_num=1"
        postHasNumber = false
    }

    // Check if user has an existing appointment
    // Possible errors returned:
    //      <1,2,9>,<34,35,37,38>
    func getEta(completionHandler:(etaResponse:[String: AnyObject]) -> Void!) {
        var etaResponse = [String: AnyObject]()
        
        getEtaPostRequest().HTTPBody = self.GET_ETA_PARAM.dataUsingEncoding(NSUTF8StringEncoding)
        let task = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil {
                etaResponse.updateValue(-500, forKey: "error")
                completionHandler(etaResponse: etaResponse)
                return
            } else {
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]
                    var errorHit = false
                    if let errorVal = responseJSON[0]["error"] {
                        self.setEtaPostParam()
                        etaResponse.updateValue(errorVal as! Int, forKey: "error")
                        errorHit = true
                        
                        let fatalInd = responseJSON[0]["fatal"] as! Int
                        if(fatalInd == 1) {
                            // Fatal error -- 1,2,9 -- these are only returned when user does not have a number (i.e. getNextNum)
                            // TODO: handle fatal error
                            completionHandler(etaResponse: etaResponse)
                            return
                        } else {  // Non-fatal error from etaName and etaPhone (user does not have a number)
                            // User does not have a number, still got a valid eta response
                            if let getNextNumErrorVal = responseJSON[1]["error"] { // these would only be returned by getNextNum and should always be fatal
                                etaResponse.updateValue(getNextNumErrorVal, forKey: "error2") // this is ONLY used in the fatalErrorHandler
                                let getNextNumFatalInd = responseJSON[1]["fatal"] as! Int
                                if(getNextNumFatalInd == 1) {
                                    // Fatal error -- 1,2,9
                                    // TODO: handle FATAL ERROR
                                } else {
                                    // Currently cannot reach this spot, as the second-level errors are always fatal. Treat as fatal, may be changed in the future as needed
                                }
                                completionHandler(etaResponse: etaResponse)
                                return
                            } else {
                                // Non-fatal error -- 34,35,37,38; received valid eta response from getNextNum
                            }
                        }
                        etaResponse.updateValue(0, forKey: "hasNumBool")
                    } else {
                        etaResponse.updateValue(self.postHasNumber, forKey: "hasNumBool")
                    }

                    // Will be returned whether user has a number or not
                    //var etaMinsArray = [(Int, Double)]()
                    if(errorHit == false) { // this means NO error was found
                        let etaResponseArray = responseJSON[0]["etaArray"] as! [[String: AnyObject]]
                        for i in 1...etaResponseArray.count {
                            let etaMinVal = etaResponseArray[i-1]["etaMins"] as! Double
                            //let etaId = etaResponseArray[i-1]["id"] as! Int
                            etaResponse.updateValue(etaMinVal, forKey: "etaMinsSingle")
                        }
                    } else { // non-fatal error was hit
                        self.setEtaPostParam()
                        var responseRecord:[[String: AnyObject]]
                        if(errorHit) { // e.g. need to go into array index 1
                            responseRecord = responseJSON[1]["etaArray"] as! [[String: AnyObject]]
                        } else {
                            // go into array index 0
                            responseRecord = responseJSON[0]["etaArray"] as! [[String: AnyObject]]
                        }
                        let etaMinVal = responseRecord[0]["etaMins"] as! Double
                        //let etaId = responseRecord[0]["id"] as! Int
                        etaResponse.updateValue(etaMinVal, forKey: "etaMinsSingle")
                    }
                    completionHandler(etaResponse: etaResponse)
                    return
                } catch {
                    print("Exception in postController -- getEta")
                }
            }
        }

        task.resume()
    }
    
    // Get a number
    // Possible errors returned: <2,5,7>
    func getNumber(inId:Int?=nil, inName:String, inPhone:String, numRes:Int?=1, inEmailParm:String?=nil, completionHandler:(getNumResponse:[String: AnyObject]) -> Void!) {
        var reservationInd = false
        var GET_NUM_PARAM = "user_name=\(inName)&user_phone=\(inPhone)&numRes=\(numRes)\(inEmailParm)"
        
        // User is making a reservation
        if let inIdUnwrapped = inId {
            GET_NUM_PARAM += "&get_res=\(String(inIdUnwrapped))"
            reservationInd = true
        }
        getNumberPostRequest().HTTPBody = GET_NUM_PARAM.dataUsingEncoding(NSUTF8StringEncoding)

        var getNumResponse = [String: AnyObject]()

        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()) { data,response,error in
            if error != nil {
                getNumResponse.updateValue(-500, forKey: "error")
                self.setEtaPostParam()
                completionHandler(getNumResponse: getNumResponse)
                return
            } else { // No http error
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]
                    
                    // First make sure an expected response was received
                    if let getNumError = responseJSON[0]["error"] {
                        let getNumFatal = responseJSON[0]["fatal"] as! Int
                        getNumResponse.updateValue(getNumError as! Int, forKey: "error")
                        if(getNumFatal == 1) {
                            self.setEtaPostParam()
                            completionHandler(getNumResponse: getNumResponse)
                            return
                        }
                    }

                    // User does have a number at this point
                    self.setEtaPostParam(inName, phoneParam: inPhone)

                    if(reservationInd) {
                        getNumResponse.updateValue(responseJSON[0]["id"] as! Int, forKey: "id")
                        // TODO: add etaMins here?
                        completionHandler(getNumResponse: getNumResponse)
                    } else {
                        var getNumArray = [Int: Double]()
                        for i in 1...responseJSON.count {
                            getNumArray.updateValue(responseJSON[i-1]["etaMins"] as! Double, forKey: responseJSON[i-1]["id"] as! Int)
                        }
                        getNumResponse.updateValue(getNumArray, forKey: "getNumArray")
                        completionHandler(getNumResponse:getNumResponse)
                    }
                    return
                } catch {
                    // TODO: Exception
                    print("Exception in PostController -- getNum")
                }
            }
        }
        task.resume()
    }
    
    // Cancel Appointment
    // Possible Errors returned: <-10>

    func cancelAppointment(delName: String, delPhone: String, completionHandler:(delResponse:[String:AnyObject]) -> Void!) {
        let DEL_NUM_PARAM = "deleteName=\(delName)&deletePhone=\(delPhone)"
        getNumberPostRequest().HTTPBody = DEL_NUM_PARAM.dataUsingEncoding(NSUTF8StringEncoding)
        
        var cancelResponse = [String: AnyObject]()
        
        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
            if error != nil{
                cancelResponse.updateValue(-500, forKey: "error")
                completionHandler(delResponse: cancelResponse)
                return
            } else {
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                    let delResult: Int = responseJSON["delResult"] as! Int
                    self.setEtaPostParam()
                    cancelResponse.updateValue(delResult, forKey: "error")
                    completionHandler(delResponse:cancelResponse)
                    return
                } catch {
                    // TODO: need to do some cleanup here
                    // cancelResponse.updateValue(-500, forKey: "error")
                    print("Exception in PostController -- cancel")
                }
            }
        }
        task.resume()
    }
    
    // Get available reservations
    func getOpenings(completionHandler:(openingsArray:[String: AnyObject]) -> Void!)  {
        getOpeningsPostRequest().HTTPBody = GET_QUEUE_PARAMS.dataUsingEncoding(NSUTF8StringEncoding)

        var openingsArray = [String: AnyObject]()
        let task = getOpeningsPostSession().dataTaskWithRequest(getOpeningsPostRequest()) { data,response, error in
            if error != nil {
                openingsArray.updateValue(-500, forKey: "error")
                completionHandler(openingsArray: openingsArray)
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]
                if let errorId = responseJSON[0]["error"] {
                    let errorFatalInd = responseJSON[0]["fatal"] as! Int
                    if(errorFatalInd == 1) { // presently only fatal errors are being thrown
                        openingsArray.updateValue(errorId as! Int, forKey: "error")
                        completionHandler(openingsArray: openingsArray)
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
                openingsArray.updateValue(availableSpotsArray, forKey: "availableSpotsArray")
                openingsArray.updateValue(availableSpots, forKey: "availableSpots")
                completionHandler(openingsArray: openingsArray)
                return
            } catch {
                // TODO: handle error
                print("Exception in PostController -- getOpenings")
            }
        }
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








