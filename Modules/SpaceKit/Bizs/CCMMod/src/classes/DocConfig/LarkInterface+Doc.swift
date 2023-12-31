//
//  LarkInterface+Doc.swift
//  LarkInterface
//
//  Created by 李晨 on 2019/7/11.
//

import Foundation
import UIKit
import LarkModel
import EENavigator
import RustPB
import LarkOpenChat

// MARK: - DocPushBody
public struct DocPushBody: CodablePlainBody {
    public static let pattern: String = "//client/doc"

    public let key: String
    public let channelID: String
    public let lastMessageID: String
    public let sourceType: String

    public init(
        key: String,
        channelID: String,
        lastMessageID: String,
        sourceType: String
    ) {
        self.key = key
        self.channelID = channelID
        self.lastMessageID = lastMessageID
        self.sourceType = sourceType
    }
}

/// It would be 'false' when click Close on page
public typealias SendDocConfirm = Bool
public typealias SendDocBlock = (SendDocConfirm, [SendDocModel]) -> Void

/**
 云文档Cell是否可选中
 .optionalType（可选）默认为可选
 .notOptionalType（不可选）
 */
public enum SendDocModelCanSelectType {
    case optionalType
    case notOptionalType
}

public final class SendDocModel {
    public var id: String
    public var title: String
    // Search Broker V2 自带高亮 优先使用这个
    public var attributedTitle: NSAttributedString?
    public var ownerID: String
    public var ownerName: String
    public var updateTime: Int64
    public var url: String
    public var docType: RustPB.Basic_V1_Doc.TypeEnum
    public var titleHitTerms: [String]
    public var isCrossTenant: Bool
    /// 自定义icon 的key
    public var iconKey: String?
    /// 自定义icon的type，目前type == 1是image
    public var iconType: IconType?
    // wiki 真正类型
    public var wikiSubType: RustPB.Basic_V1_Doc.TypeEnum
    /**Cell是否可选*/
    public var sendDocModelCanSelectType: SendDocModelCanSelectType
    /// 自定义标签文案
    public var relationTag: Basic_V1_TagData?
    public var searchRelationTag: Search_V2_TagData?

    public init(
        id: String,
        title: String,
        attributedTitle: NSAttributedString?,
        ownerID: String,
        ownerName: String,
        url: String,
        docType: RustPB.Basic_V1_Doc.TypeEnum,
        updateTime: Int64,
        titleHitTerms: [String],
        isCrossTenant: Bool,
        iconKey: String? = nil,
        iconType: Int? = nil,
        wikiSubType: RustPB.Basic_V1_Doc.TypeEnum,
        sendDocModelCanSelectType: SendDocModelCanSelectType,
        relationTag: Basic_V1_TagData? = nil,
        searchRelationTag: Search_V2_TagData? = nil
    ) {
        self.id = id
        self.title = title
        self.attributedTitle = attributedTitle
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.url = url
        self.docType = docType
        self.updateTime = updateTime
        self.titleHitTerms = titleHitTerms
        self.isCrossTenant = isCrossTenant
        self.iconKey = iconKey
        if let iconTypeValue = iconType, let type = IconType(rawValue: iconTypeValue) {
            self.iconType = type
        }
        self.wikiSubType = wikiSubType
        self.sendDocModelCanSelectType = sendDocModelCanSelectType
        self.relationTag = relationTag
        self.searchRelationTag = searchRelationTag
    }

    public convenience init(
        id: String,
        title: String,
        ownerID: String,
        ownerName: String,
        url: String,
        docType: RustPB.Basic_V1_Doc.TypeEnum,
        updateTime: Int64,
        titleHitTerms: [String],
        isCrossTenant: Bool,
        iconKey: String? = nil,
        iconType: Int? = nil,
        wikiSubType: RustPB.Basic_V1_Doc.TypeEnum,
        sendDocModelCanSelectType: SendDocModelCanSelectType,
        relationTag: Basic_V1_TagData? = nil,
        searchRelationTag: Search_V2_TagData? = nil
    ) {
        self.init(
            id: id,
            title: title,
            attributedTitle: nil,
            ownerID: ownerID,
            ownerName: ownerName,
            url: url,
            docType: docType,
            updateTime: updateTime,
            titleHitTerms: titleHitTerms,
            isCrossTenant: isCrossTenant,
            iconKey: iconKey,
            iconType: iconType,
            wikiSubType: wikiSubType,
            sendDocModelCanSelectType: sendDocModelCanSelectType,
            relationTag: relationTag,
            searchRelationTag: searchRelationTag
        )
    }
}

public extension SendDocModel {
    enum IconType: Int {
        case unknow = 0
        case image = 1

        static let supportedShowingTypes: [IconType] = [.image]

        /// 判断当前是否是支持显示的类型，一开始支持图片、自定义的图，加这个是为了考虑以后兼容新的类型，在老的客户端上至少能正常显示默认图
        public var isCurSupported: Bool {
            return IconType.supportedShowingTypes.contains(self)
        }
    }
}

public final class SendDocBody: PlainBody {

    public static let pattern = "//client/docs/sendDoc"

    public struct Context {
        /// max count of docs file that user can select
        public let maxSelect: Int
        /// if nil, vc will show detail title like "Send Doc file"
        public let title: String?
        /// if nil, vc will show detail text like "Send"
        public let confirmText: String?
        /// Chat Module will show different owner name on different scenes of chat
        public let chat: Chat?
        /// sendDocOptionalType = 1 sendDocNotOptionalType = 2
        public let sendDocCanSelectType: SendDocCanSelectType?

        public weak var chatOpenTabService: ChatOpenTabService?

        public init(maxSelect: Int = Int.max,
                    title: String? = nil,
                    confirmText: String? = nil,
                    chat: Chat? = nil,
                    sendDocCanSelectType: SendDocCanSelectType? = .sendDocOptionalType,
                    chatOpenTabService: ChatOpenTabService? = nil) {
            self.maxSelect = maxSelect
            self.title = title
            self.confirmText = confirmText
            self.chat = chat
            self.sendDocCanSelectType = sendDocCanSelectType
            self.chatOpenTabService = chatOpenTabService
        }
    }

    public let context: Context
    public let sendDocBlock: SendDocBlock

    public init(_ context: Context = Context(),
                sendDocBlock: @escaping SendDocBlock) {
        self.context = context
        self.sendDocBlock = sendDocBlock
    }
}

public struct CreateDocBody: CodablePlainBody {
    public static let pattern = "//client/creation/doc/new"

    public init() { }
}
