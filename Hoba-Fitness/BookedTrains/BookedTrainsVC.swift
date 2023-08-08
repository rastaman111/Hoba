import UIKit
import Alamofire
import SwiftyJSON
import APESuperHUD
import YandexMobileMetrica

final class BookedTrainsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MenuDelegate {
    // MARK: - Properties
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var easySlideNavigationController: ESNavigationController?
    
    var labelDays: UILabel?
    var labelHours: UILabel?
    var labelMins: UILabel?
    var labelSecs: UILabel?
    var labelTitle: UILabel?
    var labelContainer: UIView?
    
    var selectedIndex: Int = 0
    var selectedTimeStamp: TimeInterval = 0
    
    var localTime: Int = 0
    var timeScaleStep = 1 // # secs in 1
    var timer: Timer?
    
    var trainState: TrainState = .waitForTrain
    
    ///
    var updatePeriod = 10
    var updateCounter = 0
    var canUpdate = true
    
    let center = UNUserNotificationCenter.current()
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UIView!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Обновляем...")
        checkUpdates(completion: { _ in
            APESuperHUD.dismissAll(animated: true)
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reportEvent("Мои тренировки", [:])
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTable), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        /// UI
        self.navigationItem.setHidesBackButton(true, animated:true);
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.title = "Мои тренировки"
        self.setMenuButton()
        
        ///
        timeScaleStep = App.DEBUG ? App.this.TIMESTEP : 1
        localTime = Int(Date().localSeconds())
        
        if App.this.storedTrains.count > 0 {
            selectedTimeStamp = TimeInterval(App.this.storedTrains[0].startsAt)
        }
        fireTimer()
        
        selectedIndex = selectedIndex >= App.this.storedTrains.count ? 0 : selectedIndex
        trainState = .waitForTrain
        tableView.reloadData()
        
        ///
        
        center.getPendingNotificationRequests { (notifications) in
            print("~~~ Count: \(notifications.count)")
            for item in notifications {
                print("!!!", item.identifier, item.content, item.content.title)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    // MARK: - Foreground \ Background
    @objc func appMovedToBackground() {
        stopTimer()
    }
    
    @objc func appMovedToForeground() {
        fireTimer()
    }
    
    
    // MARK: - IBActions
    @IBAction func openRooms(_ sender: Any) {
        
        /*let vc = App.this.userInfoWasSet
         ? UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
         : UIStoryboard(name: "NewOrExisting", bundle: nil).instantiateViewController(withIdentifier: "NewOrExisting")
         self.navigationController?.viewControllers[0] = vc
         self.navigationController?.popToRootViewController(animated: true)*/
        
        /*if App.this.userInfoWasSet {
         let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
         if let slideController = self.easySlideNavigationController {
         slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: false)
         }
         }
         else {
         let vc = UIStoryboard(name: "NewOrExisting", bundle: nil).instantiateViewController(withIdentifier: "NewOrExisting")
         if let slideController = self.easySlideNavigationController {
         slideController.setBodyViewController(vc, closeOpenMenu: true, ignoreClassMatch: false)
         }
         }*/
        
        let vc = UIStoryboard(name: "SelectStarterTrain", bundle: nil).instantiateViewController(withIdentifier: "SelectStarterTrain")
        self.navigationController?.viewControllers[0] = vc
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Data processing
    @objc func updateTable() {
        self.tableView.reloadData()
    }
    
    // MARK: -  Timer
    func fireTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                         selector: #selector(self.tickTimer(timer:)),
                                         userInfo: nil, repeats: true)
            timer?.fire()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func displayCounter(time: TimeInterval) {
        if selectedIndex < App.this.storedTrains.count && App.this.storedTrains[selectedIndex].isNotFinished() {
            labelDays?.text = "00"
            labelHours?.text = "00"
            labelMins?.text = "00"
            labelSecs?.text = "00"
            labelTitle?.text = "Тренировка НЕ ЗАВЕРШЕНА"
        }
        else if time > 0 {
            let (days, hours, mins, secs) = secondsToDays(seconds: time)
            labelDays?.text = String(format: "%02d", days)
            labelHours?.text = String(format: "%02d", hours)
            labelMins?.text = String(format: "%02d", mins)
            labelSecs?.text = String(format: "%02d", secs)
            
        }
        else {
            labelDays?.text = "00"
            labelHours?.text = "00"
            labelMins?.text = "00"
            labelSecs?.text = "00"
            labelTitle?.text = "До завершения тренировки"
        }
    }
    
    @objc func tickTimer(timer: Timer) {
        if updateCounter < updatePeriod {
            updateCounter += 1
        }
        else {
            updateCounter = 0
            if canUpdate {
                canUpdate = false
                checkUpdates(completion: { _ in
                    self.canUpdate = true
                    self.tableView.reloadData()
                })
            }
        }
        
        if App.this.storedTrains.count > 0 {
            /*
             if App.this.storedTrains.count == 0 {
             stopTimer()
             return
             }
             */
            
            if selectedIndex >= App.this.storedTrains.count {
                selectedIndex = 0
                tableView.reloadData()
            }
            
            let thisTrain = App.this.storedTrains[selectedIndex]
            
            if thisTrain.startsAt == 0 {
                showCounter(diff: 0)
                trainState = .trainFinished
                labelTitle?.text = "Тренировка завершена"
                labelContainer?.backgroundColor = .gray
            } else {
                let timeDiff: Int = (thisTrain.startsAt - MIN_10) - Int(Date().localSeconds())
                
                /// ДО тренировки
                if timeDiff > 0 {
                    showCounter(diff: timeDiff + MIN_10)
                    trainState = .waitForTrain
                    labelTitle?.text = "До тренировки осталось"
                    labelContainer?.backgroundColor = colorTrainWaiting
                }
                
                /// время ВНУТРИ сессии: 10 мин переодевание, 60 мин треня, 10 мин переодевание
                if timeDiff <= 0 && timeDiff >= -MIN_80 {
                    // ставим заголовки-картинки в зависимости от стадии сессии
                    let stage: Int = -timeDiff / MIN_10
                    
                    switch stage {
                    case 0:
                        labelTitle?.text = "До тренировки осталось"
                        showCounter(diff: MIN_10 + timeDiff)
                        labelContainer?.backgroundColor = colorTrainFirstChange
                        if trainState != .firstChangeClothes {
                            trainState = .firstChangeClothes
                            //appDelegate.fireNotification(title: "Начало тренировки", msg: "Вы можете войти в зал.")
                        }
                    case 1, 2, 3, 4:
                        trainState = .trainTime
                        labelTitle?.text = "До конца осталось"
                        showCounter(diff: MIN_60 + MIN_10 + timeDiff)
                        labelContainer?.backgroundColor = colorTrainTime
                    case 5, 6:
                        labelTitle?.text = "Скоро завершение"
                        showCounter(diff: MIN_60 + MIN_10 + timeDiff)
                        labelContainer?.backgroundColor = colorTrainCloseToEnd
                        if trainState != .trainToEnd {
                            trainState = .trainToEnd
                            //appDelegate.fireNotification(title: "Скоро завершение", msg: "Скоро тренировка закончится.")
                        }
                    case 7:
                        labelTitle?.text = "Время для выхода"
                        showCounter(diff: MIN_60 + MIN_10 + MIN_10 + timeDiff)
                        labelContainer?.backgroundColor = colorTrainFirstChange
                        if trainState != .secondChangeClothes {
                            trainState = .secondChangeClothes
                            //appDelegate.fireNotification(title: "Тренировка закончена", msg: "Время для выхода")
                        }
                    default:
                        break
                    }
                }
                
                /// время ВЫШЛО и треня НЕ завершена
                if timeDiff < -MIN_80 && thisTrain.isNotFinished() {
                    showCounter(diff: 0)
                    labelTitle?.text = "ВЫЙТИ ИЗ ЗАЛА"
                    labelContainer?.backgroundColor = colorTrainNotFinished
                    
                    if trainState != .trainNotFinished {
                        trainState = .trainNotFinished
                        raiseAlert("Оплаченное время тренировки вышло", "За каждые полчаса сверх времени тренировки списывается сумма по тарифу. Зайдите в тренировку и завершите ее.", "Понятно")
                    }
                }
                
                /// время ВЫШЛО и треня завершена
                if timeDiff < -MIN_80 && !thisTrain.isNotFinished() {
                    showCounter(diff: 0)
                    labelTitle?.text = "Тренировка ЗАВЕРШЕНА"
                    labelContainer?.backgroundColor = .gray
                    /// clear finished trains
                    ///            if !App.this.DEBUG {
                    var buf: [SingleTrain] = []
                    for train in App.this.storedTrains {
                        if !train.isFinished(local: localTime) {
                            buf.append(train)
                        }
                    }
                    App.this.storedTrains = buf
                    tableView.reloadData()
                    ///            }
                }
            }
        }
        
        localTime += timeScaleStep
    }
    
    func showCounter(diff: Int) {
        if diff > 0 {
            let (days, hours, mins, secs) = secondsToDays(seconds: TimeInterval(diff))
            labelDays?.text = String(format: "%02d", days)
            labelHours?.text = String(format: "%02d", hours)
            labelMins?.text = String(format: "%02d", mins)
            labelSecs?.text = String(format: "%02d", secs)
        }
        else {
            labelDays?.text = "00"
            labelHours?.text = "00"
            labelMins?.text = "00"
            labelSecs?.text = "00"
        }
    }
    
    @IBAction func openWorkout(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Workout", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Workout") as! WorkoutVC
        vc.thisTrain = App.this.storedTrains[sender.tag]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Table funcs
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        emptyLabel.isHidden = App.this.storedTrains.count > 0
        tableView.isHidden = !emptyLabel.isHidden
        return App.this.storedTrains.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainItem", for: indexPath as IndexPath) as! TrainItem
        
        /// set selected bg color
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(argb: 0xff383536)
        cell.selectedBackgroundView = bgColorView
        
        cell.placeAddress.text = App.this.storedTrains[indexPath.row].address
        cell.trainDateTime.text = App.this.storedTrains[indexPath.row].trainTime
        cell.textDescription.text = App.this.storedTrains[indexPath.row].textDescription
        cell.openWorkoutButton.tag = indexPath.row
        
        if selectedIndex == indexPath.row {
            // assign visible counts
            labelDays = cell.countDays
            labelHours = cell.countHours
            labelMins = cell.countMins
            labelSecs = cell.countSecs
            labelTitle = cell.countTitle
            labelContainer = cell.contentContainer
            // show initial vals
            
            tickTimer(timer: timer!)
            cell.counterContainerHC.constant = 80
        }
        else {
            cell.contentContainer.backgroundColor = .clear
            cell.counterContainerHC.constant = 0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let tappedTrain = App.this.storedTrains[indexPath.row]
        
        let deleteTitle = NSLocalizedString("Удалить", comment: "Удалить")
        let deleteAction = UITableViewRowAction(style: .destructive, title: deleteTitle) {
            (action, indexPath) in
            let alert = UIAlertController(title: "Отмена тренировки", message: "Вы хотите отменить тренировку в \(tappedTrain.address),\n\(tappedTrain.trainTime) ?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Да, хочу", style: .default, handler: {
                action in
                
                ///
                let body: [String : Any] = [ "action": "refund", "uuid": tappedTrain.uid, "email": App.this.userMail]
                APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отменяем...")
                cancelTrain(body, completion: { json, response in
                    APESuperHUD.dismissAll(animated: true)
                    if response.result.isSuccess {
                        removeTrain(idx: indexPath.row)
                        tableView.reloadData()
                        self.raiseAlert(TRAIN_CANCEL, TRAIN_CANCEL_SENT_MSG, "Хорошо")
                    }
                    else {
                        self.raiseAlert("Увы!", "Не удалось отправить запрос на отмену. Повторите попытку позже.", "Понятно")
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        deleteAction.backgroundColor = .red
        
        let transferTitle = NSLocalizedString("Перенести", comment: "Перенести")
        let transferAction = UITableViewRowAction(style: .normal, title: transferTitle) {
            (action, indexPath) in
            let alert = UIAlertController(title: "Перенос тренировки", message: "Вы хотите перенести тренировку на другое время?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Да, хочу", style: .default, handler: {
                action in
                
                App.this.loadSchedule(fromVC: self, id: tappedTrain.roomId, forChange: true, changeTrain: tappedTrain)
                
            }))
            alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        transferAction.backgroundColor = colorActiveGreen
        
        //return [transferAction, deleteAction]
        return [deleteAction]
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let tappedTrain = App.this.storedTrains[indexPath.row]
        
        ///
        let deleteAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let alert = UIAlertController(title: "Отмена тренировки", message: "Вы хотите отменить тренировку в \(tappedTrain.address),\n\(tappedTrain.trainTime) ?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Да, хочу", style: .default, handler: {
                action in
                
                reportEvent("Отмена", [:])
                
                ///
                let body: [String : Any] = [ "action": "refund", "uuid": tappedTrain.uid, "email": App.this.userMail]
                APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отменяем...")
                cancelTrain(body, completion: { json, response in
                    APESuperHUD.dismissAll(animated: true)
                    if response.result.isSuccess {
                        removeTrain(idx: indexPath.row)
                        tableView.reloadData()
                        self.raiseAlert(TRAIN_CANCEL, TRAIN_CANCEL_SENT_MSG, "Хорошо")
                    }
                    else {
                        self.raiseAlert("Увы!", "Не удалось отправить запрос на отмену. Повторите попытку позже.", "Понятно")
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            success(true)
        })
        deleteAction.image = UIImage(named: "iconTrashCan")
        deleteAction.backgroundColor = .red
        
        ///
        let editAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let alert = UIAlertController(title: "Перенос тренировки", message: "Вы хотите перенести тренировку на другое время?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Да, хочу", style: .default, handler: {
                action in
                
                reportEvent("Перенос", [:])
                App.this.loadSchedule(fromVC: self, id: tappedTrain.roomId, forChange: true, changeTrain: tappedTrain)
            }))
            alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            success(true)
        })
        editAction.image = UIImage(named: "iconChangeSchedule")
        editAction.backgroundColor = colorActiveGreen
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

class TrainItem: UITableViewCell {
    @IBOutlet weak var contentContainer: UIView!
    
    @IBOutlet weak var countTitle: UILabel!
    @IBOutlet weak var placeAddress: UILabel!
    @IBOutlet weak var trainDateTime: UILabel!
    @IBOutlet weak var counterContainerHC: NSLayoutConstraint!
    @IBOutlet weak var openWorkoutButton: UIButton!
    @IBOutlet weak var textDescription: UILabel!
    
    @IBOutlet weak var countDays: UILabel!
    @IBOutlet weak var countHours: UILabel!
    @IBOutlet weak var countMins: UILabel!
    @IBOutlet weak var countSecs: UILabel!
}
