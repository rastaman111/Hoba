import UIKit
import SwiftyJSON
import APESuperHUD
import Alamofire

final class App {
    // MARK: - Debugging stuff
    var TIMESTEP = 1 //40
    static let DEBUG = false        // !!!!!
    static let DEBUGTOKEN = false   // !!!!!
    static var STATICTOKEN = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIrNzk3NzUxNTUxMjEiLCJpYXQiOjE2MTUyMjgyMTgsImlzcyI6InJ1LmhvYmEifQ.2xS7cOLmJ-DNOeIvM3uT6ZKdyikMtZCbjOTzdrQoyfLLCsavO1gMPv31DzHlUsthW5BIWXLUV5vLFhp5yza73w"

    static let TESTURL = "https://android.test.hoba.fit"
    static let PRODURL = "https://android.hoba.fit"
    static var BASEURL = DEBUG ? App.TESTURL : App.PRODURL

    let PAYMENTKEY = "live_Nzc5Mjk4XSqjR3Q10O-HZDQlOgv3A_scZ1jpLjMvzFQ"

    // MARK: - Properties
    static let this = App()

    ///static var popToRoot = false

    var slideNavigationController: SlideNavigationController?
    
    // MARK: - Trains
    var bookedTrain = SingleTrain()

    var selectedTimeSlot = NOTSELECTED
        
    var reservedRoom: String = "Варшавское шоссе, 141, корпус 10" /*{
        get {
            return UserDefaults.standard.string(forKey: "selectedRoom") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedRoom")
            UserDefaults.standard.synchronize()
        }
    }*/

    var reservedRoomId: Int = 32 /*{
        get {
            return UserDefaults.standard.integer(forKey: "reservedRoomId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "reservedRoomId")
            UserDefaults.standard.synchronize()
        }
    }*/

    var reservedDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "reservedDate") as? Date ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "reservedDate")
            UserDefaults.standard.synchronize()
        }
    }
    
    var reservedIntervalStart: Int {
        get {
            return UserDefaults.standard.integer(forKey: "reservedIntervalStart")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "reservedIntervalStart")
            UserDefaults.standard.synchronize()
        }
    }

    var reservedIntervalEnd: Int {
        get {
            return UserDefaults.standard.integer(forKey: "reservedIntervalEnd")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "reservedIntervalEnd")
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - User data
    static var authUser = false
    
    var freeTrainsAvail: Bool {
        get {
            //return true
            return userInfoWasSet ? userInfo["countfree"].intValue > 0 : true
        }
    }
    
    var freeTrains: Int {
        get {
            //return 0
            return userInfo["countfree"].intValue
        }
    }

    var activeAbonement: Bool {
        get {
            for u in userInfo["unlimtarif"].arrayValue {
                if u["idtarif"].intValue == userTariff["id"].intValue
                    //&& u["active"].boolValue
                    && Date.from(string: u["enddate"].stringValue, with: "yyyy-MM-dd")! >= Date()
                    && userTariff["tariftype"].intValue == TARIFF_ABONEMENT {
                    return true
                }
            }

            return false
        }
    }

    var onboardingWasShown: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "onboardingWasShown")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "onboardingWasShown")
            UserDefaults.standard.synchronize()
        }
    }

    var storedTrains: [SingleTrain] {
        get {
            if let decoded = UserDefaults.standard.object(forKey: "storedSlots") as? Data {
                return (NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [SingleTrain])?.sorted(by: { $0.startsAt < $1.startsAt }) ?? []
            } else {
                return []
            }
        }
        set {
            let encodedData = NSKeyedArchiver
                .archivedData(withRootObject: newValue.sorted(by: { $0.startsAt < $1.startsAt }))
            UserDefaults.standard.set(encodedData, forKey: "storedSlots")
            UserDefaults.standard.synchronize()
        }
    }

    var isEmployee: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isEmployee")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isEmployee")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userPhoneConfirmed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "userPhoneConfirmed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userPhoneConfirmed")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userInfoWasSet: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "userInfoWasSet")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userInfoWasSet")
            UserDefaults.standard.synchronize()
        }
    }

    var userPhone: String {
        get {
            return UserDefaults.standard.string(forKey: "userPhone") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userPhone")
            UserDefaults.standard.synchronize()
        }
    }

    var userLastName: String {
        get {
            return UserDefaults.standard.string(forKey: "userLastName") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userLastName")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userFirstName: String {
        get {
            return UserDefaults.standard.string(forKey: "userFirstName") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userFirstName")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userBirthDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "userBirthDate") as? Date ?? Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userBirthDate")
            UserDefaults.standard.synchronize()
        }
    }

    var userMail: String {
        get {
            return UserDefaults.standard.string(forKey: "userMail") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userMail")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userCardDigits: String {
        get {
            //return UserDefaults.standard.string(forKey: "userCardDigits") ?? ""
            return userInfo["last4"].stringValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userCardDigits")
            UserDefaults.standard.synchronize()
        }
    }

    var userCardLinked: Bool {
        get {
            return !userCardDigits.isEmpty
        }
    }
    
    var userInfo: JSON {
        get {
            if let userJson = UserDefaults.standard.value(forKey: "userInfoJson") as? String {
                if !userJson.isEmpty && userJson != "nil" {
                    if let json = userJson.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                        return try! JSON(data: json)
                    }
                }
            }
            return JSON("nil")
        }
        set {
            UserDefaults.standard.set(newValue.rawString() ?? "{}", forKey: "userInfoJson")
            UserDefaults.standard.synchronize()
        }
    }
    
    var deviceUUID: String = UIDevice.current.identifierForVendor?.uuidString ?? "1234567890"
    
    var userToken: String {
        get {
            return App.DEBUGTOKEN ? App.STATICTOKEN : UserDefaults.standard.string(forKey: "userJWT") ?? ""
            //return UserDefaults.standard.string(forKey: "userJWT") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userJWT")
            UserDefaults.standard.synchronize()
        }
    }
    
    var userJWTExpiration: Int {
        get {
            return UserDefaults.standard.integer(forKey: "userJWTExpiration")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userJWTExpiration")
            UserDefaults.standard.synchronize()
        }
    }
    
    var paymentToken: String {
        get {
            return UserDefaults.standard.string(forKey: "paymentToken") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "paymentToken")
            UserDefaults.standard.synchronize()
        }
    }
    
    var genderId: Int = 0
        /*? {  // 0 - male, 1 - female
        get {
            return UserDefaults.standard.integer(forKey: "genderId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "genderId")
            UserDefaults.standard.synchronize()
        }
    }*/
        
    // MARK: - Tariffs
    var tariffs: JSON {
        get {
            return App.this.userInfo["listtarif"]
        }
        set {
            App.this.userInfo["listtarif"] = newValue
        }
    }
    
    var userTariffId: Int {
        get {
            return App.this.userTariff["id"].intValue
        }
    }

    var userTariffType: Int {
        get {
            return App.this.userTariff["tariftype"].intValue
        }
    }
    
    var userTariffAbonement: Bool {
        get {
            return App.this.userTariff["tariftype"].intValue == TARIFF_ABONEMENT
        }
    }
    
    var userTariffTrainsCount: Int { // кол-во часов для выбранного тарифа (например, для тарифа с тренером или с пакетом часов)
        get {
            return UserDefaults.standard.integer(forKey: "userTariffTrainsCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userTariffTrainsCount")
            UserDefaults.standard.synchronize()
        }
    }

    var userTariff: JSON {
        get {
            var jsonString = ""
            if let storedString = UserDefaults.standard.value(forKey: "userTariff") as? String {
                jsonString = storedString
            }
            else {
                jsonString = ""
            }
            if jsonString != "" {
                if let json = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    return try! JSON(data: json)
                }
                else {
                    return JSON()
                }
            }
            else {
                return JSON()
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawString() ?? "{}", forKey: "userTariff")
            UserDefaults.standard.synchronize()
        }
    }

    var rooms: JSON {
        get {
            var jsonString = ""
            if let storedString = UserDefaults.standard.value(forKey: "roomsFilteredList") as? String {
                jsonString = storedString
            }
            else {
                jsonString = ""
            }
            if jsonString != "" {
                if let json = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    return try! JSON(data: json)
                }
                else {
                    return JSON()
                }
            }
            else {
                return JSON()
            }
        }
        set {
            let paramsString = newValue.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) ?? "{}"
            UserDefaults.standard.set(paramsString, forKey: "roomsFilteredList")
            UserDefaults.standard.synchronize()
        }
    }
    
    var paidSubscription: JSON {
        get {
            var jsonString = ""
            if let storedString = UserDefaults.standard.value(forKey: "paidSubscription") as? String {
                jsonString = storedString
            }
            else {
                jsonString = ""
            }
            if jsonString != "" {
                if let json = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    return try! JSON(data: json)
                }
                else {
                    return JSON()
                }
            }
            else {
                return JSON()
            }            
        }
        set {
            UserDefaults.standard.set(newValue.rawString() ?? "{}", forKey: "paidSubscription")
            UserDefaults.standard.synchronize()
        }
    }
    
    func storePaidSubscription(json: JSON) {
        UserDefaults.standard.set(json.rawString() ?? "{}", forKey: "paidSubscription\(json["tarif"]["id"].stringValue)")
        UserDefaults.standard.synchronize()
    }
    
    func getPaidSubscription(id: String) -> JSON {
        var jsonString = ""
        if let storedString = UserDefaults.standard.value(forKey: "paidSubscription\(id)") as? String {
            jsonString = storedString
        }
        else {
            jsonString = ""
        }
        if jsonString != "" {
            if let json = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                return try! JSON(data: json)
            }
            else {
                return JSON()
            }
        }
        else {
            return JSON()
        }
    }
    
    func loadSchedule(fromVC: UIViewController, id: Int, forChange: Bool, changeTrain: SingleTrain) {
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Загружаем...")
        
        let url = "\(App.BASEURL)/schedule"
        let hdr = [
            "Content-Type": "application/json"
        ]
        let body = """
            {
                "listid": [\(id)],
                "selectdate": "\(Date().toString(format: "yyyy-MM-dd"))"
            }
        """
        
        Alamofire.request(url, method: .post, parameters: [:], encoding: body, headers: hdr).responseJSON {
            response in
            APESuperHUD.dismissAll(animated: true)
            if let data = response.result.value {
                
                let schedule = JSON(data).arrayValue
                
                if schedule.count > 0 {
                    let storyboard = UIStoryboard(name: "Schedule", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "Schedule") as! ScheduleVC
                    vc.jsonSchedule = schedule[0]["tableplanner"].arrayValue
                    vc.weChangeSchedule = forChange
                    vc.trainToChange = changeTrain
                    fromVC.navigationController?.pushViewController(vc, animated: true)
                }
                else {
                    fromVC.raiseAlert("Увы!", "!Не удалось загрузить расписание. Повторите попытку позже.", "Понятно")
                }
            }
            else {
                fromVC.raiseAlert("Увы!", "Не удалось загрузить расписание. Повторите попытку позже.", "Понятно")
            }
        }
    }
    
    var fcmToken: String {
        get {
            return UserDefaults.standard.string(forKey: "fcmToken") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fcmToken")
            UserDefaults.standard.synchronize()
        }
    }    
}
