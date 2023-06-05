import UIKit
import Alamofire
import SwiftyJSON
import APESuperHUD
import UIKit
import SafariServices
import MessageUI
import YandexMobileMetrica

final class DrawerVC: UIViewController, MenuDelegate, MFMailComposeViewControllerDelegate {
    var easySlideNavigationController: ESNavigationController?
    @IBOutlet weak var version: UILabel!
    
    public static var instance: DrawerVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DrawerVC.instance = self
        
        version.text = "v.\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "")"
    }
    
    @IBAction func mainMenu(_ sender: Any) {
        if App.this.userInfoWasSet {
            let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
            if let slideController = self.easySlideNavigationController {
                slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: false)
            }
        }
        else {
            let vc = UIStoryboard(name: "NewOrExisting", bundle: nil).instantiateViewController(withIdentifier: "NewOrExisting")
            if let slideController = self.easySlideNavigationController {
                slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: false)
            }
        }
    }
    
    @IBAction func personalInfo(_ sender: Any) {
        let vc = UIStoryboard(name: "PersonalInfo", bundle: nil).instantiateViewController(withIdentifier: "PersonalInfo")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
    
    @IBAction func bookedTrainings(_ sender: Any) {
        let vc = UIStoryboard(name: "BookedTrains", bundle: nil).instantiateViewController(withIdentifier: "BookedTrains")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
    
    @IBAction func selectRoom(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Rooms")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
    
    @IBAction func viewTariffs(_ sender: Any) {
        let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
    
    @IBAction func viewAbout(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "About")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
    
    @IBAction func openSite(_ sender: Any) {
        reportEvent("Сайт", [:])        
        guard let url = URL(string: "http://www.hoba.fit") else { return }
        UIApplication.shared.open(url, options: [:])
    }
    
    @IBAction func sendEmail(_ sender: Any) {
        if let slideController = self.easySlideNavigationController{
            slideController.closeOpenMenu(animated: false, completion: {
                if MFMailComposeViewController.canSendMail() {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self
                    mail.setToRecipients(["hoba.fit@mail.ru"])
                    mail.setSubject("Hoba: iOS-приложение")
                    let vc = UIApplication.shared.keyWindow!.rootViewController
                    vc?.present(mail, animated: true)
                } else {
                    self.raiseAlert("Увы!", "Похоже, на вашем телефоне не настроен ни один почтовый аккаунт.", "Понятно")
                }
            })
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

    public func openProfile() {
        let vc = UIStoryboard(name: "PersonalInfo", bundle: nil).instantiateViewController(withIdentifier: "PersonalInfo")
        if let slideController = self.easySlideNavigationController{
            slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: true)
        }
    }
}
