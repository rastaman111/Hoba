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

enum TokensRequestFactory {
    static func decodeTokensRequest(from decoder: Decoder) -> TokensRequest? {
        guard let container = try? decoder.singleValueContainer() else {
            return nil
        }

        if let response = try? container.decode(TokensRequestPaymentMethodData.self) {
            return response
        } else if let response = try? container.decode(TokensRequestPaymentMethodId.self) {
            return response
        } else if let response = try? container.decode(TokensRequestPaymentInstrumentId.self) {
            return response
        } else {
            return nil
        }
    }

    static func encodeTokensRequest(
        _ tokensRequest: TokensRequest, to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()
        switch tokensRequest {
        case let response as TokensRequestPaymentMethodData:
            try container.encode(response)
        case let response as TokensRequestPaymentMethodId:
            try container.encode(response)
        case let response as TokensRequestPaymentInstrumentId:
            try container.encode(response)
        default:
            try container.encode(tokensRequest)
        }
    }
}
