//
//  EncryptoIdKit.swift
//  ByteViewTracker
//
//  Created by kiri on 2021/6/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import CryptoSwift

public struct EncryptoIdKit {
    // 加密 userID 算法与 tea 平台一致
    public static func encryptoId(_ id: String) -> String {
        let encryptoId = prefixToken() + (id + suffixToken()).md5()
        return encryptoId.sha1()
    }

    private static func prefixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return String(prefix.prefix(6))
        }
        return prefix
    }

    private static func suffixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return String(prefix.suffix(6))
        }
        return prefix
    }
}
