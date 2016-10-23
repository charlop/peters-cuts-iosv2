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
    
    let postController = PostController()
    var initPerformed = false

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
    
    // Handle errors here whenever possible
    func handleError(errorId : Int, errorAction : String) {
        if(errFlag > 2) {
            self.sendNotification("Fail", messageText: CONSTS.GET_ERROR_TEXT(errorId))
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
    
    
    // Returns the wait time
    func getWaitTime() {
        // Check if user has any existing appointments
        var etaResponse = postController.getEta()
        if let etaResponseError = etaResponse["error"] {
            let (errorFatalBool, errorAction) = CONSTS.GET_ERROR_ACTION(etaResponseError as! Int)
            if(errorFatalBool) { // i.e. error codes -1,2,9
                self.handleError(etaResponseError as! Int, errorAction: errorAction)
            } else {
                // Non-fatal errors possible: 34,35,36
                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = CONSTS.GET_ERROR_TEXT(etaResponseError as! Int) })
                self.hideGetNumber(false)
            }
        }
        
        // User has an existing number
        if(initPerformed == false) {
            if let unwrappedName = userDefaults.name {
                if let hasNumUnwrapped = etaResponse["hasNumBool"] {
                    var greetingLabelSelected = ""
                    let hasNumBool = hasNumUnwrapped as! Bool
                    if(hasNumBool) {
                        greetingLabelSelected = self.haircut_upcoming_label
                    } else {
                        greetingLabelSelected = self.existingUserGreeting
                    }
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey \(unwrappedName), \(greetingLabelSelected)" })
                    self.hideGetNumber(hasNumBool)
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "Hey, \(self.sign_up_label)" })
            }
        }
        
        // TODO: Not showing current # anywhere though. Is it needed really?

        var etaMinsVal = etaResponse["etaMinsArray"] as! [Int: Double]
        let etaHrs = Int(etaMinsVal[0]! / 60)
        let etaMins = Int(etaMinsVal[0]! % 60)
        if(etaHrs == 0) {
            dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String(etaMins) + " minutes" })
        } else {
            dispatch_async(dispatch_get_main_queue(), { self.waitTime.text = String (etaHrs) + " hours " + String(etaMins) + " minutes" })
        }
        initPerformed = true

        
// TODO: this can be removed, just make sure any errors are addressed with the "error" handler
        /*
        getEtaPostRequest().HTTPBody = getEtaPostParams.dataUsingEncoding(NSUTF8StringEncoding)
        let task1 = getEtaPostSession().dataTaskWithRequest(getEtaPostRequest()){ data,response,error in

            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [[String: AnyObject]]
                
                let curEtaMins = responseJSON[0]["etaMins"] as! Int
                
         
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
 */
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
        
        let getNumResponse = postController.getNumber(userName, inPhone: userPhone, numRes: stepperCount, inEmailParm: email)

        if let getNumResponseError = getNumResponse["error"] {
            // Possible values: 1,2,7,9
            let (errorFatalBool, errorAction) = CONSTS.GET_ERROR_ACTION(getNumResponseError as! Int)
            if(errorFatalBool) {
                self.handleError(getNumResponseError as! Int, errorAction: errorAction)
                return
            } else {
                // Non-fatal errors possible: 7
                if(errorAction == "DUPLICATE") {
                    self.hideGetNumber(true)
                    self.initPerformed = false // re-initialize local IDs
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = CONSTS.GET_ERROR_TEXT(getNumResponseError as! Int) })
                } else {
                    self.handleError(getNumResponseError as! Int, errorAction: errorAction)
                    return // treat as fatal
                }
            }
        }
        
        // Successfully acquired numbers
        // Long term TODO: this can track all appointments with slight modification. One day...
        let getNumResponseArray = getNumResponse["getNumArray"] as! [Int: Double]
        userDefaults.addNumber(getNumResponseArray)
        
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
    } // end of getNumber function
    
    @IBAction func cancelAppointmentWithSender(sender: UIButton) {
        // TODO: customer can have multiple reservations!!
        if(userDefaults.idsValidBool) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            // Prompt customer to confirm they want to delete
            let cancelAction = "Cancel"

            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: cancelAction)
        }  else { // Customer doesn't have a local ID currently
            // TODO: this error message is no good -- it does mean some clean-up is required
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
                let delResponse = postController.cancelAppointment(delName, delPhone: delPhone)
                if let delError = delResponse["error"] {
                    // TODO: handle error
                    let (eFatalBool, eAction) = CONSTS.GET_ERROR_ACTION(delError as! Int)
                    if(eFatalBool) {
                        self.handleError(delError as! Int, errorAction: eAction)
                        return
                    } else if(delError as! Int == CONSTS.GET_ERROR_CODE("DEL_NUM_FAIL")) {
                        self.sendNotification("FAIL", messageText: CONSTS.GET_ERROR_TEXT(delError as! Int))
                        self.hideGetNumber(true)
                        return
                    } else {
                        self.handleError(delError as! Int, errorAction: eAction)
                        return
                    } // treat as fatal
                } else { // Appointment Success supposedly
                    userDefaults.removeAllNumbers()
                    self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                    
                    dispatch_async(dispatch_get_main_queue(), { self.greetingLabel.text = "\(self.generalGreeting), \(delName)?" })
                    self.hideGetNumber(false)
                }
            }
        }
    }

    @IBAction func StepperWithSender(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load previous info from user defaults
        userDefaults.getUserDetails()
        checkForExistingAppointment(userDefaults.name)

        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.getWaitTime), userInfo: nil, repeats: true)
        
        // TODO: Limit this to just 1-2
        //
        //
        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}// end of view controller
