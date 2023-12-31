//
//  SBCipher.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

public protocol SBCipher: AnyObject {
    typealias RawPath = String
    @available(*, deprecated, message: "兼容现在的接口、后续会去掉")
    func isEnabled() -> Bool

    /// 文件头信息长度
    var headerBytes: Int { get }

    /// 获取文件大小
    func fileSize(atPath path: RawPath) throws -> Int

    /// 检查 Data 是否被加密了
    func checkEncrypted(for data: Data) -> Bool
    func checkEncrypted(forPath path: RawPath) -> Bool

    /// 基于 Path 进行加/解密
    func encryptPath(_ path: RawPath) throws -> RawPath
    func decryptPath(_ path: RawPath) throws -> RawPath
    func decryptPathInPlace(_ path: RawPath) throws

    /// 基于 Data 进行加/解密
    func writeData(_ data: Data, to path: RawPath) throws
    func readData(from path: RawPath) throws -> Data

    /// 基于 InputStream 进行加解密
    func inputStream(atPath path: RawPath) -> SBInputStream?
    func outputStream(atPath path: RawPath, append shouldAppend: Bool) -> SBOutputStream?

    /// 基于 FileHandle 进行加解密
    func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle
}

public enum SBCipherMode {
    case compatible
    case space(Space)
}

extension SBCipherMode {
    var hashKey: String {
        switch self {
        case .compatible: return "compatible"
        case .space(let space): return space.isolationId
        }
    }
}

/// 加密套件
public struct SBCipherSuite: Hashable {
    var key: String

    /// 默认加密
    ///  - 原地加密，加密后的文件覆盖源文件
    ///  - 异地解密，解密后的内容放在临时目录
    public static let `default` = SBCipherSuite(key: "default")

    /// 和 `default` 类似，不同点是：异地加密，不影响原文
    ///  - 异地加密，不影响源文件
    ///  - 异地解密
    public static let writeBack = SBCipherSuite(key: "writeback")
}

public final class SBCipherManager {

    struct CryptoConfig {
        var path: AbsPath
        var suite: SBCipherSuite
    }

    static let loadableKey = "LarkStorage_SandboxCryptoRegistry"

    public typealias CipherProvider = (SBCipherMode) -> SBCipher?

    private var _allSuites = [SBCipherSuite: CipherProvider]()

    var allSuites: [SBCipherSuite: CipherProvider] {
        Dependencies.loadOnce(Self.loadableKey)
        return _allSuites
    }

    // 保护 cryptoConfigs
    private let confLock = UnfairLock()
    // 记录要加密的目录
    var cryptoConfigs = [Space: [CryptoConfig]]()

    public static let shared = SBCipherManager()

    // MARK: Register Cipher

    /// 注册 Cipher
    public func register(suite: SBCipherSuite, provider: @escaping CipherProvider) {
        _allSuites[suite] = provider
    }

    /// 获取 Cipher
    public func cipher(for suite: SBCipherSuite, mode: SBCipherMode = .compatible) -> SBCipher? {
        return allSuites[suite]?(mode)
    }

    // MARK: Set Crypto

    /// 基于路径指定加密配置
    public func setCrypto(forPath path: AbsPath, space: Space, with suite: SBCipherSuite = .default) {
        confLock.lock()
        defer { confLock.unlock() }
        let newConf = CryptoConfig(path: path, suite: suite)
        if var confs = cryptoConfigs[space] {
            confs.append(newConf)
        } else {
            cryptoConfigs[space] = [newConf]
        }
    }

    /// 提取业务注册的加密配置
    func cipher(forPath path: AbsPath, space: Space) -> SBCipher? {
        confLock.lock()
        defer { confLock.unlock() }
        let matched = cryptoConfigs[space]?.first(where: { conf in  path.starts(with: conf.path) })
        guard let suite = matched?.suite else {
            return nil
        }
        return cipher(for: suite, mode: .space(space))
    }

}
