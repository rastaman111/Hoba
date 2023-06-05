import UIKit
import APESuperHUD

final class SlideNavigationController: ESNavigationController, MenuDelegate {
    var easySlideNavigationController: ESNavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        App.this.slideNavigationController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        loadClientState(completion: {
            json in
            APESuperHUD.dismissAll(animated: true)
        })
        
        // set right menu view controllers
        let optionalRightVC = self.storyboard?.instantiateViewController(withIdentifier: "Drawer")
        if let rightVC = optionalRightVC {
            self.setupMenuViewController(.rightMenu, viewController: rightVC)
            if var delegate: MenuDelegate = rightVC as? MenuDelegate{
                delegate.easySlideNavigationController = self
            }
        }
        
        var vc: UIViewController?
        if App.this.userInfoWasSet {
            vc = App.this.storedTrains.count > 0
            ? UIStoryboard(name: "BookedTrains", bundle: nil).instantiateViewController(withIdentifier: "BookedTrains")
            : UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
        }
        else {
            vc = UIStoryboard(name: "NewOrExisting", bundle: nil).instantiateViewController(withIdentifier: "NewOrExisting")
        }
        
        App.this.slideNavigationController?.setBodyViewController(vc!, closeOpenMenu: false, ignoreClassMatch: true)
        
        if !App.this.onboardingWasShown {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "OnboardingNavi")
            self.present(vc, animated: true)
        }
    }
}
