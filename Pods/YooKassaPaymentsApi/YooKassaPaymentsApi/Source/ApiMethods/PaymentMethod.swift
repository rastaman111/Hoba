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
import FunctionalSwift
import YooMoneyCoreApi

/// Request information about your saved payment method.
/// The request allows you to get information about the saved payment method by its unique identifier.
/// In response to the request, the data of the saved payment method will come.
public struct PaymentMethod {

    /// Payment method code.
    public let type: PaymentMethodType

    /// The ID of the payment method.
    public let id: String

    /// You can use your saved payment method to make direct debits.
    public let saved: Bool

    /// The name of the payment method.
    public let title: String?

    /// To pay by credit card you need to enter CVV2/CVC2/CVP2 code.
    public let cscRequired: Bool

    /// Your credit card details.
    public let card: PaymentMethodBankCard?

    /// Creates instance of `PaymentMethod`.
    ///
    /// - Parameters:
    ///   - type: Payment method code.
    ///   - id: The ID of the payment method.
    ///   - saved: You can use your saved payment method to make direct debits.
    ///   - title: The name of the payment method.
    ///   - cscRequired: To pay by credit card you need to enter CVV2/CVC2/CVP2 code.
    ///   - card: Your credit card details.
    ///
    /// - Returns: Instance of `PaymentMethod`.
    public init(type: PaymentMethodType,
                id: String,
                saved: Bool,
                title: String?,
                cscRequired: Bool,
                card: PaymentMethodBankCard?) {
        self.type = type
        self.id = id
        self.saved = saved
        self.title = title
        self.cscRequired = cscRequired
        self.card = card
    }

    /// API method for `PaymentMethod`.
    public struct Method {

        /// Client application key.
        public let oauthToken: String

        /// The ID of the saved payment method.
        public let paymentMethodId: String

        /// Creates instance of API method for `PaymentMethod`.
        ///
        /// - Parameters:
        ///   - oauthToken: Client application key.
        ///   - paymentMethodId: The ID of the saved payment method.
        ///
        /// - Returns: Instance of API method for `PaymentMethod`.
        public init(oauthToken: String,
                    paymentMethodId: String) {
            self.oauthToken = oauthToken
            self.paymentMethodId = paymentMethodId
        }
    }
}

// MARK: - Decodable

extension PaymentMethod: Decodable {

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(PaymentMethodType.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        let saved = try container.decode(Bool.self, forKey: .saved)
        let title = try container.decodeIfPresent(String.self, forKey: .title)
        let cscRequired = try container.decode(Bool.self, forKey: .cscRequired)
        let card = try container.decodeIfPresent(PaymentMethodBankCard.self, forKey: .card)

        self.init(
            type: type,
            id: id,
            saved: saved,
            title: title,
            cscRequired: cscRequired,
            card: card
        )
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case saved
        case title
        case cscRequired = "csc_required"
        case card
    }
}

// MARK: - PaymentsApiResponse

extension PaymentMethod: PaymentsApiResponse {}

// MARK: - JsonApiResponse

extension PaymentMethod: JsonApiResponse {}

// MARK: - ApiMethod

extension PaymentMethod.Method: ApiMethod {
    public typealias Response = PaymentMethod

    public var hostProviderKey: String {
        return Constants.paymentsApiMethodsKey
    }

    public var httpMethod: HTTPMethod {
        return .get
    }

    public var parametersEncoding: ParametersEncoding {
        return QueryParametersEncoder()
    }

    public var headers: Headers {
        let headers = Headers(
            [
                AuthorizationConstants.authorization: AuthorizationConstants.basicAuthorizationPrefix + oauthToken,
            ]
        )
        return headers
    }

    public func urlInfo(from hostProvider: HostProvider) throws -> URLInfo {
        return .components(host: try hostProvider.host(for: hostProviderKey),
                           path: "/api/frontend/v3/payment_method")
    }
}

// MARK: - Method: Encodable, Decodable

extension PaymentMethod.Method: Encodable, Decodable {

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethodId, forKey: .paymentMethodId)
    }

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let paymentMethodId = try container.decode(String.self, forKey: .paymentMethodId)
        self.init(oauthToken: "", paymentMethodId: paymentMethodId)
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
    }
}
