import UIKit
import CoreData
import Foundation
import UserNotifications

class userInfoViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    @IBOutlet weak var nameInvalidLabel: UILabel!
    @IBOutlet weak var phoneInvalidLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    let userDefaults = User()
    var nameValid = false
    var phoneValid = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        /*
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        */
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let extName = userDefaults.getUserName()
        let extPhone = userDefaults.getUserPhone()
        let extEmail = userDefaults.getUserEmail()
        
        if(extName != "") {
            nameField.text = extName
            nameValid=true
        }
        if (extPhone != "") {
            phoneField.text = extPhone
            phoneValid = true
        }
        if(extEmail != "") {
            emailField.text = extEmail
        }
        if(phoneValid && nameValid) {
            saveButton.isEnabled=true
        }
    }
    
    // On namefield change
    @IBAction func validateNameWithSenderWithSender(_ sender: AnyObject) {
        if let nameTextField = nameField.text {
            if(nameTextField == "" || nameTextField.count < 3) {
                nameInvalidLabel.isHidden = false
                saveButton.isEnabled=false
                nameValid = false
            } else {
                nameValid = true
                if(nameValid && phoneValid) {
                    saveButton.isEnabled=true
                }
                nameInvalidLabel.isHidden = true
            }
        }
    }
    
    @IBAction func validatePhoneWithSenderWithSender(_ sender: AnyObject) {
        if let phoneText = phoneField.text {
            if(phoneText == "" || phoneText.count < 10 || phoneText.count > 20
            ) {
                phoneInvalidLabel.isHidden = false
                saveButton.isEnabled=false
                phoneValid = false
            } else {
                do {
                    let regexStr = "^(?:(?:\\+?1\\s*(?:[.-]\\s*)?)?(?:\\(\\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\\s*\\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\\s*(?:[.-]\\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\\s*(?:[.-]\\s*)?([0-9]{4})(?:\\s*(?:#|x\\.?|ext\\.?|extension)\\s*(\\d+))?$"
                    let validatePhoneRegex = try NSRegularExpression(pattern: regexStr, options: [])
                    if validatePhoneRegex.firstMatch(in: phoneField.text!, options: [], range: NSMakeRange(0, phoneField.text!.count)) != nil {
                        // valid phone number
                        phoneValid = true
                        phoneInvalidLabel.isHidden = true
                        if(nameValid && phoneValid) {
                            saveButton.isEnabled=true
                        }
                    } else {
                        // invalid phone number
                        phoneInvalidLabel.isHidden = false
                        saveButton.isEnabled=false
                        phoneValid = false
                    }
                } catch _ as NSError {
                    // treat as invalid?
                    phoneInvalidLabel.isHidden = false
                    saveButton.isEnabled=false
                    phoneValid = false
                }
            }
        }
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButtonActionWithSender(_ sender: AnyObject) {
        if let name = nameField.text {
            if let phone = phoneField.text {
                userDefaults.saveUserDetails(name, inPhone: phone, inEmail: emailField.text!)
                
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                    (granted, error) in
                    //Parse errors and track state
                   }
                //UNNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
                //UIUserNotificationSettings(types: [.badge, .alert, .sound ], categories: nil)
                //UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                //UNUserNotificationCenter.requestAuthorization(notificationSettings)
                
                // UIApplication.sharedApplication.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
                _ = navigationController?.popToRootViewController(animated: true)
                
            } else {
                phoneInvalidLabel.isHidden = false
            }
        } else {
            nameInvalidLabel.isHidden = false
        }
    }

    @IBAction func handleSwipe(_ gestureRecognizer : UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Go back to main screen -- animate on right-swipe, do not animate otherwise
            if gestureRecognizer.direction == .right || gestureRecognizer.direction == .down {
                _ = navigationController?.popToRootViewController(animated: true)
            } else {
                //_ = navigationController?.popToRootViewController(animated: false)
            }
        }
    }
}
