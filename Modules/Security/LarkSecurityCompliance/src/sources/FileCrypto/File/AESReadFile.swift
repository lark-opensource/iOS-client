//
//  AESFile.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/30.
//

import UIKit
import CommonCrypto

final class AESReadFile: AESBaseFile {
    let fileHandle: SCFileHandle
    let cryptor: AESCryptor

    /// readable file size
    private var fileSize = UInt64(0)

    init(deviceKey: Data, header: AESHeader, filePath: String) throws {
        fileHandle = try SCFileHandle(path: filePath, option: .read)
        guard let nonce = header.values[.nonce] else {
            throw AESError.nonceIsNil
        }

        self.cryptor = AESCryptor(operation: .decrypt, key: deviceKey, iv: nonce)
        try fileHandle.seek(toOffset: AESHeader.size)

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
                guard let data = try fileHandle.read(upToCount: Int(length)) else { return }
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
        throw AESError.operationIsError("read mode cannot write")
    }
}
