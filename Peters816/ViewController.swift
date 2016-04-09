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
    @IBOutlet weak var Stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    
    
    @IBAction func Stepper(sender: UIStepper) {
        
        stepperLabel.text = String(Int(Stepper.value))
        
    }
  
    
    
    
    // MARK: seconds to hours, minutes, seconds
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // notification statuses
    var firstNotificationStatus:Bool = false
    var NowNotificationStatus:Bool = false
    var youAreNextNotification:Bool = false
    
    // MARK: 40 min notification setting
    func notificationSetting (input:String) -> Void{
        
        if (input == "setON") {
            self.firstNotificationStatus = true
            // print("\(firstNotificationStatus)")
            
        } else if (input == "setOFF") {
            self.firstNotificationStatus = false
            
        }
        }
    
    // MARK: Now notification setting
    func NowNotificationSetting (input:String) -> Void{
        
        if (input == "setON") {
            self.NowNotificationStatus = true
            
        } else if (input == "setOFF") {
            self.NowNotificationStatus = false
            
        }
        
    }
    
    // MARK: you are next notification
    func youAreNextNotification (input:String) -> Void{
        
        
        if (input == "setON") {
            self.NowNotificationStatus = true
        } else if (input == "setOFF") {
            self.NowNotificationStatus = false
        }
        }
    
    
    
    // Mark: function to set the two numbers - current and next
    
    func parseNumbers() {
        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        print(readableData)
        currentNumber.text = readableData["current"].stringValue
        nextNumber.text = readableData["next"].stringValue
        }
    
    func parseJSON() {
        
        let url1 = NSURL(string: "http://peterscuts.com/lib/app_request.php")
        //let jsonData = NSData(contentsOfURL: url1!) as NSData!
        //let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        let request1 = NSMutableURLRequest(URL: url1!)
        let session1 = NSURLSession.sharedSession()
        var err: NSError?
        // print ("test2")
        let task1 = session1.dataTaskWithRequest(request1){ data,response,error in
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
                let current_Number:Int = responseJSON["current"] as! Int
                let next_Number:Int = responseJSON["next"] as! Int
                // print (current_Number, next_Number)
                if ( current_Number == -2){
                    self.currentNumber.text = "error"
                } else {
                    self.currentNumber.text = String(current_Number)
                }
                if ( next_Number == -2){
                    self.nextNumber.text = "error"
                } else {
                    self.nextNumber.text = String(next_Number)
                }
                // print ("\(self.currentNumber.text), \(self.nextNumber.text) ")
                // get the wait time using next_Number
                let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                let request2 = NSMutableURLRequest(URL: url2!)
                let session2 = NSURLSession.sharedSession()
                request2.HTTPMethod = "POST"
                // get the next_Number again , but from nextNumber.text ...
                let nextNumberInt: Int = Int(self.nextNumber.text!)!
                let customerid:String = "customerid=\(nextNumberInt)"             // REPLACE WITH next_Number after debug
                // print (customerid)
                request2.HTTPBody = customerid.dataUsingEncoding(NSUTF8StringEncoding)
                let task2 = session2.dataTaskWithRequest(request2) {data, response, error  in
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
                        // print (count)
                        let waitTime_seconds = count * 20 * 60
                        let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                        self.waitTime.text = "\(h) hrs: \(m)mins"
                        
                    } catch {
                        print("Error -> \(error)")
                    }
                } // end of task2
                task2.resume()

            } catch {
                print ("Error connecting to the server")
            }
        }// end of task1
        task1.resume()
        
        
        self.getNumberButton.hidden = false

    } // end of parseJSON()
    
    // MARK: determine whether has an appointment for today , if not jsonParse()
    func checkAppointmentForToday() {
        
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
                    let status = items.valueForKey("status") as! String
                    var numberInt: [Int] = []
                    if date == todays_string_date {                         // select All today's appointments
                        if status == "EMPTY" {                              // select those that are waiting to be finished
                            numberInt.append(Int(number)!)
                        } // end of if status == "EMPTY" 
                        if numberInt.count > 0 {
                            var minNumber: Int = numberInt[0]
                            for intNumber in numberInt{
                                if minNumber > intNumber{
                                    minNumber = intNumber
                                }// end of if minNumber > intNumber
                                if Int(number) == minNumber{
                                    // replace get number button(hide) with "Your appointment # ("number") today is " UILabel - make one
                                    // replace staticApproxWait label with "Your approx wait time" label - make one?
                                    // replace waitTime [until now with last number to php page] with ("number") to php page
                                    self.getNumberButton.hidden = true
                                    self.myNumberLabel.hidden = false
                                    self.cancelAppointment.hidden = false
                                    self.Stepper.hidden = true
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
                                            let count: Int = responseJSON["retVal"] as! Int                  // retVal
                                            // print (count)
                                            let waitTime_seconds = count * 20 * 60
                                            let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                                            self.waitTime.text = "\(h) hrs : \(m) min"
                                            
                                            // MARK: Notifications
                                            if (count == 2) {
                                                if (self.firstNotificationStatus == true) {
                                                    // do nothing. notification already set
                                                } else {
                                                    // create notification that your appointment is up in 40 mins
                                                    func createLocalNotification(nextActualNumber: Int) {
                                                        let localNotification = UILocalNotification()
                                                        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
                                                        localNotification.soundName = UILocalNotificationDefaultSoundName
                                                        localNotification.alertBody = "Your haircut appointment #\(number)is in half hour!"
                                                        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                                                        self.notificationSetting("setON")
                                                    } // end of createLocalNotif
                                                } // end of else
                                            } else if (count == 1) {
                                                if (self.youAreNextNotification == true) {
                                                    // do nothing. notification has already been set
                                                } else {
                                                    // create notification
                                                    func createLocalNotification(nextActualNumber: Int) {
                                                        let localNotification = UILocalNotification()
                                                        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
                                                        localNotification.soundName = UILocalNotificationDefaultSoundName
                                                        localNotification.alertBody = "Your haircut appointment #\(number)is in half hour!"
                                                        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                                                        self.youAreNextNotification("setON")
                                                    } // end of notif func
                                                } // end of else

                                            } else if (count == 0) {
                                                if (self.NowNotificationStatus == true) {
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
                                                } // of else notification
                                            } else if (count == -1) {
                                                //convert status to "FINISHED"
                                                let changeStatusOfAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context)
                                                changeStatusOfAppointment.setValue("FINISHED", forKey: "status")
                                                // as the function is repeated and each number is checked for the minimumest number....and reaches count -1, each of them's status will be changed here
                                                // also turn all notifications to off again
                                                //turn off all notifications
                                                self.notificationSetting("setOFF")
                                                self.NowNotificationSetting("setOFF")
                                                self.youAreNextNotification("setOFF")
                                                // clear the numberInt array, since it will recreate it next time it runs
                                                numberInt.removeAll()

                                            }
                                        } catch {
                                            print ("error in getting count")
                                        }
                                    } // end of task
                                    task.resume()
                                  
                                    
                                    
                                } // end of if Int(number) == minNumber
                            
                            } // end of for intNumber in numberInt
                        } else {// end of if numberInt.count > 0
                        parseJSON()
                        }
                    } else {// end of date == todays_string_date
                    parseJSON()
                    }
                } // end of for items in results as! [NSManagedObject]
            } else{// end of if results.count > 0
                parseJSON()
            }
            
        } catch {
                    print ("error fetching core data")
                }
        
        
    }  //  end of func checkTodayAppointment()
    
    
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
                // First get the stepper value from label, default 1
                let stepperCount = Int(stepperLabel.text!)
                if (stepperCount == 1){
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    
                    let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                    let request = NSMutableURLRequest(URL: url!)
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "POST"
                    // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
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
                                                let alertController = UIAlertController(title: "Store Closed", message: "Store is closed. Please call (519)816-2887", preferredStyle: .Alert  )
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
                                addAppointment.setValue("EMPTY", forKey: "status")
                                do{
                                    try context.save()
                                }catch {
                                    print ("error saving data")
                                }
                                self.checkAppointmentForToday()
                                
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
                    } // end of task
                    task.resume()
                    

                    
                } else if (stepperCount == 2) {
                    
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userNames: [String] = [userName1,userName2]
                    for userName in userNames{
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
                        request.HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
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
                                                    let alertController = UIAlertController(title: "Store Closed", message: "Store is closed. Please call (519)816-2887", preferredStyle: .Alert  )
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
                                    addAppointment.setValue("EMPTY", forKey: "status")
                                    do{
                                        try context.save()
                                    }catch {
                                        print ("error saving data")
                                    }
                                    self.checkAppointmentForToday()
                                    
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
                        } // end of task
                        task.resume()
                        

                    } // for userName in userNames
                    
                } else if (stepperCount == 3) {
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userName3 = "\(userName)3"
                    let userNames: [String] = [userName1,userName2,userName3]
                    for userName in userNames{
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
                        request.HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
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
                                                    let alertController = UIAlertController(title: "Store Closed", message: "Store is closed. Please call (519)816-2887", preferredStyle: .Alert  )
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
                                    addAppointment.setValue("EMPTY", forKey: "status")
                                    do{
                                        try context.save()
                                    }catch {
                                        print ("error saving data")
                                    }
                                    self.checkAppointmentForToday()
                                    
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
                        } // end of task
                        task.resume()
                        
                        
                    } // for userName in userNames
                    
                } else if (stepperCount == 4) {
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userName3 = "\(userName)3"
                    let userName4 = "\(userName)4"
                    let userNames: [String] = [userName1,userName2,userName3,userName4]
                    for userName in userNames{
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
                        request.HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
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
                                                    let alertController = UIAlertController(title: "Store Closed", message: "Store is closed. Please call (519)816-2887", preferredStyle: .Alert  )
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
                                    addAppointment.setValue("EMPTY", forKey: "status")
                                    do{
                                        try context.save()
                                    }catch {
                                        print ("error saving data")
                                    }
                                    self.checkAppointmentForToday()
                                    
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
                        } // end of task
                        task.resume()
                        
                        
                    } // for userName in userNames
                }
        } // end of get number function
    

    } // end of getNumber function
    
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
                                    // convert status of appointment to "CANCELLED"
                                    let cancelAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context)
                                    cancelAppointment.setValue("CANCELLED", forKey: "status")
                                    do {
                                        try context.save()
                                    } catch {
                                        print ("ERROR -> \(error)")
                                    }
                                    
                                    // ADD here turning the status of the appointment to "CANCELLED"
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
        //    self.checkAppointmentForToday()
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
        self.cancelAppointment.hidden = true
        
        //checkAppointmentForToday() // check if theres any appointment
        //NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "checkAppointmentForToday", userInfo: nil, repeats: true)
        parseJSON()
        // parseNumbers()
        // NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "parseNumbers", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }







}// end of view controller