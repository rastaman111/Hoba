import UIKit
import SwiftyJSON
import Alamofire
import APESuperHUD
import YandexMobileMetrica

final class Init_2_PersonalInfoVC: UIViewController {
    // MARK: - Properties
    var popToRoot = false
    
    // MARK: - IBOutlets
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var pickerContainer: UIView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var linkTextView: UITextView!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        /// UI
        self.setBackButton()
        datePicker.setValue(UIColor.white, forKeyPath: "textColor")

        /// Data
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } 
        datePicker.set16YearValidation()
        datePicker.date = App.this.userBirthDate
        lastName.text = App.this.userLastName
        firstName.text = App.this.userFirstName
        pickerSubmit(dateButton)
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center

        let attributedStringColor: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.white,
                                                                     .font: UIFont.systemFont(ofSize: 10),
                                                                     .paragraphStyle: paragraphStyle]
        
        let attributedString = NSMutableAttributedString(string: "Нажимая кнопку, вы соглашаетесь с Правилами клуба и условиями оферты.", attributes: attributedStringColor)
        let linkRange1 = (attributedString.string as NSString).range(of: "Правилами клуба")
        let linkRange2 = (attributedString.string as NSString).range(of: "оферты")
        attributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.hoba.fit/rules", range: linkRange1)
        attributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.hoba.fit/policy", range: linkRange2)
        let linkAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor(argb: 0xff92B909)
        ]
        
        linkTextView.linkTextAttributes = linkAttributes
        linkTextView.attributedText = attributedString
    }

    // MARK: - IBActions
    @IBAction func pickerCancel(_ sender: Any) {
        pickerContainer.isHidden = true
    }
    
    @IBAction func pickerSubmit(_ sender: UIButton) {
        pickerContainer.isHidden = true
        App.this.userBirthDate = datePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd MMMM yyyy"
        let selectedDate = dateFormatter.string(from: App.this.userBirthDate)
        dateButton.setTitle(selectedDate, for: .normal)
    }
    
    @IBAction func openPicker(_ sender: UIButton) {
        datePicker.date = App.this.userBirthDate
        pickerContainer.isHidden = false
    }
    
    @IBAction func submitPersInfo(_ sender: Any) {
        App.this.userLastName = lastName.text ?? ""
        App.this.userFirstName = firstName.text ?? ""
        App.this.userMail = email.text ?? ""
        
        if App.this.userLastName.isEmpty || App.this.userFirstName.isEmpty
            || !App.this.userLastName.isLatinAndCyrillic
            || !App.this.userFirstName.isLatinAndCyrillic {
            raiseAlert("Увы!", "Пожалуйста, проверьте введенные имя и фамилию. Они могут содержать только латинские и кириллические символы. ", "Понятно")
        }
        else if !App.this.userMail.isEmpty && !App.this.userMail.isEmail() {
            raiseAlert("Увы!", "Пожалуйста, проверьте указанный адрес email", "Понятно")
        }
        else {
            reportEvent("Ввод данных", [:])
            
            /// Storing user data
            let body: [String : Any] = [
                "surname": App.this.userLastName, "nameclient": App.this.userFirstName,
                "birthday": App.this.userBirthDate.toString(format: "dd-MM-yyyy"),
                "email": App.this.userMail, "sex": App.this.genderId == 0 ? "male" : "female",
                "typeos": "ios", "phone": App.this.userPhone
            ]
            updateClientInfo(body, completion: { json in
                App.this.userInfo = json
            })
            
            App.this.userInfoWasSet = true

            self.raiseAlert("Поздравляем!", "Вы успешно зарегистрированы. Желаем продуктивных тренировок!", "Отлично", completion: { _ in
                
                if App.this.userTariffType == TARIFF_FREE && !App.this.freeTrainsAvail {
                    self.raiseDialog("Увы!", "Бесплатные тренировки закончились. Перейти к выбору тарифа?", positive: "Да, пожалуйста", onPositive: { _ in
                        let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs")
                        self.navigationController?.viewControllers[0] = vc
                        self.navigationController?.popToRootViewController(animated: true)
                    }, negative: "Нет, не сейчас", onNegative: { _ in
                        let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
                        self.navigationController?.viewControllers[0] = vc
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
                else {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Rooms")
                    self.navigationController?.viewControllers[0] = vc
                    self.navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }
}
