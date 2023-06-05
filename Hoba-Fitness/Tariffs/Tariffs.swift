import UIKit
import APESuperHUD
import Alamofire
import SwiftyJSON
import YandexMobileMetrica

final class TariffsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabelHC: NSLayoutConstraint!
    @IBOutlet weak var retryButton: UIButton!
    
    var dismissOnTariffSelected = false
    var popOnTariffSelected = false
    var openPayAfterTariffSelection = false
    var showMenuButton = true
    var noFreeTrains = false
    
    var thisVC: TariffsVC?
    var titleVisible = false
    var filteredTariffs: [JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// UI
        if showMenuButton {
            self.setMenuButton()
        }
        self.setBackButton()
        
        titleLabelHC.constant = titleVisible ? 48 : 0
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
        
        thisVC = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reportEvent("Тарифы", [:])
        reloadTariffs(retryButton)
    }
    
    func getTariffDescr(_ tariff: JSON) -> String {
        let price = tariff["coast"].stringValue
        switch tariff["tariftype"].intValue {
        case TARIFF_FREE:
            return "Бесплатная пробная тренировка"
        case TARIFF_SINGLE_TRAIN:
            return (price == "0" ? "Бесплатная пробная тренировка" : "\(price) руб. за каждую тренировку")
        case TARIFF_YEAR_PLAN:
            return "\(price) руб. за каждую тренировку" + "\n+\(tariff["coastsubscription"].stringValue) руб за \(tariff["periodsub"].stringValue)"
        case TARIFF_TRAINS_W_COACH:
            return "\(price) руб. за тренировку с персональным тренером"
        case TARIFF_PACKAGE:
            return "\(price) руб. за каждый час \n(часов в пакете: \(tariff["count"].stringValue))"
        case TARIFF_ABONEMENT:
            let days = tariff["periodsub"].intValue
            return "Абонемент \(price) руб. за \(days) \(getNumEnding(number: days, declinations: ["день", "дня", "дней"]))"
        default:
            var tarifDesc = "\(price) руб. за каждую тренировку"
            if tariff["usesubscribe"].boolValue {
                tarifDesc += "\n+\(tariff["coastsubscription"].stringValue) руб за \(tariff["periodsub"].stringValue)"
            }
            return tarifDesc
        }
    }
    
    /// Table
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredTariffs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TariffItem", for: indexPath as IndexPath) as! TariffItem
        
        let tariff = self.filteredTariffs[indexPath.row]
        
        cell.priceLabel.text = tariff["coast"].stringValue
        cell.priceTitle.text = getTariffDescr(tariff)
        cell.tariffButton.tag = indexPath.row
        cell.tariffDescription.text = tariff["description"].stringValue
        
        if tariff["id"].intValue == App.this.userTariffId || isSubscribed(tariff) {
            cell.tariffButton.backgroundColor = UIColor(argb: 0xff383536)
            cell.tariffButton.setTitle("Тариф выбран", for: .normal)
            cell.iconWeight.image = UIImage(named: "iconWeight")
            cell.containerView.layer.borderColor = UIColor.white.cgColor
        }
        else {
            cell.tariffButton.backgroundColor = UIColor(argb: 0xff92B909)
            cell.tariffButton.setTitle("Выбрать тариф", for: .normal)
            cell.iconWeight.image = UIImage(named: "iconWeightActive")
            cell.containerView.layer.borderColor = UIColor(argb: 0xff92B909).cgColor
        }
        
        if tariff["tariftype"].intValue == TARIFF_FREE {
            cell.tariffDescription.text = "Одна бесплатная тренировка для знакомства с залом"
        }
        
        if tariff["id"].intValue == 3 {
            cell.tariffDescription.text = "Стартовый тариф по умолчанию - подходит для первого раза и для тех, кто тренируется пару раз в месяц"
        }
        
        if tariff["tariftype"].intValue == TARIFF_ABONEMENT {
            let desc = tariff["description"].stringValue
            cell.abonementTitle.text = desc.isEmpty ? "Абонемент" : desc
            cell.abonementSection.isHidden = false
            cell.abonementSectionHC.constant = 100
            cell.abonementDescription.text = "Количество тренировок не ограничено, длительность \(tariff["periodsub"].intValue) дней."
        }
        else {
            cell.abonementSection.isHidden = true
            cell.abonementSectionHC.constant = 0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func selectExitScenario() {
        if self.dismissOnTariffSelected {
            self.thisVC?.dismiss(animated: true, completion: nil)
        }
        else if self.popOnTariffSelected {
            self.thisVC?.navigationController?.popViewController(animated: true)
        }
        else if self.openPayAfterTariffSelection {
            if App.this.bookedTrain.slots.count == 0 {
                /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "Rooms")
                self.navigationController?.pushViewController(vc, animated: true)*/
                App.this.loadSchedule(fromVC: self, id: App.this.reservedRoomId, forChange: false, changeTrain: SingleTrain())
            }
            else {
                let storyboard = UIStoryboard(name: "Booking", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "BookTrain") as! BookTrainVC
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            /*let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Rooms")
            self.navigationController?.viewControllers[0] = vc
            self.navigationController?.popToRootViewController(animated: true)*/
            App.this.loadSchedule(fromVC: self, id: App.this.reservedRoomId, forChange: false, changeTrain: SingleTrain())
        }
    }
    
    ///
    @IBAction func tariffButtonTapped(_ sender: UIButton) {
        let tariff = self.filteredTariffs[sender.tag]
        
        reportEvent("Выбор тарифа \(getTariffDescr(tariff))", [:])
        
        if App.this.userInfoWasSet {
            
            if paidTariffIdx(id: tariff["id"].intValue) != nil
                || isYearPlanActive(tariff["id"].intValue)
                || isAbonementPlanActive(tariff["id"].intValue) {
                
                App.this.userTariff = tariff
                
                self.scrollToActive()
                self.raiseAlert("Подтверждение", "У вас уже имеется подписка на выбранный тариф. Тариф подтвержден.", "Отлично", completion: { handler in
                    self.selectExitScenario()
                })
            }
            else if App.this.userTariffId == tariff["id"].intValue {
                App.this.userTariff = tariff
                self.scrollToActive()
                self.raiseAlert("Выбор тарифа", "Тариф подтвержден", "Хорошо", completion: { handler in
                    self.selectExitScenario()
                })
            }
            else {
                var priceTitle = ""
                switch tariff["tariftype"].intValue {
                case TARIFF_SINGLE_TRAIN:
                    let price = tariff["coast"].intValue
                    priceTitle = price == 0 ? "бесплатную пробную тренировку" : "тариф \(price) руб. за каждую тренировку"
                case TARIFF_YEAR_PLAN:
                    priceTitle = "тариф \(tariff["coast"].stringValue) руб. за каждую тренировку" + "\n+\(tariff["coastsubscription"].stringValue) руб за \(tariff["periodsub"].stringValue)"
                case TARIFF_TRAINS_W_COACH:
                    priceTitle = "тариф \(tariff["coast"].stringValue) руб. за тренировку с персональным тренером"
                case TARIFF_PACKAGE:
                    priceTitle = "тариф \(tariff["coast"].stringValue) руб. за каждый час \n(часов в пакете: \(tariff["count"].stringValue))"
                default:
                    var priceTitle = "тариф \(tariff["coast"].stringValue) руб. за каждую тренировку"
                    if tariff["usesubscribe"].boolValue {
                        priceTitle += "\n+\(tariff["coastsubscription"].stringValue) руб за \(tariff["periodsub"].stringValue)"
                    }
                }
                
                let alert = UIAlertController(title: "Выбор тарифа", message: "Вы хотите подключить \(priceTitle)?", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Да", style: .default, handler: {
                    action in
                    App.this.userTariff = tariff
                    App.this.userTariffTrainsCount = App.this.userTariff["count"].intValue
                    
                    self.scrollToActive()
                    self.selectExitScenario()
                }))
                alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: {
                    action in
                    self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else {
            App.this.userTariff = tariff
            scrollToActive()
            self.raiseDialog("Регистрация", "Для выбора тарифа необходимо зарегистрироваться. Хотите продолжить?",
                positive: "Да, зарегистрироваться",
                onPositive: {_ in
                    let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
                    self.navigationController?.pushViewController(vc, animated: true)},
                negative: "Нет, не надо",
                onNegative: {_ in })
        }
    }
    
    @IBAction func reloadTariffs(_ sender: UIButton) {
        loadTariffs(completion: { tariffs in
            self.filteredTariffs = tariffs.arrayValue.filter{ $0["active"].boolValue == true }.sorted(by: { $0["coast"].intValue < $1["coast"].intValue })

            if App.this.freeTrainsAvail {
                var tmp = self.filteredTariffs
                tmp.insert(genFreeTrain(), at: 0)
                self.filteredTariffs = JSON(tmp).arrayValue
            }
            
            self.tableView.reloadData()
            self.tableView.isHidden = false
            self.retryButton.isHidden = true
            self.scrollToActive()
        })
    }
    
    func activeIdx() -> Int {
        if let i = filteredTariffs.firstIndex(where: { $0["id"].intValue == App.this.userTariffId }) {
            return i
        }
        return 0
    }
    
    func scrollToActive() {
        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath(row: activeIdx(), section: 0), at: .middle, animated: false)
    }

    /// Picker funcs
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

class TariffItem: UITableViewCell {
    @IBOutlet weak var iconWeight: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceTitle: UILabel!
    @IBOutlet weak var tariffButton: UIButton!
    @IBOutlet weak var tariffDescription: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var abonementSection: UIView!
    @IBOutlet weak var abonementSectionHC: NSLayoutConstraint!
    @IBOutlet weak var abonementDescription: UILabel!
    @IBOutlet weak var abonementTitle: UILabel!
}

