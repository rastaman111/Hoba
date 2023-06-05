import UIKit

extension UIViewController {
    
    func statusBarStyle(_ style: UIStatusBarStyle) {
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = style == .lightContent ? UIColor.black : .white
            statusBar.setValue(style == .lightContent ? UIColor.white : .black, forKey: "foregroundColor")
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func raiseAlert(_ title: String, _ msg: String, _ button: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: button, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func raiseAlert(_ title: String, _ msg: String, _ button: String, completion: @escaping (_ action: UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: button, style: .default, handler: completion))
        self.present(alert, animated: true, completion: nil)
    }
    
    func raiseDialog(_ title: String, _ msg: String, positive: String, onPositive: @escaping (_ action: UIAlertAction) -> Void, negative: String, onNegative: @escaping (_ action: UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: negative, style: .default, handler: onNegative))
        alert.addAction(UIAlertAction(title: positive, style: .default, handler: onPositive))
        self.present(alert, animated: true, completion: nil)
    }
    
    ///
    func setBackButton() {
        self.navigationController?.navigationBar.topItem?.title = ""
    }
    
    func getEasySlide() -> ESNavigationController {
        return self.navigationController as! ESNavigationController
    }
    
    func setMenuButton() {
        self.navigationController?.navigationBar.barTintColor = App.DEBUG ? .red : .black
        
        //if App.this.userInfoWasSet {
            getEasySlide().enableMenu(.rightMenu, enabled: true)
            let rightButton = UIBarButtonItem(image: UIImage(named: "iconMenu")?.imageResize(sizeChange: CGSize(width: 20, height: 20)), style: .done, target: self, action: #selector(self.openRightMenu))
            self.navigationItem.rightBarButtonItem = rightButton
            self.navigationItem.rightBarButtonItem?.tintColor = .white
        /*}
        else {
            getEasySlide().enableMenu(.rightMenu, enabled: false)
        }*/
    }
    
    @objc internal func openRightMenu() {
        reportEvent("MainWTMenu", [:])
        self.getEasySlide().openMenu(.rightMenu, animated: true, completion: {})
    }
}
