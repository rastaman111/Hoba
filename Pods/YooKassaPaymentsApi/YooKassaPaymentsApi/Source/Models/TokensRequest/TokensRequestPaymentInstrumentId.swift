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

/// Request for data tokenization based on data about the saved binding of the payment instrument.
public final class TokensRequestPaymentInstrumentId: TokensRequest {

    /// ID of the binding data for repeated payments to the merchant's stores.
    public let paymentInstrumentId: String

    /// The CVC2/CVV2/CVC2 code, 3 or 4 characters, is printed on the back of the card. 
    /// It must be transmitted if this is required for payment with a saved bank card (the csc_required attribute).
    public let csc: String?

    /// Creates instance of `TokensRequestPaymentInstrumentId`.
    ///
    /// - Parameters:
    ///   - amount: Payment amount, the nominal value of the order for the buyer.
    ///   - tmxSessionId: ThreatMetrix session ID.
    ///   - confirmation: Payment confirmation method.
    ///   - paymentInstrumentId: ID of the binding data for repeated payments to the merchant's stores.
    ///   - csc: The CVC2/CVV2/CVC2 code, 3 or 4 characters, is printed on the back of the card.
    ///          It must be transmitted if this is required for payment with a saved bank card (the csc_required attribute).
    ///
    /// - Returns: Instance of `TokensRequestPaymentInstrumentId`
    public init(amount: MonetaryAmount?,
                tmxSessionId: String,
                confirmation: Confirmation?,
                savePaymentMethod: Bool?,
                paymentInstrumentId: String,
                csc: String?) {
        self.paymentInstrumentId = paymentInstrumentId
        self.csc = csc
        super.init(amount: amount,
                   tmxSessionId: tmxSessionId,
                   confirmation: confirmation,
                   savePaymentMethod: savePaymentMethod)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encode(tmxSessionId, forKey: .tmxSessionId)
        try container.encodeIfPresent(confirmation, forKey: .confirmation)
        try container.encodeIfPresent(savePaymentMethod, forKey: .savePaymentMethod)
        try container.encode(paymentInstrumentId, forKey: .paymentInstrumentId)
        try container.encodeIfPresent(csc, forKey: .csc)
    }

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let amount = try container.decodeIfPresent(MonetaryAmount.self, forKey: .amount)
        let tmxSessionId = try container.decode(String.self, forKey: .tmxSessionId)
        let confirmation = try container.decodeIfPresent(Confirmation.self, forKey: .confirmation)
        let savePaymentMethod = try container.decodeIfPresent(Bool.self, forKey: .savePaymentMethod)
        let paymentInstrumentId = try container.decode(String.self, forKey: .paymentInstrumentId)
        let csc = try container.decodeIfPresent(String.self, forKey: .csc)

        self.init(amount: amount,
                  tmxSessionId: tmxSessionId,
                  confirmation: confirmation,
                  savePaymentMethod: savePaymentMethod,
                  paymentInstrumentId: paymentInstrumentId,
                  csc: csc)
    }

    private enum CodingKeys: String, CodingKey {
        case tmxSessionId = "tmx_session_id"
        case amount = "amount"
        case confirmation
        case savePaymentMethod = "save_payment_method"
        case paymentInstrumentId = "payment_instrument_id"
        case csc
    }
}
