import UIKit
import Foundation

class aboutViewController: UIViewController {
    var ADDRESS_URL: String = "939+Wyandotte+St+E+Windsor+ON"
    var OPEN_HOURS:String = ""
    var userDefaults = User()
    @IBOutlet weak var shopHoursLabel: UILabel!
    @IBAction func call(_ sender: UIButton) {
        
        // Launch dialer
        let url:URL = URL(string: "tel://5198162887")!
        
        if (UIApplication.shared.canOpenURL(url))
        {
            //UIApplication.shared.openURL(url)
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    @IBAction func directions(_ sender: UIButton) {
        if let url = URL(string: "http://maps.apple.com/?daddr=" + ADDRESS_URL) {
            //UIApplication.shared.openURL(url)
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = User()
        
        // Do any additional setup after loading the view, typically from a nib.
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        getNewHours()
        getNewAddr()
    }
    
    func getNewHours() {
        self.shopHoursLabel.text = self.userDefaults.getHoursText()

        Task {
            let newHours = try await APIService.shared.getHours()
            let msgLength = newHours.messageText.count

            await MainActor.run {
                if newHours.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                    self.userDefaults.saveHoursText(newHours.messageText)
                    self.shopHoursLabel.text = self.userDefaults.getHoursText()
                }
            }
        }
    }

    func getNewAddr() {
        self.ADDRESS_URL = self.userDefaults.getAddrUrl()

        Task {
            let newAddr = try await APIService.shared.getAddress()
            let msgLength = newAddr.messageText.count

            await MainActor.run {
                if newAddr.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                    self.userDefaults.saveAddrUrl(newAddr.messageText)
                    self.ADDRESS_URL = self.userDefaults.getAddrUrl()
                }
            }
        }
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
