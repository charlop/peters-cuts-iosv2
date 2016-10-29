import UIKit
import CoreData
import Foundation

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
    
    //@IBAction func termsOfUse(sender: UIButton) { }
    //@IBAction func privacyPolicy(sender: UIButton) { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let extname: String? = userDefaults.name
        let extphone: String? = userDefaults.phone
        let extemail: String? = userDefaults.email
        if(extname != nil && extname != "") {
            nameField.text = extname
            nameValid=true
        }
        if (extphone != nil && extphone != "") {
            phoneField.text = extphone
            phoneValid = true
        }
        if extemail != nil {
            emailField.text = extemail
        }
        if(phoneValid && nameValid) {
            saveButton.enabled=true
        }
    }
    
    // On namefield change
    @IBAction func validateNameWithSenderWithSender(sender: AnyObject) {
        // TODO: maybe name must have criteria?
        if(nameField.text == nil || nameField.text == "") {
            nameInvalidLabel.hidden = false
            saveButton.enabled=false
            nameValid = false
        } else {
            nameValid = true
            if(nameValid && phoneValid) {
                saveButton.enabled=true
            }
            nameInvalidLabel.hidden = true
        }
    }
    
    @IBAction func validatePhoneWithSenderWithSender(sender: AnyObject) {
        if(phoneField.text == nil || phoneField.text == "") {
            phoneInvalidLabel.hidden = false
            saveButton.enabled=false
            phoneValid = false
        } else {
            phoneValid = true
            if(nameValid && phoneValid) {
                saveButton.enabled=true
            }
            phoneInvalidLabel.hidden = true
        }
        
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButtonActionWithSender(sender: AnyObject) {
        if let name = nameField.text {
            if let phone = phoneField.text {
                userDefaults.saveUserDetails(name, inPhone: phone, inEmail: emailField.text!)
            } else {
                phoneInvalidLabel.hidden = false
            }
        } else {
            nameInvalidLabel.hidden = false
        }
    }
}
