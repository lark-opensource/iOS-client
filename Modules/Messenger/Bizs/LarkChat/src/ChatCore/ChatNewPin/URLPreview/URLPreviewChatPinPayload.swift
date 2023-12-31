//
//  URLPreviewChatPinPayload.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import LarkOpenChat
import RustPB
import LarkModel
import TangramService

struct URLPreviewChatPinPayload: ChatPinPayload {
    let icon: RustPB.Im_V1_UniversalChatPinIcon
    let url: String
    let title: String
    let titleUpdated: Bool
    let iconUpdated: Bool
    let hangPoint: RustPB.Basic_V1_PreviewHangPoint
    var urlPreviewEntity: URLPreviewEntity?
    var inlineEntity: InlinePreviewEntity?

    var displayTitle: String {
        if !titleUpdated,
           let inlineTitle = inlineEntity?.title,
           !inlineTitle.isEmpty {
            return inlineTitle
        } else {
            return title
        }
    }

    var displayIcon: RustPB.Im_V1_UniversalChatPinIcon {
        if !iconUpdated,
           let inlineEntity = inlineEntity,
           let pbModel = URLPreviewPinIconTransformer.convertToChatPinIcon(inlineEntity) {
            return pbModel
        } else {
            return icon
        }
    }
}

extension URLPreviewChatPinPayload: URLPreviewChatPinModel {}

struct URLPreviewChatPinSceneConfig {
    static let appID = 7_233_759_024_884_219_924
    static let appSceneType = 1
}
