//
//  SBUtil+Crypto.swift
//  LarkStorage
//
//  Created by 7Up on 2023/8/28.
//

import Foundation

// MARK: - Encrypt/Decrypt Path

extension SBUtils {
    @inline(__always)
    internal static func cipher(forSuite: SBCipherSuite) -> SBCipher? {
        return SBCipherManager.shared.cipher(for: .default)
    }
}

/// 基于整文件加解密接口
/// - SeeAlso: [加解密 - 使用说明](https://bytedance.feishu.cn/wiki/UcLPwYREFiusKbkkYOlc7V8Ancd)
public extension SBUtils {

    /// 对 path 进行整文件加密（原址加密）
    /// - Parameter path: 要加密的路径
    @discardableResult
    static func encrypt(atPath path: AbsPathConvertiable) throws -> AbsPath {
        let path = path.asAbsPath()
        guard let cipher = cipher(forSuite: .default) else {
            SBUtils.log.error("missing cipher")
            return path
        }
        return try cipher.encryptPath(path.absoluteString).asAbsPath()
    }


    /// 对 path 进行整文件解密，返回明文路径
    /// - Parameter path: 要解密的路径
    /// - Returns: 明文路径
    static func decrypt(atPath path: AbsPathConvertiable) throws -> AbsPath {
        let path = path.asAbsPath()
        guard let cipher = cipher(forSuite: .default) else {
            SBUtils.log.error("missing cipher")
            return path
        }
        return try cipher.decryptPath(path.absoluteString).asAbsPath()
    }

    /// 对 path 进行整文件 **原址** 解密
    /// - Parameter path: 要解密的路径
    static func decryptInPlace(atPath path: AbsPathConvertiable) throws {
        guard let cipher = cipher(forSuite: .default) else {
            SBUtils.log.error("missing cipher")
            return
        }
        try cipher.decryptPathInPlace(path.asAbsPath().absoluteString)
    }
}

// MARK: - Check Encrypted

/// 加密状态
public enum SBEncryptStatus {
    /// 被加密了
    case encrypted
    /// 未被加密
    case unencrypted
    /// 未知（cipher 缺失、文件读取异常等）
    case unknown
}

private let logPrefix1 = "[check_encrypt_status] "

extension SBUtils {
    /// 检查 data 是否被加密了
    /// - Parameters:
    ///   - data: 二进制数据
    ///   - suite: 加密套件
    /// - Returns: 加密状态
    public static func checkEncryptStatus(forData data: Data, suite: SBCipherSuite = .default) -> SBEncryptStatus {
        guard let cipher = cipher(forSuite: suite) else {
            log.error("\(logPrefix1)missing cipher for suite: \(suite)")
            return .unknown
        }
        let ret = cipher.checkEncrypted(for: data)
        log.info("\(logPrefix1)check_result: \(ret)")
        return ret ? .encrypted : .unencrypted
    }

    /// 检查 path 所对应的文件是否被加密了
    /// - Parameters:
    ///   - path: 文件所对应的路径
    ///   - suite: 加密套件
    /// - Returns: 加密状态
    public static func checkEncryptStatus(forFileAt path: AbsPathConvertiable, suite: SBCipherSuite = .default) -> SBEncryptStatus {
        guard let cipher = cipher(forSuite: suite) else {
            log.error("\(logPrefix1)missing cipher for suite: \(suite)")
            return .unknown
        }
        let ret = cipher.checkEncrypted(forPath: path.asAbsPath().absoluteString)
        log.info("\(logPrefix1)check_result: \(ret)")
        return ret ? .encrypted : .unencrypted
    }
}

private let logPrefix2 = "[decrypt_file_handle] "

extension SBUtils {
    /// 判断 path 所对应的文件是否被加密了，如果是，则对其进行 **原址** 解密
    /// - Parameters
    ///   - path: 目标路径
    static func decryptInPlaceIfNeeded(_ path: AbsPathConvertiable) {
        guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
            log.info("\(logPrefix2)miss cipher")
            return
        }
        do {
            try cipher.decryptPathInPlace(path.asAbsPath().absoluteString)
        } catch {
            log.error("\(logPrefix2)decrypt in place failed. err: \(error)")
        }
    }

    /// 检查 FileHandle 的加密状态，通过 FileHandle 读取数据，然后复原 offset
    static func decryptedFileHandle(forReadingFrom url: URL) throws -> FileHandle {
        let fileHandle = try FileHandle(forReadingFrom: url)
        guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
            return fileHandle
        }
        do {
            let oldOffset = try fileHandle.sb.offset()
            /// 基于 fileHandle 判断是否被加密了，如果是，则进行解密，然后构建新的 FileHandle 返回
            if let data = try fileHandle.sb.read(upToCount: cipher.headerBytes), cipher.checkEncrypted(for: data) 
            {
                // close 掉原来的 FileHandle -> 解密 -> 基于解密路径构建新的 FileHandle
                try fileHandle.sb.close()
                let decrypted = try cipher.decryptPath(url.asAbsPath().absoluteString)
                return try FileHandle(forReadingFrom: decrypted.asAbsPath().url)
            } else {
                // 恢复 FileHandle 的 offset -> oldOffset
                try fileHandle.sb.seek(toOffset: oldOffset)
                return fileHandle
            }
        } catch {
            log.error("\(logPrefix2)decrypt for reading failed. err: \(error)")
            try? fileHandle.sb.close()
            return try FileHandle(forReadingFrom: url)
        }
    }
}

private let logPrefix3 = "[file_size] "

extension SBUtils {
    /// 获取文件大小。如果是解密文件，则返回明文大小
    public static func fileSize(atPath path: AbsPathConvertiable) -> UInt64? {
        let path = path.asAbsPath()
        guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
            log.info("\(logPrefix3)miss cipher")
            return path.fileSize
        }
        do {
            return UInt64(try cipher.fileSize(atPath: path.absoluteString))
        } catch {
            log.error("\(logPrefix3)get file size failed. err: \(error)")
            return path.fileSize
        }
    }
}
