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

/// Indication of the possibility of saving payment data for repeated payments.
public enum SavePaymentMethod: RawRepresentable, Codable, Equatable {

    /// Allow to save payment method.
    case allowed

    /// Cannot save payment method.
    case forbidden

    /// Unsupported field type.
    case unknown(String)

    // MARK: - RawRepresentable

    private enum _SavePaymentMethod: String {
        case allowed
        case forbidden
    }

    public typealias RawValue = String

    public init(rawValue: SavePaymentMethod.RawValue) {
        if let value = _SavePaymentMethod(rawValue: rawValue) {
            switch value {
            case .allowed:
                self = .allowed
            case .forbidden:
                self = .forbidden
            }
        } else {
            self = .unknown(rawValue)
        }
    }

    public var rawValue: SavePaymentMethod.RawValue {
        switch self {
        case .allowed:
            return _SavePaymentMethod.allowed.rawValue
        case .forbidden:
            return _SavePaymentMethod.forbidden.rawValue
        case .unknown(let value):
            return value
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(rawValue: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    // MARK: - Equatable

    public static func == (lhs: SavePaymentMethod, rhs: SavePaymentMethod) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
