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

/// Method of payment through YooMoney.
public class PaymentInstrumentYooMoneyWallet: PaymentOptionYooMoneyInstrument {

    /// Wallet account number.
    public let accountId: String

    /// The amount in the selected currency.
    public let balance: MonetaryAmount

    /// Creates instance of `PaymentInstrumentYooMoneyWallet`.
    ///
    /// - Parameters:
    ///   - paymentMethodType: Type of the source of funds for the payment.
    ///   - confirmationType: List of possible methods of payment confirmation.
    ///                       If payment confirmation is not required, the field is missing.
    ///                       Read more about the scenarios of
    ///                       [confirmation of payment](https://yookassa.ru/docs/guides/#confirmation) by the buyer.
    ///   - charge: The amount to be paid by the buyer subject to possible currency
    ///             conversion and additional fees in excess of the payment amount.
    ///   - instrumentType: The type of the source of funds for payments from the YooMoney.
    ///   - accountId: Wallet account number.
    ///   - balance: The amount in the selected currency.
    ///   - identificationRequirement: Required type of user identification.
    ///   - fee: Commission from the buyer in excess of the payment amount.
    ///          The field is present if there are commissions in excess of the payment amount.
    ///   - savePaymentMethod: Indication of the possibility of saving payment data for repeated payments.
    ///
    /// - Returns: Instance of `PaymentInstrumentYooMoneyWallet`.
    public init(
        paymentMethodType: PaymentMethodType,
        confirmationTypes: Set<ConfirmationType>?,
        charge: MonetaryAmount,
        instrumentType: YooMoneyInstrumentType,
        accountId: String,
        balance: MonetaryAmount,
        identificationRequirement: IdentificationRequirement?,
        fee: Fee?,
        savePaymentMethod: SavePaymentMethod,
        savePaymentInstrument: Bool?
    ) {
        self.accountId = accountId
        self.balance = balance
        super.init(
            paymentMethodType: paymentMethodType,
            confirmationTypes: confirmationTypes,
            charge: charge,
            instrumentType: instrumentType,
            identificationRequirement: identificationRequirement,
            fee: fee,
            savePaymentMethod: savePaymentMethod,
            savePaymentInstrument: savePaymentInstrument
        )
    }

    // MARK: - Codable

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(String.self, forKey: .accountId)
        balance = try container.decode(MonetaryAmount.self, forKey: .balance)
        try super.init(from: decoder)
    }

    private enum CodingKeys: String, CodingKey {
        case accountId = "id"
        case balance
    }
}
