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
    @IBOutlet weak var Stepper: UIStepper!
    @IBOutlet weak var stepperLabel: UILabel!
    
    
    @IBAction func Stepper(sender: UIStepper) {
        
        stepperLabel.text = String(Int(Stepper.value))
        
    }
  
    
    
    

    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
   
    // notification statuses
    var firstNotificationStatus:Bool = false
    var nextNotificationStatus:Bool = false
    var nowNotificationStatus:Bool = false
    
    
 
    func fortyMinutesNotification (input:String) -> Void{
        
        if (input == "setON") {
            self.firstNotificationStatus = true
            // print("\(firstNotificationStatus)")
        } else if (input == "setOFF") {
            self.firstNotificationStatus = false
        }
        }
    func youAreNextNotification (input:String) -> Void{
        
        
        if (input == "setON") {
            self.nextNotificationStatus = true
        } else if (input == "setOFF") {
            self.nextNotificationStatus = false
        }
    }
 
    func NowNotification (input:String) -> Void{
        
        if (input == "setON") {
            self.nowNotificationStatus = true
        } else if (input == "setOFF") {
            self.nowNotificationStatus = false
        }
    }
    
 

    
 
    func createLocalNotification(number: String, time: String) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.alertBody = "Your haircut appointment # \(number) is \(time)!"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
  
    func parseNumbers() {
        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
        let jsonData = NSData(contentsOfURL: url!) as NSData!
        let readableData = JSON(data: jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        // print(readableData)
        currentNumber.text = readableData["current"].stringValue
        nextNumber.text = readableData["next"].stringValue
        }
    
    func parseJSON() {
        
        print ("parseJSON() begin")
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
                print("Result -> \(responseJSON)")
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
                let etaMinutes:Int = responseJSON ["eta"] as! Int
                print (etaMinutes)
                let etaSeconds:Int = etaMinutes * 60
                let (h,m,s) = self.secondsToHoursMinutesSeconds(etaSeconds)
                self.waitTime.text = "\(h)hrs:\(m)mins"
                self.staticApproxWait.text = "Approximate wait time for next appointment is"

            } catch {
                print ("Error connecting to the server")
            }
        }// end of task1
        task1.resume()
        self.getNumberButton.hidden = false
        self.stepperLabel.hidden = false
        self.Stepper.hidden = false

        print ("parseJSON() end")

    } // end of parseJSON()
    
    
    func checkAppointmentForToday() {
        
        // print ("checkAppointmentForToday() begin")
        self.getNumberButton.hidden = true
        self.Stepper.hidden = true
        self.stepperLabel.hidden = true
        
        // try to retrieve appointment in core data with today's NSDate
        let appdel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appdel.managedObjectContext
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        let todays_date = NSDate()
        let todays_string_date:String = dateFormatter.stringFromDate(todays_date)
        print (todays_string_date)
        do {
            let request = NSFetchRequest (entityName: "Appointments")
            let predicate1 = NSPredicate (format: "date = %@", todays_string_date)
            let predicate2 = NSPredicate (format: "status = %@", "EMPTY")
            let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate1, predicate2])
            request.predicate = compound
            let results:NSArray = try context.executeFetchRequest(request)
            // print (results)
            if results.count > 0 {
                var intNumberArray:[Int] = []
                print ( results.count )
            // get the number for each object in the results array, add to intNumberArray
                for res in results{
                    let numberString: String = res.valueForKey("number") as! String
                    let numberInt: Int = Int(numberString)!
                    intNumberArray.append(numberInt)
                }
                print ("intNumberArray is : \(intNumberArray)")
                // find the minimum number in intNumberArray
                var minNumber:Int = intNumberArray[0]
                if intNumberArray.count > 0 {
                    minNumber = intNumberArray[0]
                    for number in intNumberArray{
                        if minNumber >= number{
                            minNumber = number
                        }
                    }
                } // end of intNumberArray.count > 0
                
                /////////////////////// now that you got the minimum number in list of appointments use that to get the wait time
                let minNumberString:String = String(minNumber)
                print ("Minimum number is :\(minNumber)")
                self.getNumberButton.hidden = true
                self.myNumberLabel.hidden = false
                self.cancelAppointment.hidden = false
                self.Stepper.hidden = true
                self.staticApproxWait.text = "Your approximate wait time is"
                self.myNumberLabel.text = "Your appointment # is \(minNumberString) "
                // COUNT for today's appointment and wait time
                let url = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                let request = NSMutableURLRequest(URL: url!)
                let session = NSURLSession.sharedSession()
                var err: NSError?
                request.HTTPMethod = "POST"
                let postParams =  "user_name=Spandan&customerid=\(minNumberString)"
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
                        print (count)
                        let waitTime_seconds = count * 20 * 60
                        let (h,m,s) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                        self.waitTime.text = "\(h) hrs : \(m) min"
                        print ("\(self.waitTime.text)")
                        //  Notifications
                        if (count == 2) {
                            if (self.firstNotificationStatus == true) {
                                // do nothing. notification already set
                            } else {
                                
                                self.createLocalNotification(minNumberString, time: "in 40 mins")
                                self.fortyMinutesNotification("setON")
                                
                            } // end of else
                        } else if (count == 1) {
                            if (self.nextNotificationStatus == true) {
                                // do nothing. notification has already been set
                                // print ("aaaaaaaaaaaaaaaaaaaaaaa")
                            } else {
                                self.createLocalNotification(minNumberString, time: "next")
                                self.youAreNextNotification("setON")
                                // print ("bbbbbbbbbbbbbbbbbbbbbbb")

                            } // end of else
                            
                        } else if (count == 0) {
                            
                            print ("Count = 0 is reached ... ")
                            if (self.nowNotificationStatus == true) {
                                // do nothing. notification already set.
                                self.waitTime.text = "Your appointment is Now"
                                // print ("count 0 Text: \(self.waitTime.text)")
                                
                            } else {
                                self.createLocalNotification(minNumberString, time: "Now")
                                self.NowNotification("setON")
                                dispatch_async(dispatch_get_main_queue(),
                                               {
                                                let alertController = UIAlertController(title: "Rush to your appointment!", message: "Your Appointment is Now", preferredStyle: .Alert  )
                                                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                                                }
                                                alertController.addAction(cancelAction)
                                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                }
                                                alertController.addAction(OKAction)
                                                self.presentViewController(alertController, animated: true, completion: nil)
                                }) // end of dispatch

                            } // of else notification
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count != 0 {
                                        let managedObject = result[0]
                                        managedObject.setValue("FINISHED", forKey: "status")
                                        do{
                                            try context.save()
                                        }catch{
                                            print ("Error saving change status")
                                        }
                                    } // end of result.count != 0
                                } // end of result =  executeFetchReuest
                                
                                
                            } catch {
                                print ("error")
                            }

                        } else if (count == -2) {
                            // when appointment doesn't exist on server b/c peter cancelled it , change status to "cancelled"
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count != 0 {
                                        let managedObject = result[0]
                                        managedObject.setValue("CANCELLED", forKey: "status")
                                        do{
                                            try context.save()
                                        }catch{
                                            print ("Error saving change status")
                                        }
                                    } // end of result.count != 0
                                } // end of result =  executeFetchReuest
                            } catch {
                                print ("error")
                            }
                            //////////////////////////////////// let customer get a new appointment:
                            dispatch_async(dispatch_get_main_queue(),
                                           {
                                            let alertController = UIAlertController(title: "Appointment # \(minNumberString)", message: "Did you miss appointment #\(minNumberString)? Would like to get a new one?", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "Yes", style: .Default) { (action) in
                                          
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
                                                            print ("Result -> \(responseJSON)")
                                                            let gotNumberInt: Int = responseJSON["getId"] as! Int
                                                            print (gotNumberInt)
                                                            // let gotNumberString: String = responseJSON["getId"] as! String
                                                            // responseJSON["getId"] as! String
                                                            //print (gotNumberString)
                                                            let gotNumberString: String = String(gotNumberInt)
                                                            print (gotNumberString)
                                                            let messageReturned: String = responseJSON["message"] as! String
                                                            print (gotNumberString, messageReturned)
                                                            //MARK: trying to get a new number if missing / deleted appointment
                                                            if (gotNumberString == "-2") {
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
                                                            } else if (gotNumberString == "-9") {
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
                                                            
                                                            if (gotNumberString != "-2" && gotNumberString != "-9"){
                                                                if (messageReturned == "new"){
                                                                    
                                                                    // create a pop alerting number
                                                                    dispatch_async(dispatch_get_main_queue(), {
                                                                        let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                                                    // let gotNumberString = String(gotNumber)
                                                                    
                                                                    // insert date and number into entity
                                                                    let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context) as NSManagedObject
                                                                    addAppointment.setValue(string_date, forKey: "date")
                                                                    //   print (string_date)
                                                                    addAppointment.setValue(gotNumberString, forKey: "number")
                                                                    addAppointment.setValue("EMPTY", forKey: "status")
                                                                    do{
                                                                        try context.save()
                                                                    }catch {
                                                                        print ("error saving data")
                                                                    }
                                                                    print ("User added: \(addAppointment)")
                                                                    
                                                                } else if (messageReturned == "duplicate") {
                                                                    dispatch_async(dispatch_get_main_queue(),
                                                                        {
                                                                            let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                                                // ...
                                                                            }
                                                                            alertController.addAction(OKAction)
                                                                            self.presentViewController(alertController, animated: true, completion: nil)
                                                                    })
                                                                } // end of else if "duplicate"
                                                            } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){
                                                            
                                                            
                                                        } catch {
                                                            print ("Error: problem getting number")
                                                        }

                                                        
                                                        
                                                        
                                                        
                                                        
                                                    } // end of task
                                                    task.resume()
                                                    
                                                    
                                                } // end of else to username/number present
                                                
                                            
                                            } // end of OKAction
                                            
                                            let CancelAction = UIAlertAction(title: "No", style: .Default) { (action) in
                                                // than mark it finished
                                                do {
                                                    let request = NSFetchRequest (entityName: "Appointments")
                                                    request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                                    if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                                        if result.count != 0 {
                                                            let managedObject = result[0]
                                                            managedObject.setValue("FINISHED", forKey: "status")
                                                            do{
                                                                try context.save()
                                                            }catch{
                                                                print ("Error saving change status")
                                                            }
                                                        } // end of result.count != 0
                                                    } // end of result =  executeFetchReuest
                                                } catch {
                                                    print ("error")
                                                }
                                                
                                            }
                                            alertController.addAction(OKAction)
                                            alertController.addAction(CancelAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            })

                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            /////////////// end of else if (count == -2)
                        } else if (count == -1) {
                            // their turn passed , never went thru 0 = never labelled finished... show prompt to cancel, get a new one
                            
                            // check if status is "finished" via peter = "T" -> count = 0 condition
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count != 0 {
                                        let managedObject = result[0]
                                        let checkStatus: String = managedObject.valueForKey("status") as! String
                                        if checkStatus != "FINISHED" {
                                            dispatch_async(dispatch_get_main_queue(),
                                                           {
                                                            let alertController = UIAlertController(title: "Appointment # \(minNumberString)", message: "Did you miss appointment #\(minNumberString)? Would like to get a new one?", preferredStyle: .Alert  )
                                                            let OKAction = UIAlertAction(title: "Yes", style: .Default) { (action) in
                                                                let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                                                                let request = NSMutableURLRequest(URL: url2!)
                                                                let session = NSURLSession.sharedSession()
                                                                request.HTTPMethod = "POST"
                                                                let deleteid: String = "deleteid=\(minNumberString)"
                                                                request.HTTPBody = deleteid.dataUsingEncoding(NSUTF8StringEncoding)
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
                                                                            print (confirmation)
                                                                            
                                                                            // convert status of appointment to "CANCELLED"
                                                                            let cancelAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context)
                                                                            cancelAppointment.setValue("CANCELLED", forKey: "status")
                                                                            do {
                                                                                try context.save()
                                                                            } catch {
                                                                                print ("ERROR -> \(error)")
                                                                            }

                                                                            // and get a NEW appointment !
                                                                            /////////////////////////////////
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
                                                                                    print ("Result -> \(responseJSON)")
                                                                                    let gotNumberInt: Int = responseJSON["getId"] as! Int
                                                                                    print (gotNumberInt)
                                                                                    // let gotNumberString: String = responseJSON["getId"] as! String                              
                                                                                    // responseJSON["getId"] as! String
                                                                                    //print (gotNumberString)
                                                                                    let gotNumberString: String = String(gotNumberInt)
                                                                                    print (gotNumberString)
                                                                                    let messageReturned: String = responseJSON["message"] as! String
                                                                                    print (gotNumberString, messageReturned)
                                                                                    
                                                                                    if (gotNumberString == "-2") {
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
                                                                                    } else if (gotNumberString == "-9") {
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
                                                                                    
                                                                                    if (gotNumberString != "-2" && gotNumberString != "-9"){
                                                                                        if (messageReturned == "new"){
                                                                                            
                                                                                            // create a pop alerting number
                                                                                            dispatch_async(dispatch_get_main_queue(), {
                                                                                                let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                                                                            // let gotNumberString = String(gotNumber)
                                                                                            
                                                                                            // insert date and number into entity
                                                                                            let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context) as NSManagedObject
                                                                                            addAppointment.setValue(string_date, forKey: "date")
                                                                                            //   print (string_date)
                                                                                            addAppointment.setValue(gotNumberString, forKey: "number")
                                                                                            addAppointment.setValue("EMPTY", forKey: "status")
                                                                                            do{
                                                                                                try context.save()
                                                                                            }catch {
                                                                                                print ("error saving data")
                                                                                            }
                                                                                            print ("User added: \(addAppointment)")
                                                                                            
                                                                                        } else if (messageReturned == "duplicate") {
                                                                                            dispatch_async(dispatch_get_main_queue(),
                                                                                                {
                                                                                                    let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                                                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                                                                        // ...
                                                                                                    }
                                                                                                    alertController.addAction(OKAction)
                                                                                                    self.presentViewController(alertController, animated: true, completion: nil)
                                                                                            })
                                                                                        } // end of else if "duplicate"
                                                                                    } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){
                                                                                    
                                                                                } catch {
                                                                                    print("Error -> \(error)")
                                                                                }
                                                                            } // end of task
                                                                            task.resume()

                                                                            
                                                                            
                                                                            } // end of else for having name and number
                                                                            /////////////////////////////////
                                                                        } else if confirmation == "F" {
                                                                            
                                                                            // send pop up, appointment cancelled
                                                                            dispatch_async(dispatch_get_main_queue(),
                                                                                {
                                                                                    let alertController = UIAlertController(title: "Appointment Cancellation", message: "Error cancelling appointment.", preferredStyle: .Alert  )
                                                                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                                                        // ...
                                                                                    }
                                                                                    alertController.addAction(OKAction)
                                                                                    self.presentViewController(alertController, animated: true, completion: nil)
                                                                            })
                                                                        }
                                                                    } catch {
                                                                        print ("Error: could not cancel the appointment")
                                                                        
                                                                    }
                                                                    
                                                                    
                                                                    
                                                                    
                                                                } // end of task
                                                                task.resume()
                                                         
                                            } // end of OKAction
                                            
                                            let CancelAction = UIAlertAction(title: "No", style: .Default) { (action) in
                                                // than mark it finished
                                                do {
                                                    let request = NSFetchRequest (entityName: "Appointments")
                                                    request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                                    if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                                        if result.count != 0 {
                                                            let managedObject = result[0]
                                                            managedObject.setValue("FINISHED", forKey: "status")
                                                            do{
                                                                try context.save()
                                                            }catch{
                                                                print ("Error saving change status")
                                                            }
                                                        } // end of result.count != 0
                                                    } // end of result =  executeFetchReuest
                                                } catch {
                                                    print ("error")
                                                }
                                                
                                            }
                                            alertController.addAction(OKAction)
                                            alertController.addAction(CancelAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                                        })

                                        } // end of if checkStatus != "FINISHED"
                                    } // end of result.count != 0
                                } // end of result =  executeFetchReuest
                            } catch {
                                print ("error")
                            }
                        } // end of else if count = -1
                } catch {
                        print ("erro")
                    }
                } // end of task
                task.resume()
                
            /////////////////////////
            } else {
                parseJSON()
                myNumberLabel.hidden = true
            }// end of if results.count > 0
            
            
        } catch {     // for catching errors from -- let results:NSArray = try context.executeFetchRequest(request)
            print ("error in getting count")
        }
        
        print ("checkAppointmentForToday() end")
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
                
                //MARK: stepper 1
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
                            print ("Result -> \(responseJSON)")
                            let gotNumberInt: Int = responseJSON["getId"] as! Int
                            print (gotNumberInt)
                           // let gotNumberString: String = responseJSON["getId"] as! String                              // responseJSON["getId"] as! String
                            //print (gotNumberString)
                            let gotNumberString: String = String(gotNumberInt)
                            print (gotNumberString)
                            let messageReturned: String = responseJSON["message"] as! String
                            print (gotNumberString, messageReturned)
                            
                            if (gotNumberString == "-2") {
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
                            } else if (gotNumberString == "-9") {
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
                            
                            if (gotNumberString != "-2" && gotNumberString != "-9"){
                            if (messageReturned == "new"){
                                
                                // create a pop alerting number
                                dispatch_async(dispatch_get_main_queue(), {
                                    let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                // let gotNumberString = String(gotNumber)
                                
                                // insert date and number into entity
                                let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context) as NSManagedObject
                                addAppointment.setValue(string_date, forKey: "date")
                                //   print (string_date)
                                addAppointment.setValue(gotNumberString, forKey: "number")
                                addAppointment.setValue("EMPTY", forKey: "status")
                                do{
                                    try context.save()
                                }catch {
                                    print ("error saving data")
                                }
                                print ("User added: \(addAppointment)")
                                
                            } else if (messageReturned == "duplicate") {
                                dispatch_async(dispatch_get_main_queue(),
                                               {
                                                let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                    // ...
                                                }
                                                alertController.addAction(OKAction)
                                                self.presentViewController(alertController, animated: true, completion: nil)
                                })
                            } // end of else if "duplicate"
                            } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){

                        } catch {
                            print("Error -> \(error)")
                        }
                    } // end of task
                    task.resume()
                    self.checkAppointmentForToday()


                    //MARK: stepper 2
                } else if (stepperCount == 2) {
                    
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userNames: [String] = [userName1,userName2]
                    for name in userNames{
                        print (name)
                        
                   
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(name)&user_phone=\(phone)&user_email=\(email)"
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
                                print ("Result -> \(responseJSON)")
                                let gotNumberInt: Int = responseJSON["getId"] as! Int
                                print (gotNumberInt)
                                // let gotNumberString: String = responseJSON["getId"] as! String                              // responseJSON["getId"] as! String
                                //print (gotNumberString)
                                let gotNumberString: String = String(gotNumberInt)
                                print (gotNumberString)
                                let messageReturned: String = responseJSON["message"] as! String
                                print (gotNumberString, messageReturned)
                                
                                if (gotNumberString == "-2") {
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
                                } else if (gotNumberString == "-9") {
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
                                
                                if (gotNumberString != "-2" && gotNumberString != "-9"){
                                    if (messageReturned == "new"){
                                        
                                        // create a pop alerting number
                                        dispatch_async(dispatch_get_main_queue(), {
                                            let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                        // let gotNumberString = String(gotNumber)
                                        
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
                                        
                                    } else if (messageReturned == "duplicate") {
                                        dispatch_async(dispatch_get_main_queue(),
                                                       {
                                                        let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                            // ...
                                                        }
                                                        alertController.addAction(OKAction)
                                                        self.presentViewController(alertController, animated: true, completion: nil)
                                        })
                                    } // end of else if "duplicate"
                                } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){
                                
                            } catch {
                                print("Error -> \(error)")
                            }
                        } // end of task
                        task.resume()
                        self.checkAppointmentForToday()
                        
                    } // for userName in userNames
 
                    //MARK: stepper 3
                } else if (stepperCount == 3) {
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userName3 = "\(userName)3"
                    let userNames: [String] = [userName1,userName2,userName3]
                    for name in userNames{
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(name)&user_phone=\(phone)&user_email=\(email)"
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
                                print ("Result -> \(responseJSON)")
                                let gotNumberInt: Int = responseJSON["getId"] as! Int
                                print (gotNumberInt)
                                // let gotNumberString: String = responseJSON["getId"] as! String                              // responseJSON["getId"] as! String
                                //print (gotNumberString)
                                let gotNumberString: String = String(gotNumberInt)
                                print (gotNumberString)
                                let messageReturned: String = responseJSON["message"] as! String
                                print (gotNumberString, messageReturned)
                                
                                if (gotNumberString == "-2") {
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
                                } else if (gotNumberString == "-9") {
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
                                
                                if (gotNumberString != "-2" && gotNumberString != "-9"){
                                    if (messageReturned == "new"){
                                        
                                        // create a pop alerting number
                                        dispatch_async(dispatch_get_main_queue(), {
                                            let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                        // let gotNumberString = String(gotNumber)
                                        
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
                                        
                                    } else if (messageReturned == "duplicate") {
                                        dispatch_async(dispatch_get_main_queue(),
                                                       {
                                                        let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                            // ...
                                                        }
                                                        alertController.addAction(OKAction)
                                                        self.presentViewController(alertController, animated: true, completion: nil)
                                        })
                                    } // end of else if "duplicate"
                                } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){
                                
                            } catch {
                                print("Error -> \(error)")
                            }
                        } // end of task
                        task.resume()
                        self.checkAppointmentForToday()
                        
                    } // for userName in userNames
                    
                    //MARK: stepper 4
                } else if (stepperCount == 4) {
                    let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
                    let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
                    let userName1 = "\(userName)1"
                    let userName2 = "\(userName)2"
                    let userName3 = "\(userName)3"
                    let userName4 = "\(userName)4"
                    let userNames: [String] = [userName1,userName2,userName3,userName4]
                    for name in userNames{
                        let url = NSURL(string: "http://peterscuts.com/lib/app_request.php")
                        let request = NSMutableURLRequest(URL: url!)
                        let session = NSURLSession.sharedSession()
                        request.HTTPMethod = "POST"
                        // request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        let postParams =  "user_name=\(name)&user_phone=\(phone)&user_email=\(email)"
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
                                print ("Result -> \(responseJSON)")
                                let gotNumberInt: Int = responseJSON["getId"] as! Int
                                print (gotNumberInt)
                                // let gotNumberString: String = responseJSON["getId"] as! String                              // responseJSON["getId"] as! String
                                //print (gotNumberString)
                                let gotNumberString: String = String(gotNumberInt)
                                print (gotNumberString)
                                let messageReturned: String = responseJSON["message"] as! String
                                print (gotNumberString, messageReturned)
                                

                                if (gotNumberString == "-2") {
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
                                } else if (gotNumberString == "-9") {
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
                                
                                if (gotNumberString != "-2" && gotNumberString != "-9"){
                                    if (messageReturned == "new"){
                                        
                                        // create a pop alerting number
                                        dispatch_async(dispatch_get_main_queue(), {
                                            let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the que. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
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
                                        // let gotNumberString = String(gotNumber)
                                        
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
                                        
                                    } else if (messageReturned == "duplicate") {
                                        dispatch_async(dispatch_get_main_queue(),
                                                       {
                                                        let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the que.", preferredStyle: .Alert  )
                                                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                            // ...
                                                        }
                                                        alertController.addAction(OKAction)
                                                        self.presentViewController(alertController, animated: true, completion: nil)
                                        })
                                    } // end of else if "duplicate"
                                } // end of if (gotNumberString != "-2" && gotNumberString != "-9"){
                                
                            } catch {
                                print("Error -> \(error)")
                            }
                        } // end of task
                        task.resume()
                        self.checkAppointmentForToday()

                    } // for userName in userNames
                } // end of else if (stepperCount == 4)
                
                self.checkAppointmentForToday()

        } // end of get number function
    
        self.checkAppointmentForToday()

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
        
        dispatch_async(dispatch_get_main_queue(),
                       {
                        let alertController = UIAlertController(title: "Cancel Appointment", message: "Your appointment(s) will be cancelled. Go ahead?", preferredStyle: .Alert  )
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            //////////////////////////////////////
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                let predicate1 = NSPredicate (format: "date = %@", todays_string_date)
                                let predicate2 = NSPredicate (format: "status = %@", "EMPTY")
                                let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate1, predicate2])
                                request.predicate = compound
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count > 0 {
                                        for item in result{
                                            
                                            let number:String = item.valueForKey("number") as! String
                                            print (number)
                                            let url2 = NSURL(string: "http://peterscuts.com/lib/request_handler.php")
                                            let request = NSMutableURLRequest(URL: url2!)
                                            let session = NSURLSession.sharedSession()
                                            request.HTTPMethod = "POST"
                                            let deleteIdNumberInt:Int = Int(number)! as Int // b/c the string version has "Optional (#)" in it
                                            print (deleteIdNumberInt)
                                            let deleteIdNumberString:String = String(deleteIdNumberInt)
                                            print (deleteIdNumberString)
                                            let deleteid: String = "deleteid=\(deleteIdNumberString)"
                                            request.HTTPBody = deleteid.dataUsingEncoding(NSUTF8StringEncoding)
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
                                                        print (confirmation)
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
                                                        self.checkAppointmentForToday()
  
                                                    } else if confirmation == "F" {
                                                        
                                                        // send pop up, appointment cancelled
                                                        dispatch_async(dispatch_get_main_queue(),
                                                            {
                                                                let alertController = UIAlertController(title: "Appointment Cancellation", message: "Error cancelling appointment.", preferredStyle: .Alert  )
                                                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                                                                    // ...
                                                                }
                                                                alertController.addAction(OKAction)
                                                                self.presentViewController(alertController, animated: true, completion: nil)
                                                        })
                                                    }
                                                    
                                                    
                                                    
                                                    
                                                } catch {
                                                    print ("error: let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: [])")
                                                }
                                            } // end of task
                                            task.resume()
                                            
                                            
                                            
                                        } // end of for item in result
                                        
                                    } // end of if result.count > 0
                                } // end of result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                            } catch{
                                
                                print ("error fetching from core data")
                            }
                            
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                let predicate1 = NSPredicate (format: "date = %@", todays_string_date)
                                let predicate2 = NSPredicate (format: "status = %@", "EMPTY")
                                let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate1, predicate2])
                                request.predicate = compound
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count > 0 {
                                        for items in result {
                                            items.setValue("CANCELLED", forKey: "status")
                                        }
                                        do{
                                            try context.save()
                                        }catch{
                                            print ("Error saving change status")
                                        }
                                    } // end of result.count != 0
                                } // end of result =  executeFetchReuest
                                
                            } catch {
                                
                                print ("error fetching and cancelling from core data")
                            }

                            
                            /////////////////////////////////
                        } // end of OKAction
                        
                        let CancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
                        // do nothing.
                        }
                        alertController.addAction(OKAction)
                        alertController.addAction(CancelAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
        })

        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false
        self.myNumberLabel.hidden=true
        self.checkAppointmentForToday()
        
    } // end of cancel function




    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.getNumberButton.hidden = true
        self.myNumberLabel.hidden = true
        self.cancelAppointment.hidden = true
        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false
        
        checkAppointmentForToday() // check if theres any appointment
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "checkAppointmentForToday", userInfo: nil, repeats: true)
        parseNumbers()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "parseNumbers", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }







}// end of view controller