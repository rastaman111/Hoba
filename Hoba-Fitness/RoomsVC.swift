import UIKit
import APESuperHUD
import Alamofire
import SwiftyJSON
import YandexMobileMetrica

final class InitialVC: UIViewController, MenuDelegate {
    var easySlideNavigationController: ESNavigationController?
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var listContainer: UIView!
    
    @IBOutlet weak var viewSelector: UISegmentedControl!
    
    var listVC: RoomsListVC?
    var mapVC: RoomsMapVC?
    
    let group = DispatchGroup()
    ///var jsonListFull: [JSON] = []
    ///var jsonListFiltered: [JSON] = []
    var errorOnLoading = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
        //let params : [String : Any] = ["Выбор зала": "true"]
        YMMYandexMetrica.reportEvent("Выбор зала", parameters: [:])
        
        //print("---", App.this.userJWT)
        
        /// UI
        self.navigationItem.setHidesBackButton(true, animated:true);
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.title = "Выберите зал"
        self.navigationController?.navigationBar.topItem?.title = ""

        (UIApplication.shared.delegate as! AppDelegate).notificationCenter.getPendingNotificationRequests(completionHandler: {
            requests in
            print(requests)
        })
        
        //////////////
        /*
        if !App.this.userPhoneConfirmed {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPhone") as! Init_0_PhoneVC
            self.navigationController?.pushViewController(vc, animated: false)
        }
        else if !App.this.userInfoWasSet {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPersonalInfo") as! Init_2_PersonalInfoVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if App.this.userTariffId == TARIFF_NOT_SET && App.this.freeTrains == 0 {
            let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs") as! TariffsVC
            vc.dismissOnTariffSelected = false
            vc.callPaidVCThen = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if App.this.userCardDigits.isEmpty {
            let vc = UIStoryboard(name: "Booking", bundle: nil).instantiateViewController(withIdentifier: "BookingPaymentCard") as! Init_3_LinkCardVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if (App.this.userTariffId == TARIFF_NOT_SET) && (App.this.freeTrains == 0) {
            let vc = UIStoryboard(name: "Tariffs", bundle: nil).instantiateViewController(withIdentifier: "Tariffs") as! TariffsVC
            vc.titleVisible = true
            vc.callPaidVCThen = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        */
        //////////////

        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        ///self.navigationController?.navigationBar.barTintColor = App.DEBUG ? .red : .black
        
        self.setMenuButton()

        loadData()

        /// attaching list
        listVC = (storyboard!.instantiateViewController(withIdentifier: "RoomsList") as! RoomsListVC)
        listVC?.parentVC = self
        addChild(listVC!)
        listVC!.view.translatesAutoresizingMaskIntoConstraints = false
        listContainer.addSubview(listVC!.view)
        
        NSLayoutConstraint.activate([
            listVC!.view.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor, constant: 0),
            listVC!.view.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor, constant: 0),
            listVC!.view.topAnchor.constraint(equalTo: mapContainer.topAnchor, constant: 0),
            listVC!.view.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor, constant: 0)
            ])
        listVC!.didMove(toParent: self)
        
        /// attaching map
        mapVC = (storyboard!.instantiateViewController(withIdentifier: "RoomsMap") as! RoomsMapVC)
        mapVC?.parentVC = self
        mapVC?.viewFrame = mapContainer.frame
        
        addChild(mapVC!)
        mapVC!.view.translatesAutoresizingMaskIntoConstraints = false
        mapContainer.addSubview(mapVC!.view)
        
        NSLayoutConstraint.activate([
            mapVC!.view.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor, constant: 0),
            mapVC!.view.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor, constant: 0),
            mapVC!.view.topAnchor.constraint(equalTo: mapContainer.topAnchor, constant: 0),
            mapVC!.view.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor, constant: 0)
            ])
        mapVC!.didMove(toParent: self)

        ///
        if !App.this.onboardingWasShown {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "OnboardingNavi")
            self.present(vc, animated: true)
        }
    }

    @objc func loadData() {
        errorOnLoading = false
        
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Загружаем...")
        
        /// loading rooms list
        group.enter()
        
        Alamofire.request("\(App.BASEURL)/rooms", method: .post, parameters: [:], encoding: "", headers: hdrs()).responseJSON {
            response in
            if let data = response.result.value {
                ///print(App.this.userInfo)
                ///self.jsonListFull = JSON(data).arrayValue
                App.this.rooms = JSON(data)
            }
            else {
                self.errorOnLoading = true
            }
            self.group.leave()
        }

        /// refreshing jwt key
        if !App.this.userJWT.isEmpty && App.this.userJWTExpiration < Int(Date().timeIntervalSince1970) {
            group.enter()
            Alamofire.request("\(App.BASEURL)/refreshkey/", method: .post, parameters: [:], encoding: "", headers: hdrs()).responseJSON {
                response in
                if let data = response.result.value {
                    let json = JSON(data)
                    App.this.userJWT = json["jwtkey"].stringValue
                    App.this.userJWTExpiration = Int(Date().timeIntervalSince1970) +
                        (json["expiration"].intValue * 86400)
                }
                else {
                    self.errorOnLoading = true
                }
                self.group.leave()
            }
        }
        
        /// loading user info
        group.enter()
        loadClientState(completion: {
            json in
            self.errorOnLoading = json.isEmpty
            self.group.leave()            
        })
        
        /// Loading is done
        group.notify(queue: .main) {
            APESuperHUD.dismissAll(animated: true)
            
            if self.errorOnLoading {
                App.this.userTariff = App.this.tariffs.arrayValue.first { $0["id"].intValue == App.this.userTariffId } ?? JSON()
                let alert = UIAlertController(title: "Увы!", message: "Не удалось загрузить данные. Повторите попытку.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Повторить", style: .cancel, handler: {
                    action in
                    self.loadData()
                }))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                self.listVC?.updateData(json: App.this.rooms.arrayValue)
                self.mapVC?.updateMap(json: App.this.rooms.arrayValue)
            }
        }
    }
    
    func currentTariffIsActive() -> Bool {
        return App.this.tariffs.arrayValue
            .first(where: { $0["id"].intValue == App.this.userTariffId })?["active"].boolValue ?? false
    }
    
    @IBAction func viewChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 { // list
            UIView.animate(withDuration: 0.1, animations: {
                self.listContainer.alpha = 1.0
                self.mapContainer.alpha = 0
            })
        }
        else {
            UIView.animate(withDuration: 0.1, animations: {
                self.listContainer.alpha = 0
                self.mapContainer.alpha = 1.0
            })
        }
    }
    
    func loadSchedule(id: Int) {
        App.this.loadSchedule(fromVC: self, id: id, forChange: false, changeTrain: SingleTrain())
    }
    
    @IBAction func openChat(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Chat") as! ChatVC
        self.present(vc, animated: true)
    }
}
