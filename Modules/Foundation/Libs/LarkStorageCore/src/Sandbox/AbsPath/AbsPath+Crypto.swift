//
//  AbsPath+Crypto.swift
//  LarkStorage
//
//  Created by 7Up on 2023/4/4.
//

import Foundation

extension AbsPath {
    /// 对 path 进行原址加密
    public func encryptInPlace() throws {
        guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
            return
        }
        let _ = try cipher.encryptPath(absoluteString)
    }

    /// 对 path 进行解密，返回新的解密路径
    public func decrypted() throws -> AbsPath {
        return try SBUtils.decrypt(atPath: self)
    }
}
