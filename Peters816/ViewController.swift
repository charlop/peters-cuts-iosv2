import UIKit
import CoreData
import Foundation
import SwiftyJSON

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var currentNumber: UILabel!
    @IBOutlet weak var staticNextNumber: UILabel!
    @IBOutlet weak var waitTime: UILabel!
    @IBOutlet weak var staticApproxWait: UILabel!
    @IBOutlet weak var myNumberLabel: UILabel!
    @IBOutlet weak var getNumberButton: UIButton!
    @IBOutlet weak var reservationButton: UIButton!
    @IBOutlet weak var cancelAppointment: UIButton!
    @IBOutlet weak var Stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!

    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: Actions -- doesn't seem like these are needed
    //@IBAction func updateInfo(sender: UIButton) { }
    //@IBAction func about(sender: UIButton) { }
    
    var GET_ETA_REQUEST:NSMutableURLRequest!
    var GET_ETA_SESSION:NSURLSession!
    var GET_NUMBER_POST_REQUEST:NSMutableURLRequest!
    var GET_NUMBER_POST_SESSION:NSURLSession!
    var APP_REQUEST_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request2.php")!
    
    let noInfoGreeting:String = "Welcome to Peter's, Please set your information to make reservations."
    let existingUserGreeting:String = "looking to get a haircut?"
    let unknownErrorGreeting:String = "Not sure what happened there...Still need a haircut?"
    let forIssuesAlert:String = "For issues, please call Peter (519) 816-2887"
    let unknownDeleteAlert:String = "Something's not right...Please call Peter (519) 816-2887"
    let defaultWaitTime:String = "Wait Time"
    let serverErrorGreeting:String = "Service is down :( Please call Peter (519) 816-2887"
    let yourEtaLabel:String = "Your haircut is in"
    let yourNowLabel:String = "Your appointment is now!"
    let custWaitTime:String = "WHAT IS THIS"
    let multCustWaitTime:String = "THIS NEEDS TO BE DONE STILL TOO."
    let signUpText:String = "Tap on My Information before you can book a haircut"

    
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
    
    // Get the list of positive user IDs in local storage -- return empty array if none exist
    func getIds() -> [Int] {
        let curUserIds:[Int] = userDefaults.objectForKey("dailyIdArray") as? [Int] ?? [Int]()
        if(curUserIds.count < 1) {
            return [Int]()
        }
        
        var validIds = [Int]()
        for i in 1...curUserIds.count {
            if(curUserIds[i-1] > 0) {
                validIds.insert(curUserIds[i-1], atIndex: i-1)
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
        
        getEtaPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        let task1 = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil{
                self.greetingLabel.text = self.serverErrorGreeting
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )	// as! [[String: AnyObject]]
                
                let curEtaMins = responseJSON[0]["etaMins"] as! Int
                
                // TODO: store the ID and make sure the array is updated ONLY if necessary -- call hideGetNumber ONLY if there has been a change (i.e. Peter deleted them)
                // This needs to be fixed -- wrong address...
                //let curCustId:Int = responseJSON["id"] as! Int
                // Not showing current # anywhere though. Is it needed really?
                
                if(curEtaMins < 0) { // Store is closed or invalid mySQL response
                    self.staticApproxWait.text = String(responseJSON[0]["message"])
                    self.waitTime.text = ""
                    self.currentNumber.text = ""
                } else if(curEtaMins >= 0) { // valid value received
                    let etaHrs:Int = Int(curEtaMins/60)
                    let etaMins:Int = curEtaMins % 60
                    if(etaHrs > 0) {
                        self.waitTime.text = "\(etaHrs) hours \(etaMins) minutes"
                    } else {
                        self.waitTime.text = "\(etaMins) minutes"
                    }

                    // This part should be handled elsewhere, no need to do it every time...?
/*
                    if(userValidIds.count == 0) { // Customer doesn't have a number
                        self.staticApproxWait.text = self.defaultWaitTime
                        self.hideGetNumber(false)
                    } else if(userValidIds.count == 1) { // Customer has 1 appointment
                        self.staticApproxWait.text = self.custWaitTime
                        self.hideGetNumber(true)
                    } else { // Customer has multiple appointments
                        self.staticApproxWait.text = self.multCustWaitTime
                        self.hideGetNumber(true)
                    }
 */
                    
// TODO: could these benefit from hideGetNumber??
                } else { // unknown response
                    self.greetingLabel.text = self.serverErrorGreeting
                    self.waitTime.text = ""
                    self.currentNumber.text = ""
                }
            } catch {
                self.greetingLabel.text = self.serverErrorGreeting
                self.waitTime.text = ""
                self.currentNumber.text = ""
            }
        }// end of task1
        task1.resume()
    }

    // Check if user has an appointment to decide which view to present
    func checkForExistingAppointment(inName:String?=nil) {
        self.greetingLabel.text = "Just a sec..."
        
        var postParams = ""
        var localCustIdArray :[Int]
        
        if let extName:String = inName {
            if let extPhone = userDefaults.stringForKey("number") {
                localCustIdArray = self.getIds()
                if(localCustIdArray.count > 0) {
                    // User possibly has a number already
                    // TODO: fix line below
                    self.waitTime.text = String(localCustIdArray[0] * 3) + "mins FIX!!"
                    
                    postParams =  "etaName=" + extName + "&etaPhone=" + extPhone
                } else {
                    // TODO: handle this elsewhere, not a good idea to mix
                    postParams = "get_next_num=1" // number is not necessary, only post param key is needed
                }
            } else { // name exists but phone doesn't...
                sendNotification("Hey!", messageText: self.signUpText)
                return
            }
        } else { // user info doesn't exist, send them to the sign-up screen
            sendNotification("Hey!", messageText: self.signUpText)
            return
        }
        
        getEtaPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil{
                self.sendNotification("Not Again...", messageText: self.serverErrorGreeting)
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) //as! [[String: AnyObject]]

                let etaMinsResponse: Int = responseJSON[0]["etaMins"] as! Int
  
                if(etaMinsResponse >= 0) {
                    self.hideGetNumber(true)
                    let etaHrs: Int = Int(etaMinsResponse/60);
                    let etaMins: Int = etaMinsResponse % 60;
                    if(etaHrs == 0) {
                        self.waitTime.text = "\(etaMins) minutes"
                    } else {
                        self.waitTime.text = "\(etaHrs) hours \(etaMins) minutes"
                    }
                    // Update the local IDs -- only if valid customer number exists in DB
                    if(localCustIdArray.count <= 0) { // this means get_next_num=1 was used -- there's probably a better way to handle it
                        var custIdArray :[Int] = [-1,-1,-1,-1]  // array for up to 4 customer ID's
                        for i in 1...responseJSON.count {
                            custIdArray[i-1] = responseJSON[i-1]["id"] as! Int
                        }
                        self.userDefaults.setObject(custIdArray, forKey: "dailyIdArray")
                    }
                } else if(etaMinsResponse < 0) { // no rows returned
                    self.hideGetNumber(false)
                    self.userDefaults.setObject([-1,-1,-1,-1], forKey: "dailyIdArray")
                    self.greetingLabel.text = responseJSON[0]["message"] as? String
                }

                // TODO: figure out how to handle notifications. I don't think this is the best way to track whether a notification has been set
                // This should only go in the first IF block
                //  Notifications
/*                if (self.firstNotificationStatus != true) {
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
                }*/
            } catch {
                self.sendNotification("Not Again...checkCatch", messageText: self.serverErrorGreeting)
                self.hideGetNumber(false)
             }
        }
        task.resume()
    }
    
    func hideGetNumber(hideGetNum: Bool) {
        if(hideGetNum) { // Toggle controls
            self.getNumberButton.hidden = true
            self.reservationButton.hidden = true
            self.myNumberLabel.text = custWaitTime
            self.cancelAppointment.hidden = false
            self.Stepper.hidden = true
            self.stepperLabel.hidden = true
            self.staticApproxWait.text = self.yourEtaLabel
        } else {
            self.cancelAppointment.hidden = true
            self.getNumberButton.hidden = false
            self.reservationButton.hidden = false
            self.Stepper.hidden = false
            self.stepperLabel.hidden = false
        }
    }
    
    func sendNotification(titleText:String, messageText:String, alternateAction:UIAlertAction?=nil) {
        dispatch_async(dispatch_get_main_queue(),
                       {
                        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .Alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                        alertController.addAction(OKAction)
                        if let unwrappedAlternateAction = alternateAction {
                            alertController.addAction(unwrappedAlternateAction)
                        }
                        self.presentViewController(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    @IBAction func getNumberWithSender(sender: UIButton) {
        // User info does not exist
        if (NSUserDefaults.standardUserDefaults().stringForKey("name") == nil || NSUserDefaults.standardUserDefaults().stringForKey("number") == nil) {
            self.sendNotification("Not so fast...", messageText: self.signUpText)
            return
        }
        
        // First get the stepper value from label, default 1
        var stepperCount:Int=1
        if(Int(stepperLabel.text!) > 0) {
            stepperCount=Int(stepperLabel.text!)!
        }
        let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
        let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
        var email:String = ""
        if (NSUserDefaults.standardUserDefaults().stringForKey("email") != nil){
            email = "&user_email=" + NSUserDefaults.standardUserDefaults().stringForKey("email")!
        }

        var postParams =  "user_name=\(userName)&user_phone=\(phone)\(email)"
        if(stepperCount > 1) {
            postParams =  "user_name=\(userName)&user_phone=\(phone)\(email)&numRes=\(stepperCount)"
        }
        getNumberPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)

        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
                if error != nil {
                    self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
                    return
                }
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [[String: AnyObject]]

                    // First make sure an expected response was received
                    let id1Num: Int = responseJSON[0]["id1"] as! Int
                    if(id1Num < 1) { // Error was received...
                        // TODO: set the wait time or any session parameters here??
                        let messageReturned: String = responseJSON[0]["message"] as! String
                        self.sendNotification("Hey!", messageText: messageReturned)
                        return
                    }
                    
                    var userIdsArray = [-1,-1,-1,-1]
                    for i in 1...stepperCount {
                        let curId:String = "id" + String(i)
                        userIdsArray[i - 1] = responseJSON[i - 1][curId] as! Int
                    }
                    // Long term TODO: this can track all appointments with slight modification. One day...
                    let firstStartTime : Int = responseJSON[0]["start_time1"] as! Int
                    var alertText = "Your haircut is in " + String(firstStartTime) + " minutes"
                    if(stepperCount > 1) {
                        alertText = "You have scheduled " + String(stepperCount) + " haircuts, first one is at " + String(firstStartTime)
                    }
                    alertText += " Please check back in the app for updated waiting time."
                    // create a pop alerting number
                    self.sendNotification("Your Appointment", messageText: alertText)
                    // TODO: does anything else need to be added to defaultstorage?
                    } catch {
                        self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
                }
            } // end of task
            task.resume()
        self.hideGetNumber(true)
    } // end of getNumber function
    
    @IBAction func cancelAppointmentWithSender(sender: UIButton) {
        // TODO: dailyIdArray!!!
        let custIdArray :[Int] = userDefaults.arrayForKey("dailyIdArray") as! [Int]
        let custId = custIdArray[0]
        let extname: String? = userDefaults.stringForKey("name")
        let extphone: String? = userDefaults.stringForKey("phone")

        // TODO: customer can have multiple reservations!!
        if(custId > 0) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            let postParams =  "deleteId=\(custId)&deleteName=\(extname)&deletePhone=\(extphone)"
            getNumberPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
            
            // Prompt customer to confirm they want to delete
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                return; // is this enough to cancel?? pass from other function?
            }

            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: cancelAction)
            
            let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
                if error != nil{
                    self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
                    return
                }
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                    let delResult: Int = responseJSON["delResult"] as! Int
                    if(delResult > 0) { // Delete succeeded
                        self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                    } else { // Delete did not succeed
                        self.sendNotification("Error!", messageText: self.unknownDeleteAlert)
                    }
                } catch {
                    self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
                }
            }
            task.resume()

        } else { // Customer doesn't have a local ID currently
            self.greetingLabel.text = unknownErrorGreeting
        }
        self.userDefaults.setObject([-1,-1,-1,-1], forKey: "dailyIdArray")
        self.hideGetNumber(false)
    } // end of cancel function
    
    @IBAction func StepperWithSender(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let unwrappedCustName = userDefaults.stringForKey("name") {
            self.greetingLabel.text = "Hey \(unwrappedCustName), " + existingUserGreeting
            checkForExistingAppointment(unwrappedCustName)
        } else {
            self.greetingLabel.text = noInfoGreeting
            checkForExistingAppointment()
        }
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.getWaitTime), userInfo: nil, repeats: true)

        
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
};// end of view controller
