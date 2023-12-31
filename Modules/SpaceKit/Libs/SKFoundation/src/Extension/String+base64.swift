//  Created by Songwen Ding on 2018/7/18.

import Foundation

extension String {
    public func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    public func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

extension String {
    var toISO88591Data: Data? {
        let estr = "iso-8859-1"
        let cfe = CFStringConvertIANACharSetNameToEncoding(estr as CFString)
        let se = CFStringConvertEncodingToNSStringEncoding(cfe)
        let encoding = String.Encoding(rawValue: se)

        return self.data(using: encoding)

    }

    var toBase64Data: Data? {
        return Data(base64Encoded: self)
    }
}
