//
//  FoundationUtils.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/7/17.
//

import Foundation
import CommonCrypto

extension String {
    func md5() -> String {
        guard let data = self.data(using: .utf8) else {
            return self
        }

        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        #if swift(>=5.0)
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        #else
        _ = data.withUnsafeBytes { bytes in
            return CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
        #endif

        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func toBool() -> Bool? {
        if ["true", "1", "yes"].contains(self.lowercased()) {
            return true
        }
        if ["false", "0", "no"].contains(self.lowercased()) {
            return false
        }
        return nil
    }
}

extension URL {
    var urlParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
