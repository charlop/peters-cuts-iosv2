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
    @IBOutlet weak var numHaircutsStatic: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    
    var GET_ETA_REQUEST:NSMutableURLRequest!
    var GET_ETA_SESSION:NSURLSession!
    var GET_NUMBER_POST_REQUEST:NSMutableURLRequest!
    var GET_NUMBER_POST_SESSION:NSURLSession!
    var APP_REQUEST_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request2.php")!
    
    let userDefaults = User()
    var errFlag = 0
    
    let noInfoGreeting:String = "Welcome to Peter's, Please set your information to make reservations."
    let existingUserGreeting:String = "looking to get a haircut?"
    let unknownErrorGreeting:String = "Not sure what happened there...Still need a haircut?"
    let forIssuesAlert:String = "For issues, please call Peter (519) 816-2887"
    let unknownDeleteAlert:String = "Something's not right...Please call Peter (519) 816-2887"
    let defaultWaitTime:String = "Wait Time"
    let serverErrorGreeting:String = "Service is down :( Please call Peter (519) 816-2887"
    let yourEtaLabel:String = "Your haircut is in"
    let yourNowLabel:String = "Your appointment is now!"
    let multCustWaitTime:String = "THIS NEEDS TO BE DONE STILL TOO."
    let signUpText:String = "Tap on My Information before you can book a haircut"
    let haircut_upcoming_label:String = "Your spot is saved"
    let loadingInitGreeting:String = " Loading the latest schedule..."
    let hasLocalNumberGreeting:String = "Loading your latest appointment info"
    let generalGreeting:String = "How's it going"
    
    // this value will change based on the post request needed (i.e. etaName / etaPhone)
    // todo -- this is ugly, move the possible values into an array and access them that way...
    var getEtaPostParams = "get_next_num=1" // number not necessary, only post key needed
    var postHasNumber = false
    // todo -- seriously, this is disgusting!!
    func setEtaPostParams(nameParam:String?=nil, phoneParam:String?=nil) {
        if let setName = nameParam {
            if let setPhone = phoneParam {
                getEtaPostParams = "etaName=\(setName)&etaPhone=\(setPhone)"
                postHasNumber=true
                return
            }
        }
        getEtaPostParams = "get_next_num=1"
        postHasNumber = false
    }
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
    
    // Returns the wait time
    func getWaitTime() {
        // Check if user has any existing appointments
        
        getEtaPostRequest().HTTPBody = getEtaPostParams.dataUsingEncoding(NSUTF8StringEncoding)
        let task1 = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil {
                if(self.errFlag > 1) {
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = self.serverErrorGreeting })
                    self.errFlag = 0
                    return
                }
                self.errFlag += 1
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [[String: AnyObject]]
                
                let curEtaMins = responseJSON[0]["etaMins"] as! Int
                
                // TODO: Not showing current # anywhere though. Is it needed really?
                
                if(curEtaMins <= 0) { // Store is closed or invalid mySQL response
                    // TODO this should still return something useful for the user...
                    if(self.userDefaults.idsValidBool) {
                        self.userDefaults.removeAllNumbers()
                        self.setEtaPostParams() // user does not have a number
                        self.hideGetNumber(false)
                    }
                    if let unwrappedMessage = responseJSON[0]["message"] {
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = String(unwrappedMessage) })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = self.serverErrorGreeting })
                    }
                    self.waitTime.text = ""
                    self.currentNumber.text = ""
                    if(self.errFlag > 1) {
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(self.userDefaults.name), \(self.existingUserGreeting)" })
                    }
                    self.errFlag = 0
// TODO: set other text fields
                } else if(curEtaMins > 0) { // valid value received
                    // TODO: greetingLabel!!!
                    let etaHrs:Int = Int(curEtaMins/60)
                    let etaMins:Int = curEtaMins % 60
                    if(etaHrs > 0) {
                        dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = "\(etaHrs) hours \(etaMins) minutes" })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = "\(etaMins) minutes" })
                    }
                    if(self.errFlag > 1) {
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(self.userDefaults.name), \(self.existingUserGreeting)" })
                    }
                    self.errFlag = 0
// TODO: could these benefit from hideGetNumber??
                } else { // unknown response
                    if(self.errFlag > 1) {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.greetingLabel.text = self.serverErrorGreeting
                            self.waitTime.text = ""
                            self.currentNumber.text = ""
                        })
                        self.errFlag = 0
                    }
                    self.errFlag += 1
                }
            } catch {
                dispatch_async(dispatch_get_main_queue(), {
                    self.greetingLabel.text = self.serverErrorGreeting
                    self.waitTime.text = ""
                    self.currentNumber.text = ""
                })
            }
        }// end of task1
        task1.resume()
    }

    // Check if user has an appointment to decide which view to present
    func checkForExistingAppointment(inName:String?=nil) {
        var uName = ""
        if let savedName = inName {
            self.greetingLabel.text = "Hey \(savedName), \(self.existingUserGreeting) \(self.loadingInitGreeting)"
            uName = savedName
            if(userDefaults.idsValidBool) { // User has at least 1 appointment
                let etaLocal :(Int, Int) = userDefaults.getEta()

                // dispatch async might not be needed??
                dispatch_async(dispatch_get_main_queue(),
                {
                    if (etaLocal.0 == 0) {
                        self.waitTime.text="\(etaLocal.1) minutes"
                    } else if(etaLocal.0 > 0){ // valid eta
                        self.waitTime.text="\(etaLocal.0) hours \(etaLocal.1) minutes"
                    } else {// Error -- do something maybe, but if not that's cool too
                        self.waitTime.text = "..."
                    }
                    self.greetingLabel.text = "Hey \(savedName), \(self.hasLocalNumberGreeting)"
                })
            }
            // pass in the name and phone to see if appointments exist
            self.setEtaPostParams(userDefaults.name, phoneParam: userDefaults.phone)
        } else {
            self.greetingLabel.text = noInfoGreeting + loadingInitGreeting
            sendNotification("Hey!", messageText: self.signUpText)
        }
        
        getEtaPostRequest().HTTPBody = self.getEtaPostParams.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in
            if error != nil{
                dispatch_async(dispatch_get_main_queue(), { self.sendNotification("Fail", messageText: self.serverErrorGreeting) })
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [[String: AnyObject]]

                let etaMinsResponse: Int = responseJSON[0]["etaMins"] as! Int
  
                if(etaMinsResponse > 0) {
                    let hasNumInd :Int = responseJSON[0]["hasNum"] as! Int
                    
                    if(hasNumInd > 0) { // user already has a number
                        self.hideGetNumber(true)
                        var custIdArray = [Int: Double]()
                        
                        // Update the local IDs
                        for i in 1...responseJSON.count {
                            let etaDouble = responseJSON[i-1]["etaMins"] as! Double
                            custIdArray.updateValue(etaDouble, forKey: responseJSON[i-1]["id"] as! Int)
                        }
                        self.userDefaults.addNumber(custIdArray)
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(uName), \(self.haircut_upcoming_label)" })
                    } else {
                        // TODO: user does not have a number
                        self.hideGetNumber(false)
                        self.userDefaults.removeAllNumbers()
                        self.setEtaPostParams() // make sure other functions don't think user has valid number

                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(uName), \(self.existingUserGreeting)" })
                    }
                    let etaHrs: Int = Int(etaMinsResponse/60);
                    let etaMins: Int = etaMinsResponse % 60;
                    if(etaHrs == 0) {
                        dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String(etaMins) + " minutes" })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String (etaHrs) + " hours " + String(etaMins) + " minutes" })
                    }
                } else { // no rows returned
                    self.hideGetNumber(false)
                    self.userDefaults.removeAllNumbers()
                    
                    // TODO: other messages need to be set here!!
                    // TODO: below line will wrap 'message' in optional()
                        if let unwrappedGreetingLabel = responseJSON[0]["message"] {
                            dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text =  String(unwrappedGreetingLabel) })
                        } else {
                            if(self.errFlag > 1) {
                                self.sendNotification("Ooh...", messageText: self.serverErrorGreeting)
                                self.hideGetNumber(false)
                                self.errFlag = 0
                            } else {
                                self.errFlag += 1
                            }
                        }
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
                if(self.errFlag > 1) {
                    self.sendNotification("Ooh...", messageText: self.serverErrorGreeting)
                    self.hideGetNumber(false)
                    self.errFlag = 0
                } else {
                    self.errFlag += 1
                }
             }
        }
        task.resume()
    }
    
    func hideGetNumber(hideGetNum: Bool) {
        dispatch_async(dispatch_get_main_queue(),
        {
            if(hideGetNum) { // Toggle controls
                self.getNumberButton.hidden = true
                self.reservationButton.hidden = true
                self.myNumberLabel.hidden = true
                self.cancelAppointment.hidden = false
                self.Stepper.hidden = true
                self.stepperLabel.hidden = true
                self.staticApproxWait.text = self.yourEtaLabel
                self.numHaircutsStatic.hidden = true
            } else {
                self.cancelAppointment.hidden = true
                self.getNumberButton.hidden = false
                self.reservationButton.hidden = false
                self.Stepper.hidden = false
                self.stepperLabel.hidden = false
                self.numHaircutsStatic.hidden = false
                self.staticApproxWait.text = self.defaultWaitTime

            }
        })
    }
    
    func sendNotification(titleText:String, messageText:String, alternateAction:String?=nil) {
        dispatch_async(dispatch_get_main_queue(),
                       {
                        
                        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .Alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            if let unrwappedAltAction = alternateAction {
                                if(unrwappedAltAction == "Cancel") {
                                    self.cancelAppointmentReally()
                                }
                            }
                        }
                        alertController.addAction(OKAction)
                        if let unwrappedAlternateAction = alternateAction {
                            let alternateAlertAction = UIAlertAction(title: unwrappedAlternateAction, style: .Cancel) { (action) in
                                return // is this enough to cancel?? pass from other function?
                            }
                            alertController.addAction(alternateAlertAction)
                        }
                        self.presentViewController(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    @IBAction func getNumberWithSender(sender: UIButton) {
        // User info does not exist
        var userName = ""
        var phone = ""
        if let unwrappedName = self.userDefaults.name {
            if let unwrappedPhone = self.userDefaults.phone {
                userName = unwrappedName
                phone = unwrappedPhone
            } else {
                self.sendNotification("Not so fast...", messageText: self.signUpText)
                return
            }
        } else {
            self.sendNotification("Not so fast...", messageText: self.signUpText)
            return
        }
        
        // First get the stepper value from label, default 1
        var stepperCount:Int=1
        if(Int(stepperLabel.text!) > 0) {
            stepperCount=Int(stepperLabel.text!)!
        }
        var email:String = ""
        if (userDefaults.email != nil){
            email = "&user_email=" + userDefaults.email!
        }

        var postParams =  "user_name=\(userName)&user_phone=\(phone)\(email)"
        if(stepperCount > 1) {
            postParams =  "user_name=\(userName)&user_phone=\(phone)\(email)&numRes=\(stepperCount)"
        }
        getNumberPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)

        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
                if error != nil {
                    self.sendNotification("Fail...", messageText: self.serverErrorGreeting)
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
                    self.setEtaPostParams(userName as String, phoneParam: phone as String)
                    var userIdsArray = [Int: Double]()
                    for i in 1...responseJSON.count {
                        let curId:String = "id" + String(i)
                        let startTm:String = "start_time" + String(i)
                        userIdsArray.updateValue(responseJSON[i-1][startTm] as! Double, forKey: responseJSON[i-1][curId] as! Int)
                    }
                    self.userDefaults.addNumber(userIdsArray)
                    // Long term TODO: this can track all appointments with slight modification. One day...
                    let firstStartTime : Int = responseJSON[0]["start_time1"] as! Int
                    var alertText = "Your haircut is in " + String(firstStartTime) + " minutes"
                    if(stepperCount > 1) {
                        alertText = "You have scheduled " + String(stepperCount) + " haircuts, first one is at " + String(firstStartTime)
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "\(userName), \(alertText)" })
                    }
                    alertText += " Please check back in the app for updated waiting time."
                    dispatch_async(dispatch_get_main_queue(), {
                        self.greetingLabel.text = self.haircut_upcoming_label
                    })
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

        // TODO: customer can have multiple reservations!!
        if(userDefaults.idsValidBool) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            // Prompt customer to confirm they want to delete
            let cancelAction = "Cancel"

            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: cancelAction)
        }  else { // Customer doesn't have a local ID currently
            // this error message is no good -- it does mean some clean-up is required
            if(self.errFlag > 1) {
                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = self.unknownErrorGreeting })
                self.errFlag = 0
            } else {
                self.errFlag += 1
            }
            hideGetNumber(false)
        }
    }
    func cancelAppointmentReally() {
        if let dName = userDefaults.name {
            if let dPhone = userDefaults.phone {
                let postParams =  "deleteName=\(dName)&deletePhone=\(dPhone)"
                getNumberPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
            }
        }
        
        let task = getNumberPostSession().dataTaskWithRequest(getNumberPostRequest()){ data,response,error in
            if error != nil{
                self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                let delResult: Int = responseJSON["delResult"] as! Int
                if(delResult > 0) { // Delete succeeded
                    self.setEtaPostParams()
                    self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                } else { // Delete did not succeed
                    self.sendNotification("Error!", messageText: self.unknownDeleteAlert)
                }
                
            } catch {
                self.sendNotification("FAIL", messageText: self.serverErrorGreeting)
            }
        }
        task.resume()
        userDefaults.removeAllNumbers()
        let uName = self.userDefaults.name!
        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "\(self.generalGreeting), \(uName)?" })
        self.hideGetNumber(false)
    } // end of cancel function

    @IBAction func StepperWithSender(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load previous info from user defaults
        userDefaults.getUserDetails()
        checkForExistingAppointment(userDefaults.name)

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
