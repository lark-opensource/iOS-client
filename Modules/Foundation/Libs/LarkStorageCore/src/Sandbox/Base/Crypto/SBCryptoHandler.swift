//
//  SandboxDynCryptoProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2023/2/9.
//

import Foundation

final class SBCryptoHandler<RawPath: PathType> {
    let cipher: SBCipher
    let forwarder: Sandbox<RawPath>
    let pathConverter: (AbsPath) -> RawPath

    init(cipher: SBCipher, forwarder: Sandbox<RawPath>, pathConverter: @escaping (AbsPath) -> RawPath) {
        self.cipher = cipher
        self.forwarder = forwarder
        self.pathConverter = pathConverter
    }

    @inline(__always)
    private func logInfo(_ message: String) {
        sandboxLogger.info("[crypto proxy]: \(message)")
    }

    func createFile(atPath path: RawPath, contents: Data?, attributes: FileAttributes?) throws {
        let hasContents = contents != nil
        if LarkStorageFG.streamCrypto {
            do {
                logInfo("create/stream/begin. path: \(path.absoluteString), hasContents: \(hasContents)")
                try cipher.writeData(contents ?? Data(), to: path.absoluteString)
                logInfo("create/stream/end")
            } catch {
                try? forwarder.removeItem(atPath: path)
                throw error
            }
        } else {
            logInfo("create/path/begin. path: \(path.absoluteString), hasContents: \(hasContents)")
            try forwarder.createFile(atPath: path, contents: contents, attributes: attributes)
            logInfo("create/path/create")

            guard hasContents else { return }

            do {
                let encryptedPath = try cipher.encryptPath(path.absoluteString)
                logInfo("create/path/encrypt. path: \(encryptedPath)")
            } catch {
                // 加密失败，不删除源文件
                // try? forwarder.removeItem(atPath: path)
                throw error
            }
        }
    }

    func read<D: SBBaseReadable>(atPath path: RawPath, with context: SBReadingContext) throws -> D {
        if LarkStorageFG.streamCrypto, let DataConvertible = D.self as? SBDataConvertible.Type {
            let rawPath = path.absoluteString
            logInfo("read/stream/begin. path: \(rawPath)")
            let data = try cipher.readData(from: rawPath)
            let ret = try DataConvertible.sb_from_data(data, with: context)
            logInfo("read/stream/close")
            guard let d = ret as? D else {
                #if DEBUG || ALPHA
                fatalError("unexpected")
                #else
                throw SandboxError.performReadingUnexpected(message: "path: \(path.absoluteString), type: \(type(of: D.self)))")
                #endif
            }
            return d
        } else {
            logInfo("read/path/begin. path: \(path.absoluteString)")
            let decryptedPath = try _decrypted(path: path.absoluteString, type: "readFile")
            logInfo("read/path/decrypt. path: \(decryptedPath)")
            let path = pathConverter(AbsPath(decryptedPath))
            let data: D = try forwarder.performReading(atPath: path, with: context)
            logInfo("read/path/read.")
            return data
        }
    }

    func write<D: SBBaseWritable>(
        _ data: D,
        atPath path: RawPath,
        with context: SBWritingContext
    ) throws {
        if LarkStorageFG.streamCrypto, let dataType = data as? SBDataConvertible {
            do {
                logInfo("write/stream/begin. path: \(path.absoluteString)")
                let data = try dataType.sb_to_data(with: context)
                try cipher.writeData(data, to: path.absoluteString)
                logInfo("write/stream/end")
            } catch {
                try? forwarder.removeItem(atPath: path)
                throw error
            }
        } else {
            logInfo("write/path/begin. path: \(path.absoluteString)")
            try forwarder.performWriting(data, atPath: path, with: context)
            logInfo("write/path/write.")
            do {
                let encryptedPath = try cipher.encryptPath(path.absoluteString)
                logInfo("write/path/encrypt. path: \(encryptedPath)")
            } catch {
                // 加密失败，不删除源文件
                // try? forwarder.removeItem(atPath: path)
                throw error
            }
        }
    }

    private func _decrypted(path: String, type: String) throws -> String {
        var decryptedPath = path
        do {
            decryptedPath = try cipher.decryptPath(path)
        } catch {
            if path.asAbsPath().exists {
                let message = "decrypt failed. type: \(type), path: \(path), err: \(error)"
                sandboxLogger.error(message)
            } else {
                sandboxLogger.info("does not exists. path: \(path)")
            }
        }
        return decryptedPath
    }

    func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> FileHandle {
        // 目前仅支持 fileHandle 读的解密，先对整文件解密，然后再返回流
        guard case .reading = usage else {
            return try forwarder.fileHandle(atPath: path, forUsage: usage)
        }

        logInfo("getFileHandle/begin. path: \(path.absoluteString)")
        let decryptedPath = try _decrypted(path: path.absoluteString, type: "fileHandle")
        logInfo("getFileHandle/decrypt. path: \(decryptedPath)")
        let path = pathConverter(AbsPath(decryptedPath))
        let fileHandle = try forwarder.fileHandle(atPath: path, forUsage: usage)
        logInfo("getFileHandle/end")
        return fileHandle
    }

    func fileHandle_v2(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle {
        let rawPath = path.absoluteString
        logInfo("getFileHandle/begin. path: \(rawPath)")
        let fileHandle = try cipher.fileHandle(atPath: rawPath, forUsage: usage)
        logInfo("getFileHandle/end")
        return fileHandle
    }

    func inputStream(atPath path: RawPath) throws -> InputStream? {
        // 处理：先对整文件解密，然后再返回流
        logInfo("getIputStream/begin. path: \(path.absoluteString)")
        let decryptedPath = try _decrypted(path: path.absoluteString, type: "inputStream")
        logInfo("getIputStream/decrypt. path: \(decryptedPath)")
        let path = pathConverter(AbsPath(decryptedPath))
        let inputSteam = forwarder.inputStream(atPath: path)
        logInfo("getIputStream/end")
        return inputSteam
    }

    func inputStream_v2(atPath path: RawPath) throws -> SBInputStream? {
        logInfo("getInputStreamV2/begin. path: \(path.absoluteString)")
        return cipher.inputStream(atPath: path.absoluteString)
    }

    func outputStream_v2(atPath path: RawPath, append shouldAppend: Bool) throws -> SBOutputStream? {
        logInfo("getOutputStreamV2/begin. path: \(path.absoluteString)")
        return cipher.outputStream(atPath: path.absoluteString, append: shouldAppend)
    }

    func moveItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        logInfo("moveItem/begin atPath: \(srcPath.absoluteString), dstPath: \(dstPath.absoluteString)")
        try forwarder.moveItem(atPath: srcPath, toPath: dstPath)
        logInfo("moveItem/end1")
        do {
            _ = try cipher.encryptPath(dstPath.absoluteString)
            logInfo("moveItem/end2")
        } catch {
            logInfo("moveItem/end2 failed. err: \(error)")
        }
    }

    func copyItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        logInfo("copyItem atPath: \(srcPath.absoluteString), dstPath: \(dstPath.absoluteString)")
        try forwarder.copyItem(atPath: srcPath, toPath: dstPath)
        logInfo("copyItem/end1")
        do {
            _ = try cipher.encryptPath(dstPath.absoluteString)
            logInfo("copyItem/end2")
        } catch {
            logInfo("copyItem/end2 failed. err: \(error)")
        }
    }

}
