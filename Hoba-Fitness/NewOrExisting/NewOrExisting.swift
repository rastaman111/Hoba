import UIKit

class NewOrExistingVC: UIViewController {
    // MARK: - Properties
    
    // MARK: - IBOutlets
    @IBAction func registerUser(_ sender: Any) {
        reportEvent("FirstStartNew", [:])
        App.authUser = false
        //let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
        let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain") as! SelectStarterTrainVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func authUser(_ sender: Any) {
        reportEvent("FirstStartReg", [:])
        let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
        self.navigationController?.pushViewController(vc, animated: true)
        App.authUser = true
    }
    
    @IBAction func openSite(_ sender: Any) {
        reportEvent("FirstStartSite", [:])
        guard let url = URL(string: "http://www.hoba.fit") else { return }
        UIApplication.shared.open(url, options: [:])
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setMenuButton()
        
        if !App.this.onboardingWasShown {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "OnboardingNavi")
            self.present(vc, animated: true)
        }
    }
    
    // MARK: - Set up
    
    // MARK: - IBActions
    
    // MARK: - Navigation
    
    // MARK: - Data processing
    
    // MARK: - Extensions
}
