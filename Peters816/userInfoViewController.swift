import UIKit
import CoreData
import Foundation

class userInfoViewController: UIViewController {
    @IBOutlet weak var staticEnterName: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var staticEnterPhone: UILabel!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var staticEnterEmail: UILabel!
    @IBOutlet weak var emailField: UITextField!

    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let extname: String? = userDefaults.stringForKey("name")
        let extphone: String? = userDefaults.stringForKey("number")
        let extemail: String? = userDefaults.stringForKey("email")
        if extname != nil {
            nameField.text = extname
        }
        if extphone != nil {
            phoneField.text = extphone
        }
        if extemail != nil {
            emailField.text = extemail
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButton(sender: UIButton) {
        userDefaults.setObject(nameField.text, forKey: "name")
        userDefaults.setObject(phoneField.text, forKey: "number")
        userDefaults.setObject(emailField.text, forKey: "email")
    }
}
