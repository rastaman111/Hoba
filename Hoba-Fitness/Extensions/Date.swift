import UIKit

extension Date {
    func dayOfWeek() -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 0
        return "\(calendar.component(.weekday, from: self))"
    }
    
    func toString(format: String) -> String { //"dd-MM-yyyy"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    static func from(string: String, with: String) -> Date? { //"yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = with
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        guard let date = dateFormatter.date(from: string) else {
            assert(false, "No date from string")
            return nil
        }
        return date
    }
    
    func localSeconds() -> TimeInterval {
        return Double(TimeZone.current.secondsFromGMT(for: self)) + self.timeIntervalSince1970
    }
    
    func secondsOfDay() -> TimeInterval {
        let calendar = Calendar.current
        let time=calendar.dateComponents([.hour,.minute,.second], from: Date())
        return TimeInterval((time.hour! * 60 * 60) + (time.minute! * 60) + time.second!)
    }

    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }

    var hourBefore: Date {
        return Calendar.current.date(byAdding: .hour, value: -1, to: noon)!
    }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var year: Int {
        return Calendar.current.component(.year,  from: self)
    }
    var day: Int {
        return Calendar.current.component(.day,  from: self)
    }
    var hour: Int {
        return Calendar.current.component(.hour,  from: self)
    }
    var min: Int {
        return Calendar.current.component(.minute,  from: self)
    }

    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

func changeDateFormat(date: String) -> String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let date = dateFormatter.date(from: date) else {
        assert(false, "No date from string")
        return ""
    }
    dateFormatter.dateFormat = "EEEE, dd MMMM, yyyy"
    let result = dateFormatter.string(from: date)
    return result
}

func timeStampOfNow() -> Int {
    let date = Date()
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    let minutes = calendar.component(.minute, from: date)
    
    return minutes * 60 + hour * 60 * 60
}

func secondsToHours(seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600,
            (seconds % 3600) / 60,
            (seconds % 3600) % 60)
}

func secondsToDays(seconds: TimeInterval)  -> (Int, Int, Int, Int) {
    return (Int(seconds / 86400),
            (Int(seconds) % 86400) / 3600,
            (Int(seconds) % 3600) / 60,
            (Int(seconds) % 3600) % 60)
}
