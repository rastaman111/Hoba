import UIKit
import Alamofire
import SwiftyJSON
import APESuperHUD
import YandexMobileMetrica

let TRAIN_FREE: Int = 1
let TRAIN_ALREADY_PAID: Int = 2
let TRAIN_SHOULDBE_PAID: Int = 3

final class BookTrainVC: UIViewController, MenuDelegate {
    // MARK: - Properties
    var easySlideNavigationController: ESNavigationController?
    var trainType: Int = TRAIN_FREE
    let dispatcher: DispatchGroup = DispatchGroup()
    var jsonResponse = JSON()
    var canPay = true
    var hoursNotYetSelected = true

    // promocodes
    var responseStatusCode = 0
    var promoCanBeApplied = false

    // MARK: - IBOutlets
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var cardNumber: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var promoCode: UITextField!
    @IBOutlet weak var promoCodeContainer: UIView!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// UI
        setBackButton()
        hideKeyboardWhenTappedAround()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateView(price: App.this.userTariff["coast"].floatValue, response: JSON())

        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Проверяем цену...")
        reserve(isFirst: (trainType == TRAIN_FREE), writeOff: (trainType ==
            TRAIN_ALREADY_PAID || trainType == TRAIN_FREE), completion: {
                json, response in
                APESuperHUD.dismissAll(animated: true)

                if let code = response.response?.statusCode {
                    self.responseStatusCode = code
                }
                if let data = response.result.value {
                    self.jsonResponse = JSON(data)
                }
                parseReserve(response: self.jsonResponse)
        })

        if (App.this.userCardDigits.isEmpty && App.this.userTariffType == TARIFF_FREE)
            || App.this.activeAbonement
            || App.this.userCardLinked {
            submitButton.setTitle("Оплатить", for: .normal)
        }
        else {
            submitButton.setTitle("Привяжите карту", for: .normal)
        }

    }

    func showHoursCountSelector(completion: @escaping (_ count: Int) -> Void) {
        let message = "\n\n\n\n\n\n"
        let alert = UIAlertController(title: "Выберите количество часов с тренером.", message: message,
                                      preferredStyle: UIAlertController.Style.actionSheet)
        alert.isModalInPopover = true

        let pickerFrame = UIPickerView(frame: CGRect(x: 0, y: 60, width: self.view.bounds.width - 20, height: 140))
        pickerFrame.tag = 555

        //set the pickers datasource and delegate
        pickerFrame.delegate = self
        pickerFrame.dataSource = self

        //Add the picker to the alert controller
        alert.view.addSubview(pickerFrame)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            completion(coachHours[pickerFrame.selectedRow(inComponent: 0)])
        })
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Отмена", style: .destructive, handler: nil)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Data processing
    func updateView(price: Float, response: JSON) {

        changeButton.isHidden = true

        App.this.bookedTrain.price = price == -1
            ? App.this.userTariff["coast"].floatValue * App.this.userTariff["count"].floatValue
            : price

        let (h1, m1, _) = secondsToHours(seconds: App.this.reservedIntervalStart)
        let (h2, m2, _) = secondsToHours(seconds: App.this.reservedIntervalEnd)
        
        dateTimeLabel.text = "\(App.this.reservedDate.toString(format: "dd MMMM yyyy")) с \(String(format: "%02d", h1) + ":" + String(format: "%02d", m1)) по \(String(format: "%02d", h2) + ":" + String(format: "%02d", m2))"
        cardNumber.text = App.this.userCardDigits.isEmpty ? "Карта еще не привязана" : "XXXX-XXXX-XXXX-\(App.this.userCardDigits)"
        addressLabel.text = App.this.reservedRoom

        var priceTitle = "Первая тренировка - бесплатно! Забронировать?"

        switch App.this.userTariffType {
            
        case TARIFF_PACKAGE:
                if isPackagePlanAvail(App.this.userTariffId) {
                    priceTitle = "Тренировка входит в предоплаченный пакет."
                    self.submitButton.setTitle("Забронировать", for: .normal)
                    App.this.bookedTrain.textDescription = "Пакетный план \(App.this.bookedTrain.price) руб. за 1 час"
                    self.trainType = TRAIN_ALREADY_PAID
                }
                else {
                    App.this.bookedTrain.price = response.isEmpty
                        ? App.this.userTariff["coast"].floatValue * App.this.userTariff["count"].floatValue
                        : response["sum"].floatValue
                    
                    App.this.userTariffTrainsCount = App.this.userTariff["count"].intValue
                    
                    App.this.bookedTrain.textDescription = "Пакетный план \(App.this.bookedTrain.price) руб. за 1 час"
                    
                    self.trainType = TRAIN_SHOULDBE_PAID
                    
                    priceTitle = "\(App.this.bookedTrain.price) руб за \(App.this.userTariffTrainsCount) \(getNumEnding(number: App.this.userTariffTrainsCount, declinations: ["час", "часа", "часов"]))."
            }
            case TARIFF_TRAINS_W_COACH:
                if isPackagePlanAvail(App.this.userTariffId) {
                    priceTitle = "Тренировка входит в предоплаченный пакет."
                    self.submitButton.setTitle("Забронировать", for: .normal)
                    App.this.bookedTrain.textDescription = "Тренировка с инструктором \(App.this.bookedTrain.price) руб. за 1 час"
                    self.trainType = TRAIN_ALREADY_PAID
                }
                else {
                    App.this.bookedTrain.price = price == -1 ? 0 : App.this.bookedTrain.price
                    
                    App.this.userTariffTrainsCount = coachHours[0] // 1 час
                    priceTitle = "\(App.this.bookedTrain.price) руб за \(App.this.userTariffTrainsCount) \(getNumEnding(number: App.this.userTariffTrainsCount, declinations: ["тренировку", "тренировки", "тренировок"])) с тренером."

                    App.this.bookedTrain.textDescription = "Тренировка с инструктором \(App.this.bookedTrain.price) руб. за 1 час"
                    self.trainType = TRAIN_SHOULDBE_PAID
                    self.changeButton.isHidden = false
            }
            case TARIFF_ABONEMENT:
                let price = App.this.bookedTrain.price
                let days = App.this.userTariff["periodsub"].intValue
                if isAbonementPlanActive(App.this.userTariffId) {
                    priceTitle = "Тренировка входит в предоплаченный пакет."
                    self.submitButton.setTitle("Забронировать", for: .normal)
                    App.this.bookedTrain.textDescription = "Абонемент \(price) руб. за \(days) \(getNumEnding(number: days, declinations: ["день", "дня", "дней"]))"
                    self.trainType = TRAIN_ALREADY_PAID
                }
                else {
                    priceTitle = "Сумма к оплате: \(price) руб. за \(days) \(getNumEnding(number: days, declinations: ["день", "дня", "дней"]))"
                    App.this.bookedTrain.price = App.this.userTariff["coast"].floatValue
                    App.this.bookedTrain.textDescription = "Абонемент \(price) руб. за \(days) \(getNumEnding(number: days, declinations: ["день", "дня", "дней"]))"
                    self.trainType = TRAIN_SHOULDBE_PAID
            }
            case TARIFF_YEAR_PLAN:
                if isYearPlanActive(App.this.userTariffId) {
                    priceTitle = "Сумма к оплате: \(App.this.bookedTrain.price) руб за тренировку."
                    App.this.bookedTrain.textDescription = "Годовая подписка \(App.this.userTariff["coast"].intValue + App.this.userTariff["coastsubscription"].intValue)"
                    self.trainType = TRAIN_SHOULDBE_PAID
                }
                else {
                    priceTitle = "Сумма к оплате: \(App.this.bookedTrain.price + App.this.userTariff["coastsubscription"].floatValue) руб за тренировку и годовую подписку."

                    App.this.bookedTrain.textDescription = "Годовая подписка \(App.this.bookedTrain.price + App.this.userTariff["coastsubscription"].floatValue)"
                    self.trainType = TRAIN_SHOULDBE_PAID
            }
            case TARIFF_FREE:
                App.this.bookedTrain.price = 0
                priceTitle = "Бесплатная тренировка.\nСумма к оплате: 0 руб."
                App.this.bookedTrain.textDescription = "Бесплатная тренировка."
                self.trainType = TRAIN_FREE
                self.submitButton.setTitle("Забронировать", for: .normal)

            default: /// Single train
                App.this.bookedTrain.price = App.this.bookedTrain.extended
                    ? App.this.bookedTrain.price * 1.5
                    : App.this.bookedTrain.price
                priceTitle = "Сумма к оплате: \(App.this.bookedTrain.price) руб за тренировку."
                App.this.bookedTrain.textDescription = "Тариф \(App.this.bookedTrain.price) руб за тренировку."
                self.trainType = TRAIN_SHOULDBE_PAID
        }
        self.priceLabel.text = priceTitle

        self.promoCodeContainer.isHidden = (self.trainType == TRAIN_ALREADY_PAID || App.this.userTariffType == TARIFF_FREE)
    }

    @IBAction func change(_ sender: Any) {
        showHoursCountSelector { count in
            App.this.userTariffTrainsCount = count
            self.hoursNotYetSelected = false
            App.this.bookedTrain.price = App.this.bookedTrain.price * Float(App.this.userTariffTrainsCount)
            self.priceLabel.text = "\(App.this.bookedTrain.price) руб за \(App.this.userTariffTrainsCount) \(getNumEnding(number: App.this.userTariffTrainsCount, declinations: ["тренировку", "тренировки", "тренировок"])) с тренером."
        }
    }
    
    @IBAction func submit(_ sender: Any) {
        if (App.this.userCardDigits.isEmpty && App.this.userTariffType == TARIFF_FREE)
        || App.this.activeAbonement
        || App.this.userCardLinked {
            bookTrain()
        }
        else {
            linkCard()
        }
    }

    @IBAction func checkPromoAction(_ sender: Any) {
        if (promoCode.text ?? "").isEmpty {
            self.raiseAlert("Увы!", "Введите промо-код", "Понятно")
        }
        else {
            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Проверяем промокод...")

            promoCanBeApplied = false
            checkPromo(tariff: App.this.userTariffId, room: App.this.bookedTrain.roomId,
                       uuid: App.this.bookedTrain.uid, promo: promoCode.text ?? "", completion: {
                        success, msg, response in
                        APESuperHUD.dismissAll(animated: true)
                        
                        if success {
                            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
                            self.promoCanBeApplied = success

                            var successMsg = "Промо-код успешно применён."

                            if response["typecount"].stringValue == "t" {
                                successMsg += " Теперь часов: \(response["count"].intValue)."
                            }
                            else if response["typecount"].stringValue == "d" {
                                successMsg += " Теперь дней: \(response["count"].intValue)."
                            }
                            else if response["typediscount"].stringValue == "s" {
                                self.updateView(price: response["sum"].floatValue, response: response)
                            }
                            else {
                                self.updateView(price: response["sum"].floatValue, response: response)
                            }

                            self.raiseAlert("Ура!", successMsg, "Отлично")
                        }
                        else {
                            self.raiseAlert("Увы!", msg, "Понятно")
                        }
            })
        }
    }

    func linkCard() {
        self.raiseAlert("Увы!", "Пожалуйста, перейдите в Профиль и привяжите карту для оплаты.", "Понятно")
    }

    func bookTrain() {
        changeButton.isHidden = true

        reportEvent(App.this.userTariffType == TARIFF_FREE ? "БТ" : "Оплата \(App.this.bookedTrain.textDescription)", [:])

        if App.this.userTariffType == TARIFF_TRAINS_W_COACH && !isPackagePlanAvail(App.this.userTariffId) && App.this.userTariffTrainsCount == 0 {
            self.viewWillAppear(false)
        }
        else {
            if !App.this.userMail.isEmpty && !App.this.userMail.isEmail() {
                raiseAlert("Увы!", "Пожалуйста, проверьте указанный адрес email", "Понятно")
            }
            else {
                if canPay {
                    canPay = false
                    submitButton.isEnabled = false
                    submitButton.alpha = 0.4

                    if responseStatusCode == 200 || responseStatusCode == 201 {
                        if self.trainType == TRAIN_SHOULDBE_PAID {
                            var body: [String : Any] = [
                                "action": "paid",
                                "uuid": App.this.bookedTrain.uid,
                                "payToken": App.this.paymentToken,
                                "payMethodS": "bankCard",
                                "email": App.this.userMail,
                                "amount": App.this.bookedTrain.price,
                                "amountsub": App.this.userTariff["coastsubscription"].intValue,
                                "idtarif": App.this.userTariffId
                            ]
                            if App.this.userTariff["tariftype"].intValue == TARIFF_TRAINS_W_COACH {
                                body["count"] = App.this.userTariffTrainsCount
                            }
                            if self.promoCanBeApplied {
                                body["promoname"] = promoCode.text ?? ""
                            }

                            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отправляем...")
                            Alamofire.request("\(App.BASEURL)/paid", method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdrs())
                                .responseJSON {
                                    response in
                                    if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
                                        if let data = response.result.value {
                                            let payResponse = JSON(data)
                                            if payResponse["paid"].boolValue == true {

                                                addTrain(App.this.bookedTrain)

                                                APESuperHUD.dismissAll(animated: true)
                                                self.canPay = true
                                                self.submitButton.isEnabled = true
                                                self.submitButton.alpha = 1
                                                self.raiseAlert("Поздравляем!", "Вы успешно оплатили тренировку!", "Отлично", completion: { action in
                                                    self.navigationController?.viewControllers[0] = UIStoryboard(name: "BookedTrains", bundle: nil).instantiateViewController(withIdentifier: "BookedTrains")
                                                    self.navigationController?.popToRootViewController(animated: true)
                                                })
                                            }
                                            else {
                                                APESuperHUD.dismissAll(animated: true)
                                                self.canPay = true
                                                self.submitButton.isEnabled = true
                                                self.submitButton.alpha = 1
                                                self.raiseAlert("Увы!", "Не удалось оплатить тренировку. Пожалуйста, повторите попытку позже!", "Понятно")
                                            }
                                        }
                                    }
                                    else {
                                        APESuperHUD.dismissAll(animated: true)
                                        self.canPay = true
                                        self.submitButton.isEnabled = true
                                        self.submitButton.alpha = 1
                                        self.raiseAlert("Увы!", "Не удалось забронировать тренировку. Пожалуйста, повторите попытку позже!", "Ок")
                                    }
                                    loadClientState(completion: { json in })
                            }

                        }
                        else {
                            addTrain(App.this.bookedTrain)

                            APESuperHUD.dismissAll(animated: true)
                            self.raiseAlert("Поздравляем!", "Вы успешно забронировали тренировку!", "Отлично", completion: { action in
                                self.navigationController?.viewControllers[0] = UIStoryboard(name: "BookedTrains", bundle: nil).instantiateViewController(withIdentifier: "BookedTrains")
                                self.navigationController?.popToRootViewController(animated: true)
                            })
                        }
                    }
                    else {
                        APESuperHUD.dismissAll(animated: true)
                        self.canPay = true
                        self.submitButton.isEnabled = true
                        self.submitButton.alpha = 1

                        self.raiseAlert("Увы!", "Извините, произошла ошибка.", "Понятно", completion: {
                            action in
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension BookTrainVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return coachHours.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(coachHours[row])"
    }
}
