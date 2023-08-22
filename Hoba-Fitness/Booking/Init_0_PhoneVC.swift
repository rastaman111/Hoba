import UIKit
import SwiftyJSON
import Alamofire
import BEMCheckBox
import APESuperHUD
import PhoneNumberKit
import YandexMobileMetrica

final class Init_0_PhoneVC: UIViewController, UITextFieldDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var phoneNumber: PhoneNumberTextField!
    @IBOutlet weak var agreementCheckBox: BEMCheckBox!
    @IBOutlet weak var linkTextView: UITextView!

    // MARK: - Set up
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// UI
        self.setBackButton()
        self.title = "Укажите номер телефона"
        
        //self.phoneNumber.attributedPlaceholder = NSAttributedString(string: "+7 (___)___-____",
//                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
        self.phoneNumber.delegate = self
        self.phoneNumber.withExamplePlaceholder = true
        self.phoneNumber.withPrefix = true
        self.phoneNumber.numberPlaceholderColor = UIColor.white.withAlphaComponent(0.34)
        self.phoneNumber.countryCodePlaceholderColor = UIColor.white.withAlphaComponent(0.35)
        
        let attributedStringColor: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.white,
                                                                     .font: UIFont.systemFont(ofSize: 12)]
        
        let attributedString = NSMutableAttributedString(string: "Ознакомлен с условиями обработки персональных данных в соответствии с Политикой конфиденциальности.\nТакже настоящим я подтверждаю, что мне исполнилось 16 лет.", attributes: attributedStringColor)
        let linkRange1 = (attributedString.string as NSString).range(of: "Политикой конфиденциальности")
        attributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.hoba.fit/privacy", range: linkRange1)
        let linkAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor(argb: 0xff92B909)
        ]
        
        linkTextView.linkTextAttributes = linkAttributes
        linkTextView.attributedText = attributedString
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)

        return false
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.phoneNumber && self.phoneNumber.text!.count == 0 {
            self.phoneNumber.text = "+7"
        }

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.phoneNumber {
            let isNumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
            let withDecimal = (string == NumberFormatter().decimalSeparator &&
                textField.text?.contains(string) == false)
           
            guard isNumber || withDecimal else {
                return false
            }
            
            if string == "." {
                return false
            }
            
            let fullString = (textField.text ?? "") + string
            textField.text = PhoneFormatter.shared.formatTwo(phoneNumber: fullString, shouldRemoveLastDigit: range.length == 1)

            return false
        }
        
        return true
    }

    // MARK: - Actions
    
    @IBAction func sendSMS(_ sender: Any) {
        if !agreementCheckBox.on {
            raiseAlert("Увы!", "Необходимо ваше согласие на обработку персональных данных.", "Понятно")
        } else {
            reportEvent("Телефон", [:])
            
            App.this.userPhone = phoneNumber.text ?? ""
            App.this.userPhone = App.this.userPhone
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "")
            
            if !App.this.userPhone.isPhoneNumber {
                raiseAlert("Увы!", "Пожалуйста, проверьте введенный вами номер телефона - на него будет отправлено SMS.", "Понятно")
            } else {
               
                if App.this.userPhone == "+71234567890" {
                    //App.this.userToken = App.STATICTOKEN
                    App.this.userJWTExpiration = Int(Date().timeIntervalSince1970) +
                        60 * 60 * 24 * 365
//                    App.this.userPhoneConfirmed = true
                    
                    let storyboard = UIStoryboard(name: "Booking", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "BookingPersonalInfo") as! Init_2_PersonalInfoVC
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let url = "\(App.BASEURL)/registration"
                    APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отправляем...")
                    
                    Alamofire.request(url, method: .post, parameters: [:], encoding: "{\"phone\": \"\(App.this.userPhone)\"}", headers: ["Content-Type":"application/json"])
                        .responseString { response in
                            APESuperHUD.dismissAll(animated: true)
                            if response.result.isSuccess {
                                let alert = UIAlertController(title: "Запрос отправлен!", message: "На указанный вами номер отправлено сообщение с кодом.", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Отлично", style: .default, handler: {
                                    action in
                                    let storyboard = UIStoryboard(name: "Booking", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "BookingConfirmationCode") as! Init_1_ConfirmationCodeVC
                                    self.navigationController?.pushViewController(vc, animated: true)
                                }))
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                self.raiseAlert("Увы!", "Не удалось запросить код. Проверьте введенный номер и повторите попытку.", "Понятно")
                            }
                    }
                }
            }
        }
    }
}
