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

/// Payment method data for ApplePay.
public class PaymentMethodDataApplePay: PaymentMethodData {

    /// The contents of the field paymentData object [PKPaymentToken]
    /// Apple Pay payment token. Comes in Base64 format.
    /// (https://developer.apple.com/documentation/passkit/pkpaymenttoken)
    public let paymentData: String

    /// Creates instance of `PaymentMethodDataApplePay`.
    ///
    /// - Parameters:
    ///   - paymentData: The contents of the field paymentData object [PKPaymentToken]
    ///                  Apple Pay payment token. Comes in Base64 format.
    ///                  (https://developer.apple.com/documentation/passkit/pkpaymenttoken)
    ///
    /// - Returns: Instance of `PaymentMethodDataApplePay`.
    public init(paymentData: String) {
        self.paymentData = paymentData
        super.init(paymentMethodType: .applePay)
    }

    // MARK: - Codable

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentData, forKey: .paymentData)
        try super.encode(to: encoder)
    }

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard case .applePay = try container.decode(PaymentMethodType.self, forKey: .paymentMethodType) else {
            throw DecodingError.incorrectType
        }
        let paymentData = try container.decode(String.self, forKey: .paymentData)
        self.init(paymentData: paymentData)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodType = "type"
        case paymentData = "payment_data"
    }
}
