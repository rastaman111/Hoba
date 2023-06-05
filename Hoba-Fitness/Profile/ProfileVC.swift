import UIKit
import APESuperHUD
import Alamofire
import SwiftyJSON
import BEMCheckBox
import YooKassaPayments
import YandexMobileMetrica
import ScheduledNotificationsViewController

final class ProfileVC: UIViewController {
        // MARK: - Properties
    var tokenizationModuleInput: TokenizationModuleInput? = nil
    var url3ds: String = ""
    var token: Tokens? = nil
    var paymentMethodType: PaymentMethodType?
    let settingsService: SettingsService? = nil
    lazy var settings: Settings = {
        if let settings = settingsService?.loadSettingsFromStorage() {
            return settings
        } else {
            let settings = Settings()
            settingsService?.saveSettingsToStorage(settings: settings)

            return settings
        }
    }()

        // MARK: - IBOutlets
    @IBOutlet weak var userFirstName: UILabel!
    @IBOutlet weak var userLastName: UILabel!
    @IBOutlet weak var userBirthDate: UILabel!
    @IBOutlet weak var userMail: UILabel!
    @IBOutlet weak var cardNumber: UITextField!
    @IBOutlet weak var linkCardButton: UIButton!
    @IBOutlet weak var unlinkCardButton: UIButton!
    @IBOutlet weak var autoRenewal: BEMCheckBox!
    @IBOutlet weak var autoRenewalLabel: UILabel!
    @IBOutlet weak var cardInfoContainer: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var unlinkCardButtonHC: NSLayoutConstraint!

        // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

            /// UI
        self.setMenuButton()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleAutoRenewal(_:)))
        self.autoRenewal.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reportEvent("Личный кабинет", [:])

        if App.this.userCardDigits.isEmpty {
            self.cardNumber.text = "XXXX-XXXX-XXXX-XXXX"
            unlinkCardButtonHC.constant = 0
        }
        else {
            cardNumber.text = "XXXX-XXXX-XXXX-\(App.this.userCardDigits)"
            unlinkCardButtonHC.constant = 40
        }

        if App.this.userInfoWasSet {
            editButton.setTitle("Редактировать", for: .normal)
            cardInfoContainer.isHidden = false
            autoRenewal.isHidden = false
            autoRenewalLabel.isHidden = false
        }
        else {
            userBirthDate.text = ""
            editButton.setTitle("Зарегистрироваться", for: .normal)
            cardInfoContainer.isHidden = true
            autoRenewal.isHidden = true
            autoRenewalLabel.isHidden = true
        }

        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")

        updateView()
    }

        // MARK: - IBActions
    @IBAction func listNotifications(_ sender: Any) {
        let notificationsVC = ScheduledNotificationsViewController()
        self.navigationController?.pushViewController(notificationsVC, animated: true)
    }

    @IBAction func editButton(_ sender: Any) {
        if App.this.userInfoWasSet {
            let storyboard = UIStoryboard(name: "PersonalInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "EditPersonalInfo") as! EditProfileVC
            present(vc, animated: true, completion: nil)
        }
        else {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func actionLinkCard(_ sender: Any) {
        reportEvent("Карта", [:])

        linkCard()
            //shop id 574103

        /*let amount = Amount(value: 1.00, currency: .rub)
         let paymentMethodTypes: PaymentMethodTypes = [.bankCard]
         let _: TokenizationSettings = TokenizationSettings(paymentMethodTypes: paymentMethodTypes)

         let inputData: TokenizationFlow = .tokenization(
         TokenizationModuleInputData(clientApplicationKey: App.this.PAYMENTKEY,
         shopName: "Хоба-Фитнес",
         purchaseDescription: "Проверка платежной карты",
         amount: amount,
         savePaymentMethod: .on)
         )

         tokenizationVC = TokenizationAssembly.makeModule(inputData: inputData, moduleOutput: self)
         present(tokenizationVC as! UIViewController, animated: true, completion: nil)*/
    }

    @IBAction func unlinkCard(_ sender: Any) {
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        delinkCard(completion: { _ in
            APESuperHUD.dismissAll(animated: true)
            self.cardNumber.text = "XXXX-XXXX-XXXX-XXXX"

            self.unlinkCardButtonHC.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.unlinkCardButton.layoutIfNeeded()
            })
        })
    }

        // MARK: - Listeners
    @objc func handleAutoRenewal(_ sender: UITapGestureRecognizer? = nil) {
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        let jsonRequest = "{\"autorenewal\": \(!autoRenewal.on) }"
        Alamofire.request("\(App.BASEURL)/autorenewal/", method: .post, parameters: [:], encoding: jsonRequest, headers: hdrs())
            .response {
                response in
                APESuperHUD.dismissAll(animated: true)
                if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
                    self.autoRenewal.on = !self.autoRenewal.on
                }
                else {
                    self.raiseAlert("Увы!", "Не удалось отправить. Повторите попытку позже.", "Понятно")
                }
            }
    }

    @objc func prolongingAbonement(sender: UIButton!) {
        if let plan = App.this.userInfo["listtarif"].arrayValue.first(where: {
            $0["id"].intValue == sender.tag }) {
            self.raiseDialog("Продление абонемента",
                             "Хотите оплатить продление абонемента на \(plan["periodsub"].stringValue) \(getNumEnding(number: plan["periodsub"].intValue, declinations: ["день", "дня", "дней"])) за \(plan["coast"].intValue) руб.?",
                             positive: "Да, оплатить",
                             onPositive: {_ in
                APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
                let jsonRequest = "{\"idtarif\": \(sender.tag) }"
                Alamofire.request("\(App.BASEURL)/renewal", method: .post, parameters: [:], encoding: jsonRequest, headers: hdrs())
                    .responseJSON {
                        response in
                        APESuperHUD.dismissAll(animated: true)
                        if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
                            self.raiseAlert("Поздравляем", "Продление успешно оплачено.", "Ура", completion: {_ in
                                self.viewWillAppear(true)
                            })
                        }
                        else {
                            self.raiseAlert("Увы!", "Не удалось отправить. Повторите попытку позже.", "Понятно")
                        }
                    }
            },
                             negative: "Нет, не надо",
                             onNegative: {_ in })
        }
    }

        // MARK: - UI
    func getText(item: String, title: Bool) -> PaddingLabel {
        let ttl = PaddingLabel(padding: UIEdgeInsets(top: title ? 16 : 0, left: 8, bottom: title ? 16 : 0, right: 8))
        ttl.font = title ? ttl.font.withSize(16) : ttl.font.withSize(14)
        ttl.textColor = title ? .white : UIColor(rgb: 0xCCCCCC)
        ttl.textAlignment = .left
        ttl.addConstraint(NSLayoutConstraint(item: ttl, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width))
        ttl.text = item
        return ttl
    }
    
    func getButton(title: String, tariffId: Int) -> UIView {
        let btn = UIButton()
        
        btn.setTitle(title, for: .normal)
        btn.addConstraint(NSLayoutConstraint(item: btn, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width - 60))
        
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(colorActiveGreen, for: .normal)
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.darkGray.cgColor
        btn.tag = tariffId
        btn.addTarget(self, action: #selector(prolongingAbonement), for: UIControl.Event.touchUpInside)
        
        return btn
    }

    func updateView() {
        loadClientState(completion: {
            json in

            APESuperHUD.dismissAll(animated: true)

            self.userFirstName.text = "Имя: " + App.this.userFirstName
            self.userLastName.text = "Фамилия: " + App.this.userLastName
            self.userMail.text = App.this.userMail
            self.userBirthDate.text = App.this.userInfoWasSet ?
                App.this.userBirthDate.toString(format: "dd MMMM yyyy") : ""

            self.autoRenewal.setOn(App.this.userInfo["autorenewal"].boolValue, animated: true)

            if (App.this.userInfo["listsub"].arrayValue.count
                + App.this.userInfo["listabonement"].arrayValue.count
                + App.this.userInfo["unlimtarif"].arrayValue.count) > 0 {

                for view in self.stack.arrangedSubviews { view.removeFromSuperview() }

                let ttl = self.getText(item: "Активные планы и подписки", title: true)
                ttl.font = ttl.font.withSize(20)
                ttl.textAlignment = .center
                self.stack.addArrangedSubview(ttl)

                var descr = ""
                for sub in App.this.userInfo["listsub"].arrayValue {
                    
                    descr = sub["tarif"]["description"].stringValue.isEmpty ? "" :                      "\n" + sub["tarif"]["description"].stringValue

                    if sub["tarif"]["tariftype"].intValue == TARIFF_TRAINS_W_COACH {
                        let tariffView = UsedTariffItem.instanceFromNib()
                        tariffView.tariffTitle.text = "Пакет часов с инструктором" + descr

                        tariffView.tariffDesc.text = "Цена 1 часа: \(sub["tarif"]["coast"].intValue) руб."
                            + "\nОсталось часов: \(sub["balance"].intValue)"
                        tariffView.tariffProlongHC.constant = 0
                        tariffView.addConstraint(NSLayoutConstraint(item: tariffView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width))
                        self.stack.addArrangedSubview(tariffView)
                    }

                    if sub["tarif"]["tariftype"].intValue == TARIFF_PACKAGE {
                        let tariffView = UsedTariffItem.instanceFromNib()
                        tariffView.tariffTitle.text = "Пакет часов" + descr
                        tariffView.tariffDesc.text = "Цена 1 часа: \(sub["tarif"]["coast"].intValue) руб."
                            + "\nОсталось часов: \(sub["balance"].intValue)"
                        tariffView.tariffProlongHC.constant = 0
                        tariffView.addConstraint(NSLayoutConstraint(item: tariffView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width))
                        self.stack.addArrangedSubview(tariffView)
                    }
                }

                for sub in App.this.userInfo["listabonement"].arrayValue {
                    descr = sub["tarif"]["description"].stringValue.isEmpty ? "" :                      "\n" + sub["tarif"]["description"].stringValue

                    if let plan = App.this.userInfo["listtarif"].arrayValue.first(where: {
                        $0["id"].intValue == sub["idtarif"].intValue }) {

                        let tariffView = UsedTariffItem.instanceFromNib()
                        tariffView.tariffTitle.text = "Годовая подписка" + descr
                        tariffView.tariffDesc.text = "Цена 1 часа: \(plan["coast"].intValue) руб."
                            + "\nАбон.плата за год: \(plan["coastsubscription"].intValue) руб."
                            + "\nЗавершается: \(Date(timeIntervalSince1970: sub["endDateEpoch"].doubleValue).toString(format: "dd MMMM yyyy"))г."

                        tariffView.tariffProlongHC.constant = 0
                        tariffView.addConstraint(NSLayoutConstraint(item: tariffView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width))

                        self.stack.addArrangedSubview(tariffView)
                    }
                }

                for sub in App.this.userInfo["unlimtarif"].arrayValue {
                    descr = sub["tarif"]["description"].stringValue.isEmpty ? "" :                      "\n" + sub["tarif"]["description"].stringValue

                    if let plan = App.this.userInfo["listtarif"].arrayValue.first(where: {
                        $0["id"].intValue == sub["idtarif"].intValue }) {

                        let tariffView = UsedTariffItem.instanceFromNib()
                        tariffView.tariffTitle.text = "Абонемент на \(plan["periodsub"].stringValue) \(getNumEnding(number: plan["periodsub"].intValue, declinations: ["день", "дня", "дней"]))" + descr
                        tariffView.tariffDesc.text = "Цена абонемента: \(plan["coast"].intValue) руб."
                            + "\n" + "Завершается: \(sub["enddate"].stringValue)"

                        tariffView.addConstraint(NSLayoutConstraint(item: tariffView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.stack.bounds.width))

                        if sub["active"].boolValue {
                            tariffView.tariffProlongHC.constant = 30
                            tariffView.tariffProlong.tag = sub["idtarif"].intValue
                            tariffView.tariffProlong.addTarget(self, action: #selector(self.prolongingAbonement), for: UIControl.Event.touchUpInside)
                        }
                        else {
                            tariffView.tariffProlongHC.constant = 0
                        }

                        self.stack.addArrangedSubview(tariffView)
                    }
                }
            }

            var desc = ""
            switch App.this.userTariff["tariftype"].intValue {
                case TARIFF_SINGLE_TRAIN:
                    desc = "\(App.this.userTariff["coast"].stringValue) руб. за каждую тренировку"
                case TARIFF_YEAR_PLAN:
                    desc = "\(App.this.userTariff["coast"].stringValue) руб. за каждую тренировку" + "\n+\(App.this.userTariff["coastsubscription"].stringValue) руб за \(App.this.userTariff["periodsub"].stringValue)"
                case TARIFF_TRAINS_W_COACH:
                    desc = "\(App.this.userTariff["coast"].stringValue) руб. за тренировку с персональным тренером"
                    desc += "\nОсталось тренировок: \(App.this.userTariffTrainsCount)"
                case TARIFF_PACKAGE:
                    desc = "\(App.this.userTariff["coast"].stringValue) руб. за каждый час \n(часов в пакете: \(App.this.userTariff["count"].stringValue))"
                    desc += "\nОсталось тренировок: \(App.this.userTariffTrainsCount)"
                default:
                    desc = "\(App.this.userTariff["coast"].stringValue) руб. за каждую тренировку"
                    if App.this.userTariff["usesubscribe"].boolValue {
                        desc += "\n+\(App.this.userTariff["coastsubscription"].stringValue) руб за \(App.this.userTariff["periodsub"].stringValue)"
                }
            }
        })
    }

        // MARK: - Payment
    func linkCard() {
        reportEvent("Карта", [:])
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            reportEvent("Карта", [:])

                //shop id 574103
            let amount = Amount(value: 1.00, currency: .rub)
            let paymentMethodTypes: PaymentMethodTypes = [.bankCard]
            let tokenizationSettings: TokenizationSettings = TokenizationSettings(paymentMethodTypes: paymentMethodTypes)

            let inputData: TokenizationFlow = .tokenization(
                TokenizationModuleInputData(
                    clientApplicationKey: App.this.PAYMENTKEY,
                    shopName: "Хоба-Фитнес",
                    purchaseDescription: "Проверка платежной карты",
                    amount: amount,
                    tokenizationSettings: tokenizationSettings,
                    savePaymentMethod: .on))

            strongSelf.tokenizationModuleInput = TokenizationAssembly.makeModule(inputData: inputData, moduleOutput: strongSelf)
            strongSelf.present(strongSelf.tokenizationModuleInput as! UIViewController, animated: true, completion: nil)
        }
    }
}

    // MARK: - Extensions

extension ProfileVC: TokenizationModuleOutput {
    func didSuccessfullyConfirmation(paymentMethodType: PaymentMethodType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            reportEvent("Карта привязана", [:])

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dismiss(animated: true)
            }

            Alamofire.request("\(App.BASEURL)/linkpaidstatus", method: .post, parameters: [:], encoding: "{\"uuid\": \"123\"}", headers: hdrs())
                .responseJSON {
                    response in

                    if let data = response.result.value {
                        let json3ds = JSON(data)
                        if json3ds["paid"].exists() && json3ds["paid"].boolValue == true {

                            reportEvent("Карта привязана", [:])

                            self.cardNumber.text = "XXXX-XXXX-XXXX-\(json3ds["last4"].stringValue)"

                            self.unlinkCardButtonHC.constant = 40
                            UIView.animate(withDuration: 0.3, animations: {
                                self.unlinkCardButton.layoutIfNeeded()
                            })

                            let alert = UIAlertController(title: "Поздравляем!", message: "Карта успешно привязана!", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Отлично", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        else {
                            reportEvent("Карта не привязана", [:])

                            App.this.userCardDigits = ""
                            self.raiseAlert("Увы!", "Не удалось привязать карту. Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                        }
                    }
                }

            /*let alertController = UIAlertController(
                title: "Confirmation",
                message: "Successfully confirmation",
                preferredStyle: .alert
            )
            let action = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(action)
            self.dismiss(animated: true)
            self.present(alertController, animated: true)*/
        }
    }

    func didFinish(on module: TokenizationModuleInput, with error:
                    YooKassaPaymentsError?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }
    
    func tokenizationModule(_ module: TokenizationModuleInput,
                            didTokenize token: Tokens,
                            paymentMethodType: PaymentMethodType) {

        DispatchQueue.main.async { [weak self] in
        guard let strongSelf = self else { return }
            strongSelf.token = token
            strongSelf.paymentMethodType = paymentMethodType
            
            let jsonRequest = """
            {\"action\": \"paid\", \"uuid\": \"123\", \"payToken\": \"\(strongSelf.token?.paymentToken ?? "")\",
            \"payMethodS\": \"bankCard\", \"amount\": 1, \"amountsub\": 0, \"idtarif\": 0 }
            """
            
            Alamofire.request("\(App.BASEURL)/linkcard", method: .post, parameters: [:], encoding: jsonRequest, headers: hdrs())
                .responseJSON {
                    response in

                    //print("--- url: ", "\(App.BASEURL)/linkcard")
                    //print("--- headers: ", hdrs())
                    //print("--- request: ", jsonRequest)
                    //print("--- response", response)
                    
                    App.this.paymentToken = strongSelf.token?.paymentToken ?? ""
                    
                    if let data = response.result.value {

                        reportEvent("Карта привязана", [:])
                        let jsonResponse = JSON(data)

                        module.startConfirmationProcess(confirmationUrl:  jsonResponse["url"].stringValue, paymentMethodType: paymentMethodType)
                        /*
                        strongSelf.url3ds = jsonResponse["url"].stringValue
                        module.start3dsProcess(requestUrl: strongSelf.url3ds)*/
                    }
            }
        }
    }
    
    func didSuccessfullyPassedCardSec(on module: TokenizationModuleInput) {
        reportEvent("Карта привязана", [:])
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true)
        }

        Alamofire.request("\(App.BASEURL)/linkpaidstatus", method: .post, parameters: [:], encoding: "{\"uuid\": \"123\"}", headers: hdrs())
            .responseJSON {
                response in
                if let data = response.result.value {
                    let json3ds = JSON(data)
                    if json3ds["paid"].exists() && json3ds["paid"].boolValue == true {
                        
                        reportEvent("Карта привязана", [:])

                        self.cardNumber.text = "XXXX-XXXX-XXXX-\(json3ds["last4"].stringValue)"
                        
                        self.unlinkCardButtonHC.constant = 40
                        UIView.animate(withDuration: 0.3, animations: {
                            self.unlinkCardButton.layoutIfNeeded()
                        })

                        //App.this.userCardLinked = true

                        let alert = UIAlertController(title: "Поздравляем!", message: "Карта успешно привязана!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Отлично", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    /*
                    else {
                        reportEvent("Карта не привязана", [:])

                        App.this.userCardDigits = ""
                        self.raiseAlert("Увы!", "Не удалось привязать карту. Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                    }
                    */
                }
        }
    }
}

