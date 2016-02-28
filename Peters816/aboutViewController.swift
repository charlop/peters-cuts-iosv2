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

class aboutViewController: UIViewController {


    @IBAction func call(sender: UIButton) {
        
        // Launch dialer
        let url:NSURL = NSURL(string: "tel://5198162887")!
        
        if (UIApplication.sharedApplication().canOpenURL(url))
        {
            UIApplication.sharedApplication().openURL(url)
        }
        
    }
    
    @IBAction func directions(sender: UIButton) {
        
        if let url = NSURL(string: "http://maps.apple.com/?daddr=939+Wyandotte+St+E+Windsor+ON") { UIApplication.sharedApplication().openURL(url)
        }
        
    }
    
override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
    
    
}

override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
}


}