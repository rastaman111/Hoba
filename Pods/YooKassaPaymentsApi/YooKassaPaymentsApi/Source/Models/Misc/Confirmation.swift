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

/// Payment confirmation method.
public struct Confirmation {

    /// Type of custom payment confirmation process.
    /// Read more about the scenarios of [confirmation of payment](https://yookassa.ru/docs/guides/#confirmation)
    /// by the buyer.
    public let type: ConfirmationType

    /// Address of the page to which the user will return.
    public let returnUrl: String?

    /// Creates instance of Confirmation.
    ///
    /// - Parameters:
    ///   - type: Type of custom payment confirmation process.
    ///           Read more about the scenarios of [confirmation of payment](https://yookassa.ru/docs/guides/#confirmation)
    ///           by the buyer.
    ///   - returnUrl: Address of the page to which the user will return.
    public init(type: ConfirmationType,
                returnUrl: String?) {
        self.type = type
        self.returnUrl = returnUrl
    }
}

// MARK: - Codable

extension Confirmation: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ConfirmationType.self, forKey: .type)
        let returnUrl = try container.decodeIfPresent(String.self, forKey: .returnUrl)
        self.init(type: type, returnUrl: returnUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(returnUrl, forKey: .returnUrl)
        
        if type == .mobileApplication {
            try container.encode("ios", forKey: .appOSType)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case returnUrl = "return_url"
        case appOSType = "app_os_type"
    }
}
