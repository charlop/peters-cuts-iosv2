//
//  ViewController.swift
//  Peters816
//
//  Created by spandan on 2016-02-10.
//  Copyright © 2016 spandan jansari. All rights reserved.
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
    @IBOutlet weak var myNumberLabel: UILabel!
    @IBOutlet weak var getNumberButton: UIButton!
    @IBOutlet weak var cancelAppointment: UIButton!
    
    // MARK: seconds to hours, minutes, seconds
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // MARK: 40 min notification setting
    func notificationSetting (input:String) -> (Bool){
        
        var status:Bool
        if (input == "question") {
            return status
        } else if (input == "setON") {
            status = true
            return status
        } else if (input == "setOFF") {
            status = false
            return status
        }
    }
    
    // MARK: Now notification setting
    func NowNotificationSetting (input:String) -> (Bool){
        
        var status:Bool
        if (input == "question") {
            return status
        } else if (input == "setON") {
            status = true
            return status
        } else if (input == "setOFF") {
            status = false
            return status
        }
    }
    
    // Mark: function to set the two numbers - current and next
    
    func parseNumbers () {
        
        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        if ( Int(readableData["current"].stringValue) == -2){
            currentNumber.text = "0"
        } else {
            currentNumber.text = readableData["current"].stringValue
        }
        nextNumber.text = readableData["next"].stringValue
    }
        
    // MARK: determine whether has an appointment for today , if not jsonParse()
    func is_there_an_appointment_for_today() {
        
        // try to retrieve appointment in core data with today's NSDate
        
        let appdel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appdel.managedObjectContext
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        let todays_date = NSDate()
        let todays_string_date:String = dateFormatter.stringFromDate(todays_date)

        do {
            let request = NSFetchRequest (entityName: "Appointments")
            let results = try context.executeFetchRequest(request)
            if results.count > 0 {
                for items in results as! [NSManagedObject]{
                    let date = items.valueForKey("date") as! String
                    let number = items.valueForKey("number") as! String
                    print (date)
                    print (number)
                    if date == todays_string_date {
                        // replace get number button(hide) with "Your appointment # ("number") today is " UILabel - make one
                        // replace staticApproxWait label with "Your approx wait time" label - make one?
                        // replace waitTime [until now with last number to php page] with ("number") to php page
                        self.getNumberButton.hidden = true
                        self.staticApproxWait.text = "Your approximate wait time is"
                        self.myNumberLabel.text = "Your appointment # is \(number) "
                        
                        // get the COUNT and update waitTime.text
                        let url = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        var err: NSError?
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=Spandan&customerid=\(number)"
                        request.HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
                        session
                        let task = session.dataTaskWithRequest(request){ data,response,error in
                            if error != nil{
                                print("ERROR -> \(error)")
                                return
                            }
                            if let httpResponse = response as? NSHTTPURLResponse {
                                // print("responseCode \(httpResponse.statusCode)")
                            }
                            do {
                                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )
                                // print("Result -> \(responseJSON)")
                                let count = responseJSON["retVal"] as! Int                  // retVal
                                print ("\(count)")
                                let waitTime_seconds = count * 20 * 60
                                let (h,m,s) = ViewController().secondsToHoursMinutesSeconds(waitTime_seconds)
                                ViewController().waitTime.text = "\(h) : \(m)"
                                
                                if (count == 2) {
                                    
                                    let checkNotification = self.notificationSetting("question")
                                    if (checkNotification == true) {
                                        // do nothing. notification already set
                                    } else {
                                        // create notification that your appointment is up in 40 mins
                                        func createLocalNotification(nextActualNumber: Int) {
                                        let localNotification = UILocalNotification()
                                        let seconds1 = 20*2*60 // int value
                                        let seconds2 = Double(seconds1)     // double value
                                        localNotification.fireDate = NSDate(timeIntervalSinceNow: seconds2)
                                        localNotification.soundName = UILocalNotificationDefaultSoundName
                                        localNotification.alertBody = "Your haircut appointment is in half hour!"
                                        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                                        self.notificationSetting("setON")
                                        
                                        } // end of createLocalNotif
                                    } // end of else if
                                }  else if (count == 0) {                // end of count = 2
                                    
                                    let checkNowNotification = self.NowNotificationSetting("question")
                                    if (checkNowNotification == true) {
                                        // do nothing. notification already set.
                                    } else {
                                    // create notification that your appointment is up right now
                                        func createLocalNotification() {
                                        let localNotificationNow = UILocalNotification()
                                        localNotificationNow.fireDate = NSDate(timeIntervalSinceNow: 0)           // change to 10 to approx wait time subtraction
                                        localNotificationNow.soundName = UILocalNotificationDefaultSoundName
                                        localNotificationNow.alertBody = "Your haircut appointment is Now"
                                        UIApplication.sharedApplication().scheduleLocalNotification(localNotificationNow)
                                        self.NowNotificationSetting("setON")
                                        } // end of creating "Now" notification
                                    }
                                } // end of else if count = 0
                            } catch {                                   // end of do
                                print ("error...")
                            }
                        } // end of task
                        task.resume()
                    } else {                                            // end of if date == todays_string_date

                        func jsonParse () {
                            
                            let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                            let jsonData = NSData(contentsOfURL: url!) as NSData!
                            let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
                            if ( Int(readableData["current"].stringValue) == -2){
                                currentNumber.text = "error"
                            } else {
                                currentNumber.text = readableData["current"].stringValue
                            }
                            if ( Int(readableData["next"].stringValue) == -2){
                            nextNumber.text = "error"
                            } else {
                                currentNumber.text = readableData["next"].stringValue
                            }
                            let next_Number = Int(nextNumber.text!)                             // will be used to get the wait time via count
                            let current_Number = Int(currentNumber.text!)
                            
                            // APPROX_WAIT_TIME
                            
                            // without appointment using the count method and using the previous current_Number and next_Number = customerid
                            
                            // set the max number as 'customerid' for count
                            let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                            let request = NSMutableURLRequest(URL: url2!)
                            let session = NSURLSession.sharedSession()
                            request.HTTPMethod = "POST"
                            // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                            // var params = ["customerid":"\(number)"] as Dictionary<String, String>
                            // print ("\(params)")
                            
                            let customerid:String = "customerid=\(next_Number)"
                            
                            request.HTTPBody = customerid.dataUsingEncoding(NSUTF8StringEncoding)
                            session
                            let task = session.dataTaskWithRequest(request) {data, response, error  in
                                if error != nil{
                                    print("ERROR -> \(error)")
                                    return
                                }
                                if let httpResponse = response as? NSHTTPURLResponse {
                                    // print("responseCode \(httpResponse.statusCode)")
                                }
                                do {
                                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )
                                    // print("Result -> \(responseJSON)")
                                    let count = responseJSON["retVal"] as! Int                  // retVal
                                    let waitTime_seconds = count * 20 * 60
                                    let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                                    self.waitTime.text = "\(h) : \(m)"
                                    
                                } catch {
                                    print("Error -> \(error)")
                                }
                            } // end of task
                            task.resume()
                        } // end of jsonParse()
                    }
                } // end of for statement
            } // end of results count IF statement
        } catch {                                               // end of do statement
            print ("error ... ")                                // replace/correct with correct error to try fetch request from core data
        }
    } //  end of func is_there_an_appointment_for_today() and nested jsonParse()


    
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
        
            // print (email)
            
            
            
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
                        }) // end of dispatch
             return
            } else {
                
        let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
        let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
        
        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
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
                
                if (gotNumber == -2) {
                    print ("insert did not succeed") // SET UP A POP UP NOTIFICATION
                } else if (gotNumber == -9) {
                    print ("store if closed") // SET UP A POP UP NOTIFICATION
                }
                
                // Wait time does not need to be updated here. it can be updated in the is_there_an_appointment_today() function
                
                if (messageReturned == "new"){
                    
                    // some change
                  // create a pop alerting number
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumber) in the que. Please check back in the app for updated waiting time. Also, a notification will be set 40 mins prior to your appointment.", preferredStyle: .Alert  )
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            // ...
                        }
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            // ...
                        }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                    
                    // create ManagedObjectContext
                    let appdel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let context: NSManagedObjectContext = appdel.managedObjectContext
                    
                    // Get the Date in string format
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateStyle = .LongStyle
                    dateFormatter.timeStyle = .NoStyle
                    let date = NSDate()
                    let string_date:String = dateFormatter.stringFromDate(date)
                    
                    // insert date and number into entity
                    let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context)
                    addAppointment.setValue(string_date, forKey: "date")
                    addAppointment.setValue(gotNumber, forKey: "number")
                    do{
                        try context.save()
                    }catch {
                        print ("error saving data")
                    }
                    // update the app look with  (which will replace the get number button and wait time)
                    self.is_there_an_appointment_for_today()
                    
                } else if (messageReturned == "duplicate") {
                    dispatch_async(dispatch_get_main_queue(),
                        {
                        let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumber) in the que.", preferredStyle: .Alert  )
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            // ...
                        }
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            // ...
                        }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                } // end of else if "duplicate"
                
            } catch {
                print("Error -> \(error)")
                }
                //update screen ...
                self.is_there_an_appointment_for_today() // change screen
                } // end of task
                task.resume()
    } // of else statement (to having input name and number)
    
    } // end of get number function
    
    
    
    @IBAction func cancelAppointment(sender: AnyObject) {
        
        
        // fetch today's appointment
        let appdel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appdel.managedObjectContext
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        let todays_date = NSDate()
        let todays_string_date:String = dateFormatter.stringFromDate(todays_date)
        
        do {
            let request = NSFetchRequest (entityName: "Appointments")
            let results = try context.executeFetchRequest(request)
            if results.count > 0 {
                
                for items in results as! [NSManagedObject]{
                    let date = items.valueForKey("date") as! String
                    let number = items.valueForKey("number") as! String
                    if date == todays_string_date {
                        
                        // send cancel request
                        let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                        let request = NSMutableURLRequest(URL: url2!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let deleteid:String = number
                        request.HTTPBody = deleteid.dataUsingEncoding(NSUTF8StringEncoding)
                        session
                        let task = session.dataTaskWithRequest(request) {data, response, error  in
                            if error != nil{
                                print("ERROR -> \(error)")
                                return
                            }
                            if let httpResponse = response as? NSHTTPURLResponse {
                                // print("responseCode \(httpResponse.statusCode)")
                            }
                            do {
                                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )
                                // print("Result -> \(responseJSON)")
                                let confirmation = responseJSON["retVal"] as! String
                                if confirmation == "T" {
                                    
                                    // send pop up, appointment cancelled
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            let alertController = UIAlertController(title: "Appointment Cancelled", message: "Your Appointment has been cancelled.", preferredStyle: .Alert  )
                                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                                                // ...
                                            }
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                // ...
                                            }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                                    })
                                }
                            } catch {
                                print("Error -> \(error)")
                            }
                        } // end of task
                        task.resume()
                        
                        
                        // also delete the appointment from Core Data
                        
                        
                    } else {                                    // end of if date == todays_string_date statement
                        // print no appointments today
                    }
                } // end of FOR statement
            } catch {
                print (error)
            }
            
        
        
    } // end of cancelAppointment
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        is_there_an_appointment_for_today() // check if theres any appointment
        NSTimer.scheduledTimerWithTimeInterval(180, target: self, selector: "is_there_an_appointment_for_today", userInfo: nil, repeats: true)
        parseNumbers()
        NSTimer.scheduledTimerWithTimeInterval(180, target: self, selector: "parseNumbers", userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    
    
    
    
    
}

