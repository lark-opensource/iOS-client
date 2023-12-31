//
//  ShareBlockItemByMessageCard.swift
//  LarkWorkplaceModel
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation

/// [lark/workplace/api/ShareBlockItemByMessageCard] - request parameters
public struct WPShareBlockByMessageCardRequestParams: Codable {
    /// List of receiver who should received message card
    public let receivers: [WPMessageReceiver]
    /// Block item identifier
    public let itemId: String
    /// Block share info
    public var shareInfo: ShareInfo

    enum CodingKeys: String, CodingKey {
        case receivers
        case itemId = "itemID"
        case shareInfo
    }

    public init(receivers: [WPMessageReceiver], itemId: String, shareInfo: ShareInfo) {
        self.receivers = receivers
        self.itemId = itemId
        self.shareInfo = shareInfo
    }
}

extension WPShareBlockByMessageCardRequestParams {
    /// Block share info
    public struct ShareInfo: Codable {
        /// I18n title
        public let title: I18nStruct<String>?
        /// I18n imageKey
        public let imageKey: I18nStruct<String>?
        /// I18n detail button name
        public let detailBtnName: I18nStruct<String>?
        /// Redirect link for different platform
        public let detailBtnLink: [String: String]?
        /// I18n label
        public let blockShareName: I18nStruct<String>?
        /// Leave message
        public let leaveMessage: String?

        enum CodingKeys: String, CodingKey {
            case title
            case imageKey
            case detailBtnName = "redirectButtonName"
            case detailBtnLink = "linkURL"
            case blockShareName
            case leaveMessage = "leaveWord"
        }

        public init(title: I18nStruct<String>? = nil, imageKey: I18nStruct<String>? = nil, detailBtnName: I18nStruct<String>? = nil, detailBtnLink: [String : String]? = nil, blockShareName: I18nStruct<String>? = nil, leaveMessage: String? = nil) {
            self.title = title
            self.imageKey = imageKey
            self.detailBtnName = detailBtnName
            self.detailBtnLink = detailBtnLink
            self.blockShareName = blockShareName
            self.leaveMessage = leaveMessage
        }
    }
}

extension WPShareBlockByMessageCardRequestParams.ShareInfo {
    public struct I18nStruct<T: Codable>: Codable {
        /// Instance for different locale
        public let text: [String: T]?

        public init(_ text: [String : T]? = nil) {
            self.text = text
        }
    }
}

/// Receiver information
public struct WPMessageReceiver: Codable {
    /// Type (user or chat)
    public let type: ReceiverType
    /// Identifier (userId or chatId)
    public let id: String

    enum CodingKeys: String, CodingKey {
        case type = "receiverType"
        case id = "receiverID"
    }

    public init(type: ReceiverType, id: String) {
        self.type = type
        self.id = id
    }
}

extension WPMessageReceiver {
    public enum ReceiverType: Int, Codable {
        case user = 1
        case chat = 2
    }
}

/// [lark/workplace/api/ShareBlockItemByMessageCard] - response data
public struct WPBlockShareStatus: Codable {
    /// List of failed case
    public let failedReceivers: [WPMessageReceiver]?
}
