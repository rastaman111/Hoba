import UIKit
import Alamofire
import SwiftyJSON
import APESuperHUD

func hdrs() -> HTTPHeaders? {
    return ["Content-Type": "application/json", "X-AUTH-TOKEN": App.this.userToken]
}

func applyPromo(tariff: Int, promo: String, completion : @escaping (_ success: Bool, _ msg: String,
                                                                    _ response: JSON) -> Void) {
    let body: [String : Any] = [
        "versioncode": 41,
        "versionname": "41",
        "idtarif": "\(tariff)",
        "promoname": promo
    ]
    
    Alamofire.request("\(App.BASEURL)/applypromo", method: .post, parameters: [:], encoding:
                        JSON(body).rawString()!, headers: hdrs()).responseString {
        response in
        let json = JSON(response.result.value!.data(using: String.Encoding.utf8)!)
        completion(json != JSON.null, response.result.value!, json)
    }
}

func checkPromo(tariff: Int, room: Int, uuid: String, promo: String,
                completion : @escaping (_ success: Bool, _ msg: String, _ response: JSON) -> Void) {
    let body: [String : Any] = [
        "versioncode": 41,
        "versionname": "41",
        "idtarif": "\(tariff)",
        "idroom": room,
        "uuid": uuid,
        "promoname": promo
    ]
    
    Alamofire.request("\(App.BASEURL)/getpromo", method: .post, parameters: [:], encoding:
                        JSON(body).rawString()!, headers: hdrs()).responseString {
        response in
        let json = JSON(response.result.value!.data(using: String.Encoding.utf8)!)
        
        print("--- /checkPromo: ", body)
        print("--- /checkPromo: ", response)
        //print("--- /checkPromo: ", json != JSON.null)
        
        completion(json != JSON.null, response.result.value!, json)
    }
}

func loadTariffs(completion: @escaping (_ tariffs: JSON) -> Void) {
    if App.this.tariffs.count > 0 {
        completion(App.this.tariffs)
    }
    else {
        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Загружаем...")
        let body: [String : Any] = [ "versioncode": 41, "versionname": "41" ]
        Alamofire.request("\(App.BASEURL)/tarifs", method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdrs())
            .responseJSON {
                response in
                APESuperHUD.dismissAll(animated: true)
                if let data = response.result.value {
                    let json = JSON(data)
                    completion(json)
                }
            }
    }
}

func loadClientState(completion: @escaping (_ json: JSON) -> Void) {
    let body: [String : Any] = [ "versioncode": 41, "versionname": "41" ]
    Alamofire.request("\(App.BASEURL)/updateclient", method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdrs())
        .responseJSON {
            response in
            if let data = response.result.value {
                let json = JSON(data)
                
                App.this.userMail = json["email"].stringValue
                App.this.userFirstName = json["nameclient"].stringValue
                App.this.userLastName = json["surname"].stringValue
                App.this.userPhone = json["phone"].stringValue
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                App.this.userBirthDate = dateFormatter.date(from: json["birthday"].stringValue) ?? Date()
                
                App.this.userInfo = json
                
                App.this.userInfo["listsub"].arrayObject = App.this.userInfo["listsub"].arrayValue.filter { $0["balance"].intValue > 0 }
                
                App.this.userInfo["unlimtarif"].arrayObject = App.this.userInfo["unlimtarif"].arrayValue.filter { Date.from(string: $0["enddate"].stringValue, with: "yyyy-MM-dd") ?? Date() > Date() }
                
                completion(json)
            }
        }
}

func delinkCard(completion: @escaping (_ json: JSON) -> Void) {
    let body: [String : Any] = [ "versioncode": 41, "versionname": "41" ]
    Alamofire.request("\(App.BASEURL)/deletelink", method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdrs())
        .responseJSON {
            response in
            if let data = response.result.value {
                completion(JSON(data))
            }
            else {
                completion(JSON())
            }
        }
}

func updateClientInfo(_ body: [String : Any], completion: @escaping (_ json: JSON) -> Void) {
    var patchedBody = body
    patchedBody["versioncode"] = 41
    patchedBody["versionname"] = "41"
    
    Alamofire.request("\(App.BASEURL)/updateclient", method: .post, parameters: [:],
                      encoding: JSON(patchedBody).rawString()!, headers: hdrs())
    .responseJSON {
        response in
        if let data = response.result.value {
            completion(JSON(data))
        }
    }
}

func checkUpdates(completion: @escaping (_ json: JSON) -> Void) {
    var trainsAdded = false
    
    Alamofire.request("\(App.BASEURL)/listchange", method: .post, parameters: [:], encoding: "{}", headers: hdrs()).responseJSON {
        response in
        if let data = response.result.value {
            let json = JSON(data)
            
            let dispatcher: DispatchGroup = DispatchGroup()
            
            for item in json["ch"].arrayValue {
                
                if item["action"] == "addtraining" {
                    let j = JSON.init(parseJSON: item["changejson"].stringValue)
                    trainsAdded = true
                    dispatcher.enter()
                    let body = "{\"idchange\": \(j["idchange"].intValue)}"
                    Alamofire.request("\(App.BASEURL)/deletechange", method: .post, parameters: [:], encoding: body, headers: hdrs()).responseJSON {
                        response in
                        addTrain(generateTrain(j))
                        dispatcher.leave()
                    }
                }
                if item["action"] == "staff" {
                    let j = JSON.init(parseJSON: item["changejson"].stringValue)
                    App.this.isEmployee = j["isemployee"].boolValue
                }
            }
            
            dispatcher.notify(queue: .main) {
                if trainsAdded {
                    NotificationCenter.default.post(name: Notification.Name("receivedTrainUpdates"), object: nil)
                    (UIApplication.shared.delegate as! AppDelegate).fireNotification(title: "Добавлены тренировки", msg: "Вы можете увидеть их в разделе \"Мои тренировки\".")
                }
            }
            completion(JSON(data))
        }
    }
}

func cancelTrain(_ body: [String : Any], completion: @escaping (_ json: JSON, _ response: DataResponse<String>) -> Void) {
    
    Alamofire.request("\(App.BASEURL)/refund", method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdrs())
        .responseString { response in
            if let data = response.result.value {
                completion(JSON(data), response)
            }
        }
}

func reserve(isFirst: Bool, writeOff: Bool, completion: @escaping (_ json: JSON, _ response: DataResponse<Any>) -> Void) {
    
    let reserveJson = getBookingJson(first: isFirst, writeOff: writeOff)
    
    Alamofire.request("\(App.BASEURL)/reserve", method: .post, parameters: [:], encoding: reserveJson, headers: hdrs())
        .responseJSON { response in
            if let data = response.result.value {
                print("--- /reserve: ", response)
                completion(JSON(data), response)
            }
            else {
                completion(JSON(), response)
            }
        }
}

func getSchedule(date: String, roomId: Int, completion: @escaping (_ json: [JSON]) -> Void) {
    let url = "\(App.BASEURL)/schedule"
    let hdr = [
        "Content-Type": "application/json"
    ]
    let body = """
            {
                "listid": [\(roomId)],
                "selectdate": "\(date)"
            }
        """
    
    Alamofire.request(url, method: .post, parameters: [:], encoding: body, headers: hdr).responseJSON {
        response in
        APESuperHUD.dismissAll(animated: true)
        if let data = response.result.value {
            let schedule = JSON(data).arrayValue
            completion(schedule)
        }
        else {
            completion([])
        }
    }
}
