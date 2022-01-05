import UIKit
import CoreData
import Foundation


class privacyPolicyViewController: UIViewController {
    @IBOutlet weak var privacyPolicy: UILabel!
    @IBOutlet weak var privacyPolicyText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleSwipe(_ gestureRecognizer : UISwipeGestureRecognizer) {
        // Animate only if swiping in correct direction
        if gestureRecognizer.direction == .right {
            _ = navigationController?.popViewController(animated: true)
        } else {
            _ = navigationController?.popViewController(animated: false)
        }
    }
}
