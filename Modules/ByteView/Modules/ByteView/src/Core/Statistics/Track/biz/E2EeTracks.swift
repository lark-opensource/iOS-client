//
//  E2EeTracks.swift
//  ByteView
//
//  Created by ZhangJi on 2023/5/23.
//

import Foundation
import ByteViewTracker

final class E2EeTracks {
    enum EncryptType: String {
        case media
        case chat
    }

    enum EncryptError: Int {
        // 加解密数据长度为0
        case inputDataLengthZero = -1
        case ok = 0
        // 不是加密资源
        case notEncryptFile
        // 密钥或 nonce 不符合预期
        case badKey
        // 元数据过大
        case metadataTooLarge
        // 元数据解析失败
        case metadataParseFail
        // 元数据解密失败
        case decryptMetadatFail
        // 资源解密失败
        case decryptFileFail
        // IO 错误，可从 errno 取 system error
        case ioError
        // IO 错误，但没有 errno
        case ioUnknown
        // 路径不符合 utf8 要求
        case pathNoUtf8
        // 文件长度不符合预期
        case badFileLength
        // 不支持的算法
        case noSupportAlgorithm
        // 未知错误
        case unknown = 255
    }

    static func trackEncryptErrors(encryptErrors: [Int: Int], decryptErrors: [Int: Int], type: EncryptType) {
        for (key, count) in encryptErrors {
            let error = EncryptError(rawValue: key) ?? .unknown
            VCTracker.post(name: .vc_j2m_content_decrypt_status,
                           params: ["type": type,
                                    "fail_num": count,
                                    "status": "fail",
                                    "fail_step": "encrypt",
                                    "fail_reason": error.stringReason])
        }
        for (key, count) in decryptErrors {
            let error = EncryptError(rawValue: key) ?? .unknown
            VCTracker.post(name: .vc_j2m_content_decrypt_status,
                           params: ["type": type,
                                    "fail_num": count,
                                    "status": "fail",
                                    "fail_step": "decrypt",
                                    "fail_reason": error.stringReason])
        }
    }

    static func trackMeetingKeyStatus() {
        VCTracker.post(name: .vc_j2m_meeting_key_status,
                       params: ["status": "fail",
                                "fail_reason": "key_conflict_with_server"])
    }
}

extension E2EeTracks.EncryptError {
    var stringReason: String {
        switch self {
        case .inputDataLengthZero:
            return "INPUT_DATA_LENGTH_0"
        case .ok:
            return "OK"
        case .notEncryptFile:
            return "NOT_ENCRYPT_FILE"
        case .badKey:
            return "BAD_KEY"
        case .metadataTooLarge:
            return "METADATA_TOO_LARGE"
        case .metadataParseFail:
            return "METADATA_PARSE_FAIL"
        case .decryptMetadatFail:
            return "DECRYPT_METADATA_FAIL"
        case .decryptFileFail:
            return "DECRYPT_FILE_FAIL"
        case .ioError:
            return "IO_ERROR"
        case .ioUnknown:
            return "IO_UNKNOWN"
        case .pathNoUtf8:
            return "PATH_NO_UTF8"
        case .badFileLength:
            return "BAD_FILE_LENGTH"
        case .noSupportAlgorithm:
            return "NO_SUPPORT_ALGORITHM"
        case .unknown:
            return "UNKNOWN"
        }
    }
}
