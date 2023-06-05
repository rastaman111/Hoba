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

import YooMoneyCoreApi

/// Payments API error
public struct PaymentsApiError: Error, JsonApiResponse, PaymentsErrorApiResponse {

    /// The error ID in which it is possible to find operation in Kibana.
    public let id: String?

    /// Object type.
    public let type: PaymentErrorType

    /// Detailed description of the error.
    public let description: String?

    /// The name of the parameter that caused the error.
    public let parameter: String?

    /// The recommended number of milliseconds after which to retry the query.
    public let retryAfter: String?

    /// Error code.
    public let errorCode: PaymentErrorCode

    /// Creates instance of PaymentError.
    ///
    /// - Parameters:
    ///   - id: The error ID in which it is possible to find operation in Kibana.
    ///   - type: Object type.
    ///   - description: Detailed description of the error.
    ///   - parameter: The name of the parameter that caused the error.
    ///   - retryAfter: The recommended number of milliseconds after which to retry the query.
    ///   - errorCode: Error code.
    /// - Returns: Instance of `PaymentsApiError`.
    public init(id: String?,
                type: PaymentErrorType,
                description: String?,
                parameter: String?,
                retryAfter: String?,
                errorCode: PaymentErrorCode) {
        self.id = id
        self.type = type
        self.description = description
        self.parameter = parameter
        self.retryAfter = retryAfter
        self.errorCode = errorCode
    }

    // MARK: - Codable

    /// Creates a new instance by decoding from the given decoder.
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(String.self, forKey: .id)
        let type = try container.decode(PaymentErrorType.self, forKey: .type)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        let parameter = try container.decodeIfPresent(String.self, forKey: .parameter)
        let retryAfter = try container.decodeIfPresent(String.self, forKey: .retryAfter)
        let errorCode = try container.decode(PaymentErrorCode.self, forKey: .code)
        self.init(id: id,
                  type: type,
                  description: description,
                  parameter: parameter,
                  retryAfter: retryAfter,
                  errorCode: errorCode)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case description
        case parameter
        case retryAfter = "retry_after"
        case code
    }
}
