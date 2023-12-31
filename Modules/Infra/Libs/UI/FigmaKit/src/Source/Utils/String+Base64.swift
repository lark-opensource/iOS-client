//
//  String+Base64.swift
//  EEAtomic
//
//  Created by Hayden Wang on 2021/9/2.
//

import Foundation

extension String {

    // Tool: https://www.base64encode.org/

    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
