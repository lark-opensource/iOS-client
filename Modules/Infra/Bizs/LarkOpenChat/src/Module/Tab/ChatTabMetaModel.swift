//
//  ChatTabMetaModel.swift
//  LarkOpenChat
//
//  Created by 赵家琛 on 2021/6/16.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkOpenIM

/// 业务方初始化基本信息
public struct ChatTabMetaModel: MetaModel {
    public let chat: Chat
    public let content: ChatTabContent?
    public let type: ChatTabType /// 某些业务可以不依赖 content ，只根据 type 进行初始化
    public init(chat: Chat, type: ChatTabType, content: ChatTabContent? = nil) {
        self.chat = chat
        self.type = type
        self.content = content
    }
}

public struct ChatJumpTabModel {
    public let chat: Chat
    public let content: ChatTabContent
    public let targetVC: UIViewController

    public init(chat: Chat, content: ChatTabContent, targetVC: UIViewController) {
        self.chat = chat
        self.content = content
        self.targetVC = targetVC
    }
}

/// Tab 类型
public typealias ChatTabType = RustPB.Im_V1_ChatTab.TypeEnum

/// Tab 基本信息
public typealias ChatTabContent = RustPB.Im_V1_ChatTab

/// 自定义添加 Tab 基本信息
public struct ChatAddTabMetaModel {
    public struct ExtraInfo {
        public let event: String
        public let params: [String: Any]
        public init(event: String, params: [String: Any]) {
            self.event = event
            self.params = params
        }
    }

    public let chat: Chat
    public let type: ChatTabType
    public let targetVC: UIViewController
    public var extraInfo: ExtraInfo?

    public init(chat: Chat, type: ChatTabType, targetVC: UIViewController, extraInfo: ExtraInfo? = nil) {
        self.chat = chat
        self.type = type
        self.targetVC = targetVC
        self.extraInfo = extraInfo
    }
}

/// 自定义添加 Tab 入口展示信息
public struct ChatAddTabEntry {
    public let title: String
    public let type: ChatTabType
    public let icon: UIImage

    public init(title: String, type: ChatTabType, icon: UIImage) {
        self.title = title
        self.icon = icon
        self.type = type
    }
}

/// 会话上下文信息
public struct ChatTabContextModel {
    public var chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}

/// 图片资源
public enum ChatTabImageResource {
    case image(UIImage)
    case key(key: String, config: ImageConfig?)

    public struct ImageConfig {
        public let tintColor: UIColor?
        public let placeholder: UIImage?
        public let imageSetPassThrough: RustPB.Basic_V1_ImageSetPassThrough?
        public init(tintColor: UIColor?, placeholder: UIImage?, imageSetPassThrough: RustPB.Basic_V1_ImageSetPassThrough? = nil) {
            self.tintColor = tintColor
            self.placeholder = placeholder
            self.imageSetPassThrough = imageSetPassThrough
        }
    }
}

public struct ChatTabImagePassThroughConfig {

    private static let PassThroughKey = "imageSetPassThrough"
    private static let ImageKey = "key"
    private static let FsUnitKey = "fsUnit"
    private static let CryptoKey = "crypto"
    private static let CryptoTypeKey = "type"
    private static let CipherKey = "cipher"
    private static let CipherSecretKey = "secret"
    private static let CipherNonceKey = "nonce"
    private static let CipherAdditionalDataKey = "additionalData"

    public static func convertToPBModel(_ dic: [String: Any]) -> Basic_V1_ImageSetPassThrough? {
        guard let passThroughDic = dic[PassThroughKey] as? [String: Any] else { return nil }
        var passThrough = Basic_V1_ImageSetPassThrough()
        if let key = passThroughDic[ImageKey] as? String {
            passThrough.key = key
        }
        if let fsUnit = passThroughDic[FsUnitKey] as? String {
            passThrough.fsUnit = fsUnit
        }
        if let cryptoDic = passThroughDic[CryptoKey] as? [String: Any] {
            var crypto = Basic_V1_SerCrypto()
            crypto.type = Basic_V1_SerCrypto.TypeEnum(rawValue: (cryptoDic[CryptoTypeKey] as? Int) ?? 0) ?? .unknown
            if let cipherDic = cryptoDic[CipherKey] as? [String: Any] {
                var cipher = Basic_V1_Cipher()
                cipher.secret = Data(base64Encoded: (cipherDic[CipherSecretKey] as? String) ?? "") ?? Data()
                cipher.nonce = Data(base64Encoded: (cipherDic[CipherNonceKey] as? String) ?? "") ?? Data()
                cipher.additionalData = Data(base64Encoded: (cipherDic[CipherAdditionalDataKey] as? String) ?? "") ?? Data()
                crypto.cipher = cipher
            }
            passThrough.crypto = crypto
        }
        return passThrough
    }

    public static func convertToJsonDic(_ passThrough: Basic_V1_ImageSetPassThrough) -> [String: Any] {
        var passThroughDic: [String: Any] = [ImageKey: passThrough.key,
                                            FsUnitKey: passThrough.fsUnit]
        if passThrough.hasCrypto {
            let crypto = passThrough.crypto
            var cryptoDic: [String: Any] = [:]
            if crypto.hasType {
                cryptoDic[CryptoTypeKey] = crypto.type.rawValue
            }
            if crypto.hasCipher {
                let cipher = crypto.cipher
                var cipherDic: [String: Any] = [:]
                if cipher.hasSecret {
                    cipherDic[CipherSecretKey] = cipher.secret.base64EncodedString()
                }
                if cipher.hasNonce {
                    cipherDic[CipherNonceKey] = cipher.nonce.base64EncodedString()
                }
                if cipher.hasAdditionalData {
                    cipherDic[CipherAdditionalDataKey] = cipher.additionalData.base64EncodedString()
                }
                cryptoDic[CipherKey] = cipherDic
            }
            passThroughDic[CryptoKey] = cryptoDic
        }
        return [PassThroughKey: passThroughDic]
    }
}
