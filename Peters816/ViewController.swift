import UIKit
import CoreData
import Foundation
import SwiftyJSON

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var currentNumber: UILabel!
    @IBOutlet weak var staticNextNumber: UILabel!
    @IBOutlet weak var nextNumber: UILabel!
    @IBOutlet weak var waitTime: UILabel!
    @IBOutlet weak var staticApproxWait: UILabel!
    @IBOutlet weak var myNumberLabel: UILabel!
    @IBOutlet weak var getNumberButton: UIButton!
    //@IBOutlet weak var cancelAppointment: UIButton!
    @IBOutlet weak var Stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!

    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: Actions -- doesn't seem like these are needed
    //@IBAction func updateInfo(sender: UIButton) { }
    //@IBAction func about(sender: UIButton) { }
    
    var APP_REQUEST_NEXT_NUM:NSMutableURLRequest!
    var APP_REQUEST_GET_SESSION:NSURLSession!
    var APP_REQUEST_POST:NSMutableURLRequest!
    var APP_REQUEST_POST_SESSION:NSURLSession!
    var CUST_ETA_REQUEST:NSMutableURLRequest!
    var CUST_ETA_SESSION:NSURLSession!
    var APP_REQUEST_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request2.php")!
    var REQUEST_HANDLER_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/request_handler.php")!
    
    let noInfoGreeting:String = "Welcome to Peter's, Please set your information to make reservations."
    let existingUserGreeting:String = ", looking to get a haircut?"
    let unknownErrorGreeting:String = "Not sure what happened there...Still need a haircut?"
    let forIssuesAlert:String = "For issues, please call Peter (519) 816-2887"
    let unknownDeleteAlert:String = "Something's not right...Please call Peter (519) 816-2887"
    let defaultWaitTime:String = "Wait Time"
    let serverErrorGreeting:String = "Service is down :( Please call Peter (519) 816-2887"
    let yourEtaLabel:String = "Your haircut is in"
    let yourNowLabel:String = "Your appointment is now!"
    let enterYourInfo:String = "Please enter your information."
    let custWaitTime:String = "Your Wait Time"
    let multCustWaitTime:String = "THIS NEEDS TO BE DONE STILL TOO."
    
    func getRequest() -> NSMutableURLRequest {
        if(APP_REQUEST_NEXT_NUM == nil) {
            APP_REQUEST_NEXT_NUM = NSMutableURLRequest(URL: APP_REQUEST_URL)
                APP_REQUEST_NEXT_NUM.HTTPMethod = "POST"
        }
        return APP_REQUEST_NEXT_NUM
    }
    func getSession() -> NSURLSession {
        if(APP_REQUEST_GET_SESSION == nil) {
            APP_REQUEST_GET_SESSION = NSURLSession.sharedSession()
        }
        return APP_REQUEST_GET_SESSION
    }
    func getAppRequestPostRequest() -> NSMutableURLRequest {
            if(APP_REQUEST_POST == nil) {
                APP_REQUEST_POST = NSMutableURLRequest(URL: APP_REQUEST_URL)
                    APP_REQUEST_POST.HTTPMethod = "POST"
            }
            return APP_REQUEST_POST
        }
    func getAppRequestPostSession() -> NSURLSession {
            if(APP_REQUEST_POST_SESSION == nil) {
                APP_REQUEST_POST_SESSION = NSURLSession.sharedSession()
            }
            return APP_REQUEST_POST_SESSION
        }
    func getCustEtaRequest() -> NSMutableURLRequest {
            if(CUST_ETA_REQUEST == nil) {
                CUST_ETA_REQUEST = NSMutableURLRequest(URL: REQUEST_HANDLER_URL)
                CUST_ETA_REQUEST.HTTPMethod = "POST"
            }
            return CUST_ETA_REQUEST
        }
    func getCustEtaSession() -> NSURLSession {
            if(CUST_ETA_SESSION == nil) {
                CUST_ETA_SESSION = NSURLSession.sharedSession()
            }
            return CUST_ETA_SESSION
        }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
    // notification statuses
    var firstNotificationStatus:Bool = false
    var nextNotificationStatus:Bool = false
    var nowNotificationStatus:Bool = false
    func fortyMinutesNotification (input:String) -> Void{
        if (input == "setON") {
            self.firstNotificationStatus = true
            // print("\(firstNotificationStatus)")
        } else if (input == "setOFF") {
            self.firstNotificationStatus = false
        }
    }
    func youAreNextNotification (input:String) -> Void{
        if (input == "setON") {
            self.nextNotificationStatus = true
        } else if (input == "setOFF") {
            self.nextNotificationStatus = false
        }
    }
    func NowNotification (input:String) -> Void{
        if (input == "setON") {
            self.nowNotificationStatus = true
        } else if (input == "setOFF") {
            self.nowNotificationStatus = false
        }
    }
    func createLocalNotification(number: String, time: String) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.alertBody = "Your haircut appointment # \(number) is \(time)!"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    // Get the list of user IDs in local storage
    func getIds() -> [Int] {
        let curUserIds:[Int] = userDefaults.objectForKey("dailyIdArray") as? [Int] ?? [Int]()
        if(curUserIds.count < 1) {
            return [Int]()
        }
        
        var validIds = [Int]()
        for i in 1...curUserIds.count {
            if(curUserIds[i-1] > 0) {
                validIds.insert(curUserIds[i], atIndex: i)
            }
        }
        return validIds
    }
    
    // Returns the wait time
    func getWaitTime() {
        var postParams:String = "get_next_num=1" // number is not necessary, only post param key is needed
        // Check if user has any existing appointments
        let userValidIds:[Int] = getIds()
        if(userValidIds.count > 0) { // User has at least 1 appointment
            let uName = userDefaults.stringForKey("name")! as String
            let uPhone = userDefaults.stringForKey("number")! as String
            postParams = "etaName=\(uName)&etaPhone=\(uPhone)"
        }
        
        getRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        let task1 = getSession().dataTaskWithRequest(getRequest()){ data,response,error in
            if error != nil{
                self.greetingLabel.text = self.serverErrorGreeting
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )	as! [[String: AnyObject]]
                
                let curEtaMins = responseJSON[0]["etaMins"] as! Int
                
                // This needs to be fixed -- wrong address...
                //let curCustId:Int = responseJSON["id"] as! Int
                // Not showing current # anywhere though. Is it needed really?
                if(curEtaMins < 0) { // Store is closed or invalid mySQL response
                    self.staticApproxWait.text = String(responseJSON[0]["message"])
                    self.waitTime.text = ""
                    self.nextNumber.text = ""
                } else if(curEtaMins >= 0) { // valid value received
                    let etaHrs:Int = Int(curEtaMins/60)
                    let etaMins:Int = curEtaMins % 60
                    if(etaHrs > 0) {
                        self.waitTime.text = "\(etaHrs) hours \(etaMins) minutes"
                    } else {
                        self.waitTime.text = "\(etaMins) minutes"
                    }
                    
                    if(userValidIds.count == 0) { // Customer doesn't have a number
                        self.staticApproxWait.text = self.defaultWaitTime
                        self.showHideGetNumber(true)
                    } else if(userValidIds.count == 1) { // Customer has 1 appointment
                        self.staticApproxWait.text = self.custWaitTime
                        self.showHideGetNumber(true)
                    } else { // Customer has multiple appointments
                        self.staticApproxWait.text = self.multCustWaitTime
                        self.showHideGetNumber(true)
                    }
                } else { // unknown response
                    // TODO: try to use the 'message' value
                    self.greetingLabel.text = self.serverErrorGreeting
                    self.waitTime.text = ""
                    self.nextNumber.text = ""
                }
            } catch {
                // TODO: handle the response here!
            }
        }// end of task1
        task1.resume()
        
    }
    func parseJSON() {
        // standard app request
        let postParams =  "get_next_num=1" // number is not necessary, only post param key is needed
        getRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        let task1 = getSession().dataTaskWithRequest(getRequest()){ data,response,error in
            if error != nil{
                print("ERROR -> \(error)")
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )	as! [String: AnyObject]
                
                let curCustEtaMins:Int = responseJSON["etaMins"] as! Int
                let curCustId:Int = responseJSON["id"] as! Int

                if(curCustEtaMins < 0) {
                    self.staticApproxWait.text = String(responseJSON["message"])
                    self.waitTime.text = ""
                    self.nextNumber.text = ""
                } else if(curCustEtaMins >= 0) { // valid value received
                    let h:Int = Int(curCustEtaMins/60)
                    let m:Int = curCustEtaMins % 60
                    self.waitTime.text = "\(h) hours \(m) minutes"
    self.staticApproxWait.text = self.defaultWaitTime
                    
                    // TODO: HOW IS THIS ENTIRE FUNCTION ACTUALLY BEING USED???
                    self.nextNumber.text = String(curCustId)
                } else { // unknown response
                    self.staticApproxWait.text = self.serverErrorGreeting
                    self.waitTime.text = ""
                    self.nextNumber.text = ""
                }
            } catch {
                // TODO: handle error            
            }
        }// end of task1
        task1.resume()
        
        // TODO: this next line is probably not needed in this spot
        showHideGetNumber(true)
    } // end of parseJSON()
    
    // Check if user has an appointment to decide which view to present
    func checkForExistingAppointment() {
        // Get existing user info for POST request
        let extName: String? = userDefaults.stringForKey("name")
        let extPhone: String? = userDefaults.stringForKey("number")
        
        if(extName == nil || extPhone == nil) {
            // TODO: prompt user to set their info
        }
        
        let postParams =  "etaName=\(extName)&etaPhone=\(extPhone)"
        getCustEtaRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = getCustEtaSession().dataTaskWithRequest(getCustEtaRequest()){ data,response,error in
            if error != nil{
                // TODO: error in POST response; maybe just advise to call peter?
                

            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                let etaMinsResponse: Int = responseJSON["etaMins"] as! Int
  
                if(etaMinsResponse >= 0) {
                    // TODO: valid eta response received, present it to the user
                    // Might be all done?
                    self.showHideGetNumber(false)
                    self.staticApproxWait.text = self.yourEtaLabel
                    let etaHrs: Int? = Int(etaMinsResponse/60);
                    let etaMins: Int? = etaMinsResponse % 60;
                    self.waitTime.text = "\(etaHrs) hrs \(etaMins) min"
                    
                    // Update the local ID
                    // TODO: dailyIdArray
                    self.userDefaults.setObject(responseJSON["id"] as! Int, forKey: "dailyId")
                } else if(etaMinsResponse == -1) {
                    self.showHideGetNumber(true)
                    // TODO: dailyIdArray
                    self.userDefaults.setObject(-1, forKey: "dailyId")
                } else if(etaMinsResponse < -1) {
                    self.greetingLabel.text = responseJSON["message"] as? String
                    self.showHideGetNumber(true)
                    
                }

                // TODO: figure out how to handle notifications. I don't think this is the best way to track whether a notification has been set
                // This should only go in the first IF block
                //  Notifications
                if (self.firstNotificationStatus != true) {
                    self.createLocalNotification("ID", time: "in 40 mins") //TODO: ID is just a placeholder
                    self.fortyMinutesNotification("setON")
                } else {
                    self.waitTime.text = self.yourNowLabel
                    self.createLocalNotification("ID", time: "Now") // TODO: ID is just a placeholder
                    self.NowNotification("setON")
                    dispatch_async(dispatch_get_main_queue(),
                    {
                        let alertController = UIAlertController(title: "You're Up!", message: self.yourNowLabel, preferredStyle: .Alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in}
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }) // end of dispatch
                }
            } catch {
                // TODO: what happens when an error occurs?
                
             }
        }
        task.resume()
    }
    
    func showHideGetNumber(showGetNum: Bool) {
        // TODO: flipped these for a little debug - verify
        if(true) { // Show the get a number options, hide cancel button
            self.getNumberButton.hidden = false
            self.myNumberLabel.hidden = false
            //self.cancelAppointment.hidden = false
            self.Stepper.hidden = false
        //} else {
            self.getNumberButton.hidden = false
            self.myNumberLabel.hidden = false
            //self.cancelAppointment.hidden = false
            self.Stepper.hidden = false
        }
    }
    
    @IBAction func getNumber(sender: UIButton) {
        // User info does not exist
        if (NSUserDefaults.standardUserDefaults().stringForKey("name") == nil || NSUserDefaults.standardUserDefaults().stringForKey("number") == nil) {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let alertController = UIAlertController(title: "Alert", message: self.enterYourInfo, preferredStyle: .Alert  )
                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                            alertController.addAction(OKAction)
                            self.presentViewController(alertController, animated: true, completion: nil)
            }) // end of dispatch
            return
        }
        // TODO: make sure user doesn't already have an appointment?
        
        // First get the stepper value from label, default 1
        var stepperCount:Int=1
        if(Int(stepperLabel.text!) > 0) {
            stepperCount=Int(stepperLabel.text!)!
        }
        let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
        let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
        var email:String = "-"
        if (NSUserDefaults.standardUserDefaults().stringForKey("email") != nil){
            email = NSUserDefaults.standardUserDefaults().stringForKey("email")!
        }

        var postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
        if(stepperCount > 1) {
            postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)&&numRes=\(stepperCount)"
        }
        getAppRequestPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)

            let task = getAppRequestPostSession().dataTaskWithRequest(getAppRequestPostRequest()){ data,response,error in
                if error != nil {
                    // TODO: handle error
                    // Show an alert. Maybe move that out to a separate function because it repeats so much
                    return
                }
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary

                    // First make sure an expected response was received
                    let id1Num: Int = responseJSON[0]!["id1"] as! Int
                    if(id1Num < 1) { // Error was received...
                        // TODO: handle the error, i.e. display 'message'
                        // let messageReturned: String = responseJSON["message"] as! String
/*
                            dispatch_async(dispatch_get_main_queue(),
                                           {
                                            let alertController = UIAlertController(title: "Error", message: "There was an error communicating with the server", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            }) // end of dispatch
                         return
*/
                    }
                    
                    var userIdsArray = [-1,-1,-1,-1]
                    for i in 1...stepperCount {
                        let curId:String = "id" + String(1)
                        userIdsArray.insert(responseJSON[i - 1]![curId] as! Int, atIndex: i)
                    }
                    // TODO: how to address this (calcualting difference in time)
                    let firstStartTime : String = responseJSON[0]!["start_time1"] as! String
                    var alertText = "Your haircut is scheduled for " + firstStartTime
                    if(stepperCount > 1) {
                        alertText = "You have scheduled " + String(stepperCount) + " haircuts, first one is at " + firstStartTime
                    }
                    alertText += "Please check back in the app for updated waiting time."
                    // create a pop alerting number
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Your Appointment", message: alertText, preferredStyle: .Alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                    // TODO: does anything else need to be added to defaultstorage?
                    } catch {
                        //TODO: handle error!!
                }
            } // end of task
            task.resume()
        self.showHideGetNumber(true)
    } // end of getNumber function
    
    @IBAction func cancelAppointment(sender: UIButton) {
        // TODO: dailyIdArray!!!
        let custId :Int = userDefaults.integerForKey("dailyId")
        let extname: String? = userDefaults.stringForKey("name")
        let extphone: String? = userDefaults.stringForKey("phone")

        // TODO: customer can have multiple reservations!!
        if(custId > 0) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            let postParams =  "deleteId=\(custId)&deleteName=\(extname)&deletePhone=\(extphone)"
            getAppRequestPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
            
            // Prompt customer to confirm they want to delete
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let alertController = UIAlertController(title: "Confirmation", message: "Cancel Appointments?", preferredStyle: .Alert  )
                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                                return;
                            }
                            alertController.addAction(OKAction)
                            alertController.addAction(cancelAction)
                            self.presentViewController(alertController, animated: true, completion: nil)
            })
            
            let task = getAppRequestPostSession().dataTaskWithRequest(getAppRequestPostRequest()){ data,response,error in
                if error != nil{
                    // TODO: error in POST response; maybe just advise to call peter?
                    
                }
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                    let delResult: Int = responseJSON["delResult"] as! Int
                    if(delResult > 0) { // Delete succeeded
                        dispatch_async(dispatch_get_main_queue(),
                                       {
                                        let alertController = UIAlertController(title: "Appointment Cancelled", message: self.forIssuesAlert, preferredStyle: .Alert  )
                                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                        alertController.addAction(OKAction)
                                        self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    } else { // Delete did not succeed
                        dispatch_async(dispatch_get_main_queue(),
                                       {
                                        let alertController = UIAlertController(title: "Error", message: self.unknownDeleteAlert, preferredStyle: .Alert  )
                                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                        alertController.addAction(OKAction)
                                        self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    }
                } catch {
                    // TODO: what happens when an error occurs?
                }
            }
            task.resume()

        } else { // Customer doesn't have a local ID currently
            self.greetingLabel.text = unknownErrorGreeting
        }
        self.userDefaults.setObject([-1,-1,-1,-1], forKey: "dailyIdArray")
        self.showHideGetNumber(true)
    } // end of cancel function
    
    @IBAction func Stepper(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(userDefaults.stringForKey("name") == nil) {
            self.greetingLabel.text = noInfoGreeting
        } else {
            self.greetingLabel.text = "Hey \(userDefaults.stringForKey("name")!)" + existingUserGreeting

        }
        
        // TODO: Most elements should be hidden while things load. Minimize # of occurrences of this
        /*
        self.myNumberLabel.hidden = true
        self.getNumberButton.hidden = true
        self.cancelAppointment.hidden = true
        */
        
        // TODO: Limit this to just 1-2
        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false

        // TODO: why do we check every 10 seconds?? Shouldn't this be known from delete and app_request2 response?
        checkForExistingAppointment() // check if theres any appointment
        
        // TODO: this should receive the customer's id if it exists; 0 if they don't have one.
        getWaitTime()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.getWaitTime), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
};// end of view controller
