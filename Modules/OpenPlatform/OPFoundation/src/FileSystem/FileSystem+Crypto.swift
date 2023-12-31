//
//  FileSystem+Crypto.swift
//  OPFoundation
//
//  Created by ByteDance on 2023/9/5.
//

import Foundation
import LarkStorage
import LarkSetting
import LarkCache

public struct FSCrypto {
    /// 租户后台是否配置移动端加解密
    public static func isCryptoEnable() -> Bool{
        let enable = LarkCache.isCryptoEnable()
        FileSystemUtils.logger.info("isCryptoEnable: \(enable)")
        return enable
    }
    
    /// 是否进行加密
    public static func encryptEnable() -> Bool {
        if LSFileSystem.isoPathEnable, fsCryptoConfig().encrypyEnable {
            return true
        }
        return false
    }
    
    /// 部分API使用前，需要主动解密，如getFileInfo
    public static func manualApiDecryptEnable() -> Bool {
        return fsCryptoConfig().manualApiDecrypt
    }
    
    /// LarkStorage不生效的情况下，系统文件读写进行兜底解密
    public static func oldApiDecryptEnable() -> Bool {
        return fsCryptoConfig().oldSystemApiDecrypt
    }
    
    static func manualApiDecryptFile(with filePath: String, context: FileSystem.Context) throws -> String {
        guard manualApiDecryptEnable() else {
            return filePath
        }
        return try decryptFile(with: filePath, context: context)
    }
    
    static func oldApiDecryptFile(with filePath: String, context: FileSystem.Context) throws -> String {
        guard oldApiDecryptEnable() else {
            return filePath
        }
        return try decryptFile(with: filePath, context: context)
    }
    
    /// V1版本的解密，会有明文落盘
    static func decryptFile(with filePath: String, context: FileSystem.Context) throws -> String {
        guard LSFileSystem.fileExists(filePath: filePath) else{
            context.trace.info("decryptFile fileNotExists:\(filePath)")
            return filePath
        }
        guard !LSFileSystem.isDirectory(filePath: filePath) else{
            context.trace.info("decryptFile isDirectory:\(filePath)")
            return filePath
        }
        do {
            let dPath = try SBUtils.decrypt(atPath: AbsPath(filePath)).absoluteString
            context.trace.info("decryptFile originPath:\(filePath) dPath:\(dPath)")
            return dPath
        } catch {
            context.trace.error("decryptFile error:\(error), filePath:\(filePath)")
            return filePath
        }
    }
    
    /// 正常场景不会用到，特殊场景如unzip后的文件加密需要
    @discardableResult
    static func encryptFile(with filePath: String, context: FileSystem.Context) throws -> String {
        guard encryptEnable() else {
            return filePath
        }
        guard LSFileSystem.fileExists(filePath: filePath) else{
            context.trace.info("encryptFile fileNotExists:\(filePath)")
            return filePath
        }
        guard !LSFileSystem.isDirectory(filePath: filePath) else{
            context.trace.info("encryptFile isDirectory:\(filePath)")
            return filePath
        }
        do {
            context.trace.info("encryptFile filePath:\(filePath)")
            return try SBUtils.encrypt(atPath: AbsPath(filePath)).absoluteString
        } catch {
            context.trace.error("encryptFile error:\(error), filePath:\(filePath)")
            return filePath
        }
    }
    
    static func fsCryptoConfig() -> FSCryptoConfig {
        var cryptoConfig = FSCryptoConfig.default
        do {
            let config: [String: Any] = try SettingManager.shared.setting(with: .make(userKeyLiteral: "filesystem_new_crypto_config"))
            if let encrypyEnable = config["ttfile_encrypt_enable"] as? Bool,
                let manualApiDecrypt = config["manual_api_decrypt"] as? Bool,
                let oldSystemApiDecrypt = config["old_system_api_decrypt"] as? Bool,
                let webTouchCalloutIntercept = config["web_touch_callout_intercept"] as? Bool,
                let apiShareIntercept = config["api_share_intercept"] as? Bool,
                let saveImageToPhotosAlbumIntercept = config["save_image_album_intercept"] as? Bool,
                let saveVideoToPhotosAlbumIntercept = config["save_video_album_intercept"] as? Bool,
                let openDocumentIntercept = config["open_document_more_action_intercept"] as? Bool
            {
                cryptoConfig = FSCryptoConfig(encrypyEnable: encrypyEnable,
                                              manualApiDecrypt: manualApiDecrypt,
                                              oldSystemApiDecrypt: oldSystemApiDecrypt,
                                              webTouchCalloutIntercept: webTouchCalloutIntercept,
                                              apiShareIntercept: apiShareIntercept,
                                              saveImageToPhotosAlbumIntercept: saveImageToPhotosAlbumIntercept,
                                              saveVideoToPhotosAlbumIntercept: saveVideoToPhotosAlbumIntercept,
                                              openDocumentIntercept: openDocumentIntercept)
            }
        } catch {}
        FileSystemUtils.logger.info("fsCryptoConfig: \(cryptoConfig)")
        return cryptoConfig
    }
    
    public static func checkEncryptStatus(forData data: Data) -> SBEncryptStatus{
       return SBUtils.checkEncryptStatus(forData: data)
    }
    
    public static func fileSize(atPath path: String) -> UInt64? {
        return SBUtil.fileSize(atPath: AbsPath(path))
    }
}

extension FSCrypto {
    /// 是否开启开启前置拦截
    public static func isCryptoInterceptEnable(type: CryptoInterceptType) -> Bool{
        switch type {
        case .apiShare:
            return isCryptoEnable() && fsCryptoConfig().apiShareIntercept
        case .apiSaveImageToPhotosAlbum:
            return isCryptoEnable() && fsCryptoConfig().saveImageToPhotosAlbumIntercept
        case .apiSaveVideoToPhotosAlbum:
            return isCryptoEnable() && fsCryptoConfig().saveVideoToPhotosAlbumIntercept
        case .webTouchCallout:
            return isCryptoEnable() && fsCryptoConfig().webTouchCalloutIntercept
        case .apiOpenDocument:
            return isCryptoEnable() && fsCryptoConfig().openDocumentIntercept
        }
    }
}

/// 文件加解密配置
struct FSCryptoConfig {

    /// 是否加密
    var encrypyEnable: Bool

    /// 部分API使用前，需要主动解密，如getFileInfo
    var manualApiDecrypt: Bool

    /// LarkStorage不生效的情况下，系统文件读写进行兜底解密
    var oldSystemApiDecrypt: Bool
    
    /// 网页容器图片链接长按禁止
    var webTouchCalloutIntercept: Bool
    
    /// tt.share是否开启移动端加密前置拦截
    var apiShareIntercept: Bool

    /// saveImageToPhotosAlbum是否开启移动端加密前置拦截
    var saveImageToPhotosAlbumIntercept: Bool

    /// saveVideoToPhotosAlbum是否开启移动端加密前置拦截
    var saveVideoToPhotosAlbumIntercept: Bool
    
    /// openDocument是否开启移动端加密前置拦截
    var openDocumentIntercept: Bool

    /// 默认配置
    static let `default` = FSCryptoConfig(encrypyEnable: false,
                                          manualApiDecrypt: false,
                                          oldSystemApiDecrypt: false,
                                          webTouchCalloutIntercept: true,
                                          apiShareIntercept: true,
                                          saveImageToPhotosAlbumIntercept: true,
                                          saveVideoToPhotosAlbumIntercept: true,
                                          openDocumentIntercept: true)
}

public enum CryptoInterceptType{
    case apiShare
    case webTouchCallout
    case apiSaveImageToPhotosAlbum
    case apiSaveVideoToPhotosAlbum
    case apiOpenDocument
}
