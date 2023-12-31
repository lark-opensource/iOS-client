//
//  CryptoTools.swift
//  LarkCache
//
//  Created by su on 2020/11/24.
//

import Foundation
import RxSwift
import LarkStorage

public func isCryptoEnable() -> Bool {
    return SBCipherManager.shared.cipher(for: .default)?.isEnabled() ?? false
}

/// 加密，解密相关error
public enum CryptoError {
    public enum EncryptError: Error {
        case fileNotFoundError
        case sdkError(error: Error)
    }

    public enum DecryptError: Error {
        case fileNotFoundError
        case sdkError(error: Error)
    }
}

/// Path转换协议
public protocol PathConvertiable {
    /// 转成Path对象
    func asPath() -> LfkPath
}

extension LfkPath: PathConvertiable {
    public func asPath() -> LfkPath {
        self
    }
}

extension String: PathConvertiable {
    public func asPath() -> LfkPath {
        .init(self)
    }
}

public extension PathConvertiable {
    /// 调用类方法进行加密
    @discardableResult
    func encrypt() throws -> LfkPath {
        guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
            return self.asPath()
        }
        return try cipher.encryptPath(asPath().rawValue).asPath()
    }

    /// 调用类方法进行解密
    func decrypt() throws -> LfkPath {
        let lfkPath: LfkPath = asPath()
        guard lfkPath.exists, let cipher = SBCipherManager.shared.cipher(for: .default) else {
            return lfkPath
        }
        return try cipher.decryptPath(lfkPath.rawValue).asPath()
    }

    /// 异地加密（不覆盖源文件）
    func writeBackPath() throws -> LfkPath {
        guard let cipher = SBCipherManager.shared.cipher(for: .writeBack) else {
            return self.asPath()
        }
        return try cipher.encryptPath(asPath().rawValue).asPath()
    }
}
