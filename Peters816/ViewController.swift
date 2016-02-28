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
    
   
    @IBOutlet weak var banner: UIImageView!
    @IBOutlet weak var staticCurrentNumber: UILabel!
    @IBOutlet weak var currentNumber: UILabel!
    @IBOutlet weak var staticNextNumber: UILabel!
    @IBOutlet weak var nextNumber: UILabel!
    @IBOutlet weak var waitTime: UILabel!
 
    @IBOutlet weak var staticApproxWait: UILabel!
  
    
    // MARK: json_parse
    
    func jsonParse () {
        
        let url = NSURL(string: "http://peters816.comlu.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        
        if ( Int(readableData["current"].stringValue) == -2){
    
            currentNumber.text = "0"
            
        } else {
            
            currentNumber.text = readableData["current"].stringValue
        }
        
        nextNumber.text = readableData["next"].stringValue
        
        let next_Number = Int(nextNumber.text!)
        let current_Number = Int(currentNumber.text!)
    
        
    
    
        
    // APPROX_WAIT_TIME
        
    
        
       let subtraction =  ( next_Number! - current_Number! ) * 15
        
        let wait_Time:String? = " \(subtraction)"  + " minutes"
        waitTime.text = wait_Time

    
    }
    
    // MARK: Set local notification
    
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
    
    
        // MARK: Actions
    

    @IBAction func updateInfo(sender: UIButton) {
        
    }
    
    @IBAction func about(sender: UIButton) {
    }
    
    @IBAction func termsOfUse(sender: UIButton) {
    }
    
    
    @IBAction func privacyPolicy(sender: UIButton) {
    }
    
    
    @IBAction func getNumber(sender: UIButton) {
    
   
        var email:String
            if (NSUserDefaults.standardUserDefaults().stringForKey("email") == nil){
                email = "email@email.com"
            } else {
                email = NSUserDefaults.standardUserDefaults().stringForKey("email")!
            }
        
            print (email)
            
            
            
            if (NSUserDefaults.standardUserDefaults().stringForKey("name") == nil ||
                NSUserDefaults.standardUserDefaults().stringForKey("number") == nil) {
                    
                    dispatch_async(dispatch_get_main_queue(),
                        {
                            let alertController = UIAlertController(title: "Alert", message: "Please enter your information", preferredStyle: .Alert  )
                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            }
                            alertController.addAction(cancelAction)
                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            }
                            alertController.addAction(OKAction)
                            self.presentViewController(alertController, animated: true, completion: nil)

                    })

             return
        }
        
        let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
        let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
        
        let url = NSURL(string: "http://peters816.comlu.com/lib/app_request.php")
        let request = NSMutableURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        session
        
        
        
        
     
        
        
        
        let postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
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
                let messageReturned:String = responseJSON["message"] as! String
                let current_Number = Int(self.currentNumber.text!)
                let gotTime = (gotNumber - current_Number!) * 15
                
                if (messageReturned == "new"){
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumber) in the que. Your approximate wait time is \(gotTime) minutes", preferredStyle: .Alert  )
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            // ...
                        }
                        alertController.addAction(cancelAction)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            // ...
                        }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                } else if (messageReturned == "duplicate") {
                    dispatch_async(dispatch_get_main_queue(),
                        {
                        let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumber) in the que. Your approximate wait time is \(gotTime) minutes", preferredStyle: .Alert  )
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            // ...
                        }
                        alertController.addAction(cancelAction)
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            // ...
                        }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                }
                        self.createLocalNotification(gotNumber)
                } catch {
                print("Error -> \(error)")
                    }
                self.jsonParse() // refreshes the next number
        }
        task.resume()
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       jsonParse()
        NSTimer.scheduledTimerWithTimeInterval(180, target: self, selector: "jsonParse", userInfo: nil, repeats: true)
        
       
     
            
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    
    
    
    
    
}

