//
//  AESUpdateFile.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/30.
//

import Foundation

final class AESUpdateFile: AESBaseFile {
    let fileHandle: SCFileHandle
    let cryptor: AESCryptor

    /// readable file size
    private var fileSize = UInt64(0)

    init(deviceKey: Data, header: AESHeader, filePath: String) throws {
        fileHandle = try SCFileHandle(path: filePath, option: .append)
        guard let nonce = header.values[.nonce] else {
            throw AESError.nonceIsNil
        }
        self.cryptor = AESCryptor(operation: .encrypt, key: deviceKey, iv: nonce)
        
        _ = try self.seek(from: .end, offset: 0)

        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        fileSize = max(size - AESHeader.size, 0)
    }

    func read(maxLength len: UInt32, position: UInt64?) throws -> Data {
        let count = min(UInt64(len), fileSize)
        let divider = UInt64(AESCryptorDivider)
        var groups = count / divider
        if count % divider > 0 {
            groups += 1
        }
        var result = Data()
        for index in 0 ..< groups {
            try autoreleasepool {
                let length = min(divider, UInt64(fileSize) - index * divider)
                guard let data = try fileHandle.read(upToCount: Int(length)) else {
                    return
                }
                let decryptedData = try cryptor.updateData(with: data)
                result.append(decryptedData)
            }
        }
        return result
    }
    
    func readToEnd() throws -> Data? {
        try read(maxLength: UInt32(fileSize), position: nil)
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
}
