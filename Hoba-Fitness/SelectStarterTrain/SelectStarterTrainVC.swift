import UIKit
import SwiftyJSON
import APESuperHUD

final class SelectStarterTrainVC: UIViewController {
    // MARK: - Properties
    var tariffsToSelect: [JSON] = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var freeTrainBtn: UIButton!
    @IBOutlet weak var freeTrainBtnHC: NSLayoutConstraint!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setMenuButton()
        setBackButton()

        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        loadClientState(completion: {
            json in
            APESuperHUD.dismissAll(animated: true)
            if !App.this.freeTrainsAvail {
                self.freeTrainBtnHC.constant = 0
            }
        })
    }
    
    // MARK: - IBActions
    @IBAction func openTariffSelector(_ sender: UIButton) {
        if sender.tag == TARIFF_FREE {
            reportEvent("MainWTTrial", [:])
            if App.this.userInfoWasSet {
                App.this.userTariff = genFreeTrain()
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Rooms")
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                self.raiseDialog("Авторизация", "Для бронирования тренировки необходима авторизация. Перейти к авторизации/регистрации?", positive: "Да, пожалуйста", onPositive: { _ in
                    let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
                    self.navigationController?.viewControllers[0] = vc
                    self.navigationController?.popToRootViewController(animated: true)
                }, negative: "Нет, не сейчас", onNegative: { _ in })
            }
        }
        else {
            loadTariffs(completion: { tariffs in
                switch sender.tag {
                case TARIFF_SINGLE_TRAIN:
                    reportEvent(App.this.freeTrainsAvail ? "MainWTSingle" : "MainSingle", [:])
                case TARIFF_TRAINS_W_COACH:
                    reportEvent(App.this.freeTrainsAvail ? "MainWTCoach" : "MainCoach", [:])
                case TARIFF_ABONEMENT:
                    reportEvent(App.this.freeTrainsAvail ? "MainWTAbon" : "MainAbon", [:])
                default:
                    break
                }

                if sender.tag == TARIFF_PACKAGE || sender.tag == TARIFF_TRAINS_W_COACH {
                    self.tariffsToSelect = tariffs.arrayValue.filter { $0["tariftype"].intValue == TARIFF_PACKAGE && $0["active"].boolValue == true }
                    let coachTrains = tariffs.arrayValue.filter { $0["tariftype"].intValue == TARIFF_TRAINS_W_COACH && $0["active"].boolValue == true }
                    self.tariffsToSelect.append(contentsOf: coachTrains)
                }
                else {
                    self.tariffsToSelect = tariffs.arrayValue.filter { $0["tariftype"].intValue == sender.tag
                        && $0["active"].boolValue == true }
                }

                let vc = UIStoryboard(name: "TariffSelector", bundle: nil).instantiateViewController(withIdentifier: "TariffSelector") as! TariffSelectorVC
                vc.tariffType = sender.tag
                vc.tariffsToSelect = self.tariffsToSelect
                vc.completion = {
                    id in
                    
                    App.this.userTariff = self.tariffsToSelect.first(where: {$0["id"].intValue == id })!

                    if App.this.userInfoWasSet {
                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Rooms")
                        self.navigationController?.pushViewController(vc, animated: true)                        
                        /*App.this.loadSchedule(fromVC: self, id: App.this.reservedRoomId, forChange: false, changeTrain: SingleTrain())*/
                    }
                    else {
                        self.raiseDialog("Авторизация", "Для бронирования тренировки необходима авторизация. Перейти к авторизации/регистрации?", positive: "Да, пожалуйста", onPositive: { _ in
                            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
                            self.navigationController?.viewControllers[0] = vc
                            self.navigationController?.popToRootViewController(animated: true)
                        }, negative: "Нет, не сейчас", onNegative: { _ in })
                    }
                }
                self.present(vc, animated: true)
            })
        }
    }
    
    @IBAction func openChat(_ sender: Any) {
        reportEvent(App.this.freeTrainsAvail ? "MainWTSite" : "MainSite", [:])
        guard let url = URL(string: "http://www.hoba.fit") else { return }
        UIApplication.shared.open(url, options: [:])
    }
}
