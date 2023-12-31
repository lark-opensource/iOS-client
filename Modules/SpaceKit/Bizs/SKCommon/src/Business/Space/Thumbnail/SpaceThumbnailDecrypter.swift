//
//  SpaceThumbnailDecrypter.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  

import Foundation
import CryptoSwift
import CommonCrypto
import CryptoKit
import SKFoundation
import SKInfra

// nolint-next-line: magic number
private let minDataLength = 18
// nolint-next-line: magic number
private let dataSplitIdx = 16

enum SpaceThumbnailDecryptError: LocalizedError {
    case dataTooShort
    case GCMParametersEncodeFailed
    case CBCDecryptFailed(code: CCCryptorStatus)
    case invalidImageData
    case SM4GCMDecryptImplNotInjected

    var errorDescription: String? {
        switch self {
        case .dataTooShort:
            return "encrypt data is too short to be decrypt"
        case .GCMParametersEncodeFailed:
            return "failed to encode GCM parameters before decrypt"
        case let .CBCDecryptFailed(code):
            return "CBC decryption failed with code: \(code)"
        case .invalidImageData:
            return "failed to convert data to image"
        case .SM4GCMDecryptImplNotInjected:
            return "SM4GCMDecryptImplNotInjected"
        }
    }
}

protocol SpaceThumbnailDecrypter {
    typealias DecryptError = SpaceThumbnailDecryptError
    func decrypt(encryptedData: Data) throws -> Data
}

struct TransparentDecrypter: SpaceThumbnailDecrypter {

    func decrypt(encryptedData: Data) throws -> Data {
        return encryptedData
    }

}

@available(iOS 13.0, *)
struct CryptoKitGCMDecrypter: SpaceThumbnailDecrypter {

    var secret: String
    var nonce: String

    func decrypt(encryptedData: Data) throws -> Data {
        let dataBytes = encryptedData.bytes
        let count = dataBytes.count
        guard count > minDataLength else { throw DecryptError.dataTooShort }

        guard let nonceData = Data(base64Encoded: nonce),
            let secretData = Data(base64Encoded: secret) else {
                throw DecryptError.GCMParametersEncodeFailed
        }
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let symmetricKey = SymmetricKey(data: secretData)

        let tagBytes = dataBytes.suffix(from: count - dataSplitIdx)
        let cipherBytes = dataBytes.prefix(upTo: count - dataSplitIdx)

        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: cipherBytes, tag: tagBytes)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }

}

struct CryptoSwiftGCMDecrypter: SpaceThumbnailDecrypter {

    var secret: String
    var nonce: String

    func decrypt(encryptedData: Data) throws -> Data {
        DocsLogger.warning("CryptoSwift GCM decryption has performance issue, make sure you really need to use them.")
        let dataBytes = encryptedData.bytes
        let count = dataBytes.count
        guard count > minDataLength else { throw DecryptError.dataTooShort }
        guard let ivBytes = Data(base64Encoded: nonce)?.bytes,
            let aesKeyBytes = Data(base64Encoded: secret)?.bytes else {
                throw DecryptError.GCMParametersEncodeFailed
        }
        let tagBytes = Array(dataBytes.suffix(from: count - dataSplitIdx))
        let cipherBytes = dataBytes.prefix(upTo: count - dataSplitIdx)

        let gcm = GCM(iv: ivBytes, authenticationTag: tagBytes, mode: .detached)
        let aes = try AES(key: aesKeyBytes, blockMode: gcm)
        let decrypted = try aes.decrypt(cipherBytes)
        return Data(decrypted)
    }

}

struct CBCDecrypter: SpaceThumbnailDecrypter {

    var secret: String

    func decrypt(encryptedData: Data) throws -> Data {
        guard encryptedData.count > kCCBlockSizeAES128 else { throw DecryptError.dataTooShort }
        let keyBytes = secret.bytes.sha256()
        let key = Data(keyBytes)
        let iv = encryptedData.prefix(kCCBlockSizeAES128)
        let cipherContent = encryptedData.suffix(from: kCCBlockSizeAES128)
        return try key.withUnsafeBytes { keyUnsafePointer in
            return try cipherContent.withUnsafeBytes { cipherContentUnsafePointer in
                return try iv.withUnsafeBytes { ivUnsafePointer in
                    let resultDataSize: Int = cipherContent.count + kCCBlockSizeAES128 * 2
                    var resultDataActualSize: Int = 0
                    let resultDataPointer = UnsafeMutableRawPointer.allocate(byteCount: resultDataSize, alignment: 1)
                    defer {
                        resultDataPointer.deallocate()
                    }
                    let decryptResultCode = CCCrypt(CCOperation(kCCDecrypt),
                                                    CCAlgorithm(kCCAlgorithmAES),
                                                    CCOptions(kCCOptionPKCS7Padding),
                                                    keyUnsafePointer.baseAddress, key.count,
                                                    ivUnsafePointer.baseAddress,
                                                    cipherContentUnsafePointer.baseAddress, cipherContent.count,
                                                    resultDataPointer, resultDataSize, &resultDataActualSize)
                    guard decryptResultCode == kCCSuccess else {
                        DocsLogger.error("CBC thumbnail data decrypt failed", extraInfo: ["resultCode": decryptResultCode], component: LogComponents.spaceThumbnail)
                        throw DecryptError.CBCDecryptFailed(code: decryptResultCode)
                    }
                    let resultData = Data(bytes: resultDataPointer, count: resultDataActualSize)
                    return resultData
                }
            }
        }
    }
}

public protocol SM4GCMExternalDecrypter {
    func decrypt(encryptedData: Data, secret: String, nonce: String) throws -> Data
}

struct SM4GCMDecrypter: SpaceThumbnailDecrypter {

    var secret: String
    var nonce: String

    func decrypt(encryptedData: Data) throws -> Data {
        guard let decryptImpl = DocsContainer.shared.resolve(SM4GCMExternalDecrypter.self) else {
            throw DecryptError.SM4GCMDecryptImplNotInjected
        }

        return try decryptImpl.decrypt(encryptedData: encryptedData, secret: secret, nonce: nonce)
    }
}
