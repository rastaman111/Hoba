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

/// Definition of payment method:
///
/// - payment type.
/// - the ways of its confirmation.
/// - the availability and Commission rate to the buyer.
public class PaymentOption: Codable {

    /// Type of the source of funds for the payment.
    /// - Example: bank_card
    public let paymentMethodType: PaymentMethodType

    /// List of possible methods of payment confirmation.
    /// If payment confirmation is not required, the field is missing.
    /// Read more about the scenarios of
    /// [confirmation of payment](https://yookassa.ru/docs/guides/#confirmation) by the buyer.
    /// - Example: redirect
    public let confirmationTypes: Set<ConfirmationType>?

    /// The amount to be paid by the buyer subject to possible currency
    /// conversion and additional fees in excess of the payment amount.
    public let charge: MonetaryAmount

    /// Required type of user identification.
    public let identificationRequirement: IdentificationRequirement?

    /// Commission from the buyer in excess of the payment amount.
    /// The field is present if there are commissions in excess of the payment amount.
    public let fee: Fee?

    /// Indication of the possibility of saving payment data for repeated payments.
    public let savePaymentMethod: SavePaymentMethod
    
    /// Indicates whether payment data can be saved for repeated payments in merchant stores.
    public let savePaymentInstrument: Bool?

    /// Creates instance of `PaymentOption`.
    ///
    /// - Parameters:
    ///   - paymentMethodType: Type of the source of funds for the payment.
    ///   - confirmationType: List of possible methods of payment confirmation.
    ///                       If payment confirmation is not required, the field is missing.
    ///                       Read more about the scenarios of
    ///                       [confirmation of payment](https://yookassa.ru/docs/guides/#confirmation) by the buyer.
    ///   - charge: The amount to be paid by the buyer subject to possible currency
    ///             conversion and additional fees in excess of the payment amount.
    ///   - identificationRequirement: Required type of user identification.
    ///   - fee: Commission from the buyer in excess of the payment amount.
    ///          The field is present if there are commissions in excess of the payment amount.
    ///   - savePaymentMethod: Indication of the possibility of saving payment data for repeated payments.
    ///   - savePaymentInstrument: Indicates whether payment data can be saved for repeated payments in merchant stores.
    ///
    /// - Returns: Instance of `PaymentOption`
    public init(paymentMethodType: PaymentMethodType,
                confirmationTypes: Set<ConfirmationType>?,
                charge: MonetaryAmount,
                identificationRequirement: IdentificationRequirement?,
                fee: Fee?,
                savePaymentMethod: SavePaymentMethod,
                savePaymentInstrument: Bool?) {
        self.paymentMethodType = paymentMethodType
        self.confirmationTypes = confirmationTypes
        self.charge = charge
        self.identificationRequirement = identificationRequirement
        self.fee = fee
        self.savePaymentMethod = savePaymentMethod
        self.savePaymentInstrument = savePaymentInstrument
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodType = "payment_method_type"
        case confirmationTypes = "confirmation_types"
        case charge
        case identificationRequirement = "identification_requirement"
        case fee
        case savePaymentMethod = "save_payment_method"
        case savePaymentInstrument = "save_payment_instrument"
    }
}
