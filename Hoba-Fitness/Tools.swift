import Foundation
import Alamofire
import SwiftyJSON
import YandexMobileMetrica
import UserNotifications

func reportEvent(_ title: String, _ params: [String:String]) {
    YMMYandexMetrica.reportEvent(title, parameters: params, onFailure: { _ in })
}

func delay(_ delay: Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func getBookingJson(first: Bool, writeOff: Bool) -> String {
    //print("--- userTariffId ", App.this.userTariffId)
    var res = "{"
    res += (writeOff ? "\"writeoff\": true," : "")
    res += (first ? "\"isfirst\": true," : "")
    res += """
    \"idroom\": \(App.this.reservedRoomId),
    \"idtarif\": \(App.this.userTariffId),
    \"needtrainer\": 0,
    \"action\": \"reserve\",
    \"isfirst\": \"\(first ? "true" : "false")\",
    \"listReserve\": [
    """
    for i in 0 ..< App.this.bookedTrain.slots.count {
        res += """
        {
        \"starttime\": \(App.this.bookedTrain.slots[i].starttime),
        \"date\": \"\(App.this.bookedTrain.slots[i].date)\",
        \"id\": 123
        }
        """
        if i < (App.this.bookedTrain.slots.count - 1) {
            res += ","
        }
    }
    res += "]}"
    //print("--- booking json: ", res)
    return res
}

func getTransferJson(_ train: SingleTrain, slots: [TrainingSlot]) -> String {
    var res = """
    {
    \"action\": \"transfer\",
    \"isfirst\": \"false\",
    \"uuidold\": \"\(train.uid)\",
    \"idroom\": \(train.roomId),
    
    \"listReserve\": [
    """
    for i in 0 ..< slots.count {
        res += """
        {
        \"starttime\": \(slots[i].starttime),
        \"date\": \"\(slots[i].date)\",
        \"id\": 123
        }
        """
        if i < (slots.count - 1) {
            res += ","
        }
    }
    res += "]}"
    return res
}

func doorWasOpened(forTrainId: String) -> Bool {
    return UserDefaults.standard.bool(forKey: "doorOpenedFor\(forTrainId)")
}

func saveDoorState(opened: Bool, forKey: String) {
    UserDefaults.standard.set(opened, forKey: "doorOpenedFor\(forKey)")
    UserDefaults.standard.synchronize()
}

func parseReserve(response: JSON) {
    App.this.bookedTrain.abonementEndDate = response["enddateabonement"].stringValue
    App.this.bookedTrain.roomId = response["idroom"].intValue
    App.this.bookedTrain.abonementsList = response["listAbonement"].arrayValue
    App.this.bookedTrain.uid = response["uuidreserv"].stringValue
    App.this.bookedTrain.abonement = response["abonement"].boolValue
}

func paidTariffIdx(id: Int) -> Int? {
    if let i = App.this.userInfo["listsub"].arrayValue.firstIndex(where: { $0["tarif"]["id"].intValue == id }) {
        return i
    }
    return nil
}

func paidTariffTrainsAvail() -> Int? {
    if let idx = paidTariffIdx(id: App.this.userTariffId) {
        let count = App.this.userInfo["listsub"].arrayValue[idx]["balance"].intValue
        return count > 0 ? count : nil
    }
    return nil
}

func generateTrain(_ j: JSON) -> SingleTrain {
    let train = SingleTrain()
    let slot1 = TrainingSlot(start: j["timefrom"].intValue, date: train.date.toString(format: "yyyy-MM-dd"))
    let slot2 = TrainingSlot(start: j["timefrom"].intValue + MIN_30, date: train.date.toString(format: "yyyy-MM-dd"))
    train.slots = [slot1, slot2]
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
    dateFormatter.dateFormat = "yyyy-MM-dd"
    train.date = dateFormatter.date(from: j["workoutdate_string"].stringValue)!
    
    train.roomId = j["idroom"].intValue
    train.uid = j["uuid"].stringValue
    train.address = App.this.rooms.arrayValue.first(where: {
        $0["id"].intValue == train.roomId
    })?["address"].stringValue ?? "Зал"
    
    let (h1, m1, _) = secondsToHours(seconds: j["timefrom"].intValue)
    let (h2, m2, _) = secondsToHours(seconds: j["timeto"].intValue)
    train.trainTime = "\(train.date.toString(format: "dd MMMM yyyy")) с \(String(format: "%02d", h1) + ":" + String(format: "%02d", m1)) по \(String(format: "%02d", h2) + ":" + String(format: "%02d", m2))"
    return train
}

func isYearPlanActive(_ tariffId: Int) -> Bool {
    if let tariff = App.this.userInfo["listabonement"].arrayValue
        .first(where: { $0["idtarif"].intValue == tariffId }) {
        return tariff["endDateEpoch"].doubleValue > Date().timeIntervalSince1970
    }
    return false
}

func isAbonementPlanActive(_ tariffId: Int) -> Bool {
    return App.this.activeAbonement
}

func isPackagePlanAvail(_ tariffId: Int) -> Bool {
    if let tariff = App.this.userInfo["listsub"].arrayValue
        .first(where: { $0["tarif"]["id"].intValue == tariffId }) {
        return tariff["balance"].doubleValue > 0
    }
    return false
}

func addTrain(_ train: SingleTrain) {
    (UIApplication.shared.delegate as! AppDelegate).scheduleNotification(train)
    App.this.storedTrains.append(train)
}

func removeTrain(idx: Int) {
    print("~~~ remove by idx ", App.this.storedTrains[idx].uid)
    (UIApplication.shared.delegate as! AppDelegate).removeNotification(App.this.storedTrains[idx].uid)
    App.this.storedTrains.remove(at: idx)
}

func removeTrain(id: String) {
    print("~~~ remove by id ", id)
    if let train = App.this.storedTrains.first(where: { $0.uid != id }) {
        (UIApplication.shared.delegate as! AppDelegate).removeNotification(train.uid)
    }

    App.this.storedTrains = App.this.storedTrains.filter { $0.uid != id }
}

func genFreeTrain() -> JSON {
    var result = JSON()
    result["id"].intValue = 1
    result["coast"].doubleValue = 0.0
    result["coastsubscription"].doubleValue = 0.0
    result["active"].boolValue = true
    result["periodsub"].stringValue = ""
    result["usesubscribe"].boolValue = false
    result["testtarif"].boolValue = false
    result["tariftype"].intValue = TARIFF_FREE
    result["clientchoosecount"].boolValue = false
    result["count"].doubleValue = 0.0
    //result["description"].stringValue = "Бесплатная пробная тренировка"
    result["countpeople"].double = nil
    
    return result
}

func isSubscribed(_ tariff: JSON) -> Bool {
    var subs = App.this.userInfo["listsub"].arrayValue
        
    for sub in subs {
        if tariff["id"].intValue == sub["tarif"]["id"].intValue {
            return true
        }
    }

    subs = App.this.userInfo["listabonement"].arrayValue
    for sub in subs {
        if tariff["id"].intValue == sub["tarif"]["id"].intValue {
            return true
        }
    }

    subs = App.this.userInfo["unlimtarif"].arrayValue
    
    for sub in subs {
        if tariff["id"].intValue == sub["idtarif"].intValue {
            return true
        }
    }


    return false
}
