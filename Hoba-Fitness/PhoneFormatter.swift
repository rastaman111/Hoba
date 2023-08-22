//
//  PhoneFormatter.swift
//  Hoba-Fitness
//
//  Created by Александр Сибирцев on 22.08.2023.
//  Copyright © 2023 Yaroslav Gilmullin. All rights reserved.
//

import Foundation

class PhoneFormatter: NSObject {
    static let shared = PhoneFormatter()

    // Форматирование номеров моб. телефона

    func format(phoneNumber: String, shouldRemoveLastDigit: Bool = false) -> String {
        guard !phoneNumber.isEmpty else { return "" }
        guard let regex = try? NSRegularExpression(pattern: "[\\s-\\(\\)]", options: .caseInsensitive) else { return "" }
        let r = NSString(string: phoneNumber).range(of: phoneNumber)
        var number = regex.stringByReplacingMatches(in: phoneNumber, options: .init(rawValue: 0), range: r, withTemplate: "")

        if number.count > 12 && number.contains("+7") {
            let tenthDigitIndex = number.index(number.startIndex, offsetBy: 12)
            number = String(number[number.startIndex..<tenthDigitIndex])
        } else if number.count > 12 {
            let tenthDigitIndex = number.index(number.startIndex, offsetBy: 11)
            number = String(number[number.startIndex..<tenthDigitIndex])
        }

        if shouldRemoveLastDigit {
            let end = number.index(number.startIndex, offsetBy: number.count - 1)
            number = String(number[number.startIndex..<end])
        }

        if number.count < 13 {
            number = "+7" + number.dropFirst(2)

            let end = number.index(number.startIndex, offsetBy: number.count)
            let range = number.startIndex..<end
            number = number.replacingOccurrences(of: "(\\d{1})(\\d{3})(\\d{3})(\\d{2})(\\d+)", with: "$1 $2 $3-$4-$5", options: .regularExpression, range: range)
        }

        return number
    }

    private let maxNumberCount = 11
    private let regex = try! NSRegularExpression(pattern: "[\\+\\s-\\(\\)]", options: .caseInsensitive)

    func formatTwo(phoneNumber: String, shouldRemoveLastDigit: Bool) -> String {
        guard !(shouldRemoveLastDigit && phoneNumber.count <= 2) else { return "+7" }

        let range = NSString(string: phoneNumber).range(of: phoneNumber)
        var number = self.regex.stringByReplacingMatches(in: phoneNumber, options: [], range: range, withTemplate: "")

        if number.count > self.maxNumberCount {
            let maxIndex = number.index(number.startIndex, offsetBy: self.maxNumberCount)
            number = String(number[number.startIndex..<maxIndex])
        }

        if shouldRemoveLastDigit {
            let maxIndex = number.index(number.startIndex, offsetBy: number.count - 1)
            number = String(number[number.startIndex..<maxIndex])
        }

        let maxIndex = number.index(number.startIndex, offsetBy: number.count)
        let regRange = number.startIndex..<maxIndex

        if number.count < 7 {
            let pattern = "(\\d)(\\d{3})(\\d+)"
            number = number.replacingOccurrences(of: pattern, with: "$1 $2 $3", options: .regularExpression, range: regRange)
        } else {
            let pattern = "(\\d)(\\d{3})(\\d{3})(\\d{2})(\\d+)"
            number = number.replacingOccurrences(of: pattern, with: "$1 $2 $3-$4-$5", options: .regularExpression, range: regRange)
        }

        return "+" + number
    }
}
