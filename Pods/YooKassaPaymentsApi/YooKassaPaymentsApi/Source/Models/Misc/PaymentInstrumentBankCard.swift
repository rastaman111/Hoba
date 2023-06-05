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

/// Data about the payment method using a bank card.
public struct PaymentInstrumentBankCard: Codable, Equatable {

    /// ID of the binding data for repeated payments to the merchant's stores.
    public let paymentInstrumentId: String

    /// The first 6 digits of the card number (BIN).
    public let first6: String?

    /// The last 4 digits of the card number.
    public let last4: String

    /// Whether the CSC input is required to confirm the payment with this card.
    public let cscRequired: Bool

    /// Type of Bank card.
    public let cardType: BankCardType

    /// Creates instance of `PaymentInstrumentBankCard`
    ///
    /// - Parameters:
    ///     - paymentInstrumentId: ID of the binding data for repeated payments to the merchant's stores. 
    ///     - first6: The first 6 digits of the card number (BIN). 
    ///     - last4: The last 4 digits of the card number. 
    ///     - cscRequired: Whether the CSC input is required to confirm the payment with this card. 
    ///     - cardType: Type of Bank card. 
    ///
    /// - Returns: Instance of `PaymentInstrumentBankCard`
    public init(
        paymentInstrumentId: String,
        first6: String?,
        last4: String,
        cscRequired: Bool,
        cardType: BankCardType
    ) {
        self.paymentInstrumentId = paymentInstrumentId
        self.first6 = first6
        self.last4 = last4
        self.cscRequired = cscRequired
        self.cardType = cardType
    }

    // MARK: - Codable

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentInstrumentId, forKey: .paymentInstrumentId)
        try container.encodeIfPresent(first6, forKey: .first6)
        try container.encode(last4, forKey: .last4)
        try container.encode(cscRequired, forKey: .cscRequired)
        try container.encode(cardType, forKey: .cardType)
    }

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let paymentInstrumentId = try container.decode(String.self, forKey: .paymentInstrumentId)
        let first6 = try container.decodeIfPresent(String.self, forKey: .first6)
        let last4 = try container.decode(String.self, forKey: .last4)
        let cscRequired = try container.decode(Bool.self, forKey: .cscRequired)
        let cardType = try container.decode(BankCardType.self, forKey: .cardType)

        self.init(
            paymentInstrumentId: paymentInstrumentId,
            first6: first6,
            last4: last4,
            cscRequired: cscRequired,
            cardType: cardType
        )
    }

    private enum CodingKeys: String, CodingKey {
        case paymentInstrumentId = "payment_instrument_id"
        case first6
        case last4
        case cscRequired = "csc_required"
        case cardType = "card_type"
    }
}
