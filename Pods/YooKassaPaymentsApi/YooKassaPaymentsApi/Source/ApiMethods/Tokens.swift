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
import YooMoneyCoreApi

/// Tokenization payments data.
public struct Tokens: Codable {

    /// One-time token for payment.
    public let paymentToken: String

    /// Creates instance of `Tokens`.
    ///
    /// - Parameters:
    ///   - paymentToken: One-time token for payment.
    ///
    /// - Returns: Instance of `Tokens`.
    public init(paymentToken: String) {
        self.paymentToken = paymentToken
    }

    private enum CodingKeys: String, CodingKey {
        case paymentToken = "payment_token"
    }

    /// API method for `Tokens`.
    public struct Method: Codable {

        /// Client application key.
        public let oauthToken: String

        /// Request for tokenization of the buyer's payment data for subsequent payment.
        public let tokensRequest: TokensRequest

        /// Creates instance of API method for `Tokens`.
        ///
        /// - Parameters:
        ///   - oauthToken: Client application key.
        ///   - tokensRequest: Request for tokenization of the buyer's payment data for subsequent payment.
        ///
        /// - Returns: Instance of API method for `Tokens`.
        public init(oauthToken: String,
                    tokensRequest: TokensRequest) {
            self.oauthToken = oauthToken
            self.tokensRequest = tokensRequest
        }

        /// Creates a new instance by decoding from the given decoder.
        /// This initializer throws an error if reading from the decoder fails,
        /// or if the data read is corrupted or otherwise invalid.
        ///
        /// - Parameters:
        ///   - decoder: The decoder to read data from.
        public init(from decoder: Decoder) throws {
            guard let tokensRequest = TokensRequestFactory.decodeTokensRequest(from: decoder) else {
                throw DecodingErrors.unsupportedTokensRequest
            }
            self.init(oauthToken: "", tokensRequest: tokensRequest)
        }

        /// Encodes this value into the given encoder.
        /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
        /// This function throws an error if any values are invalid for the given encoder’s format.
        ///
        /// - Parameters:
        ///   - encoder: The encoder to write data to.
        public func encode(to encoder: Encoder) throws {
            try TokensRequestFactory.encodeTokensRequest(tokensRequest, to: encoder)
        }

        /// Decoding errors.
        public enum DecodingErrors: Error {

            /// The received payment method is not supported.
            case unsupportedTokensRequest
        }
    }
}

// MARK: - PaymentsApiResponse

extension Tokens: PaymentsApiResponse {
}

// MARK: - JsonApiResponse

extension Tokens: JsonApiResponse {
}

// MARK: - ApiMethod

extension Tokens.Method: ApiMethod {

    public typealias Response = Tokens

    public var hostProviderKey: String {
        return Constants.paymentsApiMethodsKey
    }
    public var httpMethod: HTTPMethod {
        return .post
    }
    public var parametersEncoding: ParametersEncoding {
        return JsonParametersEncoder()
    }

    public var headers: Headers {
        let requiredHeaders = Headers([
            AuthorizationConstants.authorization: AuthorizationConstants.basicAuthorizationPrefix + oauthToken,
        ])

        return requiredHeaders.mappend(tokensRequest.customHeaders())
    }

    public func urlInfo(from hostProvider: HostProvider) throws -> URLInfo {
        return .components(host: try hostProvider.host(for: hostProviderKey),
                           path: "/api/frontend/v3/tokens")
    }
}
