/*
 * The MIT License
 *
 * Copyright © 2020 NBCO YooMoney LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation

/// Bank card data.
public struct BankCard: Codable {

    /// Bank card number.
    public let number: String

    /// Validity, year, YYYY.
    public let expiryYear: String

    /// The validity period of the month, MM.
    public let expiryMonth: String

    /// The CVC2 or CVV2 code, 3 or 4 characters, is printed on the back of the card.
    public let csc: String

    /// The name of the card owner.
    public let cardholder: String?

    /// Creates instance of `BankCard`.
    ///
    /// - Parameters:
    ///   - number: Bank card number.
    ///   - expiryYear: Validity, year, YYYY.
    ///   - expiryMonth: The validity period of the month, MM.
    ///   - csc: The CVC2 or CVV2 code, 3 or 4 characters, is printed on the back of the card.
    ///   - cardholder: The name of the card owner.
    ///
    /// - Returns: Instance of `BankCard`
    public init(number: String,
                expiryYear: String,
                expiryMonth: String,
                csc: String,
                cardholder: String?) {
        self.number = number
        self.expiryYear = expiryYear
        self.expiryMonth = expiryMonth
        self.csc = csc
        self.cardholder = cardholder
    }

    private enum CodingKeys: String, CodingKey {
        case number
        case expiryYear = "expiry_year"
        case expiryMonth = "expiry_month"
        case csc
        case cardholder
    }
}
