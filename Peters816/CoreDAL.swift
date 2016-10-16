//
//  coreDAL.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/11/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation
import CoreData
import UIKit


@objc(User)

class CoreDAL : NSManagedObject {
    @NSManaged var coreName: String?
    @NSManaged var corePhone: String?
    @NSManaged var coreNumHaircuts: Int
    
    class func saveUserDetails(name: String, phone: String, email: String?=nil) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Delete existing user info
        self.clearExistingData(managedContext)
        
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext:managedContext)
        let user = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        user.setValue(name, forKey: "name")
        user.setValue(phone, forKey: "phone")
        
        if(email != nil) {
            user.setValue(email, forKey: "email")
        }
        
        do {
            try managedContext.save()
        } catch {
            return false
        }
        return true
    }
    class func getUserDetails() -> (String, String, String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.returnsObjectsAsFaults = false
        do
        {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            let retName = results[0].valueForKey("name") as! String
            let retPhone = results[0].valueForKey("phone") as! String
            let retEmail = results[0].valueForKey("email") as! String
            
            return (retName, retPhone, retEmail)
        } catch let error as NSError {
            // Need to do something here possibly?
            return ("", "", "")
        }
    }
    
    // TODOS
    //  startTime doesn't need to be here? Maybe h/m? -- need to add NSDate to saveUserDetails to reset id on new day
    class func addAppointment(idNum: Int, startTime: NSDate, reservationInd: Bool) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext

        let entity = NSEntityDescription.entityForName("Haircut", inManagedObjectContext:managedContext)
        let haircut = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        haircut.setValue(idNum,forKey: "cust_id")
        haircut.setValue(startTime, forKey: "start_time")
        haircut.setValue(reservationInd, forKey: "reservation_ind")
        
        do {
            try managedContext.save()
            return true
        } catch {
            return false
        }
    }
    
    // Remove any core data -- should only be called when the user updates their name and phone
    // TODO!!! maybe don't clear the ID -- we'll see though
    class func clearExistingData(curManagedContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try curManagedContext.executeFetchRequest(fetchRequest)
            for curObject in results
            {
                let curObjectData:NSManagedObject = curObject as! NSManagedObject
                curManagedContext.deleteObject(curObjectData)
            }
        } catch let error as NSError {
            // Need to do something here possibly?
        }
    }
    
    
}
