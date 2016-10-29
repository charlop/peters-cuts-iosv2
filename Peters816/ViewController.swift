import UIKit
import CoreData
import Foundation
import SwiftyJSON

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var waitTime: UILabel!
    @IBOutlet weak var staticApproxWait: UILabel!
    @IBOutlet weak var getNumberButton: UIButton!
    @IBOutlet weak var reservationButton: UIButton!
    @IBOutlet weak var cancelAppointment: UIButton!
    @IBOutlet weak var Stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var numHaircutsStatic: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    
    let postController = PostController()
    let postErrorHandler = PostErrorHandler()
    var initPerformed = false

    let userDefaults = User()
    var errFlag = 0
    var getEtaTimer: NSTimer?
    
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
    let sign_up_label:String = "Enter your information before you can reserve a number"
    
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
        postController.getEta({(etaResponse:[String: AnyObject])->Void in
            if let etaResponseError = etaResponse["error"] {
                let (errorFatalBool, errorAction) = CONSTS.GET_ERROR_ACTION(etaResponseError as! Int)
                if(errorFatalBool) { // i.e. error codes -1,2,9
                    self.postErrorHandler.handleError(etaResponseError as! Int, errorAction: errorAction)
                    return
                } else {
                    // Non-fatal errors possible: 34,35,37,38
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = CONSTS.GET_ERROR_TEXT(etaResponseError as! Int) })
                    self.hideGetNumber(false)
                    self.initPerformed = false
                }
            }
            // No error or a Non-fatal error was returned (user may or may not have a number)
            if(self.initPerformed == false) {
                self.initPerformed = true
                if let unwrappedName = self.userDefaults.name {
                    if let hasNumUnwrapped = etaResponse["hasNumBool"] {
                        var greetingLabelSelected = ""
                        let hasNumBool = hasNumUnwrapped as! Int == 1 ? true : false
                        if(hasNumBool == true) {
                            greetingLabelSelected = self.haircut_upcoming_label
                
                        } else {
                            greetingLabelSelected = self.existingUserGreeting
                        }
                        dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(unwrappedName), \(greetingLabelSelected)" })
                        self.hideGetNumber(hasNumBool)
                        self.userDefaults.addSingleEta(etaResponse["etaMinsSingle"] as! Double)
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey, \(self.sign_up_label)" })
                }
            }
            let etaMinsVal = etaResponse["etaMinsSingle"] as! Double
            let etaHrs = Int(etaMinsVal / 60)
            let etaMins = Int(etaMinsVal % 60)
            if(etaHrs == 0) {
                dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String(etaMins) + " minutes" })
            } else {
                dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String (etaHrs) + " hours " + String(etaMins) + " minutes" })
            }
        })
    }

    // Check if user has an appointment to decide which view to present
    func checkForExistingAppointment(inName:String?=nil) {
        if let savedName = inName {
            self.greetingLabel.text = "Hey \(savedName), \(self.existingUserGreeting) \(self.loadingInitGreeting)"
            if let savedPhone = userDefaults.phone {
                postController.setEtaPostParam(savedName, phoneParam: savedPhone)
            } else {
                postController.setEtaPostParam()
            }
            if(userDefaults.idsValidBool) { // User has at least 1 appointment
                let etaLocal :(Int, Int) = userDefaults.getEta()

                // TODO dispatch async might not be needed??
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
        } else {
            sendNotification("Hey!", messageText: self.signUpText)
            postController.setEtaPostParam()
        }
        
        self.getWaitTime()

 
 
 

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

    }
    
    func hideGetNumber(hideGetNum: Bool) {
        dispatch_async(dispatch_get_main_queue(),
        {
            if(hideGetNum) { // Toggle controls
                self.getNumberButton.hidden = true
                self.reservationButton.hidden = true
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
                                    self.processCancellation()
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
        var userPhone = ""
        var email:String = ""

        if let unwrappedName = self.userDefaults.name {
            if let unwrappedPhone = self.userDefaults.phone {
                if (userDefaults.email != nil){
                    email = "&user_email=" + userDefaults.email!
                }
                userName = unwrappedName
                userPhone = unwrappedPhone
            } else {
                self.sendNotification("Not so fast...", messageText: self.signUpText)
                return
            }
        } else {
            self.sendNotification("Not so fast...", messageText: self.signUpText)
            return
        }
        
        // Get the stepper value from label, default 1
        var stepperCount:Int = 1
        if(Int(stepperLabel.text!) > 0) {
            stepperCount = Int(stepperLabel.text!)!
        }
        postController.getNumber(inName: userName, inPhone: userPhone, numRes: stepperCount, inEmailParm: email,
            completionHandler: {(getNumResponse:[String: AnyObject]) -> Void in
                if let getNumResponseError = getNumResponse["error"] {
                    // Possible values: 2,7,9
                    let (errorFatalBool, errorAction) = CONSTS.GET_ERROR_ACTION(getNumResponseError as! Int)
                    if(errorFatalBool) {
                        self.postErrorHandler.handleError(getNumResponseError as! Int, errorAction: errorAction)
                        return
                    } else { // Only non-fatal possibility is 7; duplicate
                        if(errorAction == "DUPLICATE") {
                            self.hideGetNumber(true)
                            self.initPerformed = false // re-initialize local IDs
                            self.getWaitTime() // Update information immediately
                            self.sendNotification("You're All Set", messageText: CONSTS.GET_ERROR_TEXT(getNumResponseError as! Int))
                        }
                    }
                }
                // Successfully acquired numbers
                // Long term TODO: this can track all appointments with slight modification. One day...
                let getNumResponseArray = getNumResponse["getNumArray"] as! [Int: Double]
                self.userDefaults.addNumber(getNumResponseArray)
                
                var etaHrsMinsText = ""
                if let firstEtaObj = getNumResponseArray.first {
                    let firstEtaMins = firstEtaObj.1
                    if(firstEtaMins >= 60) {
                        etaHrsMinsText = String(Int(firstEtaMins / 60)) + " hours "
                    }
                    etaHrsMinsText += String(Int(firstEtaMins % 60)) + " minutes"
                }
                
                let alertText = "Your next haircut is in \(etaHrsMinsText)"
                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "\(userName), \(alertText)" })
                
                var notificationText = "Nice! Your haircut is in "
                if(stepperCount > 1) {
                    notificationText = "You have reserved \(String(stepperCount)) haircuts, first one is in "
                }
                notificationText += etaHrsMinsText
                self.sendNotification("Your Appointment", messageText: notificationText)
                
                self.hideGetNumber(true)
            })
    }
        
    @IBAction func cancelAppointmentWithSender(sender: UIButton) {
        // TODO: customer can have multiple reservations!!
        if(userDefaults.idsValidBool) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            // Prompt customer to confirm they want to delete
            let cancelAction = "Cancel"

            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: cancelAction)
        }  else { // Customer doesn't have a local ID currently
            // TODO: this error message is no good -- it does mean some clean-up is required
            // TODO: no message is even being displayed. Should still attempt to cancel in case local data is out of sync, I think...
            
            
            if(self.errFlag > 1) {
                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = self.unknownErrorGreeting })
                self.errFlag = 0
            } else {
                self.errFlag += 1
            }
            hideGetNumber(false)
        }
    }
    func processCancellation() {
        if let delName = userDefaults.name {
            if let delPhone = userDefaults.phone {
                postController.cancelAppointment(delName, delPhone: delPhone,
                    completionHandler: {(delResponse:[String: AnyObject]) -> Void in
                        if let delError = delResponse["error"] {
                            // delError is the only value returned
                            // 1 = success, -10 = fail (fatal)
                            if(delError as! Int == 1) {
                                // not an error
                                self.hideGetNumber(false)
                                self.userDefaults.removeAllNumbers()
                                self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "\(self.generalGreeting), \(delName)?" })
                            } else {
                                self.hideGetNumber(true)
                                let (_, eAction) = CONSTS.GET_ERROR_ACTION(delError as! Int)
                                self.handleError(delError as! Int, errorAction: eAction)
                                return
                            }
                        }
                })
            }
        }
    }

    @IBAction func StepperWithSender(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        // Load previous info from user defaults
        checkForExistingAppointment(userDefaults.name)
        
        getEtaTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.getWaitTime), userInfo: nil, repeats: true)
        
        // TODO: Limit this to just 1-2
        //
        //
        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let getEtaTimerUnwrapped = getEtaTimer {
            getEtaTimerUnwrapped.invalidate()
        }
        getEtaTimer = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 
}// end of view controller
