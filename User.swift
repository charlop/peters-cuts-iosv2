//
//  User.swift
//  Peters816
//
//  Created by spandan on 2016-02-10.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation
import CoreData

@objc(User)

class User: NSManagedObject {
    @NSManaged var name: String?
    @NSManaged var phone: NSNumber?
    @NSManaged var email: String?

}
