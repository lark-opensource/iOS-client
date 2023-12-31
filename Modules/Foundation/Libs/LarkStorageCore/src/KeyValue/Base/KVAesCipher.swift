//
//  KVAesCipher.swift
//  LarkStorageAssembly
//
//  Created by 7Up on 2022/9/29.
//

import Foundation
import CommonCrypto

/// AES 加密
final class KVAesCipher: KVCipher {
    // "uVwLUX9KLkeQQE6f" 随机生成的 16 位字符串
    // nolint-next-line: magic_number
    private static var key: [UInt8] = [117, 86, 119, 76, 85, 88, 57, 75, 76, 107, 101, 81, 81, 69, 54, 102]

    func encrypt(_ data: Data) throws -> Data {
        return try Self.crypt(operation: CCOperation(kCCEncrypt), data: data)
    }

    func decrypt(_ data: Data) throws -> Data {
        return try Self.crypt(operation: CCOperation(kCCDecrypt), data: data)
    }

    private static func crypt(operation: CCOperation, data: Data) throws -> Data {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)

        var numBytesEncrypted = 0

        let status: CCCryptorStatus = try buffer.withUnsafeMutableBytes { bufferPtr in
            try data.withUnsafeBytes { dataPtr in
                // 获取 data, buffer 的原始指针
                guard let bufferAddr = bufferPtr.baseAddress,
                      let dataAddr = dataPtr.baseAddress
                else { throw KVAesCipherError.rawPointerError }
                // 使用 AES128 算法
                let algorithm = CCAlgorithm(kCCAlgorithmAES128)
                // 使用简单的 ECB 模式，不需要提供 IV
                let options = CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding)
                // 进行加解密计算，返回计算状态
                return CCCrypt(operation, algorithm, options, &Self.key, kCCKeySizeAES128, nil,
                               dataAddr, data.count, bufferAddr, bufferSize, &numBytesEncrypted)
            }
        }

        guard Int(status) == kCCSuccess else {
            throw KVAesCipherError.cryptoFailure(status: Int(status))
        }
        // 裁剪多余的 buffer
        buffer.count = numBytesEncrypted
        return buffer
    }
}

enum KVAesCipherError: Error {
    // CommonCrypto 错误
    case cryptoFailure(status: Int)
    // 获取 Data 的原始指针时出错
    case rawPointerError
}

extension KVAesCipherError: CustomStringConvertible {
    var description: String {
        switch self {
        case .cryptoFailure(let status):
            switch status {
            case kCCSuccess:
                return "not failed"
            case kCCParamError:
                return "illegal crypt parameter"
            case kCCBufferTooSmall:
                return "insufficent buffer provided for specified operation"
            case kCCMemoryFailure:
                return "memory allocation failure"
            case kCCAlignmentError:
                return "input size was not aligned properly"
            case kCCDecodeError:
                return "input data did not decode or decrypt properly"
            case kCCUnimplemented:
                return "function not implemented for the current algorithm"
            case kCCKeySizeError:
                return "invalid crypt key size"
            case kCCInvalidKey:
                return "invalid crypt key"
            default:
                return "unknown crypt status code: \(status)"
            }
        case .rawPointerError:
            return "failed to get raw pointer"
        }
    }
}
