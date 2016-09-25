//
//  ViewController.swift
//  Peters816
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
    
    var APP_REQUEST_GET:NSMutableURLRequest!
    var APP_REQUEST_GET_SESSION:NSURLSession!
    var APP_REQUEST_POST:NSMutableURLRequest!
    var APP_REQUEST_POST_SESSION:NSURLSession!
    var CUST_ETA_REQUEST:NSMutableURLRequest!
    var CUST_ETA_SESSION:NSURLSession!
    var APP_REQUEST_URL:NSURL = NSURL(string: "http://peterscuts.com/lib/app_request.php")!
    
    func getRequest() -> NSMutableURLRequest {
        if(APP_REQUEST_GET == nil) {
            APP_REQUEST_GET = NSMutableURLRequest(URL: APP_REQUEST_URL);
        }
        return APP_REQUEST_GET
    }
    func getSession() -> NSURLSession {
        if(APP_REQUEST_GET_SESSION == nil) {
            APP_REQUEST_GET_SESSION = NSURLSession.sharedSession()
        }
        return APP_REQUEST_GET_SESSION
    }
    func getAppRequestPostRequest() -> NSMutableURLRequest {
            if(APP_REQUEST_POST == nil) {
                APP_REQUEST_POST = NSMutableURLRequest(URL: NSURL(string: "http://peterscuts.com/lib/app_request.php")!)
                    APP_REQUEST_POST.HTTPMethod = "POST"
            }
            return APP_REQUEST_POST
        }
    func getAppRequestPostSession() -> NSURLSession {
            if(APP_REQUEST_POST_SESSION == nil) {
                APP_REQUEST_POST_SESSION = NSURLSession.sharedSession()
            }
            return APP_REQUEST_POST_SESSION
        }
    func getCustEtaRequest() -> NSMutableURLRequest {
            if(CUST_ETA_REQUEST == nil) {
                CUST_ETA_REQUEST = NSMutableURLRequest(URL: NSURL(string: "http://peterscuts.com/lib/request_handler.php")!)
                CUST_ETA_REQUEST.HTTPMethod = "POST"
            }
            return CUST_ETA_REQUEST
        }
    func getCustEtaSession() -> NSURLSession {
            if(CUST_ETA_SESSION == nil) {
                CUST_ETA_SESSION = NSURLSession.sharedSession()
            }
            return CUST_ETA_SESSION
        }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
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
        let jsonData = NSData(contentsOfURL: url!)
        let readableData = JSON(data: jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil)
        currentNumber.text = readableData["current"].stringValue
        nextNumber.text = readableData["next"].stringValue
    }
    func parseJSON() {
        // standard app request
        let task1 = getSession().dataTaskWithRequest(getRequest()){ data,response,error in
            if error != nil{
                print("ERROR -> \(error)")
                return
            }
            do {
                let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  )	as! [String: AnyObject]
                
                let current_Number:Int = responseJSON["current"] as! Int
                let next_Number:Int = responseJSON["next"] as! Int
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
                let etaSeconds:Int = etaMinutes * 60
                let (h,m) = self.secondsToHoursMinutesSeconds(etaSeconds)
                self.waitTime.text = "\(h)hrs \(m)mins"
                self.staticApproxWait.text = "Approximate wait time for next appointment is:"
                
            } catch {
                print ("Error connecting to the server")
            }
        }// end of task1
        task1.resume()
        self.getNumberButton.hidden = false
        self.stepperLabel.hidden = false
        self.Stepper.hidden = false
    } // end of parseJSON()
    
    func checkAppointmentForToday() {
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
        do {
            let request = NSFetchRequest (entityName: "Appointments")
            let predicate1 = NSPredicate (format: "date = %@", todays_string_date)
            let predicate2 = NSPredicate (format: "status = %@", "EMPTY")
            let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate1, predicate2])
            request.predicate = compound
            let results:NSArray = try context.executeFetchRequest(request)
            var minNumber:Int = 9999
            if results.count > 0 {
                // get the number for each object in the results array, add to intNumberArray
                for res in results{
                    let numberString: String = res.valueForKey("number") as! String
                    let numberInt: Int = Int(numberString)!
                    if(minNumber > numberInt) {
                        minNumber = numberInt
                    }
                }
            }
            if minNumber == 9999 {
                parseJSON()
                myNumberLabel.hidden = true
            } else {
                /////////////////////// now that you got the minimum number in list of appointments use that to get the wait time
                let minNumberString:String = String(minNumber)
                self.getNumberButton.hidden = true
                self.myNumberLabel.hidden = false
                self.cancelAppointment.hidden = false
                self.Stepper.hidden = true
                self.staticApproxWait.text = "Your approximate wait time is"
                self.myNumberLabel.text = "Your appointment # is \(minNumberString)"
                // COUNT for today's appointment and wait time
                let postParams =  "customerid=\(minNumberString)"
                getCustEtaRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
                
                let task = getCustEtaSession().dataTaskWithRequest(getCustEtaRequest()){ data,response,error in
                    if error != nil{
                        print("ERROR -> \(error)")
                        return
                    }
                    do {
                        let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []  ) as! [String: AnyObject]
                        let count: Int = responseJSON["retVal"] as! Int
                        let waitTime_seconds = count * 20 * 60
                        let (h,m) = self.secondsToHoursMinutesSeconds(waitTime_seconds)
                        self.waitTime.text = "\(h) hrs \(m) min"
                        //  Notifications
                        if (count == 2) {
                            if (self.firstNotificationStatus != true) {
                                self.createLocalNotification(minNumberString, time: "in 40 mins")
                                self.fortyMinutesNotification("setON")
                            }
                        } else if (count == 1) {
                            if (self.nextNotificationStatus != true) {
                                self.createLocalNotification(minNumberString, time: "next")
                                self.youAreNextNotification("setON")
                            }
                        } else if (count == 0) {
                            self.waitTime.text = "Your appointment is Now"
                            self.createLocalNotification(minNumberString, time: "Now")
                            self.NowNotification("setON")
                            dispatch_async(dispatch_get_main_queue(),
                                           {
                                            let alertController = UIAlertController(title: "Rush to your appointment!", message: "Your Appointment is Now", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in}
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            }) // end of dispatch
                            do {
                                let request = NSFetchRequest (entityName: "Appointments")
                                request.predicate = NSPredicate (format: "number = %@", minNumberString)
                                if let result = try context.executeFetchRequest(request) as? [NSManagedObject] {
                                    if result.count != 0 {
                                        let managedObject = result[0]
                                        managedObject.setValue("FINISHED", forKey: "status")
                                        do {
                                            try context.save()
                                        } catch{
                                            print ("Error saving change status")
                                        }
                                    } // end of result.count != 0
                                } // end of result =  executeFetchReuest
                            } catch {
                                print ("error")
                            }
                        } else if (count < 0) {
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
                                        } catch{
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
                                let alertController = UIAlertController(title: "Appointment # \(minNumberString)", message: "Did you miss appointment #\(minNumberString)? Please get another number or call Peter", preferredStyle: .Alert  )
                                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                alertController.addAction(OKAction)
                                self.presentViewController(alertController, animated: true, completion: nil)
                            })
                        }
                    } catch {
                        print ("error")
                    }
                }
                // NOT USED??
                task.resume()
            }
        } catch {
            print("error")
        }
    }  //  end of func checkTodayAppointment()
    // MARK: Actions
    @IBAction func updateInfo(sender: UIButton) { }
    @IBAction func about(sender: UIButton) { }
    @IBAction func termsOfUse(sender: UIButton) { }
    @IBAction func privacyPolicy(sender: UIButton) { }
    
    @IBAction func getNumber(sender: UIButton) {
        // User info does not exist
        if (NSUserDefaults.standardUserDefaults().stringForKey("name") == nil || NSUserDefaults.standardUserDefaults().stringForKey("number") == nil) {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let alertController = UIAlertController(title: "Alert", message: "Please enter your information", preferredStyle: .Alert  )
                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
                            alertController.addAction(cancelAction)
                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                            alertController.addAction(OKAction)
                            self.presentViewController(alertController, animated: true, completion: nil)
            }) // end of dispatch
            return
        }
        
        // First get the stepper value from label, default 1
        let stepperCount = Int(stepperLabel.text!)	// This is the number of appointments to make
        let userName:String = NSUserDefaults.standardUserDefaults().stringForKey("name")!
        let phone:String = NSUserDefaults.standardUserDefaults().stringForKey("number")!
        var email:String = "-"
        if (NSUserDefaults.standardUserDefaults().stringForKey("email") != nil){
            email = NSUserDefaults.standardUserDefaults().stringForKey("email")!
        }
        var i = 0
        while i < stepperCount {
            i += 1
            if (i == 0) {
                let postParams =  "user_name=\(userName)&user_phone=\(phone)&user_email=\(email)"
                getAppRequestPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
            } else {
                let postParams =  "user_name=\(userName) - \(i)&user_phone=\(phone)&user_email=\(email)"
                getAppRequestPostRequest().HTTPBody = postParams.dataUsingEncoding(NSUTF8StringEncoding)
            }
            let task = getAppRequestPostSession().dataTaskWithRequest(getAppRequestPostRequest()){ data,response,error in
                if error != nil{
                    print("ERROR -> \(error)")
                    return
                }
                do {
                    let responseJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                    if(i == 1)
                    { // Only do this part for the first customer
                        let gotNumberInt: Int = responseJSON["getId"] as! Int
                        let gotNumberString: String = String(gotNumberInt)
                        let messageReturned: String = responseJSON["message"] as! String
                        if (gotNumberString == "-2") {
                            dispatch_async(dispatch_get_main_queue(),
                                           {
                                            let alertController = UIAlertController(title: "Error", message: "There was an error communicating with the server", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            }) // end of dispatch
                        } else if (gotNumberString == "-9") {
                            dispatch_async(dispatch_get_main_queue(),
                                           {
                                            let alertController = UIAlertController(title: "Store Closed", message: "Store is closed. Please call (519)816-2887", preferredStyle: .Alert  )
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            }) // end of dispatch
                        } else if (messageReturned == "new") {
                            // create a pop alerting number
                            dispatch_async(dispatch_get_main_queue(), {
                                if(stepperCount == 1) {
                                    let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the queue. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                    alertController.addAction(OKAction)
                                    self.presentViewController(alertController, animated: true, completion: nil)
                                } else {
                                    let alertController = UIAlertController(title: "Your Appointment", message: "You have received number \(gotNumberString) in the queue for \(stepperCount) haircuts. Please check back in the app for updated waiting time. Look for a notification 40 mins prior to the appointment", preferredStyle: .Alert  )
                                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                    alertController.addAction(OKAction)
                                    self.presentViewController(alertController, animated: true, completion: nil)
                                }
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
                            let addAppointment = NSEntityDescription.insertNewObjectForEntityForName("Appointments", inManagedObjectContext: context) as NSManagedObject
                            addAppointment.setValue(string_date, forKey: "date")
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
                                            let alertController = UIAlertController(title: "Your Appointment", message: "You already received an appointment with number \(gotNumberString) in the queue.", preferredStyle: .Alert)
                                            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                                            alertController.addAction(OKAction)
                                            self.presentViewController(alertController, animated: true, completion: nil)
                            })
                        } // end of else if "duplicate"
                    }
                } catch {
                    print("Error -> \(error)")
                }
            } // end of task
            task.resume()
        } // END OF For loop
        self.checkAppointmentForToday()
    } // end of getNumber function
    
    @IBAction func cancelAppointment(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(),
        {
            let alertController = UIAlertController(title: "Cancel Appointment", message: "Please Call Peter (519) 816-2887", preferredStyle: .Alert  )
            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
            alertController.addAction(OKAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        })
        self.checkAppointmentForToday()
    } // end of cancel function
    @IBAction func Stepper(sender: UIStepper) {
        stepperLabel.text = String(Int(Stepper.value))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getNumberButton.hidden = true
        self.myNumberLabel.hidden = true
        self.cancelAppointment.hidden = true
        self.firstNotificationStatus = false
        self.nowNotificationStatus = false
        self.nextNotificationStatus = false
        
        checkAppointmentForToday() // check if theres any appointment
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.checkAppointmentForToday), userInfo: nil, repeats: true)
        parseNumbers()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.parseNumbers), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
};// end of view controller