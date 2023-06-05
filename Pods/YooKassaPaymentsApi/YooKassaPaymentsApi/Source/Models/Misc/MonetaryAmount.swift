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

/// The amount in the selected currency.
public struct MonetaryAmount: Decodable, Encodable {

    /// Sum, a decimal number with a fixed point in the string representation.
    public let value: Decimal

    /// ISO-4217 3-alpha character code of payment currency.
    public let currency: String

    /// Creates instance of `MonetaryAmount`
    ///
    /// - Parameters:
    ///   - value
    ///   - currency
    ///
    /// - Returns: Instance of `MonetaryAmount`
    public init(value: Decimal, currency: String) {
        self.value = value
        self.currency = currency
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
        guard let value = Decimal(string: try container.decode(String.self, forKey: .value)) else {
            throw DecodingError.decimalConvent
        }
        let currency = try container.decode(String.self, forKey: .currency)

        self.init(value: value, currency: currency)
    }

    /// Encodes this value into the given encoder.
    /// If the value fails to encode anything, encoder will encode an empty keyed container in its place.
    /// This function throws an error if any values are invalid for the given encoder’s format.
    ///
    /// - Parameters:
    ///   - encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(describing: value), forKey: .value)
        try container.encode(currency, forKey: .currency)
    }

    private enum CodingKeys: String, CodingKey {
        case value
        case currency
    }

    enum DecodingError: Error {
        case decimalConvent
    }
}
