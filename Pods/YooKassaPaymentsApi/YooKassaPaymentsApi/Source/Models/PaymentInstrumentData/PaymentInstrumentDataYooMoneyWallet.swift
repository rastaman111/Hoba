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

/// Data for payment via YooMoney from the wallet account.
/// The wallet ID will be determined by the authorization data of the request.
public class PaymentInstrumentDataYooMoneyWallet: PaymentMethodData {

    /// The type of the source of funds for payments from the YooMoney.
    public let instrumentType: YooMoneyInstrumentType

    /// YooMoney wallet authorization header.
    public let walletAuthorization: String

    /// Creates instance of `PaymentInstrumentDataYooMoneyWallet`.
    ///
    /// - Parameters:
    ///   - instrumentType: The type of the source of funds for payments from the YooMoney.
    ///   - walletAuthorization: YooMoney wallet authorization header.
    ///   - paymentMethodType: Type of the source of funds for the payment.
    ///
    /// - Returns: Instance of `PaymentInstrumentDataYooMoneyWallet`.
    public init(instrumentType: YooMoneyInstrumentType,
                walletAuthorization: String,
                paymentMethodType: PaymentMethodType) {
        self.instrumentType = instrumentType
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

    // MARK: - Codable

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
              instrumentType == .wallet else {
            throw DecodingError.incorrectType
        }

        self.init(
            instrumentType: instrumentType,
            walletAuthorization: "",
            paymentMethodType: paymentMethodType
        )
    }

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethodType, forKey: .paymentMethodType)
        try container.encode(instrumentType, forKey: .instrumentType)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodType = "type"
        case instrumentType = "instrument_type"
    }
}
