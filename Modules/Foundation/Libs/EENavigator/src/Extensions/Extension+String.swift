//
//  Extension+String.swift
//  EENavigator
//
//  Created by liuwanlin on 2019/1/2.
//

import Foundation

extension String {
    var trimTrailingSlash: String {
        var result = self
        while result.hasSuffix("/") {
            result = "" + result.dropLast()
        }
        return result
    }
}

extension String {
    var base64: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        return data.base64EncodedString()
    }
}
