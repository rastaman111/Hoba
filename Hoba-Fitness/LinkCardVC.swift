import UIKit
import APESuperHUD
import Alamofire
import SwiftyJSON
import YooKassaPayments
import YandexMobileMetrica

final class LinkCardVC: UIViewController {
        // MARK: - Properties
    var alreadyStarted = false

    // Card link
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
    @IBOutlet weak var linkCardButton: UIButton!

        // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

            // UI
        self.setBackButton()

        if App.this.userCardDigits.isEmpty {
            actionLinkCard(linkCardButton)
        }
    }

        // MARK: - IBActions
    @IBAction func actionLinkCard(_ sender: UIButton) {
        linkCard()
    }

        // MARK: - Card link
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

        // MARK: - Network Manager calls
}

    // MARK: - Extensions
extension LinkCardVC: TokenizationModuleOutput {
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
    }
}

/*
extension LinkCardVC: TokenizationModuleOutput {

    func _tokenizationModule(_ module: TokenizationModuleInput,
                            didTokenize token: Tokens,
                            paymentMethodType: PaymentMethodType) {


    }
    

    func didSuccessfullyPassedCardSec(on module: TokenizationModuleInput) {
        if alreadyStarted == false {
            alreadyStarted = true
            DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true)
        }


        let updateJson = "{\"uuid\": \"123\"}"
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отправляем...")

            Alamofire.request("\(App.BASEURL)/linkpaidstatus", method: .post, parameters: [:], encoding: updateJson, headers: hdrs())
                .responseJSON { response in
                    APESuperHUD.dismissAll(animated: true)
                    if let data = response.result.value {
                        let json3ds = JSON(data)
                        if json3ds["paid"].exists() && json3ds["paid"].boolValue == true {
                            
                            reportEvent("Карта привязана", [:])
                            
                            // App.this.userCardDigits = json3ds["last4"].stringValue
                            self.raiseAlert("Поздравляем!", "Карта успешно привязана!", "Отлично", completion: {
                                handler in

                                APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
                                loadClientState(completion: {
                                    json in
                                    APESuperHUD.dismissAll(animated: true)

                                    self.alreadyStarted = false

                                    if App.popToRoot {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                    else {
                                        let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookTrain") as! BookTrainVC
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }

                                })
                            })
                        }
                        else {
                            self.raiseAlert("Увы!", "Не удалось привязать карту. Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                        }
                    }
                    else {
                        self.raiseAlert("Увы!", "Не удалось привязать карту.\nКод ошибки LPS: \(response.response?.statusCode ?? -2000)\n Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                    }
            }
        }
    }




    func tokenizationModule(
        _ module: TokenizationModuleInput,
        didTokenize token: Tokens,
        paymentMethodType: PaymentMethodType
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
            // Отправьте токен в вашу систему
    }


    func didFinish(on module: TokenizationModuleInput,
                   with error: YooKassaPaymentsError?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }

    func didSuccessfullyConfirmation(
        paymentMethodType: PaymentMethodType
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                // Создать экран успеха после прохождения подтверждения (3DS или Sberpay)
            self.dismiss(animated: true)
                // Показать экран успеха
        }
    }
}
*/
