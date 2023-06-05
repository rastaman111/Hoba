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

/// Payment method data for Sberbank.
public class PaymentMethodDataSberbank: PaymentMethodData {

    /// The phone of the user which is registered in the account in Sberbank Online.
    /// Required to confirm payment by SMS (confirmation script external).
    /// Format specified in ITU-T E. 164 79000000000
    public let phone: String?

    /// Creates instance of PaymentMethodDataSberbank.
    ///
    /// - Parameters:
    ///   - phone: The phone of the user which is registered in the account in Sberbank Online.
    ///            Required to confirm payment by SMS (confirmation script external).
    ///            Format specified in ITU-T E. 164 79000000000.
    ///
    /// - Returns: Instance of `PaymentMethodDataSberbank`.
    public init(phone: String?) {
        self.phone = phone
        super.init(paymentMethodType: .sberbank)
    }

    // MARK: - Codable

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let paymentMethodType = try container.decode(PaymentMethodType.self, forKey: .paymentMethodType)

        guard case .sberbank = paymentMethodType else {
            throw DecodingError.incorrectType
        }

        let phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.init(phone: phone)
    }

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(phone, forKey: .phone)
        try super.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodType = "type"
        case phone
    }
}
