//
//  AESWriteFile.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/30.
//

import UIKit

// ignoring lark storage check for SBCipher implementation
// lint:disable lark_storage_check

final class AESWriteFile: AESBaseFile {
    let fileHandle: SCFileHandle
    let cryptor: AESCryptor

    init(deviceKey: Data, header: AESHeader, filePath: String) throws {
        guard let nonce = header.values[.nonce] else {
            throw AESError.nonceIsNil
        }
        
        self.cryptor = AESCryptor(operation: .encrypt, key: deviceKey, iv: nonce)
        if FileManager.default.fileExists(atPath: filePath) {
            try FileManager.default.removeItem(atPath: filePath)
        }
        FileManager.default.createFile(atPath: filePath, contents: nil)
        fileHandle = try SCFileHandle(path: filePath, option: .write)
        try fileHandle.write(contentsOf: header.data)
    }

    func read(maxLength len: UInt32, position: UInt64?) throws -> Data {
        throw AESError.operationIsError("write mode cannot read")
    }

    func write(data: Data, position: UInt64?) throws -> UInt32 {
        let count = data.bytes.count
        var groups = count / AESCryptorDivider
        if count % AESCryptorDivider > 0 {
            groups += 1
        }
        for index in 0 ..< groups {
            try autoreleasepool {
                let minV = index * AESCryptorDivider
                let maxV = min((index + 1) * AESCryptorDivider, count)
                let subData = data.subdata(in: minV ..< maxV)
                let encrypted = try cryptor.updateData(with: subData)
                try fileHandle.write(contentsOf: encrypted)
            }
        }

        return UInt32(data.count)
    }
    
    func readToEnd() throws -> Data? {
        throw AESError.operationIsError("write mode cannot read")
    }
}
