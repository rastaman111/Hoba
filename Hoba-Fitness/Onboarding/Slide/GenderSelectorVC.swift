import UIKit

final class GenderSelectorVC: UIViewController {
    
    @IBAction func genderSelected(_ sender: UIButton) {
        App.this.genderId = sender.tag
        
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Onboarding") as! OnboardingVC
        vc.parentVC = self
        self.navigationController?.pushViewController(vc, animated: true)
            //.present(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goBackToRoot(_ sender: Any) {
        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
    }
}


