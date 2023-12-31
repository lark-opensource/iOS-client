//
//  SandboxIsoCryptoProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

class SandboxIsoCryptoProxyBase: SandboxProxy<IsolateSandboxPath> {
    func getCryptoHandler(atPath path: RawPath, forReading: Bool) throws -> SBCryptoHandler<RawPath>? {
        fatalError("Abstract Method")
    }

    override func createFile(atPath path: RawPath, contents: Data?, attributes: FileAttributes?) throws {
        if let handler = try getCryptoHandler(atPath: path, forReading: false) {
            try handler.createFile(atPath: path, contents: contents, attributes: attributes)
        } else {
            try super.createFile(atPath: path, contents: contents, attributes: attributes)
        }
    }

    override func performReading<D: SBBaseReadable>(
        atPath path: RawPath,
        with context: SBReadingContext
    ) throws -> D {
        if let handler = try getCryptoHandler(atPath: path, forReading: true) {
            return try handler.read(atPath: path, with: context)
        } else {
            return try super.performReading(atPath: path, with: context)
        }
    }

    override func performWriting<D: SBBaseWritable>(
        _ data: D,
        atPath path: RawPath,
        with context: SBWritingContext
    ) throws {
        if let handler = try getCryptoHandler(atPath: path, forReading: false) {
            try handler.write(data, atPath: path, with: context)
        } else {
            try super.performWriting(data, atPath: path, with: context)
        }
    }

    /* v1 版本的 fileHandle 接口，加密场景和 Sandbox 的默认实现一致，无需 override
    override func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> FileHandle {
        if case .reading = usage, let handler = try getCryptoHandler(atPath: path, forReading: true) {
            return try handler.fileHandle(atPath: path, forUsage: usage)
        } else {
            return try super.fileHandle(atPath: path, forUsage: usage)
        }
    }
     */

    override func fileHandle_v2(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle {
        if case .reading = usage {
            // 走默认实现（全场景自动解密）
            return try super.fileHandle_v2(atPath: path, forUsage: usage)
        }
        if let handler = try getCryptoHandler(atPath: path, forReading: false) {
            return try handler.fileHandle_v2(atPath: path, forUsage: usage)
        } else {
            return try super.fileHandle_v2(atPath: path, forUsage: usage)
        }
    }

    override func inputStream(atPath path: RawPath) -> InputStream? {
        if let handler = try? getCryptoHandler(atPath: path, forReading: true) {
            return try? handler.inputStream(atPath: path)
        } else {
            return super.inputStream(atPath: path)
        }
    }

    override func inputStream_v2(atPath path: RawPath) -> SBInputStream? {
        if let handler = try? getCryptoHandler(atPath: path, forReading: true) {
            return try? handler.inputStream_v2(atPath: path)
        } else {
            return super.inputStream_v2(atPath: path)
        }
    }

    override func outputStream_v2(atPath path: RawPath, append shouldAppend: Bool) -> SBOutputStream? {
        if let handler = try? getCryptoHandler(atPath: path, forReading: true) {
            return try? handler.outputStream_v2(atPath: path, append: shouldAppend)
        } else {
            return super.outputStream_v2(atPath: path, append: shouldAppend)
        }
    }

    override func moveItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        if let handler = try? getCryptoHandler(atPath:dstPath, forReading: false) {
            try handler.moveItem(atPath: srcPath, toPath: dstPath)
        } else {
            try super.moveItem(atPath: srcPath, toPath: dstPath)
        }
    }

    override func copyItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        if let handler = try? getCryptoHandler(atPath:dstPath, forReading: false) {
            try handler.copyItem(atPath: srcPath, toPath: dstPath)
        } else {
            try super.copyItem(atPath: srcPath, toPath: dstPath)
        }
    }
}

final class SandboxIsoDynamicCryptoProxy: SandboxIsoCryptoProxyBase {
    let suite: SBCipherSuite

    init(wrapped: Sandbox<RawPath>, suite: SBCipherSuite) {
        self.suite = suite
        super.init(wrapped: wrapped)
    }

    override func getCryptoHandler(atPath path: RawPath, forReading: Bool) throws -> SBCryptoHandler<RawPath>? {
        guard let cipher = SBCipherManager.shared.cipher(for: suite, mode: .space(path.config.space)) else {
            log.info("missing cipher, suite: \(suite.key)")
            throw SandboxError.missingCipher
        }
        return SBCryptoHandler(cipher: cipher, forwarder: wrapped) { absPath -> RawPath in
            return .init(rootPart: absPath, type: .temporary, config: path.config)
        }
    }
}

/// 所有 `IsoPath` 都有的 proxy
final class SandboxIsoCommonCryptoProxy: SandboxIsoCryptoProxyBase {
    override func getCryptoHandler(atPath path: RawPath, forReading: Bool) throws -> SBCryptoHandler<RawPath>? {
        let conf = path.config
        let testPath = AbsPath(path.absoluteString)
        var cipher = SBCipherManager.shared.cipher(forPath: testPath, space: conf.space)
        // 针对小程序（Domain.biz.microApp）做特化，读数据场景做无脑解密
        let microAppDomain = Domain("MicroApp")
        if cipher == nil,
           LarkStorageFG.enableAutoDecrypt,
           conf.domain.isSame(as: microAppDomain),
           forReading
        {
            cipher = SBCipherManager.shared.cipher(for: .default, mode: .space(conf.space))
            // 判断文件是否被加密了，如果没有，`forReading` 场景就不走加密了
            if let cip = cipher, !cip.checkEncrypted(forPath: path.absoluteString) {
                cipher = nil
            }
        }
        if let cip = cipher {
            return SBCryptoHandler(cipher: cip, forwarder: wrapped) { absPath -> RawPath in
                return .init(rootPart: absPath, type: .temporary, config: conf)
            }
        } else {
            return nil
        }
    }
}
