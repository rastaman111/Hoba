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

/// Payment error code
///
/// - Errors for HTTP status 400 (Bad Request).
///   - invalidRequest: The request cannot be processed. The reason may be incorrect query syntax,
///                     an error in the required query parameters, their absence or unsupported method.
///   - notSupported: The request cannot be processed. The reason may be incorrect query syntax,
///                   an error in the required query parameters, their absence or unsupported method.
///
/// - Errors for HTTP status 401 (Unauthorized). Authentication or authorization error.
///   - invalidCredentials: Incorrect key is specified in the Authorization header.
///
/// - Errors for HTTP status 403 (Forbidden). Operation not allowed for user.
///   - forbidden: Not enough rights to perform the operation.
///
/// - Error for HTTP status 500 (Internal Server Error). Technical Error.
///   - internalServerError: Technical error.
///
/// - Common errors.
///   - mappingError: Error processing response from server.
public enum PaymentErrorCode: String, Codable {

    // MARK: - 400

    /// The request cannot be processed. The reason may be incorrect query syntax,
    /// an error in the required query parameters, their absence or unsupported method.
    case invalidRequest = "invalid_request"

    /// The request cannot be processed. The reason may be incorrect query syntax,
    /// an error in the required query parameters, their absence or unsupported method.
    case notSupported = "not_supported"

    // MARK: - 401

    /// Incorrect key is specified in the Authorization header.
    case invalidCredentials = "invalid_credentials"

    // MARK: - 403

    /// Not enough rights to perform the operation.
    case forbidden = "forbidden"

    // MARK: - 500

    /// Technical error.
    case internalServerError = "internal_server_error"

    // MARK: - Common errors

    /// Error processing response from server
    case mappingError
}
