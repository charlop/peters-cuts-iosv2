import UIKit
import Foundation
import UserNotifications

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var waitTime: UILabel!
    @IBOutlet weak var staticApproxWait: UILabel!
    @IBOutlet weak var getNumberButton: UIButton!
    @IBOutlet weak var reservationButton: UIButton!
    @IBOutlet weak var cancelAppointment: UIButton!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var numHaircutsStatic: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var curCustLabel: UILabel!
    @IBOutlet weak var nextNumLabelStatic: UILabel!
    @IBOutlet weak var nextNumLabel: UILabel!
    @IBOutlet weak var curNumLabelStatic: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    var userDefaults = User()
    var getEtaTimer = Timer()

    
    var currentState = AppointmentStatus.noAppointment // Default setting
    
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
    let generalGreeting:String = "How's it going"

    @IBOutlet weak var curNumUIStack: UIStackView!
    // Returns the wait time
    @objc func getWaitTime() {
        Task {
            let etaResponse = try await APIService.shared.getEta(for: userDefaults)
            self.userDefaults = User()

            let errorFatalBool = CONSTS.isFatal(errorId: etaResponse.getError())

            if etaResponse.getError() != CONSTS.ErrorNum.NO_ERROR.rawValue {
                await handleErrorInternal(errorNum: etaResponse.getError())

                if errorFatalBool {
                    // no point in getting the ETA for fatal errors
                    return
                }
            }

            await MainActor.run {
                if etaResponse.getEtaMins() > 0.0 {
                    self.setUIState(newState: etaResponse.getAppointmentStatus())
                    var waitTimeString = ""

                    let etaHrs = Int(etaResponse.getEtaMins() / 60)
                    let etaMins = Int(etaResponse.getEtaMins().truncatingRemainder(dividingBy: 60))
                    if etaHrs > 0 {
                        waitTimeString += String(etaHrs) + " hours "
                    }
                    waitTimeString += String(etaMins) + " minutes"

                    self.waitTime.text = waitTimeString
                }
                if etaResponse.getCurrentId() > 0 {
                    self.curCustLabel.text = String(etaResponse.getCurrentId())
                }
                if etaResponse.getUpcomingId() > 0 {
                    self.nextNumLabel.text = String(etaResponse.getUpcomingId())
                }
            }
        }
    }
    
    // Check if user has an appointment to decide which view to present
    // Function should only be called once, when the view initially loads
    func checkForExistingAppointment() {
        if(!userDefaults.userInfoExists) {
            self.setUIState(newState: .noUserInfo)
        } else if(self.userDefaults.hasAppointment) {
            let etaLocal :(errorNum:CONSTS.ErrorNum.RawValue, etaString:String) = self.userDefaults.getFirstUpcomingEta()
            if(etaLocal.errorNum == CONSTS.ErrorNum.NO_ERROR.rawValue) {
                // User has local appointment
                DispatchQueue.main.async(execute: {
                    // TODO: would be nice to handle these modifications elsewhere for consistency
                    self.greetingLabel.text = "Hey " + self.userDefaults.userName + ", \(self.hasLocalNumberGreeting) \(self.customGreetingMessage)"
                    
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
        
        if(errorNum == CONSTS.ErrorNum.NO_ERROR.rawValue) {
            return
        }
        DispatchQueue.main.async {
            guard let greetingLabel = self.greetingLabel else { return }
            let currentText = greetingLabel.text
            
            switch(errorNum) {
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
                self.setUIState(newState: .shopClosed)

                    if currentText != self.shopClosedGreeting {
                        self.greetingLabel.numberOfLines = (24 + self.shopClosedGreeting.count) / 25
                        self.greetingLabel.text = self.shopClosedGreeting + self.customGreetingMessage
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
                self.setUIState(newState: .shopClosed)
                DispatchQueue.main.async( execute: {self.greetingLabel.text = CONSTS.getErrorDescription(errorId: errorNum).rawValue + self.customGreetingMessage})
            default:
                break
            }
        }
    }

    func setUIState(newState:CONSTS.AppointmentStatus) {
        var updateState = newState
        
        if(!userDefaults.userInfoExists && updateState != CONSTS.AppointmentStatus.loadingView && updateState != CONSTS.AppointmentStatus.shopClosed) {
            // 1. if user info does not exist, that should be the new state
            updateState = .noUserInfo
        }
        
        if(updateState == currentState) { // Already displaying this view
            return
        } else if((currentState == .hasNumber || currentState == .hasReservation) && updateState != currentState) {
            // previous view had number, new view does not have number
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
            center.removeAllPendingNotificationRequests() // To remove all pending notifications which are not delivered yet but scheduled.
            //UIApplication.shared.cancelAllLocalNotifications()
        }
        
        currentState = updateState
        
        let hideGetNumControls = (updateState == .hasNumber || updateState == .hasReservation || updateState == .loadingView)
        let hideNextNumCurNumLabels = updateState == .shopClosed
        let reservationSpecific = updateState == .hasReservation
        let enableControls = !(updateState == .shopClosed || updateState == .noUserInfo)
        let hasNumberEtaLabelText = (updateState == .hasNumber || updateState == .hasReservation)
        let labelColor: UIColor = UIColor.label

        let etaLabelStr = hasNumberEtaLabelText ? self.yourEtaLabel : self.defaultWaitTime

        DispatchQueue.main.async( execute: {
            self.staticApproxWait.text = etaLabelStr
            
            switch(updateState) {
            case .noAppointment:
                self.nextNumLabelStatic.text = self.nextNumText
                
                self.greetingLabel.text = "Hey " + self.userDefaults.userName + ", \(self.existingUserGreeting) \(self.customGreetingMessage)"
                break
            case .hasNumber:
                self.nextNumLabelStatic.text = self.yourNumText
                self.greetingLabel.text = "Hey " + self.userDefaults.userName + ", \(self.haircut_upcoming_label)"
                break
            case .hasReservation:
                self.greetingLabel.text = "Hey " + self.userDefaults.userName + ", \(self.haircut_upcoming_label)"
                break
            case .shopClosed:
                break
            case .noUserInfo:
                self.greetingLabel.text = "Hey, \(self.signUpText) \(self.customGreetingMessage)"
                break
            case .loadingView:
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
            self.cancelAppointment.isHidden = (!hideGetNumControls || updateState == .loadingView) // not set in shop_closed
            self.numHaircutsStatic.isHidden = hideGetNumControls // not set in shop_closed
            self.stepper.isHidden = hideGetNumControls
            self.stepperLabel.isHidden = hideGetNumControls

            self.getNumberButton.isEnabled = enableControls
            self.reservationButton.isEnabled = enableControls
            self.stepper.isEnabled = enableControls
            
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
        guard userDefaults.userInfoExists else {
            setUIState(newState: .noUserInfo)
            return
        }

        // Get the stepper value from label, default 1
        var stepperCount: Int = 1
        if let stepperText = stepperLabel.text,
           let count = Int(stepperText),
           count > 0 {
            stepperCount = count
        }

        Task {
            let newUserDefaults = try await APIService.shared.getNumber(
                for: userDefaults,
                count: stepperCount,
                isReservation: false
            )
            self.userDefaults = newUserDefaults
            let firstAppointment = self.userDefaults.getFirstAppointment()

            await MainActor.run {
                if self.userDefaults.hasAppointment {
                    // Call succeeded
                    var notificationText = "Nice! Your haircut is in "
                    if stepperCount > 1 {
                        notificationText = "You have reserved \(String(stepperCount)) haircuts, first one is in "
                    }
                    notificationText += self.userDefaults.getFirstUpcomingEta().1
                    self.sendNotification("Your Appointment", messageText: notificationText)

                    self.setUIState(newState: firstAppointment.getAppointmentStatus())
                } else {
                    // Error was hit
                    Task {
                        await self.handleErrorInternal(errorNum: firstAppointment.getError())
                    }
                }
                self.getWaitTime()
            }
        }
    }
    
    @IBAction func cancelAppointmentWithSender(_ sender: UIButton) {
        // TODO: customer can have multiple reservations!!
        if(userDefaults.userInfoExists) {
            // Make sure user info is set. Local appointment does not need to exist -- although why would this button be visible?
            // Prompt customer to confirm they want to delete
            self.sendNotification("Confirmation", messageText: "Cancel Appointments?", alternateAction: "Cancel")
            // If user confirms, func processCancellation() is called
        } else { // UserInfo does not exist -- should not be reachable
            setUIState(newState: .noUserInfo)
        }
    }
    func processCancellation() {
        guard userDefaults.userInfoExists else {
            setUIState(newState: .noUserInfo)
            getWaitTime()
            return
        }

        Task {
            let delResponse = try await APIService.shared.cancelAppointment(for: userDefaults)

            await MainActor.run {
                if delResponse == CONSTS.ErrorNum.NO_ERROR.rawValue {
                    // delete succeeded
                    self.setUIState(newState: .noAppointment)
                    self.sendNotification("Appointment Cancelled", messageText: self.forIssuesAlert)

                    self.greetingLabel.text = "\(self.generalGreeting), \(self.userDefaults.userName)? \(self.customGreetingMessage)"
                } else {
                    Task {
                        await self.handleErrorInternal(errorNum: delResponse)
                    }
                }
                self.getWaitTime() // update immediately
            }
        }
    }
    
    @IBAction func StepperWithSender(_ sender: UIStepper) {
        DispatchQueue.main.async(execute: {
            self.stepperLabel.text = String(Int(self.stepper.value))
        })
    }
    
    func getClosedMessage() {
        Task {
            let closedMessage = try await APIService.shared.getClosedMessage()
            let msgLength = closedMessage.messageText.count

            await MainActor.run {
                if closedMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                    // No server error received and message text is at least 3 characters. Assume shop is closed
                    self.shopClosedGreeting = closedMessage.messageText
                    self.setUIState(newState: .shopClosed)
                }
            }
        }
    }

    func getGreetingMessage() {
        Task {
            let greetingMessage = try await APIService.shared.getGreetingMessage()
            let msgLength = greetingMessage.messageText.count

            await MainActor.run {
                if greetingMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                    self.customGreetingMessage = greetingMessage.messageText

                    guard let currentText = self.greetingLabel.text else { return }
                    if currentText.suffix(self.customGreetingMessage.count) != self.customGreetingMessage {
                        self.greetingLabel.text = currentText + self.customGreetingMessage
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Start here:
    override func viewWillAppear(_ animated: Bool) {
        userDefaults = User()

        self.setUIState(newState: .loadingView)
        // First check for closed message and any customizations to greeting
        getClosedMessage()
        getGreetingMessage()
        getWaitTime()
        checkForExistingAppointment()

        // Auto-refresh: Poll every 10 seconds for real-time updates
        // Note: This provides live queue status without requiring user action
        DispatchQueue.main.async {
            self.getEtaTimer = Timer.scheduledTimer(
                timeInterval: 10.0,
                target: self,
                selector: #selector(self.getWaitTime),
                userInfo: nil,
                repeats: true
            )
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        getEtaTimer.invalidate()
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
