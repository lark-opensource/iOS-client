//
//  SKFilePath+Encrypt.swift
//  SKFoundation
//
//  Created by ByteDance on 2022/12/20.
//

import Foundation
import LarkStorage
import LarkFileKit

extension SKFilePath {
    public func getEncryptFile(isWriteBack: Bool = true) -> SKFilePath? {
        switch self {
        case let .isoPath(path):
            if let encryptPath = try? path.encrypt(suite: isWriteBack ? .writeBack : .default) {
                return .absPath(encryptPath)
            } else {
                return nil
            }
        case let .absPath(path):
            if let encryptPath = try? path.encrypt(suite: isWriteBack ? .writeBack : .default) {
                return .absPath(encryptPath)
            } else {
                return nil
            }
        }
    }
    
    // 解密后读取Data
    public func readDecryptData() throws -> Data {
        switch self {
        case let .isoPath(path):
            let cipherPath = path.usingCipher()
            return try Data.read(from: cipherPath)
        case let .absPath(path):
            spaceAssertionFailure("abs path not support")
            return try Data.read(from: path)
        }
    }
    private func oldGetEncryptFile(originPath: String, isWriteBack: Bool = true) -> String? {
        var encryptPath: LarkFileKit.Path?
        if isWriteBack {
            encryptPath = try? originPath.writeBackPath()
        } else {
            encryptPath = try? originPath.encrypt()
        }
        return encryptPath?.rawValue
    }
}
