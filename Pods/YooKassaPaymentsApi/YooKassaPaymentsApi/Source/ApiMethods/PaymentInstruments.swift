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

/// Deleting a payment instrument for repeated payments to merchant stores.
/// Deleting a payment instrument for one merchant's store will also
/// entail its deletion for all other merchant's stores.
public struct PaymentInstruments {

    /// Creates instance of `PaymentInstruments`.
    ///
    /// - Returns: Instance of `PaymentInstruments`.
    public init() { }

    /// API method for `PaymentInstruments`.
    public struct Method {

        /// Client application key.
        public let oauthToken: String
        
        /// ID of the payment instrument for repeated payments to the merchant's stores.
        public let paymentInstrumentId: String

        /// Creates instance of API method for `PaymentInstruments`.
        ///
        /// - Parameters:
        ///   - oauthToken: Client application key.
        ///   - paymentInstrumentId: ID of the payment instrument for repeated payments to the merchant's stores.
        ///
        /// - Returns: Instance of API method for `PaymentInstruments`.
        public init(oauthToken: String, paymentInstrumentId: String) {
            self.oauthToken = oauthToken
            self.paymentInstrumentId = paymentInstrumentId
        }
    }
}

// MARK: - Decodable

extension PaymentInstruments: Decodable {}

// MARK: - PaymentsApiResponse

extension PaymentInstruments: PaymentsApiResponse {}

// MARK: - JsonApiResponse

extension PaymentInstruments: JsonApiResponse {}

// MARK: - ApiMethod

extension PaymentInstruments.Method: ApiMethod {

    public typealias Response = PaymentInstruments

    public var hostProviderKey: String {
        return Constants.paymentsApiMethodsKey
    }

    public var httpMethod: HTTPMethod {
        return .delete
    }

    public var parametersEncoding: ParametersEncoding {
        return QueryParametersEncoder()
    }

    public var headers: Headers {
        return Headers([
            AuthorizationConstants.authorization: AuthorizationConstants.basicAuthorizationPrefix + oauthToken,
        ])
    }

    public func urlInfo(from hostProvider: HostProvider) throws -> URLInfo {
        return .components(
            host: try hostProvider.host(for: hostProviderKey),
            path: String(format: "/api/frontend/v3/payment_instruments/%@", paymentInstrumentId)
        )
    }
}

// MARK: - Method: Encodable, Decodable

extension PaymentInstruments.Method: Encodable, Decodable {

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        _ = encoder.container(keyedBy: CodingKeys.self)
    }

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        self.init(oauthToken: "", paymentInstrumentId: "")
    }

    private enum CodingKeys: CodingKey {}
}
