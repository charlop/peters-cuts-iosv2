import UIKit
import CoreData
import Foundation

class aboutViewController: UIViewController {
    @IBAction func call(_ sender: UIButton) {
        
        // Launch dialer
        let url:URL = URL(string: "tel://5198162887")!
        
        if (UIApplication.shared.canOpenURL(url))
        {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func directions(_ sender: UIButton) {
        if let url = URL(string: "http://maps.apple.com/?daddr=939+Wyandotte+St+E+Windsor+ON") { UIApplication.shared.openURL(url)
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
