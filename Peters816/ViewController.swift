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
    
    var firstNotificationStatus:Bool = false
    var NowNotificationStatus:Bool = false
    
    // MARK: 40 min notification setting
    func notificationSetting (input:String) -> (Bool){
        
        if (input == "question") {
            return self.firstNotificationStatus
        } else if (input == "setON") {
            self.firstNotificationStatus = true
            // print("\(firstNotificationStatus)")
            return self.firstNotificationStatus
        } else if (input == "setOFF") {
            self.firstNotificationStatus = false
            return self.firstNotificationStatus
        }
        return self.firstNotificationStatus // this return will not be used
    }
    
    // MARK: Now notification setting
    func NowNotificationSetting (input:String) -> (Bool){
        
        if (input == "question") {
            return self.NowNotificationStatus
        } else if (input == "setON") {
            self.NowNotificationStatus = true
            return self.NowNotificationStatus
        } else if (input == "setOFF") {
            self.NowNotificationStatus = false
            return self.NowNotificationStatus
        }
        return self.NowNotificationStatus // this return will not be used
    }
    
    // Mark: function to set the two numbers - current and next
    
    func parseNumbers () {
       
        print ("readableData")

        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        currentNumber.text = readableData["current"].stringValue
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
                    print (date, number)
                    
                    if date == todays_string_date {
                        // replace get number button(hide) with "Your appointment # ("number") today is " UILabel - make one
                        // replace staticApproxWait label with "Your approx wait time" label - make one?
                        // replace waitTime [until now with last number to php page] with ("number") to php page
                        self.getNumberButton.hidden = true
                        self.myNumberLabel.hidden = false
                        self.cancelAppointment.hidden = false
                        self.staticApproxWait.text = "Your approximate wait time is"
                        self.myNumberLabel.text = "Your appointment # is \(number) "

                        // MARK: COUNT for today's appointment and wait time
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
                                print("responseCode \(httpResponse.statusCode)")
                            }
                            do {
                                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )
                                print("Result -> \(responseJSON)")
                                let count = responseJSON["retVal"] as! Int                  // retVal
                                let waitTime_seconds = count * 20 * 60
                                let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                                self.waitTime.text = "\(h) hrs : \(m) min"
                          
                                // MARK: Notifications
                                if (count == 2) {
                                    
                                    let checkNotification = self.notificationSetting("question")
                                    if (checkNotification == true) {                         // CHECK IF THE DEFAULT VALUE OF THE BOOL IS true ... IT SHOULD BE FALSE
                                        // do nothing. notification already set
                                    } else {
                                        // create notification that your appointment is up in 40 mins
                                        func createLocalNotification(nextActualNumber: Int) {
                                        let localNotification = UILocalNotification()
                                        let seconds1 = 20*2*60 // int value
                                        let seconds2 = Double(seconds1)     // double value
                                        localNotification.fireDate = NSDate(timeIntervalSinceNow: seconds2)
                                        localNotification.soundName = UILocalNotificationDefaultSoundName
                                        localNotification.alertBody = "Your haircut appointment #\(number)is in half hour!"
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
                                        localNotificationNow.alertBody = "Your haircut appointment #\(number) is Now"
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

                        self.cancelAppointment.hidden = true
                        self.myNumberLabel.hidden = true
                        self.getNumberButton.hidden = false
                        
                        // MARK: Count for next new appointment and wait time
                        
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
                            
                            // set the max number as 'customerid' for count
                            let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                            let request = NSMutableURLRequest(URL: url2!)
                            let session = NSURLSession.sharedSession()
                            request.HTTPMethod = "POST"
                            
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
                                    self.waitTime.text = "\(h) hrs: \(m)mins"
                                    
                                } catch {
                                    print("Error -> \(error)")
                                }
                            } // end of task
                            task.resume()
                        } // end of jsonParse()
                    }
                } // end of for statement
            } else {                        // end of if results.count > 0 statement
                
                self.getNumberButton.hidden = false

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
                        nextNumber.text = readableData["next"].stringValue
                    }
                    let next_Number:String = nextNumber.text!                             // will be used to get the wait time via count
                    let current_Number = Int(currentNumber.text!)
                    
                    
                    // set the max number as 'customerid' for count
                    let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                    let request = NSMutableURLRequest(URL: url2!)
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "POST"
                    // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    // var params = ["customerid":"\(number)"] as Dictionary<String, String>
                    // print ("\(params)")
                    
                    let customerid = "customerid=\(next_Number)"
                    print(customerid)
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
                            print("Result -> \(responseJSON)")
                            let count = responseJSON["retVal"] as! Int                 // retVal
                            let waitTime_seconds = count * 20 * 60
                            print ("\(waitTime_seconds)")
                            let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                            print (h, m)
                            self.waitTime.text = "\(h)hrs: \(m)min"

                        } catch {
                            print("Error -> \(error)")
                        }
                    } // end of task
                    task.resume()
                } // end of jsonParse()
                jsonParse()
            }// end of results count IF statement
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
            // print ("Result -> \(responseJSON)")
                let gotNumber = responseJSON["getId"] as! Int
                let messageReturned:String = responseJSON["message"] as! String
                
                if (gotNumber == -2) {
                    dispatch_async(dispatch_get_main_queue(),
                                   {
                                    let alertController = UIAlertController(title: "Error", message: "There was an error communicating with the server", preferredStyle: .Alert  )
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                                    }
                                    alertController.addAction(cancelAction)
                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                    }
                                    alertController.addAction(OKAction)
                                    self.presentViewController(alertController, animated: true, completion: nil)
                    }) // end of dispatch
                } else if (gotNumber == -9) {
                    dispatch_async(dispatch_get_main_queue(),
                                   {
                                    let alertController = UIAlertController(title: "Store Closed", message: "Store is closed.", preferredStyle: .Alert  )
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                                    }
                                    alertController.addAction(cancelAction)
                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                    }
                                    alertController.addAction(OKAction)
                                    self.presentViewController(alertController, animated: true, completion: nil)
                    }) // end of dispatch

                }
                
                // Wait time does not need to be updated here. it can be updated in the is_there_an_appointment_today() function
                
                if (messageReturned == "new"){
                    
                  // create a pop alerting number
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumber) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                    // change got number int to string
                    let gotNumberString = String(gotNumber)
                    
                    // insert date and number into entity
                    let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context)
                    addAppointment.setValue(string_date, forKey: "date")
                    print (string_date)
                    addAppointment.setValue(gotNumberString, forKey: "number")
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
        self.getNumberButton.hidden = true

    } // end of get number function
    
    
    
    @IBAction func cancelAppointment(sender: AnyObject) {
        // fetch today's appointment
        
        print ("todays_string_date")

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
                    let date_string = items.valueForKey("date") as! String
                    let number_string = items.valueForKey("number") as! String
                    print (items.valueForKey("date"), items.valueForKey("number"))
                    if date_string == todays_string_date {
                        // send cancel request
                        let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                        let request = NSMutableURLRequest(URL: url2!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        // first convert value for key into int without "optional" and than into a string
                        let deleteidInt:Int = items.valueForKey("number") as! Int
                        print (deleteidInt)
                        let deleteid:String = String(deleteidInt)
                        print (deleteid)
                        request.HTTPBody = deleteid.dataUsingEncoding(NSUTF8StringEncoding)
                        session
                        let task = session.dataTaskWithRequest(request) {data, response, error  in
                            if error != nil{
                                print("ERROR retrieving server confirmation")
                                return
                            }
                            if let httpResponse = response as? NSHTTPURLResponse {
                                print("responseCode \(httpResponse.statusCode)")
                            }
                            do {
                                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                                print("Result -> \(responseJSON)")
                                let confirmation = responseJSON["retVal"] as! String
                                print (confirmation)
                                if confirmation == "T" {
                                    // send pop up, appointment cancelled
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            let alertController = UIAlertController(title: "Appointment Cancelled", message: "Your Appointment has been cancelled.", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                // ...
                                            }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                                    })
                                } else if confirmation == "F" {
                                    
                                    // send pop up, appointment cancelled
                                    dispatch_async(dispatch_get_main_queue(),
                                                   {
                                                    let alertController = UIAlertController(title: "Appointment Cancelled", message: "Your Appointment was not cancelled.", preferredStyle: .Alert  )
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
                        
                        context.deleteObject(items)
                        do {
                            try context.save()
                        } catch {
                            print ("ERROR -> \(error)")
                        }
                        if items.deleted {
                            print ("Delete successful")
                        } else {
                            print ("Delete unsuccessful")
                        }
                        
                    } else {                                    // end of if date == todays_string_date statement
                        // send pop up, you do not have an appointment to be cancelled
                        dispatch_async(dispatch_get_main_queue(),
                            {
                                let alertController = UIAlertController(title: "Appointment Cancellation", message: "You do not have an appointment today to be cancelled.", preferredStyle: .Alert  )
                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                    // ...
                                }
                                alertController.addAction(OKAction)
                                self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    } // end of else
} // end of For items in result
            } else {   // end of if results.count >0
                dispatch_async(dispatch_get_main_queue(),
                               {
                                let alertController = UIAlertController(title: "Appointment Cancellation", message: "All appointments deleted.", preferredStyle: .Alert  )
                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                    // ...
                                }
                                alertController.addAction(OKAction)
                                self.presentViewController(alertController, animated: true, completion: nil)
                })
                
            }
            is_there_an_appointment_for_today()
            self.myNumberLabel.hidden = true
        } catch {
            print ("Cancellation failed.")
        }// end of do
    } // end of function











    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.getNumberButton.hidden = true
        self.myNumberLabel.hidden = true
        self.cancelAppointment.hidden = false
        
        is_there_an_appointment_for_today() // check if theres any appointment
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "is_there_an_appointment_for_today", userInfo: nil, repeats: true)
        parseNumbers()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "parseNumbers", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
} // end of view controller