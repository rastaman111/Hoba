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
import struct YooMoneyCoreApi.Headers

/// Data for payment via YooMoney from the attached Bank card.
public class PaymentInstrumentDataYooMoneyLinkedBankCard: PaymentMethodData {

    /// The type of the source of funds for payments from the YooMoney.
    public let instrumentType: YooMoneyInstrumentType

    /// ID card.
    public let cardId: String

    /// The CVC2 or CVV2 code, 3 or 4 characters, is printed on the back of the card.
    public let csc: String

    /// YooMoney wallet authorization header.
    public let walletAuthorization: String

    /// Creates instance of `PaymentInstrumentDataYooMoneyLinkedBankCard`.
    ///
    /// - Parameters:
    ///   - instrumentType: Type of the source of funds for the payment.
    ///   - cardId: ID card.
    ///   - csc: The CVC2 or CVV2 code, 3 or 4 characters, is printed on the back of the card.
    ///   - walletAuthorization: YooMoney wallet authorization header.
    ///   - paymentMethodType: Type of the source of funds for the payment.
    ///
    /// - Returns: Instance of `PaymentInstrumentDataYooMoneyLinkedBankCard`.
    public init(instrumentType: YooMoneyInstrumentType,
                cardId: String,
                csc: String,
                walletAuthorization: String,
                paymentMethodType: PaymentMethodType) {
        self.instrumentType = instrumentType
        self.cardId = cardId
        self.csc = csc
        self.walletAuthorization = walletAuthorization
        super.init(paymentMethodType: paymentMethodType)
    }

    /// Creates custom headers.
    public override func customHeaders() -> Headers {
        let value = [
            AuthorizationConstants.walletAuthorization:
            AuthorizationConstants.bearerAuthorizationPrefix + walletAuthorization,
        ]
        let customHeaders = Headers(value)
        return super.customHeaders().mappend(customHeaders)
    }

    // MARK: - Decodable

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    required convenience public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let paymentMethodType = try container.decode(PaymentMethodType.self, forKey: .paymentMethodType)
        let instrumentType = try container.decode(YooMoneyInstrumentType.self, forKey: .instrumentType)

        guard paymentMethodType == .yooMoney,
              instrumentType == .linkedBankCard else {
            throw DecodingError.incorrectType
        }

        let cardId = try container.decode(String.self, forKey: .cardId)
        let csc = try container.decode(String.self, forKey: .csc)

        self.init(instrumentType: instrumentType,
                  cardId: cardId,
                  csc: csc,
                  walletAuthorization: "",
                  paymentMethodType: paymentMethodType)
    }

    // MARK: - Encodable

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethodType, forKey: .paymentMethodType)
        try container.encode(instrumentType, forKey: .instrumentType)
        try container.encode(cardId, forKey: .cardId)
        try container.encode(csc, forKey: .csc)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodType = "type"
        case instrumentType = "instrument_type"
        case cardId = "id"
        case csc
    }
}
