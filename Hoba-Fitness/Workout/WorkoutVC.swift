import UIKit
import SwiftyJSON
import Alamofire
import APESuperHUD
import YandexMobileMetrica

final class WorkoutVC: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var workoutVC: WorkoutVC?
    
    @IBOutlet weak var diagramContainerView: UIView!
    
    var extendedWorkout = false
    
    /// Graphic assets
    var arcs: [ArcView] = []

    var arcPercents: [CGFloat] = []
    var arcInactiveColors: [UIColor] = []
    var arcActiveColors: [UIColor] = []
    
    @IBOutlet weak var dial_60: UIView!
    @IBOutlet weak var dial_90: UIView!
    
    ///
    var WORKOUT_TIME = MIN_60
    var WORKOUT_TIME_FULL = MIN_80
    var FILL_PERCENTAGE = FILL_PERCENTAGE_60
    var ONESECONARC: CGFloat = 0
    
    ///
    @IBOutlet weak var hintImage: UIImageView!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var helperBtn: UIButton!
    @IBOutlet weak var singleBtn: UIButton!
    
    ///
    @IBOutlet weak var counterWearTitleImg: UIImageView!
    @IBOutlet weak var counterTitle: UILabel!
    @IBOutlet weak var counterDays: UILabel!
    @IBOutlet weak var counterDaysWC: NSLayoutConstraint!
    @IBOutlet weak var counterDaysSubtitle: UILabel!
    @IBOutlet weak var counterDaysDiv: UILabel!
    @IBOutlet weak var counterHours: UILabel!
    @IBOutlet weak var counterMins: UILabel!
    @IBOutlet weak var counterSecs: UILabel!
    
    ///
    var timer: Timer = Timer()
    var trainState: TrainState = .waitForTrain
    var timeScaleStep = 1 // # secs in 1
    var thisTrain: SingleTrain?
    
    var timeFromStart: TimeInterval = TimeInterval()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareArcs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reportEvent("Тренировка", [:])

        workoutVC = self

        if thisTrain?.slots.count == 3 { // расширенная тренировка 1.5 часа \ абонемент
            extendedWorkout = true
        }

        if extendedWorkout {
            FILL_PERCENTAGE = 7 //FILL_PERCENTAGE_90
            arcPercents = arcPercents_90
            arcInactiveColors = arcInactiveColors_90
            arcActiveColors = arcActiveColors_90
            WORKOUT_TIME = MIN_90
            WORKOUT_TIME_FULL = MIN_110
            dial_60.isHidden = true
            dial_90.isHidden = false
        }
        else {
            FILL_PERCENTAGE = FILL_PERCENTAGE_60
            arcPercents = arcPercents_60
            arcInactiveColors = arcInactiveColors_60
            arcActiveColors = arcActiveColors_60
            WORKOUT_TIME = MIN_60
            WORKOUT_TIME_FULL = MIN_80
            dial_60.isHidden = false
            dial_90.isHidden = true
        }
        ONESECONARC = FILL_PERCENTAGE / CGFloat(TIMEPERIOD)
        
        ///
        timeScaleStep = App.DEBUG ? App.this.TIMESTEP : 1
        AppDelegate.localTime = Int(Date().localSeconds())
        
        /// UI
        self.setBackButton()
        self.prepareArcs()
        self.title = thisTrain?.trainTime
        singleBtn.isHidden = true
        
        ///
        fireTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.prepareArcs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopTimer()
    }
    
    /// Timer
    func fireTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.tickTimer(timer:)), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func stopTimer() {
        AppDelegate.localTime = Int(Date().localSeconds())
        timeFromStart = 0
        clearArcs()
        UIView.transition(with: self.counterWearTitleImg, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.counterWearTitleImg.image = UIImage(named: "clockTitle")
        }, completion: nil)
        timer.invalidate()
    }
    
    func updateCounter(diff: Int) {
        if diff > 0 {
            let (days, hours, mins, secs) = secondsToDays(seconds: TimeInterval(diff))
            if days > 0 {
                counterDaysWC.constant = 40
                counterDays.text = String(format: "%02d", days)
                counterDaysSubtitle.isHidden = false
                counterDaysDiv.isHidden = false
            }
            else {
                counterDaysWC.constant = 0
                counterDaysSubtitle.isHidden = true
                counterDaysDiv.isHidden = true
            }
            
            counterHours.text = String(format: "%02d", hours)
            counterMins.text = String(format: "%02d", mins)
            counterSecs.text = String(format: "%02d", secs)
        }
        else {
            counterDaysWC.constant = 0
            counterDaysSubtitle.isHidden = true
            counterDaysDiv.isHidden = true
            
            counterHours.text = "00"
            counterMins.text = "00"
            counterSecs.text = "00"
        }
    }
    
    @objc func tickTimer(timer: Timer) {
        self.prepareArcs()
        
        /// за 10 мин до старта трени начинается переодевание
        let timeToTrain: Int = (thisTrain?.startsAt)! - MIN_10
        let timeDiff: Int = timeToTrain - AppDelegate.localTime
        
        /// ДО тренировки
        if timeDiff > 0 {
            updateCounter(diff: timeDiff + MIN_10)
            trainState = .waitForTrain
            self.hintImage.image = UIImage(named: "hintBeforeTrain")
            counterTitle.text = "До начала осталось"
            
            self.drawButton(self.actionBtn, "Войти в зал", self.BTN_ACTION)
        }
        
        /// время ВНУТРИ сессии: 10 мин переодевание, 60 мин треня, 10 мин переодевание
        if timeDiff <= 0 && timeDiff >= -WORKOUT_TIME_FULL {
            
            /// ставим заголовки-картинки в зависимости от стадии сессии
            let stage: Int = -timeDiff / MIN_10
            
            if extendedWorkout {
                switch stage {
                case 0:
                    if trainState != .firstChangeClothes {
                        trainState = .firstChangeClothes
                        appDelegate.fireNotification(title: "Начало тренировки", msg: "Вы можете войти в зал.")
                    }
                    self.counterWearTitleImg.image = UIImage(named: "clockTitleActive")
                    self.trainState = .firstChangeClothes
                    counterTitle.text = "До начала осталось"
                    updateCounter(diff: MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    if doorWasOpened(forTrainId: thisTrain!.uid) {
                        self.hintImage.image = UIImage(named: "hintTrainTime")
                    }
                    else {
                        self.hintImage.image = UIImage(named: "hintOpenDoor")
                    }
                    
                case 1, 2, 3, 4, 5, 6, 7:
                    //self.hintImage.image = UIImage(named: "hintTrainTime")
                    trainState = .trainTime
                    counterTitle.text = "До конца осталось"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                        if doorWasOpened(forTrainId: thisTrain!.uid) {
                        self.hintImage.image = UIImage(named: "hintTrainTime")
                    }
                    else {
                        self.hintImage.image = UIImage(named: "hintOpenDoor")
                    }

                    
                case 8, 9:
                    self.hintImage.image = UIImage(named: "hintTimeEnds")
                    if trainState != .trainToEnd {
                        trainState = .trainToEnd
                        appDelegate.fireNotification(title: "Скоро завершение", msg: "Скоро тренировка закончится.")
                    }
                    
                    counterTitle.text = "До конца осталось"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                case 10:
                    self.counterWearTitleImg.image = UIImage(named: "clockTitleActive")
                    self.hintImage.image = UIImage(named: "hintExit")
                    if trainState != .secondChangeClothes {
                        trainState = .secondChangeClothes
                        appDelegate.fireNotification(title: "Тренировка закончена", msg: "Время для выхода")
                    }
                    counterTitle.text = "Время для выхода"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                default:
                    self.counterWearTitleImg.image = UIImage(named: "clockTitle")
                }
            }
            else {
                switch stage {
                case 0:
                    if trainState != .firstChangeClothes {
                        trainState = .firstChangeClothes
                        appDelegate.fireNotification(title: "Начало тренировки", msg: "Вы можете войти в зал.")
                    }
                    self.counterWearTitleImg.image = UIImage(named: "clockTitleActive")
                    self.trainState = .firstChangeClothes
                    counterTitle.text = "До начала осталось"
                    updateCounter(diff: MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    if doorWasOpened(forTrainId: thisTrain!.uid) {
                        self.hintImage.image = UIImage(named: "hintTrainTime")
                    }
                    else {
                        self.hintImage.image = UIImage(named: "hintOpenDoor")
                    }
                    
                case 1, 2, 3, 4:
                    trainState = .trainTime
                    counterTitle.text = "До конца осталось"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                    if doorWasOpened(forTrainId: thisTrain!.uid) {
                        self.hintImage.image = UIImage(named: "hintTrainTime")
                    }
                    else {
                        self.hintImage.image = UIImage(named: "hintOpenDoor")
                    }

                    
                case 5, 6:
                    self.hintImage.image = UIImage(named: "hintTimeEnds")
                    if trainState != .trainToEnd {
                        trainState = .trainToEnd
                        appDelegate.fireNotification(title: "Скоро завершение", msg: "Скоро тренировка закончится.")
                    }
                    
                    counterTitle.text = "До конца осталось"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                case 7:
                    self.counterWearTitleImg.image = UIImage(named: "clockTitleActive")
                    self.hintImage.image = UIImage(named: "hintExit")
                    if trainState != .secondChangeClothes {
                        trainState = .secondChangeClothes
                        appDelegate.fireNotification(title: "Тренировка закончена", msg: "Время для выхода")
                    }
                    counterTitle.text = "Время для выхода"
                    updateCounter(diff: WORKOUT_TIME + MIN_10 + MIN_10 + timeDiff)
                    drawArcs(current: -timeDiff)
                    
                default:
                    self.counterWearTitleImg.image = UIImage(named: "clockTitle")
                }
            }
            
            /// раскрашиваем кнопки
            if doorWasOpened(forTrainId: thisTrain!.uid) {
                singleBtn.isHidden = true
                self.drawButton(self.actionBtn, "Завершить тренировку", self.BTN_ACTION)
                helperBtn.isHidden = false
                helperBtn.tag = 1 // смена назначения кнопки
                self.drawButton(self.helperBtn, "Открыть дверь", self.BTN_ACTION)
                view.addConstraint(NSLayoutConstraint(item: helperBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (view.frame.width / 2) - 24))
            }
            else {
                self.drawButton(self.singleBtn, "Войти в зал", self.BTN_ACCENTED)
                helperBtn.tag = 0 // смена назначения кнопки
            }
        }
        
        /// время ВЫШЛО
        if timeDiff <= -WORKOUT_TIME_FULL {
            trainState = .trainFinished
            updateCounter(diff: 0)
            counterTitle.text = "Тренировка завершена"
            
            UIView.transition(with: self.hintImage, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.hintImage.image = nil
            }, completion: nil)
            
            self.actionBtn.isHidden = false
            
            if (thisTrain?.isNotFinished())! {
                if trainState != .trainNotFinished {
                    trainState = .trainNotFinished
                    raiseAlert("Оплаченное время тренировки вышло", "За каждые полчаса сверх времени тренировки списывается сумма по тарифу.", "Понятно")
                }
                self.drawButton(self.actionBtn, "Выйти из зала", self.BTN_ACCENTED)
            }
            else {
                self.drawButton(self.actionBtn, "Завершить", self.BTN_ACTION)
            }
            
            stopTimer()
            return
        }
        
        ///
        AppDelegate.localTime += timeScaleStep
    }
    
    var delayCount = 3
    var delayTimer: Timer = Timer()
    var justOpenTheDoor: Bool = true
    
    func fireDelayTimer(justOpen: Bool) {
        justOpenTheDoor = justOpen
        delayCount = 3
        delayTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.tickDelayTimer(timer:)), userInfo: nil, repeats: true)
        delayTimer.fire()
    }
       
    func stopDelayTimer() {
        delayTimer.invalidate()
    }
    
    @objc func tickDelayTimer(timer: Timer) {
        if delayCount > 0 {
            APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Дверь откроется через \(delayCount) сек...")
        }
        else {
            APESuperHUD.dismissAll(animated: true)
            stopDelayTimer()
            if justOpenTheDoor {
                self.raiseAlert("Дверь открыта", "Дверь открыта.", "Ура")
            }
            else {
                self.raiseAlert("Открыть дверь", "Выход из зала открыт", "Ок", completion: { _ in self.openFeedback() })
            }
        }
        delayCount -= 1
    }

    /// Arcs
    func prepareArcs() {
        if self.viewIfLoaded?.window != nil {
            for view in diagramContainerView.subviews {
                if view is ArcView {
                    view.removeFromSuperview()
                }
            }
            
            for i in 0 ..< arcPercents.count {
                // draw bg arcs
                let bgArc : ArcView = ArcView()
                bgArc.frame = CGRect(x: 0, y: 0, width: COUNTERDIAGRAMWIDTH, height: COUNTERDIAGRAMWIDTH)
                bgArc.startPercentage = arcPercents[i]
                bgArc.fillPercentage = FILL_PERCENTAGE
                bgArc.color = arcInactiveColors[i]
                diagramContainerView.addSubview(bgArc)
                
                // prepare active arcs
                let activeArc : ArcView = ArcView()
                activeArc.frame = CGRect(x: 0, y: 0, width: COUNTERDIAGRAMWIDTH, height: COUNTERDIAGRAMWIDTH)
                activeArc.startPercentage = arcPercents[i]
                activeArc.fillPercentage = 0
                activeArc.color = arcActiveColors[i]
                diagramContainerView.addSubview(activeArc)
                arcs.append(activeArc)
            }
        }
    }
    
    func drawArcs(current: Int) {
        let currentPeriod = Int(current) / MIN_10
        let progress = Int(current) % MIN_10
        
        clearArcs()
        
        for i in 0 ..< min(currentPeriod, arcs.count) {
            let activeArc : ArcView = ArcView()
            activeArc.frame = CGRect(x: 0, y: 0, width: COUNTERDIAGRAMWIDTH, height: COUNTERDIAGRAMWIDTH)
            activeArc.startPercentage = arcPercents[i]
            activeArc.fillPercentage = FILL_PERCENTAGE
            activeArc.color = arcActiveColors[i]
            diagramContainerView.addSubview(activeArc)
            arcs[i] = activeArc
        }
 
        if currentPeriod < arcs.count {
            arcs[currentPeriod].removeFromSuperview()
            let activeArc : ArcView = ArcView()
            activeArc.frame = CGRect(x: 0, y: 0, width: COUNTERDIAGRAMWIDTH, height: COUNTERDIAGRAMWIDTH)
            activeArc.startPercentage = arcPercents[currentPeriod]
            activeArc.fillPercentage = ONESECONARC * CGFloat(progress)
            activeArc.color = arcActiveColors[currentPeriod]
            diagramContainerView.addSubview(activeArc)
            arcs[currentPeriod] = activeArc
        }
    }
    
    func clearArcs() {
        for i in 0 ..< arcs.count {
            arcs[i].removeFromSuperview()
        }
    }
    
    /// UI
    func setUIDoorOpened() {
        saveDoorState(opened: false, forKey: self.thisTrain!.uid)
        
        self.drawButton(self.actionBtn, "Выйти из зала", self.BTN_ACCENTED)
        
        raiseAlert("Открыть дверь", "Выход из зала открыт", "Ок", completion: { _ in
            switch self.trainState {
            case .secondChangeClothes, .trainFinished:
                self.openFeedback()
            default:
                self.workoutVC?.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    /// Actions
    @IBAction func actionTap(_ sender: UIButton) {
        switch trainState {
        case .trainFinished:
            if doorWasOpened(forTrainId: thisTrain!.uid) {
               self.finishTrain { _ in }
            }
            else {
                self.navigationController?.popViewController(animated: true)
            }
        case .waitForTrain:
            self.raiseAlert("Извините", "Тренировка еще не началась.", "Понятно")
        default:
            if doorWasOpened(forTrainId: thisTrain!.uid) {
                self.finishTrain { _ in }
            }
            else {
                reportEvent("Вход в зал", [:])
                openLock { _ in }
            }
        }
    }
    
    @IBAction func helperTap(_ sender: UIButton) {
        if sender.tag == 1 {
            self.raiseDialog("Открыть дверь", "Хотите открыть дверь? Тренировка не будет завершена.", positive: "Да, хочу", onPositive: { _ in
                self.openLock(completion: { _ in })
            }, negative: "Нет, не надо", onNegative: {_ in})
        }
        else {
            let alert = UIAlertController(title: "Отмена/перенос", message: "Вы хотите отменить или перенести тренировку?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Отменить", style: .default, handler: {
                action in
                reportEvent("Отмена", [:])
                
                let body: [String : Any] = [ "action": "refund", "uuid": self.thisTrain!.uid, "email": App.this.userMail]
                APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отменяем...")
                cancelTrain(body, completion: { json, response in
                    APESuperHUD.dismissAll(animated: true)
                    if response.result.isSuccess {
                        removeTrain(id: self.thisTrain!.uid)
                        let alert = UIAlertController(title: "Отмена тренировки", message: "Запрос на отмену тренировки отправлен. Средства будут возвращены в соответствии с правилами.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Хорошо", style: .default, handler: {
                            action in
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self.raiseAlert("Увы!", "Не удалось отправить запрос на отмену. Повторите попытку позже.", "Понятно")
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Перенести", style: .default, handler: {
                action in
                reportEvent("Перенос", [:])
                App.this.loadSchedule(fromVC: self, id: self.thisTrain!.roomId, forChange: true, changeTrain: self.thisTrain!)
            }))
            alert.addAction(UIAlertAction(title: "Нет, не надо", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openFeedback() {
        let storyboard = UIStoryboard(name: "Feedback", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Feedback") as! FeedbackVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openLock(completion: @escaping (_ response: DataResponse<Any>) -> Void) {
        let json = "{\"uuid\": \"\(thisTrain?.uid ?? "")\",\"action\": \"openlock\"}"
        Alamofire.request("\(App.BASEURL)/openlock", method: .post, parameters: [:], encoding: json, headers: hdrs())
            .responseJSON {
                response in
                let statusCode = response.response?.statusCode ?? 0
                if statusCode == 200 || statusCode == 201 || App.DEBUG {
                    saveDoorState(opened: true, forKey: self.thisTrain!.uid)
                    self.drawButton(self.actionBtn, "Выйти из зала", self.BTN_ACCENTED)
                    //self.fireDelayTimer(justOpen: true)
                    if let data = response.result.value {
                        let jsonResponse = JSON(data)
                        
                        self.raiseAlert("Открыть дверь", "Введите код замка: \(jsonResponse["codelock"].stringValue) и нажмите #", "Ура")
                    }
                }
                else {
                    self.raiseAlert("Увы!", "Извините, не удалось открыть дверь. Повторите попытку позже.", "Понятно")
                }
                completion(response)
        }
    }
    
    func finishTrain(completion: @escaping (_ response: DataResponse<Any>) -> Void) {
        self.raiseDialog("Хотите завершить тренировку?", LEAVE_ROOM_MSG, positive: "Да, хочу", onPositive: { _ in
            reportEvent("Выход из зала", [:])
            
            let json = "{\"uuid\": \"\(self.thisTrain?.uid ?? "")\",\"action\": \"finish\"}"
            Alamofire.request("\(App.BASEURL)/openlock", method: .post, parameters: [:], encoding: json, headers: hdrs())
                .responseJSON {
                    response in
                    let statusCode = response.response?.statusCode ?? 0
                    if statusCode == 200 || statusCode == 201 || App.DEBUG {
                        removeTrain(id: self.thisTrain!.uid)
                        saveDoorState(opened: false, forKey: self.thisTrain!.uid)
                        self.drawButton(self.actionBtn, "Выйти из зала", self.BTN_ACCENTED)
                        //self.fireDelayTimer(justOpen: false)
                        if let data = response.result.value {
                            let jsonResponse = JSON(data)
                            self.raiseAlert("Открыть дверь", "Введите код замка: \(jsonResponse["codelock"].stringValue) и нажмите #", "Ура", completion: { _ in
                                self.openFeedback()
                            })
                        }
                    }
                    else {
                        self.raiseAlert("Увы!", "Произошла ошибка. Повторите попытку позже.", "Понятно")
                    }

                    completion(response)
            }
            
        }, negative: "Нет, не надо", onNegative: {_ in})
    }
    
    let BTN_ACCENTED = 0
    let BTN_ACTION = 1
    let BTN_HIDDEN = 3
    
    func drawButton(_ btn: UIButton, _ title: String, _ state: Int) {
        switch state {
        case BTN_ACTION:
            btn.isHidden = false
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(argb: 0xff383536).cgColor
            btn.backgroundColor = .clear
        case BTN_ACCENTED:
            btn.isHidden = false
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(argb: 0xff92B907).cgColor
            btn.backgroundColor = UIColor(argb: 0xff92B907)
        default:
            btn.isHidden = true
        }
    }
}
