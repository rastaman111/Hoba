import UIKit
import SwiftyJSON
import Alamofire
import APESuperHUD
import YandexMobileMetrica

final class EditProfileVC: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var pickerContainer: UIView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var userMail: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reportEvent("Редактировать данные", [:])
        
        /// UI
        self.setBackButton()
        datePicker.setValue(UIColor.white, forKeyPath: "textColor")
        
        /// Data
        datePicker.set16YearValidation()
        datePicker.date = App.this.userBirthDate
        pickerSubmit(dateButton)
        
        lastName.text = App.this.userLastName
        firstName.text = App.this.userFirstName
        userMail.text = App.this.userMail
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
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
    
    @IBAction func saveInfo(_ sender: Any) {
        App.this.userLastName = lastName.text ?? ""
        App.this.userFirstName = firstName.text ?? ""
        App.this.userMail = userMail.text ?? ""
        
        if Calendar.current.component(.year, from: Date()) <= Calendar.current.component(.year, from: App.this.userBirthDate) {
            raiseAlert("Увы!", "Похоже, введена некорректная дата рождения.", "Понятно")
        }
        if App.this.userLastName.isEmpty || App.this.userFirstName.isEmpty
            || !App.this.userLastName.isLatinAndCyrillic
            || !App.this.userFirstName.isLatinAndCyrillic {
            raiseAlert("Увы!", "Пожалуйста, проверьте введенные имя и фамилию. Они могут содержать только латинские и кириллические символы. ", "Понятно")
        }
        else if !App.this.userMail.isEmpty && !App.this.userMail.isEmail() {
            raiseAlert("Увы!", "Пожалуйста, проверьте введенный адрес электронной почты.", "Понятно")
        }
        else {
            App.this.userInfoWasSet = true
            
            let body: [String : Any] = [
                "surname": App.this.userLastName,
                "nameclient": App.this.userFirstName,
                "birthday": App.this.userBirthDate.toString(format: "dd-MM-yyyy"),
                "email": App.this.userMail
            ]
            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Сохраняем...")
            updateClientInfo(body, completion: {
                json in
                App.this.userInfo = json
                ///App.this.userFirstFreeUsed = App.this.userInfo["countTraining"].intValue > 0
                ///print(json)
                APESuperHUD.dismissAll(animated: true)
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
}
