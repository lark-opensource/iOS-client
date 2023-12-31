//
//  FileCryptoService.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/7/29.
//

import Foundation
import LarkContainer
import LarkStorage
import LarkSecurityComplianceInfra
import EEAtomic
import AppContainer
import RxSwift
import LarkAccountInterface
import YYCache
import LarkSetting

enum CryptoFileError: Error {
    case customError(String)
    case fileStreamError(Error)
    case fileSystemError(Int32, String)
}

public protocol FileCryptoService: SBCipher {
    func deviceKey(did: Int64) throws -> Data
    func encrypt(to toPath: RawPath) throws -> SBCipherOutputStream
    func decrypt(from fromPath: RawPath) throws -> SBCipherInputStream
}

public protocol FileCryptoWriteBackService: SBCipher { }

class FileCryptoServiceImpl: FileCryptoService {
    
    static let logger = Logger(tag: "[file_crypto]")

    private let cryptoRustService: CryptoRustService
    private let passportService: PassportService
    private let userService: PassportUserService
    private let settings: Settings

    var enableStreamCipherMode: Bool {
        guard settings.enableSecuritySettingsV2.isTrue else {
            SCLogger.info("\(SettingsImp.CodingKeys.enableStreamCipherMode.rawValue) \(self.settings.enableStreamCipherMode ?? false)",
                          tag: SettingsImp.logTag)
            return self.settings.enableStreamCipherMode ?? false
        }
        return SCSetting.staticBool(scKey: .enableStreamCipherMode, userResolver: userResolver)
    }
    private var did: String { passportService.deviceID }
    private var uid: String { userService.user.userID }
    private var didInt: Int64 { Int64(did) ?? 0 }
    private var uidInt: Int64 { Int64(uid) ?? 0 }
    private var timer: Timer?
    private let deviceKeyCache = YYMemoryCache()
    let userResolver: UserResolver
    
    private var cryptoPath: CryptoPath?
    private var cryptoStream: CryptoStream?

    deinit {
        timer?.invalidate()
    }

    init(resolver: UserResolver) throws {
        Self.logger.info("create FileCryptoServiceImpl")
        self.userResolver = resolver
        cryptoRustService = try resolver.resolve(type: CryptoRustService.self)
        passportService = try resolver.resolve(assert: PassportService.self)
        userService = try resolver.resolve(assert: PassportUserService.self)
        settings = try resolver.resolve(assert: Settings.self)
        
        setupFetchTimer()
    }
    
    /// 移动端加密功能是否开启
    /// - Returns: true:开启；false:关闭
    func isEnabled() -> Bool {
        do {
            return try cryptoRustService.isEnabled()
        } catch {
            Self.logger.error("check file crypto is enabled: \(error)")
            FileCryptoMonitor.error(["scene": "rust", "type": "is_enabled"], error: error)
            return false
        }
    }
    
    var headerBytes: Int { Int(AESHeader.size) }

    func checkEncrypted(for data: Data) -> Bool {
        do {
            let header = try AESHeader(data: data)
            return header.checkEncrypted()
        } catch {
            Self.logger.error("check encyrpted failed, error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "method": "check_encrypted_data"], error: error)
            return false
        }
    }
    
    func checkEncrypted(forPath path: RawPath) -> Bool {
        do {
            let header = try AESHeader(filePath: path)
            return header.checkEncrypted()
        } catch {
            Self.logger.error("check encyrpted failed, error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "method": "check_encrypted_path"], error: error)
            return false
        }
    }
    
    func fileSize(atPath path: RawPath) throws -> Int {
        do {
            let size = try CryptoFileSize.size(userResolver: userResolver, path)
            Self.logger.info("get file size with path: \(path) filesize: \(size)")
            return size
        } catch {
            Self.logger.error("get file size with error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "type": "file_size"], error: error)
            throw error
        }
    }
    
    /// 获取加密密钥
    
    func deviceKey(did: Int64) throws -> Data {
        if let key = deviceKeyCache.object(forKey: "\(did)") as? Data {
            Self.logger.info("get device key from local cache, did: \(did), uid: \(uidInt)")
            return key
        }
        do {
            let key = try cryptoRustService.deviceKey(uid: uidInt, did: did)
            deviceKeyCache.setObject(key, forKey: "\(did)")
            return key
        } catch {
            Self.logger.error("create device key failed: \(error)")
            FileCryptoMonitor.error(["scene": "rust", "type": "device_key"], error: error)
            throw error
        }
    }

    func encryptPath(_ path: RawPath) throws -> RawPath {
        do {
            Self.logger.info("Will encrypt file: \(URL(fileURLWithPath: path).lastPathComponent)")
            let cryptoPath = currentCryptoPath()
            return try cryptoPath.encrypt(path)
        } catch {
            Self.logger.error("error to encrypt file: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "rust", "encrypt": true, "method": "raw_path"], error: error)
            throw error
        }
    }

    func decryptPath(_ path: RawPath) throws -> RawPath {
        do {
            Self.logger.info("Will decrypt file: \(URL(fileURLWithPath: path).lastPathComponent)")
            let cryptoPath = currentCryptoPath()
            return try cryptoPath.decrypt(path)
        } catch {
            Self.logger.error("Error to decrypt file: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "rust", "encrypt": false, "method": "raw_path"], error: error)
            throw error
        }
    }
    
    func decryptPathInPlace(_ path: RawPath) throws {
        do {
            Self.logger.info("Will decrypt in place: \(path)")
            let deviceKey = try deviceKey(did: didInt)
            let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
            let migrateRaw = MigrateFileRaw(userResolver: userResolver, info: info)
            try migrateRaw.doProcess()
        } catch {
            Self.logger.error("Error to decrypt path in place: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": false, "method": "decrypt_in_place"], error: error)
            throw error
        }
    }

    func encrypt(to toPath: RawPath) throws -> SBCipherOutputStream {
        do {
            Self.logger.info("Will create encrypt file stream: \(URL(fileURLWithPath: toPath).lastPathComponent)")
            if isEnabled() {
                let cryptoStream = try currentCryptoStream()
                return try cryptoStream.encrypt(to: toPath)
            } else {
                let key = try deviceKey(did: didInt)
                let info = AESMetaInfo(filePath: toPath, deviceKey: key, uid: uid, did: did)
                return Raw.SandboxOutputStreamMigration(userResolver: userResolver, info: info)
            }
        } catch {
            Self.logger.error("Error to create encrypt file stream: \(URL(fileURLWithPath: toPath).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": true, "method": "native_stream"], error: error)
            throw error
        }
    }

    func decrypt(from fromPath: RawPath) throws -> SBCipherInputStream {
        do {
            Self.logger.info("Will create decrypt file stream: \(URL(fileURLWithPath: fromPath).lastPathComponent)")
            if isEnabled() {
                let cryptoStream = try currentCryptoStream()
                return try cryptoStream.decrypt(from: fromPath)
            } else {
                let key = try deviceKey(did: didInt)
                let info = AESMetaInfo(filePath: fromPath, deviceKey: key, uid: uid, did: did)
                return Raw.SandboxInputStreamMigration(userResolver: userResolver, metaInfo: info)
            }
        } catch {
            Self.logger.error("Error to create decrypt file stream: \(URL(fileURLWithPath: fromPath).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": false, "method": "native_stream"], error: error)
            throw error
        }
    }
    
    func inputStream(atPath path: RawPath) -> LarkStorage.SBInputStream? {
        do {
            Self.logger.info("Will create input stream: \(URL(fileURLWithPath: path).lastPathComponent)")
            if isEnabled() {
                let cryptoStream = try currentCryptoStream()
                return cryptoStream.inputStream(atPath: path)
            } else {
                let deviceKey = try deviceKey(did: didInt)
                let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
                return try Raw.InputStreamMigration(userResolver: userResolver, info: info)
            }
        } catch {
            Self.logger.error("Error to create sec input stream: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": false, "method": "input_stream"], error: error)
            return nil
        }
    }
    
    func outputStream(atPath path: RawPath, append shouldAppend: Bool) -> LarkStorage.SBOutputStream? {
        do {
            Self.logger.info("Will create output stream: \(URL(fileURLWithPath: path).lastPathComponent)")
            if isEnabled() {
                let cryptoStream = try currentCryptoStream()
                return cryptoStream.outputStream(atPath: path, append: shouldAppend)
            } else {
                let deviceKey = try deviceKey(did: didInt)
                let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
                return try Raw.OutputStreamMigration(userResolver: userResolver, info: info, append: shouldAppend)
            }
        } catch {
            Self.logger.error("Error to create sec input stream: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": true, "method": "output_stream"], error: error)
            return nil
        }
    }
    
    func fileHandle(atPath path: String, forUsage usage: LarkStorage.FileHandleUsage) throws -> LarkStorage.SBFileHandle {
        do {
            Self.logger.info("Will create file handle: \(URL(fileURLWithPath: path).lastPathComponent)")
            if isEnabled() {
                let cryptoStream = try currentCryptoStream()
                return try cryptoStream.fileHandle(atPath: path, forUsage: usage)
            } else {
                let key = try deviceKey(did: didInt)
                let info = AESMetaInfo(filePath: path, deviceKey: key, uid: uid, did: did)
                return try Raw.FileHandleMigration(userResolver: userResolver, info: info, usage: usage)
            }
        } catch {
            Self.logger.error("Error to create sec file handle: \(URL(fileURLWithPath: path).lastPathComponent), error: \(error)")
            FileCryptoMonitor.error(["scene": "native", "encrypt": false, "method": "file_handle"], error: error)
            throw error
        }
    }

    func setupFetchTimer() {
        guard enableStreamCipherMode else { return }
        self.timer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            guard let self else { return }
            do {
                let cryptoStream = try self.currentCryptoStream()
                cryptoStream.deviceKey = try self.deviceKey(did: self.didInt)
            } catch {
                Self.logger.error("timer fetch device key failed \(self.uid)")
            }
        }
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func currentCryptoStream() throws -> CryptoStream {
        if let cryptoStream {
            return cryptoStream
        }
        let stream = CryptoStream(
            enableStreamCipherMode: enableStreamCipherMode,
            deviceKey: try deviceKey(did: didInt),
            uid: uid,
            did: did,
            userResolver: userResolver
        )
        if let selfStream = self.cryptoStream {
            return selfStream
        } else {
            self.cryptoStream = stream
            return stream
        }
    }
    
    fileprivate func currentCryptoPath() -> CryptoPath {
        if let cryptoPath {
            return cryptoPath
        }
        let path = CryptoPath(userResolver: userResolver)
        if let selfPath = self.cryptoPath {
            return selfPath
        } else {
            self.cryptoPath = path
            return path
        }
    }
}

extension FileCryptoServiceImpl {
    func writeData(_ data: Data, to path: RawPath) throws {
        Self.logger.info("writeData/encrypt/ \(path)")
        let outputStream = try encrypt(to: path)
        Self.logger.info("writeData/open/ \(path)")
        try outputStream.open(shouldAppend: false)
        Self.logger.info("writeData/write/ \(path)")
        try outputStream.write(data: data)
        Self.logger.info("writeData/close/ \(path)")
        try outputStream.close()
    }

    func readData(from path: RawPath) throws -> Data {
        Self.logger.info("readData/decrypt/ \(path)")
        let inputStream = try decrypt(from: path)
        Self.logger.info("readData/open/ \(path)")
        try inputStream.open()
        Self.logger.info("readData/readAll/ \(path)")
        let data = try inputStream.readAll()
        Self.logger.info("readData/close/ \(path)")
        try inputStream.close()
        return data
    }
}

final class FileCryptoWriteBackServiceImpl: FileCryptoServiceImpl, FileCryptoWriteBackService {
    override func encryptPath(_ path: RawPath) throws -> RawPath {
        do {
            Self.logger.info("Will encrypt write back file:\(URL(fileURLWithPath: path).lastPathComponent)")
            let cryptoPath = self.currentCryptoPath()
            return try cryptoPath.writeBackPath(path)
        } catch {
            Self.logger.error("Error to encrypt write back file:\(URL(fileURLWithPath: path).lastPathComponent), error:\(error)")
            throw error
        }
    }
}
