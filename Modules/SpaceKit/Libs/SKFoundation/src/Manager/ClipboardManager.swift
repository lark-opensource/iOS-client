//
//  ClipboardManager.swift
//  SpaceKit
//
//  Created by huangzhikai on 2022/09/08
//

import Foundation

public final class ClipboardManager {
    public static let shared = ClipboardManager()
    
    // key: 文档token， 加密 id
    private var encryptMap = [String: String]()
    
    private init() {}
    // 设置和更新对应文档的encryptId
    public func updateEncryptId(token: String, encryptId: String?) {
        encryptMap[token] = encryptId
    }
    
    //通过token 获取 encryptId
    public func getEncryptId(token: String?) -> String? {
        guard let token = token else {
            return nil
        }
        return encryptMap[token]
    }
}
