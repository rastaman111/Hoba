import UIKit
import SwiftyJSON
import APESuperHUD
import Alamofire
import YandexMobileMetrica
import Toast_Swift

let NOTSELECTED: Int = -10
let ONEDAY = 24 * 60 * 60

final class ScheduleVC: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    // MARK: - Properties
    let BUTTONWIDTH: CGFloat = 40.0
    
    var jsonSchedule: [JSON] = []
    
    var schedule: [(key: Date, value: [JSON])] = []
    
    var activeDayIdx = 0
    var slotsForDay: [TrainingSlot] = []
    
    var weChangeSchedule = false
    var trainToChange: SingleTrain = SingleTrain()
    
    var selectedTrain = SingleTrain()
    
    // MARK: - IBOutlets
    @IBOutlet weak var dateButtonsStack: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonHC: NSLayoutConstraint!
    
    @IBOutlet weak var splashView: UIView!
    @IBOutlet weak var splashViewTC: NSLayoutConstraint!
    @IBOutlet weak var placeAddress: UILabel!
    @IBOutlet weak var openDoor: UIButton!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        /// UI
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.title = weChangeSchedule ? "Выберите новое время" : "Выберите время"
        
        var toastStyle = ToastStyle()
        toastStyle.backgroundColor = .lightGray
        toastStyle.messageColor = .black
        toastStyle.messageAlignment = .center
        toastStyle.titleColor = .black
        toastStyle.titleAlignment = .center
        ToastManager.shared.style = toastStyle
        
        self.setMenuButton()
        self.setBackButton()
        
        placeAddress.text = App.this.reservedRoom
        
        // Processing schedule
        // adding preloaded today's sched
        parseSchedule(json: jsonSchedule)
        // add empty days for a week
        var today = Date()
        for _ in 0..<13 {
            today.addTimeInterval(TimeInterval(ONEDAY))
            schedule.append((key: today, value: []))
        }
        updateDates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reportEvent("Зал \(App.this.reservedRoom)", [:])
        
        openDoor.isHidden = !App.this.isEmployee && !App.this.userInfo["isemployee"].boolValue
        buttonHC.constant = App.this.isEmployee && App.this.userInfo["isemployee"].boolValue ? 40 : 0
    }
    
    // MARK: - IBActions
    @IBAction func openDoorForPersonnel(_ sender: Any) {
        let updateJson = "{\"idroom\": \"\(App.this.reservedRoomId)\"}"
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Открываем...")
        Alamofire.request("\(App.BASEURL)/openforempl", method: .post, parameters: [:], encoding: updateJson, headers: hdrs())
            .responseJSON {
                response in
                APESuperHUD.dismissAll(animated: true)
                let statusCode = response.response?.statusCode ?? 0
                if statusCode == 200 || statusCode == 201 {
                    //self.raiseAlert("Входите", "Доступ в зал открыт.", "Ура")
                    if let data = response.result.value {
                        let jsonResponse = JSON(data)
                        self.raiseAlert("Открыть дверь", "Введите код замка: \(jsonResponse["codelock"].stringValue) и нажмите #", "Ура")
                    }
                }
                else {
                    self.raiseAlert("Увы!", "Извините, невозможно предоставить доступ в зал.", "Понятно")
                }
            }
    }
    
    // MARK: - Navigation
    func arrangeButton(btn: UIButton, date: Date, active: Bool, tag: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        let wd = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "dd"
        let md = dateFormatter.string(from: date)
        
        let btnTitle = NSMutableAttributedString(string: "\(md)\n\(wd)", attributes: [NSAttributedString.Key.foregroundColor : (active ? UIColor.black : UIColor.white)])
        btnTitle.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 12), range: NSMakeRange(0, btnTitle.length))
        
        btn.setBackgroundColor(color: active ? .white : .clear, forState: .normal)
        btn.setAttributedTitle(btnTitle, for: .normal)
    }
    
    // MARK: - Data processing
    func parseSchedule(json: [JSON]) {
        var scheduleTree: [Date: [JSON]] = [:]
        for j in json {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
            guard let date = dateFormatter.date(from: j["dateplan"].stringValue) else {
                assert(false, "No date from string")
                return
            }
            
            if scheduleTree[date] == nil {
                scheduleTree[date] = []
            }
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let datesAreInTheSameDay = calendar.isDate(Date(), equalTo: date, toGranularity: .day)
            
            if timeStampOfNow() < j["starttime"].intValue || !datesAreInTheSameDay {
                scheduleTree[date]?.append(j)
            }
        }
        
        schedule = scheduleTree.sorted(by: { $0.0 < $1.0 })
        
        updateDates()
    }
    
    func updateDates() {
        dateButtonsStack.subviews.forEach({ $0.removeFromSuperview() })
        
        for i in 0 ..< schedule.count {
            let btn = dateButton(date: schedule[i].key, active: false, tag: i)
            dateButtonsStack.addArrangedSubview(btn)
        }
        
        changeDay(dateButtonsStack.subviews[activeDayIdx] as! UIButton)
    }
    
    func findReservedSlots(date: Date) -> [TrainingSlot] {
        var result: [TrainingSlot] = []
        for d in App.this.storedTrains {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let datesAreInTheSameDay = calendar.isDate(d.date, equalTo: schedule[activeDayIdx].key, toGranularity: .day)
            if datesAreInTheSameDay {
                result.append(contentsOf: d.slots)
            }
        }
        return result
    }
    
    func dateButton(date: Date, active: Bool, tag: Int) -> UIButton {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        let wd = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "dd"
        let md = dateFormatter.string(from: date)
        
        let btnTitle = NSMutableAttributedString(string: "\(md)\n\(wd)", attributes: [NSAttributedString.Key.foregroundColor : (active ? UIColor.black : UIColor.white)])
        btnTitle.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 12), range: NSMakeRange(0, btnTitle.length))
        
        let btn = UIButton()
        btn.setBackgroundColor(color: active ? .white : .clear, forState: .normal)
        btn.setAttributedTitle(btnTitle, for: .normal)
        btn.titleLabel?.numberOfLines = 0
        btn.titleLabel?.lineBreakMode = .byWordWrapping
        btn.titleLabel?.textAlignment = .center
        btn.sizeToFit()
        
        btn.layer.cornerRadius = BUTTONWIDTH / 2
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: BUTTONWIDTH).isActive = true
        btn.heightAnchor.constraint(equalToConstant: BUTTONWIDTH).isActive = true
        btn.tag = tag
        btn.addTarget(self, action: #selector(changeDay(_:)), for: .touchUpInside)
        
        return btn
    }
    
    @objc func changeDay(_ sender: UIButton) {
        arrangeButton(btn: dateButtonsStack.subviews[activeDayIdx] as! UIButton, date: schedule[activeDayIdx].key, active: false, tag: activeDayIdx)
        
        activeDayIdx = sender.tag
        
        arrangeButton(btn: dateButtonsStack.subviews[activeDayIdx] as! UIButton, date: schedule[activeDayIdx].key, active: true, tag: activeDayIdx)
        
        App.this.selectedTimeSlot = NOTSELECTED
        
        //if schedule[activeDayIdx].value.count == 0 {
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        getSchedule(date: schedule[activeDayIdx].key.toString(format: "yyyy-MM-dd"), roomId: App.this.reservedRoomId, completion: { [self] daySchedule in
            
            APESuperHUD.dismissAll(animated: true)
            
            schedule[activeDayIdx].value = activeDayIdx == 0
            ? daySchedule[0]["tableplanner"].arrayValue.filter { $0["starttime"].doubleValue > Date().secondsOfDay() }
            : daySchedule[0]["tableplanner"].arrayValue
            
            slotsForDay = findReservedSlots(date: schedule[activeDayIdx].key)
            tableView.reloadData()
        })
        /*}
         else {
         tableView.reloadData()
         }*/
    }
    
    func getTime(_ h: Int, _ m: Int) -> String {
        return "\(String(format: "%02d", h)):\(String(format: "%02d", m))"
    }
    
    func reinitTrainSelection(_ idx: Int) {
        self.selectedTrain.slots = []
        self.selectedTrain.slots.append(self.getSlot(idx))
        self.view.makeToast("Тренировка может длиться 1 или 1.5 часа.", duration: 2.0, point: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 100), title: "Выберите время завершения.", image: nil) { didTap in }
    }
    
    func extendedWorkoutAvail() -> Bool{
        return !(App.this.userTariffType == TARIFF_TRAINS_W_COACH || App.this.userTariffType == TARIFF_FREE)
    }
    
    func selectBookOrLink() {
        if App.this.userCardDigits.isEmpty && App.this.userTariffType != TARIFF_ABONEMENT && App.this.userTariffType != TARIFF_FREE && !App.this.activeAbonement {
            
            /*let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "LinkCard") as! LinkCardVC
             self.navigationController?.pushViewController(vc, animated: true)*/
            
            self.raiseAlert("Нет привязанных карт!", "Пожалуйста, перейдите в Профиль и привяжите карту для оплаты.", "Понятно")
        }
        else {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookTrain") as! BookTrainVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func ifRegistrationCompleted(completion: @escaping () -> Void) {
        if !App.this.userInfoWasSet {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier:                "BookingPhone") as! Init_0_PhoneVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            completion()
        }
    }
    
    func ifTimeIsAvail(idx: Int, slots: Int, completion: @escaping () -> Void) {
        for i in idx ..< (idx + slots) {
            if thisSlotIsBooked(i) {
                raiseAlert("Извините", "Это время уже забронировано вами", "Понятно")
                return
            }
            else if i >= schedule[activeDayIdx].value.count || schedule[activeDayIdx].value[i]["freeseats"].intValue == 0 {
                raiseAlert("Увы!", "На выбранное время нет свободных мест", "Понятно")
                return
            }
            else if notEnoughSlotsTillEnd(idx: i, count: schedule[activeDayIdx].value.count) {
                raiseAlert("Увы!", "Извините, недостаточно времени.", "Понятно")
                return
            }
        }
        completion()
    }
    
    func notEnoughSlotsTillEnd(idx: Int, count: Int) -> Bool {
        //return ((App.this.userTariffType == TARIFF_ABONEMENT) ? (idx >= count - 2) : (idx >= count - 1))
        return (idx >= count)// - 1)
    }
    
    func getSlots(_ idx: Int) -> [TrainingSlot] {
        var slots: [TrainingSlot] = []
        slots.append(TrainingSlot(start: self.schedule[self.activeDayIdx].value[idx]["starttime"].intValue, date: self.schedule[self.activeDayIdx].key.toString(format: "yyyy-MM-dd")))
        slots.append(TrainingSlot(start: self.schedule[self.activeDayIdx].value[idx + 1]["starttime"].intValue, date: self.schedule[self.activeDayIdx].key.toString(format: "yyyy-MM-dd")))
        return slots
    }
    
    func getSlot(_ idx: Int) -> TrainingSlot {
        return TrainingSlot(start: self.schedule[self.activeDayIdx].value[idx]["starttime"].intValue, date: self.schedule[self.activeDayIdx].key.toString(format: "yyyy-MM-dd"), idx: idx)
    }
    
    func wrapTrain(_ train: SingleTrain) -> SingleTrain {
        App.this.reservedDate = self.schedule[self.activeDayIdx].key
        App.this.reservedIntervalStart = self.schedule[self.activeDayIdx].value[train.slots[0].idx]["starttime"].intValue
        App.this.reservedIntervalEnd = self.schedule[self.activeDayIdx].value[train.slots.last!.idx]["endtime"].intValue
        
        let (h1, m1, h2, m2) = trainTimeBounds(train.slots[0].idx, delta: train.slotsDelta)
        let endH = h2
        let endM = m2
        
        //train.slots = self.getSlots(idx)
        train.date = self.schedule[self.activeDayIdx].key
        train.address = App.this.reservedRoom
        train.trainTime = "\(App.this.reservedDate.toString(format: "dd MMMM yyyy")) с \(self.getTime(h1, m1)) по \(self.getTime(endH, endM))"
        
        return train
    }
    
    func trainTimeBounds(_ idx: Int, delta: Int) -> (Int, Int, Int, Int) {
        let (h1, m1, _) = secondsToHours(seconds: self.schedule[self.activeDayIdx].value[idx]["starttime"].intValue)
        let (h2, m2, _) = secondsToHours(seconds: self.schedule[self.activeDayIdx].value[idx + delta]["endtime"].intValue)
        return (h1, m1, h2, m2)
    }
    
    /*** Этот таймслот уже забронирован */
    func thisSlotIsBooked(_ idx: Int) -> Bool {
        /// check this slot is already booked
        for slot in slotsForDay {
            if slot.starttime == schedule[activeDayIdx].value[idx]["starttime"].intValue {
                return true
            }
        }
        return false
    }
    
    func thisSlotIsForChangingTrain(_ idx: Int, train: SingleTrain) -> Bool {
        if train.date == schedule[activeDayIdx].key {
            let slotStartTime = schedule[activeDayIdx].value[idx]["starttime"].intValue
            if  slotStartTime == train.slots[0].starttime || slotStartTime == train.slots[1].starttime {
                return true
            }
        }
        return false
    }
    
    func trainForSlot(_ idx: Int) -> SingleTrain? {
        let slotStartTime = schedule[activeDayIdx].value[idx]["starttime"].intValue
        for train in App.this.storedTrains {
            if  slotStartTime == train.slots[0].starttime || slotStartTime == train.slots[1].starttime {
                return train
            }
        }
        return nil
    }
    
    func thisTrainToChange(_ idx: Int) -> Bool {
        if let train = trainForSlot(idx) {
            if train.uid == trainToChange.uid {
                return true
            }
        }
        return false
    }
    
    
    // MARK: - Extensions
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.tableView.alpha = schedule[activeDayIdx].value.count == 0 ? 0 : 1
        return schedule[activeDayIdx].value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleItem", for: indexPath as IndexPath) as! ScheduleItem
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(argb: 0xff383536)
        cell.selectedBackgroundView = bgColorView
        
        let (h, m, _) = secondsToHours(seconds: schedule[activeDayIdx].value[indexPath.row]["starttime"].intValue)
        
        cell.dateTime.text = getTime(h, m)
        let freePlaces = schedule[activeDayIdx].value[indexPath.row]["freeseats"].intValue
        if freePlaces == 0 {
            cell.itemTitle.text = "Нет свободных мест"
            cell.dateTime.textColor = .gray
            cell.itemTitle.textColor = .gray
        }
        else {
            cell.dateTime.textColor = .white
            cell.itemTitle.textColor = .white
            cell.itemTitle.text = "Свободно \(freePlaces) \(getNumEnding(number: freePlaces, declinations: ["место", "места", "мест"]))"
        }
        
        ///
        if weChangeSchedule {
            if thisSlotIsForChangingTrain(indexPath.row, train: trainToChange) {
                cell.backgroundColor = colorInactiveGreen
            }
            else if thisSlotIsBooked(indexPath.row) {
                cell.backgroundColor = .gray
            }
            else {
                if let index = self.selectedTrain.slots.firstIndex(where: { $0.idx == indexPath.row }) {
                    cell.backgroundColor = UIColor(argb: 0xff92B909)
                } else {
                    cell.backgroundColor = .clear
                }
                //cell.backgroundColor = (indexPath.row == App.this.selectedTimeSlot
                //|| indexPath.row == App.this.selectedTimeSlot + 1) ? UIColor(argb: 0xff92B909) : .clear
            }
        }
        else {
            cell.backgroundColor = selectedTrain.slotIsIn(getSlot(indexPath.row))
            ? UIColor(argb: 0xff92B909) : .clear
            
            if thisSlotIsBooked(indexPath.row) {
                cell.backgroundColor = .blue
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        
        reportEvent("Время", [:])
        
        if App.this.userInfoWasSet {
            
            if weChangeSchedule {
                ifTimeIsAvail(idx: indexPath.row, slots: trainToChange.slots.count, completion: {
                    App.this.selectedTimeSlot = indexPath.row
                    
                    //                    self.selectedTrain.slots.append(self.getSlot(indexPath.row))
                    //                    self.selectedTrain.slots.append(self.getSlot(indexPath.row + 1))
                    
                    var index = indexPath.row
                    
                    for _ in self.trainToChange.slots {
                        self.selectedTrain.slots.append(self.getSlot(index))
                        index += 1
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    let (h1, m1, _, _) = self.trainTimeBounds(indexPath.row, delta: self.trainToChange.slots.count - 1)
                    self.raiseDialog("Перенос", "Перенести тренировку на \(self.getTime(h1, m1))?",
                                     positive: "Да, перенести",
                                     onPositive: { _ in
                        // OLD
                        //let json = getTransferJson(self.trainToChange, slots: self.getSlots(indexPath.row))
                        // NEW
                        let json = getTransferJson(self.trainToChange, slots: self.selectedTrain.slots)
                        let url = "\(App.BASEURL)/transfer"
                        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Переносим...")
                        
                        Alamofire.request(url, method: .post, parameters: [:], encoding: json, headers: hdrs())
                            .responseJSON {
                                response in
                                APESuperHUD.dismissAll(animated: true)
                                if let data = response.result.value {
                                    let jsonResponse = JSON(data)
                                    print(jsonResponse)
                                    if jsonResponse["uuidreserv"].exists() {
                                        let alert = UIAlertController(title: "Перенос", message: "Тренировка успешно перенесена", preferredStyle: UIAlertController.Style.alert)
                                        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: {
                                            action in
                                            
                                            /// FILL DATA
                                            removeTrain(id: self.trainToChange.uid)
                                            let delta = indexPath.row + self.trainToChange.slots.count
                                            self.trainToChange.slots = []
                                            for i in indexPath.row ..< delta {
                                                self.trainToChange.slots.append(self.getSlot(i))
                                            }
                                            self.trainToChange.uid = jsonResponse["uuidreserv"].stringValue
                                            self.trainToChange.date = self.schedule[self.activeDayIdx].key
                                            self.trainToChange.address = App.this.reservedRoom
                                            self.trainToChange.trainTime = "\(self.trainToChange.date.toString(format: "dd MMMM yyyy")) в \(self.getTime(h1, m1))"
                                            addTrain(self.trainToChange)
                                            self.navigationController?.viewControllers[0] = UIStoryboard(name: "BookedTrains", bundle: nil).instantiateViewController(withIdentifier: "BookedTrains")
                                            self.navigationController?.popToRootViewController(animated: true)
                                        }))
                                        self.present(alert, animated: true)
                                    }
                                    else {
                                        self.raiseAlert("Увы!", "Не удалось перенести тренировку. Повторите попытку позже.", "Понятно")
                                    }
                                }
                                else {
                                    self.raiseAlert("Увы!", "Не удалось перенести тренировку. Повторите попытку позже.", "Понятно")
                                }
                            }
                    },
                                     negative: "Нет, не надо",
                                     onNegative: { _ in
                        App.this.selectedTimeSlot = NOTSELECTED
                        App.this.bookedTrain = SingleTrain()
                        self.tableView.reloadData()
                    })
                })
            }
            else {
                if !App.this.freeTrainsAvail && App.this.userTariffType == TARIFF_FREE {
                    self.raiseDialog("Выбор тарифа", "Ваши бесплатные тренировки закончились, перейти к выбору тарифа?", positive: "Да, пожалуйста", onPositive: { _ in
                        let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs") as! TariffsVC
                        vc.popOnTariffSelected = true
                        vc.showMenuButton = true
                        self.navigationController?.pushViewController(vc, animated: true)
                    }, negative: "Нет, не сейчас", onNegative: { _ in })
                }
                else {
                    if extendedWorkoutAvail() {
                        ifTimeIsAvail(idx: indexPath.row, slots: 1, completion: {
                            if self.selectedTrain.empty {
                                self.reinitTrainSelection(indexPath.row)
                            }
                            else if self.selectedTrain.equalOrLaterThan(self.getSlot(indexPath.row)) {
                                self.reinitTrainSelection(indexPath.row)
                            }
                            else {
                                let delta = indexPath.row - self.selectedTrain.slots[0].idx
                                if (delta < 1 || delta > 2) {
                                    self.reinitTrainSelection(indexPath.row)
                                }
                                else {
                                    self.ifTimeIsAvail(idx: self.selectedTrain.slots[0].idx, slots: delta, completion: {
                                        let startIdx = self.selectedTrain.slots[0].idx + 1
                                        for i in startIdx ... indexPath.row {
                                            self.selectedTrain.slots.append(self.getSlot(i))
                                        }
                                        tableView.reloadData()
                                        
                                        let (h1, m1, h2, m2) = self.trainTimeBounds(self.selectedTrain.slots[0].idx, delta: delta)
                                        self.raiseDialog("Бронирование",
                                                         "Забронировать тренировку c \(self.getTime(h1, m1)) по \(self.getTime(h2, m2))?",
                                                         positive: "Да, забронировать",
                                                         onPositive: { _ in
                                            App.this.bookedTrain = self.wrapTrain(self.selectedTrain)
                                            self.ifRegistrationCompleted(completion: {
                                                self.selectBookOrLink()
                                            })
                                        },
                                                         negative: "Нет, не надо",
                                                         onNegative: { _ in
                                            App.this.selectedTimeSlot = NOTSELECTED
                                            App.this.bookedTrain = SingleTrain()
                                            self.tableView.reloadData()
                                        })
                                    })
                                }
                            }
                            App.this.selectedTimeSlot = indexPath.row
                            tableView.reloadData()
                        })
                    }
                    else {
                        ifTimeIsAvail(idx: indexPath.row, slots: 2, completion: {
                            App.this.selectedTimeSlot = indexPath.row
                            
                            self.selectedTrain.slots = []
                            
                            self.selectedTrain.slots.append(self.getSlot(indexPath.row))
                            self.selectedTrain.slots.append(self.getSlot(indexPath.row + 1))
                          
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            
                            let (h1, m1, h2, m2) = self.trainTimeBounds(indexPath.row, delta: 1)
                            self.raiseDialog("Бронирование",
                                             "Забронировать тренировку c \(self.getTime(h1, m1)) по \(self.getTime(h2, m2))?",
                                             positive: "Да, забронировать",
                                             onPositive: { _ in
                                App.this.bookedTrain = self.wrapTrain(self.selectedTrain)
                                self.ifRegistrationCompleted(completion: {
                                    self.selectBookOrLink()
                                })
                            },
                                             negative: "Нет, не надо",
                                             onNegative: { _ in
                                App.this.selectedTimeSlot = NOTSELECTED
                                App.this.bookedTrain = SingleTrain()
                                self.tableView.reloadData()
                            })
                        })
                    }
                }
            }
        }
        else {
            self.raiseDialog("Авторизация", "Для бронирования тренировки необходима авторизация. Перейти к авторизации/регистрации?", positive: "Да, пожалуйста", onPositive: { _ in
                let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
                self.navigationController?.viewControllers[0] = vc
                self.navigationController?.popToRootViewController(animated: true)
            }, negative: "Нет, не сейчас", onNegative: { _ in })
        }
    }
}

class ScheduleItem: UITableViewCell {
    @IBOutlet weak var dateTime: UILabel!
    @IBOutlet weak var itemTitle: UILabel!
}
