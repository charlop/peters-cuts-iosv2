import UIKit
import CoreData
import Foundation
import SwiftyJSON
import UserNotifications

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
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    
    var userDefaults = User()
    var getEtaTimer = Timer()

    
    var currentState = CONSTS.AppointmentStatus.NO_APPOINTMENT // Default setting
    
    // no user info messages
    let signUpText:String = "Tap on User Info before you can book a haircut"

    // Closed messages
    var shopClosedGreeting:String = "Peter's is closed, try checking the app after 9AM.\nSee the About page for shop hours."
    
    // Errors
    let forIssuesAlert:String = "For issues, please call Peter (519) 816-2887"

    // Labels
    let defaultWaitTime:String = "Wait Time"
    let yourNumText:String = "Your #"
    let nextNumText:String = "Next Available #"

    // Has number messages
    let haircut_upcoming_label:String = "Your spot is saved"
    let yourEtaLabel:String = "Your haircut is in"
    
    var loadingInitGreeting:String = " Loading the latest schedule..."
    let hasLocalNumberGreeting:String = "Loading your latest appointment info"
    var customGreetingMessage:String = ""

    // Get Number
    let existingUserGreeting:String = "looking to get a haircut?"
    let generalGreeting:String = "how's it going"

    @IBOutlet weak var curNumUIStack: UIStackView!
    // Returns the wait time
    @objc func getWaitTime() {
        postController.getEta(userDefaults: userDefaults, completionHandler: {(etaResponse:Appointment)->Void in
            self.userDefaults = User()
            
            let errorFatalBool = CONSTS.isFatal(errorId: etaResponse.getError())

            if(etaResponse.getError() != CONSTS.ErrorNum.NO_ERROR.rawValue) {
                self.handleErrorInternal(errorNum: etaResponse.getError())
                
                if(errorFatalBool) {
                    // no point in getting the ETA for fatal errors
                    return
                }
            }
            
            DispatchQueue.main.async(execute: {
            if(etaResponse.getEtaMins() > 0.0) {
                self.setUIState(newState: etaResponse.getAppointmentStatus())
                var waitTimeString = ""

                let etaHrs = Int(etaResponse.getEtaMins() / 60)
                let etaMins = Int(etaResponse.getEtaMins().truncatingRemainder(dividingBy: 60))
                if(etaHrs > 0) {
                    waitTimeString += String (etaHrs) + " hours "
                }
                waitTimeString += String(etaMins) + " minutes"
                
                self.waitTime.text = waitTimeString
            }
            if(etaResponse.getCurrentId() > 0) {
                self.curCustLabel.text = String(etaResponse.getCurrentId())
            }
            if(etaResponse.getUpcomingId() > 0) {
                self.nextNumLabel.text = String(etaResponse.getUpcomingId())
            }
            
            })
        })
    }
    
    // Check if user has an appointment to decide which view to present
    // Function should only be called once, when the view initially loads
    func checkForExistingAppointment() {
        if(!userDefaults.userInfoExists()) {
            self.setUIState(newState: .NO_USER_INFO)
        } else if(self.userDefaults.userHasAppointment()) {
            let etaLocal :(errorNum:CONSTS.ErrorNum.RawValue, etaString:String) = self.userDefaults.getFirstUpcomingEta()
            if(etaLocal.errorNum == CONSTS.ErrorNum.NO_ERROR.rawValue) {
                // User has local appointment
                DispatchQueue.main.async(execute: {
                    // TODO: would be nice to handle these modifications elsewhere for consistency
                    self.greetingLabel.text = "Hey " + self.userDefaults.getUserName() + ", \(self.hasLocalNumberGreeting) \(self.customGreetingMessage)"
                    
                    self.waitTime.text = etaLocal.etaString
                    
                })
            } else {
                self.handleErrorInternal(errorNum: etaLocal.errorNum)
            }
        }
        self.getWaitTime() // make POST request here
    }
 
    
    // TODO: limit greetingText setting from here!!! -- this needs to be consolidated/reconciled with setUIState
    func handleErrorInternal(errorNum:CONSTS.ErrorNum.RawValue) {
        let errorDescription = CONSTS.getErrorDescription(errorId: errorNum)
        
        switch(errorNum) {
        case CONSTS.ErrorNum.NO_ERROR.rawValue:
            return
        case CONSTS.ErrorNum.NO_INTERNET.rawValue:
            self.loadingInitGreeting = errorDescription.rawValue
            if(self.greetingLabel.text != self.loadingInitGreeting) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
                    if(Reachability.isConnectedToNetwork()) {
                        self.getWaitTime()
                    } else {
                        self.sendNotification("No Internet", messageText: " Cannot connect to the internet or update schedules!")
                    }
                })
            }
            return
        case CONSTS.ErrorNum.SHOP_CLOSED.rawValue:
            self.setUIState(newState: .SHOP_CLOSED)
            if(!(greetingLabel.text == shopClosedGreeting)) {
                DispatchQueue.main.async( execute: {
                    self.greetingLabel.numberOfLines = (24 + self.shopClosedGreeting.count) / 25
                    self.greetingLabel.text = self.shopClosedGreeting + self.customGreetingMessage })
            }
        case CONSTS.ErrorNum.GET_NUMBER_FAIL.rawValue:
            // failed get_number
            DispatchQueue.main.async( execute: {self.greetingLabel.text = CONSTS.getErrorDescription(errorId: errorNum).rawValue + self.customGreetingMessage})
        case CONSTS.ErrorNum.GET_RESERVATION_FAIL.rawValue:
            // failed reservation
            DispatchQueue.main.async( execute: {self.greetingLabel.text = CONSTS.getErrorDescription(errorId: errorNum).rawValue + self.customGreetingMessage})
        case CONSTS.ErrorNum.CANCEL_FAIL.rawValue:
            // failed delete
            DispatchQueue.main.async( execute: {self.greetingLabel.text = CONSTS.getErrorDescription(errorId: errorNum).rawValue + self.customGreetingMessage})
        case CONSTS.ErrorNum.NO_SPOTS_AVAILABLE.rawValue:
            // no more available spots
            self.setUIState(newState: .SHOP_CLOSED)
            DispatchQueue.main.async( execute: {self.greetingLabel.text = CONSTS.getErrorDescription(errorId: errorNum).rawValue + self.customGreetingMessage})
        default:
            break
        }
    }

    func setUIState(newState:CONSTS.AppointmentStatus) {
        var updateState = newState
        
        if(!userDefaults.userInfoExists() && updateState != CONSTS.AppointmentStatus.LOADING_VIEW && updateState != CONSTS.AppointmentStatus.SHOP_CLOSED) {
            // 1. if user info does not exist, that should be the new state
            updateState = .NO_USER_INFO
        }
        
        if(updateState == currentState) { // Already displaying this view
            return
        } else if((currentState == .HAS_NUMBER || currentState == .HAS_RESERVATION) && updateState != currentState) {
            // previous view had number, new view does not have number
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
            center.removeAllPendingNotificationRequests() // To remove all pending notifications which are not delivered yet but scheduled.
            //UIApplication.shared.cancelAllLocalNotifications()
        }
        
        currentState = updateState
        
        let hideGetNumControls = (updateState == .HAS_NUMBER || updateState == .HAS_RESERVATION || updateState == .LOADING_VIEW)
        let hideNextNumCurNumLabels = updateState == .SHOP_CLOSED
        let reservationSpecific = updateState == .HAS_RESERVATION
        let enableControls = !(updateState == .SHOP_CLOSED || updateState == .NO_USER_INFO)
        let hasNumberEtaLabelText = (updateState == .HAS_NUMBER || updateState == .HAS_RESERVATION)
        var labelColor: UIColor
        if #available(iOS 13.0, *) {
            labelColor = (updateState == CONSTS.AppointmentStatus.NO_APPOINTMENT || updateState == .HAS_NUMBER || updateState == .HAS_RESERVATION) ? UIColor.label : UIColor.label
        } else {
            // Fallback on earlier versions -- hopefully they're not using dark mode
            labelColor = (updateState == CONSTS.AppointmentStatus.NO_APPOINTMENT || updateState == .HAS_NUMBER || updateState == .HAS_RESERVATION) ? UIColor.black : UIColor.gray
        }
        
        let etaLabelStr = hasNumberEtaLabelText ? self.yourEtaLabel : self.defaultWaitTime

        DispatchQueue.main.async( execute: {
            self.staticApproxWait.text = etaLabelStr
            
            switch(updateState) {
            case .NO_APPOINTMENT:
                self.nextNumLabelStatic.text = self.nextNumText
                
                self.greetingLabel.text = "Hey " + self.userDefaults.getUserName() + ", \(self.existingUserGreeting) \(self.customGreetingMessage)"
                break
            case .HAS_NUMBER:
                self.nextNumLabelStatic.text = self.yourNumText
                self.greetingLabel.text = "Hey " + self.userDefaults.getUserName() + ", \(self.haircut_upcoming_label)"
                break
            case .HAS_RESERVATION:
                self.greetingLabel.text = "Hey " + self.userDefaults.getUserName() + ", \(self.haircut_upcoming_label)"
                break
            case .SHOP_CLOSED:
                break
            case .NO_USER_INFO:
                self.greetingLabel.text = "Hey, \(self.signUpText) \(self.customGreetingMessage)"
                break
            case .LOADING_VIEW:
                self.greetingLabel.text = self.loadingInitGreeting + self.customGreetingMessage
                self.nextNumLabel.text = "--"
                self.curCustLabel.text = "--"
                break
            }
            
            //self.greetingLabel.text = self.greetingLabel.text! + self.customGreetingMessage
            
            self.waitTime.textColor = labelColor
            self.curCustLabel.textColor = labelColor
            self.nextNumLabel.textColor = labelColor
            self.getNumberButton.isHidden = hideGetNumControls
            self.reservationButton.isHidden = hideGetNumControls
            self.cancelAppointment.isHidden = (!hideGetNumControls || updateState == .LOADING_VIEW) // not set in shop_closed
            self.numHaircutsStatic.isHidden = hideGetNumControls // not set in shop_closed
            self.Stepper.isHidden = hideGetNumControls
            self.stepperLabel.isHidden = hideGetNumControls
            
            self.getNumberButton.isEnabled = enableControls
            self.reservationButton.isEnabled = enableControls
            self.Stepper.isEnabled = enableControls
            
            self.curCustLabel.isHidden = hideNextNumCurNumLabels
            self.curNumLabelStatic.isHidden = hideNextNumCurNumLabels
            
            self.nextNumLabelStatic.isHidden = reservationSpecific || hideNextNumCurNumLabels
            self.nextNumLabel.isHidden = reservationSpecific || hideNextNumCurNumLabels
            
            self.waitTime.isHidden = hideNextNumCurNumLabels
            self.staticApproxWait.isHidden = hideNextNumCurNumLabels
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
                                return
                            }
                            alertController.addAction(alternateAlertAction)
                        }
                        self.present(alertController, animated: true, completion: nil)
        }) // end of dispatch
    }
    
    @IBAction func getNumberWithSender(_ sender: UIButton) {
        if(userDefaults.userInfoExists()) {
            // Get the stepper value from label, default 1
            var stepperCount:Int = 1
            if(Int(stepperLabel.text!)! > 0) {
                stepperCount = Int(stepperLabel.text!)!
            }
            
            postController.getNumber(
                userDefaults, numRes: stepperCount, reservationInd: false, completionHandler: {(newUserDefaults:User) -> Void in
                    self.userDefaults = newUserDefaults
                    let firstAppointment = self.userDefaults.getFirstAppointment()
                    
                    if(self.userDefaults.userHasAppointment()) {
                        // Call succeeded
                        var notificationText = "Nice! Your haircut is in "
                        if(stepperCount > 1) {
                            notificationText = "You have reserved \(String(stepperCount)) haircuts, first one is in "
                        }
                        notificationText += self.userDefaults.getFirstUpcomingEta().1
                        self.sendNotification("Your Appointment", messageText: notificationText)
                        
                        self.setUIState(newState: firstAppointment.getAppointmentStatus())
                    } else {
                        // Error was hit
                        self.handleErrorInternal(errorNum: firstAppointment.getError())
                    }
                    self.getWaitTime()
            })
        } else {
            // Technically this should not be possible
            self.setUIState(newState: .NO_USER_INFO)
        }
    }
    
    @IBAction func cancelAppointmentWithSender(_ sender: UIButton) {
        // TODO: customer can have multiple reservations!!
        if(userDefaults.userInfoExists()) {
            // Make sure user info is set. Local appointment does not need to exist -- although why would this button be visible?
            // Prompt customer to confirm they want to delete
            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: "Cancel")
            // If user confirms, func processCancellation() is called
        } else { // UserInfo does not exist -- should not be reachable
            setUIState(newState: .NO_USER_INFO)
        }
    }
    func processCancellation() {
        if(userDefaults.userInfoExists()) {
            postController.cancelAppointment(userDefaults, completionHandler: {(delResponse:CONSTS.ErrorNum.RawValue) -> Void in

                if(delResponse == CONSTS.ErrorNum.NO_ERROR.rawValue) {
                    // delete succeeded
                    self.setUIState(newState: .NO_APPOINTMENT)
                    self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)
                    
                    DispatchQueue.main.async(execute: { self.greetingLabel.text = "\(self.generalGreeting), \(self.userDefaults.getUserName())? \(self.customGreetingMessage)" })
                } else {
                    self.handleErrorInternal(errorNum: delResponse)
                }
            })
        } else {
            self.setUIState(newState: .NO_USER_INFO)
        }
        self.getWaitTime() // update immediately
    }
    
    @IBAction func StepperWithSender(_ sender: UIStepper) {
        DispatchQueue.main.async(execute: {
            self.stepperLabel.text = String(Int(self.Stepper.value))
        })
    }
    
    func getClosedMessage() {
        postController.getClosedMessage({ (closedMessage:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void in
            let msgLength = closedMessage.messageText.count
            
            if(closedMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3) {
                // No server error received and message text is at least 3 characters. Assume shop is closed
                self.shopClosedGreeting = closedMessage.messageText
                self.setUIState(newState: .SHOP_CLOSED)
            }
        })
    }
    func getGreetingMessage() {
        postController.getGreetingMessage({ (greetingMessage:(errorNum: CONSTS.ErrorNum, messageText: String)) -> Void in
            let msgLength = greetingMessage.messageText.count
            
            if(greetingMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3) {
                // No server error received and message text is at least 3 characters. Assume shop is closed
                //self.shopClosedGreeting = greetingMessage.messageText
                //self.setUIState(newState: .SHOP_CLOSED)
                self.customGreetingMessage = greetingMessage.messageText
                
                // print("GREETING LABEL: " + self.greetingLabel.text!.suffix(self.customGreetingMessage.count))
                // print("CUSTOM GREETING MESSAGE: " + self.customGreetingMessage)
                DispatchQueue.main.async(execute: {
                    if(self.greetingLabel.text!.suffix(self.customGreetingMessage.count) != self.customGreetingMessage) {
                      self.greetingLabel.text = self.greetingLabel.text! + self.customGreetingMessage
                    }
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Start here:
    override func viewWillAppear(_ animated: Bool) {
        userDefaults = User()
        
        self.setUIState(newState: .LOADING_VIEW)
        // First check for closed message and any customizations to greeting
        getClosedMessage()
        getGreetingMessage()
        getWaitTime()
        checkForExistingAppointment()
        
        DispatchQueue.main.async {
            self.getEtaTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.getWaitTime), userInfo: nil, repeats: true)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        getEtaTimer.invalidate()
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
