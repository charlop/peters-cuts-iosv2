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
    //      get_next_num <-1, -2, -9>
    //      etaName <34,35,36>
    var validatingFlag = false
    func getEta() -> [String: AnyObject] {
        var etaResponse = [String: AnyObject]()
        
        getEtaPostRequest().HTTPBody = self.GET_ETA_PARAM.dataUsingEncoding(NSUTF8StringEncoding)
        let task = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil {
                etaResponse.updateValue(-500, forKey: "error")
            } else {
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [[String: AnyObject]]
                    
                    
                    // User has number indicator -- needs to be returned
                    let hasNum:Bool = responseJSON[0]["hasNum"] as! Int > 0 ? true : false
                    
                    if(hasNum == false && self.postHasNumber == true) {
                        self.setEtaPostParam()
                    }
                    etaResponse.updateValue(hasNum, forKey: "hasNumBool")
                    
                    var etaMinsArray = [Int: Double]()
                    for i in 1...responseJSON.count {
                        let etaMinVal = responseJSON[i-1]["etaMins"] as! Double
                        if(etaMinVal < 0) {
                            if(self.validatingFlag || self.postHasNumber == false ||
                                (etaMinVal >= -36 && etaMinVal <= -34)
                            ) {
                                etaResponse.updateValue(Int(etaMinVal), forKey: "error")
                                self.validatingFlag = false
                                break
                            } else { // TODO: this is more complex, user does not have a number; calling function again but with postHasNumber = false
                                self.setEtaPostParam()
                                self.getEta()
                            }
                        } else {
                            etaMinsArray.updateValue(etaMinVal, forKey: responseJSON[i-1]["id"] as! Int)
                        }
                    }
                    etaResponse.updateValue(etaMinsArray, forKey: "etaMinsArray")
                    
                    // TBD if this should be handled here, probably not
                    //if(etaMinsResponse > 0) {
                    
                } catch {
                    print("Exception in postController -- getEta")
                }
            }
        }

        task.resume()
        
        
        // FUCK FUCK FUCK -- i guess this is async and it can't be returned...gonna have to rethink this entire fucking thing. Fuck it all to hell
        return etaResponse
    }
    
    // Get a number
    // Possible errors returned: <2, 7>
    func getNumber(inName:String, inPhone:String, numRes:Int, inEmailParm:String) -> [String: AnyObject] {
        let GET_NUM_PARAM = "user_name=\(inName)&user_phone=\(inPhone)&numRes=\(numRes)\(inEmailParm)"
        getNumberPostRequest().HTTPBody = GET_NUM_PARAM.dataUsingEncoding(NSUTF8StringEncoding)
        
        var getNumResponse = [String: AnyObject]()
        
        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()) { data,response,error in
            if error != nil {
                getNumResponse.updateValue(-500, forKey: "error")
                self.setEtaPostParam()
            } else { // No http error
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]
                    
                    // First make sure an expected response was received
                    let id1Num: Int = responseJSON[0]["id1"] as! Int
                    var getNumArray = [Int: Double]()

                    var validateError = 0
                    if(id1Num < 1) { // Error was received
                        if(id1Num == CONSTS.GET_ERROR_CODE("GET_NUM_FAIL")) {
                            self.setEtaPostParam(inName, phoneParam: inPhone)

                            self.validatingFlag = true
                            let validateNumReceived = self.getEta()
                            if let hasNumUnwrapped = validateNumReceived["hasNumBool"] {
                                // GetNum actually succeeded
                                let hasNumBool = hasNumUnwrapped as! Bool
                                if(hasNumBool) {
                                    getNumArray = validateNumReceived["etaMinsArray"] as! [Int : Double]
                                } else if let errorIdUnwrapped = validateNumReceived["error"]{
                                    validateError = errorIdUnwrapped as! Int
                                }
                            }
                            
                            if(validateError < 0) {
                                getNumResponse.updateValue(validateError, forKey: "error")
                                self.setEtaPostParam()
                            }
                        } else {
                            getNumResponse.updateValue(id1Num, forKey: "error")
                            self.setEtaPostParam()
                        }
                    } else {
                        self.setEtaPostParam(inName, phoneParam: inPhone)
                        for i in 1...responseJSON.count {
                            let curId:String = "id" + String(i)
                            let startTm:String = "start_time" + String(i)
                            getNumArray.updateValue(responseJSON[i-1][startTm] as! Double, forKey: responseJSON[i-1][curId] as! Int)
                        }
                        getNumResponse.updateValue(getNumArray, forKey: "getNumArray")
                    }
                } catch {
                    // TODO: Exception
                    print("Exception in PostController -- getNum")
                }
            }
        }
        task.resume()
        
        return getNumResponse
    }
    
    // Cancel Appointment
    // Possible Errors returned: <-10>
    func cancelAppointment(delName: String, delPhone: String) -> [String: AnyObject] {
        let DEL_NUM_PARAM = "deleteName=\(delName)&deletePhone=\(delPhone)"
        getNumberPostRequest().HTTPBody = DEL_NUM_PARAM.dataUsingEncoding(NSUTF8StringEncoding)
        
        var cancelResponse = [String: AnyObject]()
        
        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
            if error != nil{
                cancelResponse.updateValue(-500, forKey: "error")
            } else {
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                    let delResult: Int = responseJSON["delResult"] as! Int
                    if(delResult > 0) { // Delete succeeded
                        self.setEtaPostParam()
                    } else { // Delete possibly did not succeed
                        self.setEtaPostParam(delName, phoneParam: delPhone)
                        self.validatingFlag = true
                        let delValidateResponse = self.getEta()
                        var validateError = 0
                        if let hasNumUnwrapped = delValidateResponse["hasNumBool"] {
                            // Delete actually succeeded
                            let hasNumBool = hasNumUnwrapped as! Bool
                            if(hasNumBool == false) {
                                self.setEtaPostParam()
                            } else if let errorIdUnwrapped = delValidateResponse["error"]{
                                validateError = errorIdUnwrapped as! Int
                            }
                        }
                        if(validateError < 0) {
                            cancelResponse.updateValue(validateError, forKey: "error")
                            self.setEtaPostParam()
                        } else {
                            cancelResponse.updateValue(delResult, forKey: "error")
                            self.setEtaPostParam()
                        }
                    }
                } catch {
                    // TODO: need to do some cleanup here
                    // cancelResponse.updateValue(-500, forKey: "error")
                    print("Exception in PostController -- cancel")
                }
            }
        }
        task.resume()

        return cancelResponse
    }

}
