//
//  CryptoStream.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/8/11.
//

import Foundation
import LarkStorage
import LarkRustClient
import LarkContainer
import LarkSecurityComplianceInfra

public final class CryptoStream {

    let enableStreamCipherMode: Bool
    var deviceKey: Data
    let uid: String
    let did: String
    let userResolver: UserResolver
    let openMigrationPool: Bool

    public init(enableStreamCipherMode: Bool, deviceKey: Data, uid: String, did: String, userResolver: UserResolver) {
        self.enableStreamCipherMode = enableStreamCipherMode
        self.deviceKey = deviceKey
        self.uid = uid
        self.did = did
        self.userResolver = userResolver
        do {
            let fg = try userResolver.resolve(type: SCFGService.self)
            openMigrationPool = fg.staticValue(.enableFileMigrationPool)
            FileCryptoServiceImpl.logger.info("get open file migration: \(openMigrationPool)")
        } catch {
            openMigrationPool = false
            FileCryptoServiceImpl.logger.error("get open file migration error: \(error)")
        }
    }
    
    public func encryptVersion(path: String) -> AESFileKind {
        do {
            let header = try AESHeader(filePath: path)
            return header.encryptVersion()
        } catch {
            return .regular
        }
        
    }
    
    /// 使用统一存储提供的 CipherStream 接口进行数据加密
    /// - Parameter toPath: 文件路径
    /// - Returns: 返回加密封装的 SBCipherOutputStream，可使用 write 方法进行密文数据写入
    public func encrypt(to toPath: String) throws -> SBCipherOutputStream {
        if enableStreamCipherMode {
            let info = AESMetaInfo(filePath: toPath, deviceKey: deviceKey, uid: uid, did: did)
            return EncryptFileStream(info: info, userResolver: userResolver)
        } else {
            return EncryptPathStream(userResolver: userResolver, atFilePath: toPath)
        }
    }
    
    /// 使用统一存储提供的 CipherStream 接口进行数据解密
    /// - Parameter fromPath: 文件路径
    /// - Returns: 返回加密封装的 SBCipherInputStream，可使用  read 方法进行明文数据读取
    public func decrypt(from fromPath: String) throws -> SBCipherInputStream {
        if enableStreamCipherMode { // 是否开启v2算法：做数据迁移
            let version = encryptVersion(path: fromPath) // 加密版本
            let info = AESMetaInfo(filePath: fromPath, deviceKey: deviceKey, uid: uid, did: did)
            info.encryptVersion = version
            if version.isEncrypted { // 是否密文
                return DecryptFileStream(info: info, userResolver: userResolver)
            } else { // 非密文，openPool: true 加到数据迁移池，false 直接读取数据
                return Raw.sandboxInputStream(userResolver: userResolver, info: info, enablePool: openMigrationPool)
            }
        } else {
            return DecryptPathStream(userResolver: userResolver, atFilePath: fromPath)
        }
    }
    
    /// 使用系统的 FileHandle 接口进行文件操作
    /// - Parameters:
    ///   - path: 文件路径
    ///   - usage: 文件操作方式：
    ///     - reading
    ///     - writing(shouldAppend: Bool)
    ///     - updating
    /// - Returns: 返回解密封装的 SBFileHandle，接口和 FileHandle 保持一致
    public func fileHandle(atPath path: String, forUsage usage: LarkStorage.FileHandleUsage) throws -> SBFileHandle {
        do {
            let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
            let version = encryptVersion(path: path) // 加密版本
            info.encryptVersion = version
            if version.isEncrypted { // 加密处理
                return try Crypto.FileHandle(userResolver: userResolver, info: info, usage: usage)
            } else { // 未加密
                return try Raw.fileHandle(userResolver: userResolver, info: info, usage: usage, enablePool: openMigrationPool)
            }
        } catch {
            FileCryptoServiceImpl.logger.error("create SBFileHandle failed with error: \(error)")
            throw error
        }
    }
    
    /// 使用系统 InputStream 接口读数据
    /// - Parameter path: 文件路径
    /// - Returns: 返回解密封装的 SBInputStream，接口和 InputStream 保持一致
    public func inputStream(atPath path: String) -> LarkStorage.SBInputStream? {
        do {
            let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
            let version = encryptVersion(path: path)
            info.encryptVersion = version
            if version.isEncrypted { // 加密处理
                return try Crypto.InputStream(userResolver: userResolver, info: info)
            } else { // 未加密
                return try Raw.systemInputStream(userResolver: userResolver, info: info, enablePool: openMigrationPool)
            }
        } catch {
            FileCryptoServiceImpl.logger.error("create SBInputStream failed with error: \(error)")
            return nil
        }
    }
    
    /// 使用系统 OutputStream 接口写数据
    /// - Parameters:
    ///   - path: 文件路径
    ///   - shouldAppend: 是否追加数据
    /// - Returns: 返回加密封装的 SBOutputStream，接口和 OutputStream 保持一致
    func outputStream(atPath path: String, append shouldAppend: Bool) -> LarkStorage.SBOutputStream? {
        do {
            let info = AESMetaInfo(filePath: path, deviceKey: deviceKey, uid: uid, did: did)
            return try Crypto.OutputStream(userResolver: userResolver, info: info, append: shouldAppend)
        } catch {
            FileCryptoServiceImpl.logger.error("create SBOutputStream failed with error: \(error)")
            return nil
        }
    }
}
