import Foundation
import SwiftyJSON

@objc(SingleTrain) final class SingleTrain: NSObject, NSCoding, Codable {

    var slots: [TrainingSlot] = []
    
    var extended: Bool {
        get {
            return slots.count == 3
        }
    }
    
    var empty: Bool {
        get {
            return slots.count == 0
        }
    }
    
    var slotsDelta: Int {
        get {
            return slots.last!.idx - slots[0].idx
        }
    }
    
    var firstSlotSelected: Bool {
        get {
            return slots.count == 1
        }
    }
    
    var allSlotsSelected: Bool {
        get {
            return slots.count == 2 || slots.count == 3
        }
    }
    
    var date: Date = Date()                         // day of train at 00:00
    var startsAt: Int {                           // seconds from day beginning
        get {
            return slots.count > 0 ? Int(date.timeIntervalSince1970 + TimeInterval(slots[0].starttime)) : 0
        }
    }
    var trainTime: String = ""                      // "с 8:00 до 09:00"
    var address: String = ""
    
    // from response
    var abonement: Bool = false
    var abonementsList: [JSON] = []
    var abonementEndDate: String = ""

    var roomId: Int = 0
    var price: Float = 0
    var uid: String = "-1000" //"\(Int(arc4random_uniform(6) + 1))"
    
    var textDescription: String = "" // текстовое описание ("это тренировка за ХХХ руб.")
    
    override init() {
        date = Date()
    }
    
    init(day: Date, time: String, room: Int, address: String, slots: [TrainingSlot], price: Float, uuid: String,
         listabon: [JSON], abon: Bool, abonenddate: String, descr: String) {
        
        self.slots = slots
        self.date = day
        self.trainTime = time
        self.abonement = abon
        self.roomId = room
        self.price = price
        self.abonementsList = listabon
        self.uid = uuid
        self.abonementEndDate = abonenddate
        self.address = address
        self.textDescription = descr
    }

    init(slots: [TrainingSlot]) {
        self.date = Date()
        self.slots = slots
    }

    convenience required init?(coder aDecoder: NSCoder) {
        let list = aDecoder.decodeObject(forKey: "listReserve") as? [TrainingSlot] ?? []
        let date = aDecoder.decodeObject(forKey: "date") as? Date ?? Date()
        let abon = aDecoder.decodeBool(forKey: "abonement")
        let room = aDecoder.decodeInteger(forKey: "idroom")
        let price = aDecoder.decodeFloat(forKey: "price")
        let uuid = aDecoder.decodeObject(forKey: "uuidreserv") as? String ?? ""
        let enddate = aDecoder.decodeObject(forKey: "enddateabonement") as? String ?? ""
        let listabon = aDecoder.decodeObject(forKey: "listAbonement") as? [JSON] ?? []
        let time = aDecoder.decodeObject(forKey: "trainTime") as? String ?? ""
        let place = aDecoder.decodeObject(forKey: "trainPlace") as? String ?? ""
        let descr = aDecoder.decodeObject(forKey: "textDescription") as? String ?? ""
        
        self.init(day: date, time: time, room: room, address: place, slots: list, price: price, uuid: uuid,
                  listabon: listabon, abon: abon, abonenddate: enddate, descr: descr)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(slots, forKey: "listReserve")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(abonement, forKey: "abonement")
        aCoder.encode(roomId, forKey: "idroom")
        aCoder.encode(price, forKey: "price")
        aCoder.encode(uid, forKey: "uuidreserv")
        aCoder.encode(abonementEndDate, forKey: "enddateabonement")
        aCoder.encode(abonementsList, forKey: "listAbonement")
        aCoder.encode(trainTime, forKey: "trainTime")
        aCoder.encode(address, forKey: "trainPlace")
        aCoder.encode(textDescription, forKey: "textDescription")
    }
    
    func isFinished(local: Int) -> Bool {
        if slots.count == 0 {
            return false
        }
        let timeEnded = TimeInterval(local) >= (self.date.timeIntervalSince1970
            + TimeInterval(self.slots[1].starttime + 40 * MIN_1))
        let doorClosed = !doorWasOpened(forTrainId: uid)
        return (timeEnded && doorClosed)
    }

    func isNotFinished() -> Bool {
        return (doorWasOpened(forTrainId: uid))
    }
    
    func clearSlots() {
        slots = []
    }
    
    func slotIsIn(_ slot: TrainingSlot) -> Bool {
        if let _ = slots.firstIndex(where: { $0.starttime == slot.starttime && $0.date == slot.date }) {
            return true
        }
        return false
    }
    
    func equalOrLaterThan(_ slot: TrainingSlot) -> Bool {
        if slots.isEmpty { return true }
        return slots[0].starttime >= slot.starttime
    }
}

@objc(TrainingSlot) final class TrainingSlot: NSObject, NSCoding, Codable {
    var starttime: Int = 0
    var date: String = ""
    var idx: Int = -1
    
    init(start: Int, date: String) {
        self.starttime = start
        self.date = date
    }
    
    init(start: Int, date: String, idx: Int) {
        self.starttime = start
        self.date = date
        self.idx = idx
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let start = aDecoder.decodeInteger(forKey: "starttime")
        let date = aDecoder.decodeObject(forKey: "date") as? String ?? ""
        self.init(start: start, date: date)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(starttime, forKey: "starttime")
        aCoder.encode(date, forKey: "date")
    }
}
