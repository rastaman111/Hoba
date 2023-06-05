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

/// Request the tokenization of the buyer's payment data required
/// to create a payment method (payment_method) to be paid by the user.
public final class TokensRequestPaymentMethodData: TokensRequest {

    /// Data required to create a payment method
    /// (payment_method) that the user will pay.
    public let paymentMethodData: PaymentMethodData

    /// The unique identifier of the buyer by which the merchant identifies him. It can be represented as:
    /// - The buyer's phone number.
    /// - The buyer's email addresses.
    /// - By some other identifier by which the merchant can uniquely identify the buyer.
    public let merchantCustomerId: String?

    /// Indicates whether payment data can be saved for repeated payments in merchant stores.
    public let savePaymentInstrument: Bool?

    /// Creates instance of `TokensRequestPaymentMethodData`.
    ///
    /// - Parameters:
    ///   - amount: Payment amount, the nominal value of the order for the buyer.
    ///   - tmxSessionId: ThreatMetrix session ID.
    ///   - confirmation: Payment confirmation method.
    ///   - paymentMethodData: Data required to create a payment method
    ///                        (payment_method) that the user will pay.
    ///
    /// - Returns: Instance of `TokensRequestPaymentMethodData`
    public init(
        amount: MonetaryAmount?,
        tmxSessionId: String,
        confirmation: Confirmation?,
        savePaymentMethod: Bool?,
        paymentMethodData: PaymentMethodData,
        merchantCustomerId: String?,
        savePaymentInstrument: Bool?
    ) {
        self.paymentMethodData = paymentMethodData
        self.merchantCustomerId = merchantCustomerId
        self.savePaymentInstrument = savePaymentInstrument
        super.init(
            amount: amount,
            tmxSessionId: tmxSessionId,
            confirmation: confirmation,
            savePaymentMethod: savePaymentMethod
        )
    }

    public override func customHeaders() -> Headers {
        return paymentMethodData.customHeaders()
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
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encode(tmxSessionId, forKey: .tmxSessionId)
        try container.encodeIfPresent(confirmation, forKey: .confirmation)
        try container.encodeIfPresent(savePaymentMethod, forKey: .savePaymentMethod)
        try container.encodeIfPresent(merchantCustomerId, forKey: .merchantCustomerId)
        try container.encodeIfPresent(savePaymentInstrument, forKey: .savePaymentInstrument)
        try PaymentMethodDataFactory.encodePaymentMethodData(paymentMethodData, to: encoder)
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
        let merchantCustomerId = try container.decodeIfPresent(String.self, forKey: .merchantCustomerId)
        let savePaymentInstrument = try container.decodeIfPresent(Bool.self, forKey: .savePaymentInstrument)

        guard let paymentMethodData = PaymentMethodDataFactory.decodePaymentMethodData(from: decoder) else {
            throw DecodingErrors.unsupportedPaymentMethodData
        }

        self.init(
            amount: amount,
            tmxSessionId: tmxSessionId,
            confirmation: confirmation,
            savePaymentMethod: savePaymentMethod,
            paymentMethodData: paymentMethodData,
            merchantCustomerId: merchantCustomerId,
            savePaymentInstrument: savePaymentInstrument
        )
    }

    private enum CodingKeys: String, CodingKey {
        case tmxSessionId = "tmx_session_id"
        case amount = "amount"
        case confirmation
        case savePaymentMethod = "save_payment_method"
        case merchantCustomerId = "merchant_customer_id"
        case savePaymentInstrument = "save_payment_instrument"
    }

    /// Decoding errors.
    public enum DecodingErrors: Error {

        /// The received payment method is not supported.
        case unsupportedPaymentMethodData
    }
}
