import UIKit
import APESuperHUD
import Alamofire
import SwiftyJSON
import YooKassaPayments
import YooKassaPaymentsApi
import YandexMobileMetrica

final class Init_3_LinkCardVC: UIViewController {
    var alreadyStarted = false
    
    @IBOutlet weak var linkCardButton: UIButton!

    @IBAction func linkCard(_ sender: UIButton) {
        /*DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            reportEvent("Карта", [:])

            let paymentMethodTypes: PaymentMethodTypes = [.bankCard]

                //shop id 574103
            let amount = Amount(value: 1.00, currency: .rub)

            let tokenizationSettings: TokenizationSettings = TokenizationSettings(paymentMethodTypes: paymentMethodTypes)

            let inputData: TokenizationFlow = .tokenization(
                TokenizationModuleInputData(
                    clientApplicationKey: App.this.PAYMENTKEY,
                    shopName: "Хоба-Фитнес",
                    purchaseDescription: "Проверка платежной карты",
                    amount: amount,
                    tokenizationSettings: tokenizationSettings, savePaymentMethod: .on))

            strongSelf.tokenizationVC = TokenizationAssembly.makeModule(inputData: inputData, moduleOutput: strongSelf)
            strongSelf.present(strongSelf.tokenizationVC as! UIViewController, animated: true, completion: nil)
        }*/
    }

/*
    var tokenizationVC: TokenizationModuleInput? = nil
    
    var token: Tokens?
    var paymentMethodType: PaymentMethodType?

    public static func makeModule() -> UIViewController {
        return Init_3_LinkCardVC(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// UI
        self.setBackButton()
        
        if App.this.userCardDigits.isEmpty {
            linkCard(linkCardButton)
        }
    }
    
*/
    var url3ds: String = ""
}

/*
extension Init_3_LinkCardVC: TokenizationModuleOutput {
    func tokenizationModule(_ module: TokenizationModuleInput,
                            didTokenize token: Tokens,
                            paymentMethodType: PaymentMethodType) {
        DispatchQueue.main.async { [weak self] in
        guard let strongSelf = self else { return }
            strongSelf.token = token
            strongSelf.paymentMethodType = paymentMethodType

            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отправляем...")
            
            let url = "\(App.BASEURL)/linkcard"
            let jsonRequest = """
                {\"action\": \"paid\",
                    \"uuid\": \"123\",
                    \"payToken\": \"\(strongSelf.token?.paymentToken ?? "")\",
                    \"payMethodS\": \"bankCard\",
                    \"amount\": 1,
                    \"amountsub\": 0, \"idtarif\": 0 }
            """
            
            Alamofire.request(url, method: .post, parameters: [:], encoding: jsonRequest, headers: hdrs())
                .responseJSON {
                    response in
                    
                    APESuperHUD.dismissAll(animated: true)
                    App.this.paymentToken = strongSelf.token?.paymentToken ?? ""
                    
                    if let data = response.result.value {
                        reportEvent("Карта привязана", [:])

                        let jsonResponse = JSON(data)
                        strongSelf.url3ds = jsonResponse["url"].stringValue
                        module.start3dsProcess(requestUrl: strongSelf.url3ds)
                    }
                    else {
                        reportEvent("Карта не привязана", [:])
                        strongSelf.raiseAlert("Увы!", "Не удалось привязать карту.\nЗапрос: \(jsonRequest)\nКод ошибки LC: \(response.response?.statusCode ?? -1000)\n Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                    }
            }
        }
    }
    
    func needsConfirmPayment(requestUrl: String) {
        DispatchQueue.main.async { [weak self] in
                   guard let strongSelf = self else { return }
            strongSelf.tokenizationVC?.start3dsProcess(requestUrl: requestUrl)
        }
    }
    
    func didFinish(on module: TokenizationModuleInput, with error: YooKassaPaymentsError?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
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
                                
                                self.alreadyStarted = false
                                
                                if App.this.userTariffId == TARIFF_NOT_SET && App.this.freeTrains == 0 {
                                    let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs") as! TariffsVC
                                    vc.titleVisible = true
                                    vc.openPayAfterTariffSelection = true
                                    //vc.callRoomsVCThen = true
                                    self.navigationController?.pushViewController(vc, animated: true)
                                }
                                else {
                                    if App.this.bookedTrain.slots.count == 0 {
                                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                        let vc = storyboard.instantiateViewController(withIdentifier: "Rooms")
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }
                                    else {
                                        let storyboard = UIStoryboard(name: "Booking", bundle: nil)
                                        let vc = storyboard.instantiateViewController(withIdentifier: "BookTrain") as! BookTrainVC
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }
                                }
                            })
                        }
                        else {
                            //App.this.userCardDigits = ""
                            self.raiseAlert("Увы!", "Не удалось привязать карту. Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                        }
                    }
                    else {
                        self.raiseAlert("Увы!", "Не удалось привязать карту.\nКод ошибки LPS: \(response.response?.statusCode ?? -2000)\n Пожалуйста, проверьте введенные данные и убедитесь, что баланс карты положительный.", "Понятно")
                    }
            }
        }
    }
}
*/
