import UIKit
import CoreData
import Foundation
import SwiftyJSON
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    @IBOutlet weak var curCustLabel: UILabel!
    @IBOutlet weak var nextNumLabelStatic: UILabel!
    @IBOutlet weak var nextNumLabel: UILabel!
    @IBOutlet weak var curNumLabelStatic: UILabel!
    
    
    
    
    let postController = PostController()
    let postErrorHandler = PostErrorHandler()
    var initPerformed = false
    
    var userDefaults = User()
    var errFlag = 0
    var getEtaTimer = Timer()
    
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
    let shopClosedGreeting:String = "Peter's is closed, try checking the app after 9AM.\nSee the About page for shop hours."
    let yourNumText:String = "Your #"
    let nextNumText:String = "Next #"
    
    // notification statuses
    var firstNotificationStatus:Bool = false
    var nextNotificationStatus:Bool = false
    var nowNotificationStatus:Bool = false
    func fortyMinutesNotification (_ input:String) -> Void{
        if (input == "setON") {
            self.firstNotificationStatus = true
            // print("\(firstNotificationStatus)")
        } else if (input == "setOFF") {
            self.firstNotificationStatus = false
        }
    }
    func youAreNextNotification (_ input:String) -> Void{
        if (input == "setON") {
            self.nextNotificationStatus = true
        } else if (input == "setOFF") {
            self.nextNotificationStatus = false
        }
    }
    func NowNotification (_ input:String) -> Void{
        if (input == "setON") {
            self.nowNotificationStatus = true
        } else if (input == "setOFF") {
            self.nowNotificationStatus = false
        }
    }
    func createLocalNotification(_ number: String, time: String) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = Date(timeIntervalSinceNow: 1)
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.alertBody = "Your haircut appointment # \(number) is \(time)!"
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    // Returns the wait time
    func getWaitTime() {
        // Check if user has any existing appointments
        postController.getEta({(etaResponse:[String: AnyObject])->Void in
            var etaResponseError:Int = 0
            
            if let etaResponseErrorInner = etaResponse["error2"] {
                etaResponseError = etaResponseErrorInner as! Int
            } else if let etaResponseErrorInner = etaResponse["error"] {
                etaResponseError = etaResponseErrorInner as! Int
            }
            let (errorFatalBool, errorAction) = CONSTS.GET_ERROR_ACTION(etaResponseError)
            if(errorFatalBool) { // i.e. error codes -1,2,9
                self.handleErrorInternal(etaResponseError, errorAction: errorAction)
                return
            } else {
                // Non-fatal errors possible: 34,35,37,38
                DispatchQueue.main.async(execute: { self.greetingLabel.text = CONSTS.GET_ERROR_TEXT(etaResponseError) })
                self.hideGetNumber(false)
                self.initPerformed = false
            }
            
            // No error or a Non-fatal error was returned (user may or may not have a number)
            if(self.initPerformed == false) {
                self.initPerformed = true
                if let unwrappedName = self.userDefaults.name {
                    var hasNumBool = false
                    if let hasNumUnwrapped = etaResponse["hasNumBool"] {
                        hasNumBool = hasNumUnwrapped as! Int == 1 ? true : false
                    }
                    var greetingLabelSelected = ""
                    var curNumStaticLabelSelected = ""
                    if(hasNumBool == true) {
                        greetingLabelSelected = self.haircut_upcoming_label
                        curNumStaticLabelSelected = self.yourNumText
                        self.userDefaults.addSingleEta(etaResponse["etaMinsSingle"] as! Double)
                    } else {
                        greetingLabelSelected = self.existingUserGreeting
                        curNumStaticLabelSelected = self.nextNumText
                    }
                    DispatchQueue.main.async(execute: {
                        self.greetingLabel.text = "Hey \(unwrappedName), \(greetingLabelSelected)"
                        self.nextNumLabelStatic.text = curNumStaticLabelSelected
                    })
                    self.hideGetNumber(hasNumBool)
                } else {
                    DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey, \(self.sign_up_label)" })
                }
            }
            if let etaMinsVal = etaResponse["etaMinsSingle"] as? Double {
                let etaHrs = Int(etaMinsVal / 60)
                let etaMins = Int(etaMinsVal.truncatingRemainder(dividingBy: 60))
                
                if let custEtaSingle = etaResponse["custEtaSingle"] as? Int {
                    DispatchQueue.main.async(execute: { self.nextNumLabel.text = String(custEtaSingle) })
                }
                if let curCustNum = etaResponse["curCustNum"] as? Int {
                    DispatchQueue.main.async(execute: { self.curCustLabel.text = String(curCustNum) })
                }
                if let isReservation = etaResponse["isReservation"] as? Int {
                    // should hide these for reservation, since it is time-based, not # based (from the customer's perspective)
                    if(isReservation == 1) { // cust has a reservation
                        DispatchQueue.main.async(execute: {
                            self.nextNumLabelStatic.isHidden = true
                            self.nextNumLabel.isHidden = true
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.nextNumLabelStatic.isHidden = false
                            self.nextNumLabel.isHidden = false
                        })
                    }
                }
                
                if(etaHrs == 0) {
                    DispatchQueue.main.async(execute: { self.waitTime.text = String(etaMins) + " minutes" })
                } else {
                    DispatchQueue.main.async(execute: { self.waitTime.text = String (etaHrs) + " hours " + String(etaMins) + " minutes" })
                }
            }
            
        })
    }
    
    // Check if user has an appointment to decide which view to present
    func checkForExistingAppointment(_ inName:String?=nil) {
        if let savedName = inName {
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(savedName), \(self.existingUserGreeting) \(self.loadingInitGreeting)" })
            
            if let savedPhone = userDefaults.phone {
                postController.setEtaPostParam(savedName, phoneParam: savedPhone)
            } else {
                postController.setEtaPostParam()
            }
            self.getWaitTime() // make POST request here, so latest info can be loaded sooner
            if(userDefaults.idsValidBool) { // User has at least 1 appointment
                let etaLocal :(Int, Int) = userDefaults.getEta()
                
                DispatchQueue.main.async(execute: {
                                if (etaLocal.0 == 0) {
                                    self.waitTime.text="\(etaLocal.1) minutes"
                                } else if(etaLocal.0 > 0){ // valid eta
                                    self.waitTime.text="\(etaLocal.0) hours \(etaLocal.1) minutes"
                                } else {// Error -- do something maybe, but if not that's cool too
                                    self.waitTime.text = "..."
                                }
                                self.greetingLabel.text = "Hey \(savedName), \(self.hasLocalNumberGreeting)"
                                self.nextNumLabelStatic.text = self.yourNumText
                })
            }
            // pass in the name and phone to see if appointments exist
        } else {
            sendNotification("Hey!", messageText: self.signUpText)
            postController.setEtaPostParam()
        }
    }
    
    func handleErrorInternal(_ errorId: Int, errorAction: String) {
        if(errorAction == "UNEXPECTED_VAL") {
            //titleText:String, messageText:String, alternateAction:String?=nil
            sendNotification("No Internet", messageText: " Cannot connect to the internet or update schedules!")
        } else if(errorAction == "CLOSED") {
            self.hideGetNumber(true)
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(self.shopClosedGreeting)"
                self.getNumberButton.isEnabled = false
                self.reservationButton.isEnabled = false
                self.Stepper.isEnabled = false
                self.waitTime.isHidden = true
                self.staticApproxWait.isHidden = true
                self.cancelAppointment.isHidden = true
                
                self.nextNumLabel.isHidden = true
                self.nextNumLabelStatic.isHidden = true
                self.curCustLabel.isHidden = true
                self.curNumLabelStatic.isHidden = true
            })
        } else if(errorAction == "FAIL") {
            if(errorId == -10) {
                // failed delete
                self.hideGetNumber(true)
                
            } else {
                // failed getNumber
                self.hideGetNumber(false)
            }
            
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(CONSTS.GET_ERROR_TEXT(errorId))"
            })
        } else if(errorAction == "DUPLICATE" || errorAction == "ACTIVE") {
            self.hideGetNumber(true)
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(CONSTS.GET_ERROR_TEXT(errorId))"
            })
        } else if(errorAction == "RETURNING" || errorAction == "NO_NUMBER") {
            self.hideGetNumber(false)
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(CONSTS.GET_ERROR_TEXT(errorId))"
            })
        } else if(errorAction == "EXCEPTION") {
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey \(CONSTS.GET_ERROR_TEXT(errorId))"
            })
        } else {
            // handle "UNK" and anything else
            DispatchQueue.main.async(execute: { self.greetingLabel.text = "Hey something went wrong. Restart the app and try again. If you still have the problem, call Peter and let him know so we can get it fixed."
            })
        }
    }
    
    func hideGetNumber(_ hideGetNum: Bool) {
        DispatchQueue.main.async(execute: {
                        if(hideGetNum) { // Toggle controls
                            self.getNumberButton.isHidden = true
                            self.reservationButton.isHidden = true
                            self.cancelAppointment.isHidden = false
                            self.Stepper.isHidden = true
                            self.stepperLabel.isHidden = true
                            self.staticApproxWait.text = self.yourEtaLabel
                            self.nextNumLabelStatic.text = self.yourNumText
                            self.numHaircutsStatic.isHidden = true
                        } else {
                            self.cancelAppointment.isHidden = true
                            self.getNumberButton.isHidden = false
                            self.reservationButton.isHidden = false
                            self.Stepper.isHidden = false
                            self.stepperLabel.isHidden = false
                            self.numHaircutsStatic.isHidden = false
                            self.staticApproxWait.text = self.defaultWaitTime
                            self.nextNumLabelStatic.text = self.nextNumText
                            
                        }
        })
    }
    
    func sendNotification(_ titleText:String, messageText:String, alternateAction:String?=nil) {
        DispatchQueue.main.async(execute: {
                        
                        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            if let unrwappedAltAction = alternateAction {
                                if(unrwappedAltAction == "Cancel") {
                                    self.processCancellation()
                                }
                            }
                        }
                        alertController.addAction(OKAction)
                        if let unwrappedAlternateAction = alternateAction {
                            let alternateAlertAction = UIAlertAction(title: unwrappedAlternateAction, style: .cancel) { (action) in
                                return // is this enough to cancel?? pass from other function?
                            }
                            alertController.addAction(alternateAlertAction)
                        }
                        self.present(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    @IBAction func getNumberWithSender(_ sender: UIButton) {
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
                                            self.handleErrorInternal(getNumResponseError as! Int, errorAction: errorAction)
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
                                    let getNumResponseArray = getNumResponse["getNumArray"] as! [Int: Double]
                                    self.userDefaults.addNumber(getNumResponseArray as NSDictionary)
                                    
                                    var etaHrsMinsText = ""
                                    if let firstEtaObj = getNumResponseArray.first {
                                        let firstEtaMins = firstEtaObj.1
                                        if(firstEtaMins >= 60) {
                                            etaHrsMinsText = String(Int(firstEtaMins / 60)) + " hours "
                                        }
                                        etaHrsMinsText += String(Int(firstEtaMins.truncatingRemainder(dividingBy: 60))) + " minutes"
                                    }
                                    
                                    let alertText = "Your next haircut is in \(etaHrsMinsText)"
                                    DispatchQueue.main.async(execute: { self.greetingLabel.text = "\(userName), \(alertText)" })
                                    
                                    var notificationText = "Nice! Your haircut is in "
                                    if(stepperCount > 1) {
                                        notificationText = "You have reserved \(String(stepperCount)) haircuts, first one is in "
                                    }
                                    notificationText += etaHrsMinsText
                                    self.sendNotification("Your Appointment", messageText: notificationText)
                                    
                                    self.hideGetNumber(true)
        })
    }
    
    @IBAction func cancelAppointmentWithSender(_ sender: UIButton) {
        // TODO: customer can have multiple reservations!!
        if(userDefaults.idsValidBool) { // Make sure  customer has a number -- shouldn't be visible otherwise though?
            // Prompt customer to confirm they want to delete
            let cancelAction = "Cancel"
            
            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: cancelAction)
        }  else { // Customer doesn't have a local ID currently
            if(self.errFlag > 1) {
                DispatchQueue.main.async(execute: { self.greetingLabel.text = self.unknownErrorGreeting })
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
                                                            self.getWaitTime() // update immediately
                                                            self.userDefaults.removeAllNumbers()
                                                            self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                                                            DispatchQueue.main.async(execute: { self.greetingLabel.text = "\(self.generalGreeting), \(delName)?" })
                                                        } else {
                                                            self.hideGetNumber(true)
                                                            let (_, eAction) = CONSTS.GET_ERROR_ACTION(delError as! Int)
                                                            self.handleErrorInternal(delError as! Int, errorAction: eAction)
                                                            return
                                                        }
                                                    }
                })
            }
        }
    }
    
    @IBAction func StepperWithSender(_ sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }
    
    func getClosedMessage() {
        postController.getClosedMessage({ (closedMessage:String) -> Void in
            let msgLength = closedMessage.characters.count
            if(msgLength > 1) {
                if(closedMessage == "-500") {
                    // Server error received. Return false and do nothing for now
                    self.performInit()
                } else {
                    DispatchQueue.main.async(execute: {
                        if(msgLength > 25) {
                            self.greetingLabel.numberOfLines = msgLength / 25
                        }
                        self.greetingLabel.text = closedMessage
                        self.getNumberButton.isEnabled = false
                        self.reservationButton.isEnabled = false
                        self.Stepper.isEnabled = false
                        self.waitTime.isHidden = true
                        self.staticApproxWait.isHidden = true
                        
                        self.nextNumLabel.isHidden = true
                        self.curCustLabel.isHidden = true
                        self.nextNumLabelStatic.isHidden = true
                        self.curNumLabelStatic.isHidden = true
                    })
                }
            } else {
                self.performInit()
            }
            return
        })
    }
    func performInit() {
        userDefaults = User()
        checkForExistingAppointment(userDefaults.name)
        DispatchQueue.main.async {
            self.getEtaTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.getWaitTime), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        // First check for closed message
        // This calls performInit if there is no message
        getClosedMessage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        getEtaTimer.invalidate()
        initPerformed = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}// end of view controller


extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
