//
//  SpaceThumbnailInfo.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  

import Foundation
import SwiftyJSON
import SKFoundation

public enum SpaceThumbnailInfo: Equatable {

    public struct ExtraInfo {

        public enum EncryptType {
            // type = 0
            case noEncryption
            // type = 1
            case GCM(secret: String, nonce: String)
            // type = 2
            case CBC(secret: String)
            // type = 3
            case SM4GCM(secret: String, nonce: String)

            var isSupported: Bool {
                switch self {
                case .noEncryption,
                     .CBC:
                    return true
                case .GCM:
                    if #available(iOS 13.0, *) {
                        // iOS 13 使用系统 CryptoKit 进行解密
                        return true
                    } else {
                        return false
                    }
                case .SM4GCM:
                    return true
                }
            }

            public init?(data: [String: Any]) {
                guard let type = data["type"] as? Int else {
                    DocsLogger.error("Failed to parse encrypt type from thumbnail extra json", component: LogComponents.spaceThumbnail)
                    return nil
                }
                switch type {
                case 0:
                    self = .noEncryption
                case 1:
                    guard let secret = data["secret"] as? String, !secret.isEmpty,
                        let nonce = data["nonce"] as? String, !nonce.isEmpty else {
                            DocsLogger.error("Failed to parse GCM encrypt params from thumbnail extra json", component: LogComponents.spaceThumbnail)
                            return nil
                    }
                    self = .GCM(secret: secret, nonce: nonce)
                case 2:
                    guard let secret = data["secret"] as? String, !secret.isEmpty else {
                        DocsLogger.error("Failed to parse CBC encrypt params from thumbnail extra json", component: LogComponents.spaceThumbnail)
                        return nil
                    }
                    self = .CBC(secret: secret)
                case 3:
                    guard let secret = data["secret"] as? String, !secret.isEmpty,
                          let nonce = data["nonce"] as? String, !nonce.isEmpty else {
                        DocsLogger.error("Failed to parse SM4 GCM encrypt params from thumbnail extra json", component: LogComponents.spaceThumbnail)
                        return nil
                    }
                    self = .SM4GCM(secret: secret, nonce: nonce)
                default:
                    DocsLogger.error("Unknown encrypt type from thumbnail extra json", extraInfo: ["type": type], component: LogComponents.spaceThumbnail)
                    return nil
                }
            }
        }

        /// 额外的缩略图 URL，常为加密的缩略图下载地址
        let url: URL
        let encryptType: EncryptType

        public init?(_ data: [String: Any]) {
            guard let urlString = data["url"] as? String else {
                    DocsLogger.error("Failed to parse url from thumbnail extra json", component: LogComponents.spaceThumbnail)
                    return nil
            }
            self.init(urlString: urlString, encryptInfo: data)
        }

        public init?(urlString: String, encryptInfo: [String: Any]) {
            guard let url = URL(string: urlString) else {
                return nil
            }
            guard let encryptType = EncryptType(data: encryptInfo) else {
                return nil
            }
            self.init(url: url, encryptType: encryptType)
        }

        public init(url: URL, encryptType: EncryptType) {
            self.url = url
            self.encryptType = encryptType
        }
    }

    case unencryptOnly(unencryptURL: URL)
    case encryptedOnly(encryptInfo: ExtraInfo)
    case encryptedAndUnencrypt(encryptInfo: ExtraInfo, unencryptURL: URL)

    public var url: URL {
        switch self {
        case let .unencryptOnly(unencryptURL):
            return unencryptURL
        case let .encryptedOnly(encryptInfo):
            return encryptInfo.url
        case let .encryptedAndUnencrypt(encryptInfo, _):
            return encryptInfo.url
        }
    }

    public init?(unencryptURL: URL?, extraInfo: ExtraInfo?) {
        if let url = unencryptURL, let extraInfo = extraInfo {
            self = .encryptedAndUnencrypt(encryptInfo: extraInfo, unencryptURL: url)
        } else if let url = unencryptURL {
            self = .unencryptOnly(unencryptURL: url)
        } else if let extraInfo = extraInfo {
            self = .encryptedOnly(encryptInfo: extraInfo)
        } else {
            return nil
        }
    }
    
    public static func == (lhs: SpaceThumbnailInfo, rhs: SpaceThumbnailInfo) -> Bool {
        return lhs.url == rhs.url
    }
}
