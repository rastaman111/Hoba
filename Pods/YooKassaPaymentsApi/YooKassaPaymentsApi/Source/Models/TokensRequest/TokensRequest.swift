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

/// Request for tokenization of the buyer's payment data for subsequent payment.
public class TokensRequest: Codable {

    /// Payment amount, the nominal value of the order for the buyer.
    public let amount: MonetaryAmount?

    /// ThreatMetrix session ID.
    public let tmxSessionId: String

    /// Payment confirmation method.
    public let confirmation: Confirmation?

    /// Sign of saving payment data for repeated payments,
    /// confirmed by the user and allowed by the store settings.
    public let savePaymentMethod: Bool?

    /// Creates instance of `TokensRequest`.
    ///
    /// - Parameters:
    ///   - amount: Payment amount, the nominal value of the order for the buyer.
    ///   - tmxSessionId: ThreatMetrix session ID.
    ///   - confirmation: Payment confirmation method.
    ///
    /// - Returns: Instance of `TokensRequest`.
    public init(amount: MonetaryAmount?,
                tmxSessionId: String,
                confirmation: Confirmation?,
                savePaymentMethod: Bool?) {
        self.amount = amount
        self.tmxSessionId = tmxSessionId
        self.confirmation = confirmation
        self.savePaymentMethod = savePaymentMethod
    }

    /// Creates custom headers.
    public func customHeaders() -> Headers {
        return .mempty
    }
}
