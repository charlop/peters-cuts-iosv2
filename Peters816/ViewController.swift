//
//  ViewController.swift
//  Peters816
//
//  Created by spandan on 2016-02-10.
//  Copyright © 2016 spandan. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import SwiftyJSON

class ViewController: UIViewController {
    
    
    // MARK: Properties
    
    @IBOutlet weak var logo: UIImageView! // whats the exclamation mark?
    @IBOutlet weak var staticCurrentNumber: UILabel!
    @IBOutlet weak var currentNumber: UILabel!
    @IBOutlet weak var staticNextNumber: UILabel!
    @IBOutlet weak var nextNumber: UILabel!
    @IBOutlet weak var waitTime: UILabel!
    @IBOutlet weak var enterOnce: UILabel!
    
    // MARK: json_parse
    
    func jsonParse () {
        
        let url = NSURL(string: "http://peters816.comlu.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        currentNumber.text = readableData["current"].stringValue
        nextNumber.text = readableData["next"].stringValue
        
        let next_Number = Int(nextNumber.text!)
        let current_Number = Int(currentNumber.text!)
    
        
    
    
        
    // APPROX_WAIT_TIME
        
    
        
       let subtraction =  ( next_Number! - current_Number! ) * 15
        
        let wait_Time:String? = " Approx. wait-time is " + "\(subtraction)"  + " minutes"
        waitTime.text = wait_Time

    
    }
    
    
    func createLocalNotification(nextActualNumber: Int) {
        
        
        let localNotification = UILocalNotification()
        let current_number = currentNumber.text
        let currentActualNumber = Int(current_number!)
        let smallerWindow = ((nextActualNumber-2) - currentActualNumber!)
        
        let seconds1 = smallerWindow*15*60 // int value
        let seconds2 = Double(seconds1)     // double value
        localNotification.fireDate = NSDate(timeIntervalSinceNow: seconds2)           // change to 10 to approx wait time subtraction
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.alertBody = "Your haircut appointment is in half hour!"
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
    }
    
    //
    
        // MARK: Actions
    

    @IBAction func updateInfo(sender: UIButton) {
        
    }
    
    @IBAction func getNumber(sender: UIButton) {
    
        let url = NSURL(string: "http://peters816.comlu.com/lib/app_request.php")
        let request = NSMutableURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        session
        
        let userName = NSUserDefaults.standardUserDefaults().stringForKey("name")
        let phone = NSUserDefaults.standardUserDefaults().stringForKey("number")
        let email = NSUserDefaults.standardUserDefaults().stringForKey("email")
        
        // print (userName!)
        
                // TEST
        
         let postParams =  "user_name=\(userName!)&user_phone=\(phone!)&user_email=\(email!)"
         request.HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data,response,error in
            if error != nil{
                
                print("ERROR -> \(error)")
                return
                
            }
            
            if let httpResponse = response as? NSHTTPURLResponse {
                print("responseCode \(httpResponse.statusCode)")
                
            }
            
            
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )
                // print("Result -> \(responseJSON)")
                let gotNumber = responseJSON["getId"] as! Int
                let current_Number = Int(self.currentNumber.text!)
                let gotTime = (gotNumber - current_Number!) * 15
                
                
              
                
               // print(gotNumber)
                
                
              self.createLocalNotification(gotNumber)
                
                
                let alertController = UIAlertController(title: "Your Appointment", message: "You have received \(gotNumber) in the que. Your approximate wait time is \(gotTime)", preferredStyle: .Alert  )
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                    // ...
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                    // ...
                }
                alertController.addAction(OKAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
               
                
                } catch {
                print("Error -> \(error)")
                    }
        
        
            }
        
        task.resume()
        
    
        /* request.setValue(<#T##value: AnyObject?##AnyObject?#>, forKey: <#T##String#>)  */
        // setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       jsonParse()
        
       
     
            
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    
    
    
    
    
}

