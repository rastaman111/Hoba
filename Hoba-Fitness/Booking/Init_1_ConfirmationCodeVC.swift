import UIKit
import SwiftyJSON
import Alamofire
import APESuperHUD
import YandexMobileMetrica

final class Init_1_ConfirmationCodeVC: UIViewController {
    @IBOutlet weak var smsCode: UITextField!
    
    @IBAction func sendSMSAgain(_ sender: Any) {
        let url = "\(App.BASEURL)/registration"
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отправляем...")
        Alamofire.request(url, method: .post, parameters: [:], encoding: "{\"phone\": \"\(App.this.userPhone)\"}", headers: ["Content-Type":"application/json"])
            .responseString { response in
                APESuperHUD.dismissAll(animated: true)
                if response.result.isSuccess {
                    let alert = UIAlertController(title: "Запрос отправлен!", message: "На указанный вами номер отправлено сообщение с кодом.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Отлично", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    self.raiseAlert("Увы!", "Не удалось запросить код. Повторите попытку позже.", "Понятно")
                }
        }
    }
    
    @IBAction func checkCode(_ sender: Any) {
        if smsCode.text?.isEmpty ?? true {
            raiseAlert("Увы!", "Пожалуйста, введите полученный в SMS код. Если вы не получили его - запросите еще раз.", "Понятно")
        }
        else {
            reportEvent("СМС", [:])
            
            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Проверяем...")
            
            let url = "\(App.BASEURL)/acceptcode"
            let json = "{\"phone\": \"\(App.this.userPhone)\", \"token\": \"\(App.this.deviceUUID)\", \"typeos\":\"iOS\", \"acceptcode\": \"\(smsCode.text ?? "")\"}"
            
            Alamofire.request(url, method: .post, parameters: [:], encoding: json, headers: ["Content-Type":"application/json"])
                .responseJSON {
                    response in
                    
                    APESuperHUD.dismissAll(animated: true)
                    
                    if let data = response.result.value {
                        let json = JSON(data)
                        App.this.userInfo = json
                        App.this.userToken = json["jwtkey"].exists() ? json["jwtkey"].stringValue : ""
                        App.this.userJWTExpiration = Int(Date().timeIntervalSince1970) +
                            (json["expiration"].intValue * 86400)
                    }
                    else {
                        App.this.userToken = ""
                    }
                    
                    switch response.response?.statusCode {
                    case 200, 201:
                        
//                        App.this.userPhoneConfirmed = true
                        App.this.userInfoWasSet = true
                        
                        if App.authUser == true {
                            self.raiseAlert("Поздравляем!", "Вы успешно авторизовались. Желаем продуктивных тренировок!", "Ура!", completion: { _ in
                                let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
                                App.this.slideNavigationController?.setBodyViewController(vc, closeOpenMenu: false, ignoreClassMatch: true)
                            })
                        }
                        else {
                            let storyboard = UIStoryboard(name: "Booking", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "BookingPersonalInfo") as! Init_2_PersonalInfoVC
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                        
                    default:
                        self.raiseAlert("Увы!", "Пожалуйста, проверьте введенный вами код.", "Понятно")
                    }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
}
