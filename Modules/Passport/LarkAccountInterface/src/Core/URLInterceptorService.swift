//
//  URLInterceptorService.swift
//  LarkAccountInterface
//
//  Created by CharlieSu on 1/3/20.
//

import Foundation

// swiftlint:disable missing_docs
// swiftlint:disable inclusive_language
/// unlogin whitelist
public var unloginWhitelist: [String] = []

/// register unlogin whitelist
public enum UnloginWhitelistRegistry {
    // register
    public static func registerUnloginWhitelist(_ pattern: String) {
        unloginWhitelist.append(pattern)
    }
}

// swiftlint:enable missing_docs
