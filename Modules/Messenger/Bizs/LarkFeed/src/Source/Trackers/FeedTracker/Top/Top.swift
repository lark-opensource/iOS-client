//
//  Top.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import RustPB
import LarkModel
import LarkOpenFeed
import LarkFeedBase

/// HeaderView相关埋点
extension FeedTracker {
    struct Top {}
}

/// 在「feed置顶区」页的动作事件
extension FeedTracker.Top {
    struct Click {
        /// 左键点击置顶区的会话头像
        static func Chat(_ shortcut: ShortcutCellViewModel) {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "top_icon_chat_leftclick"
            params["target"] = "im_chat_main_view"
            params["chat_id"] = shortcut.id
            Tracker.post(TeaEvent(Homeric.FEED_TOP_CLICK, params: params))
        }

        /// 左键点击置顶区的文档头像
        static func Doc(_ shortcut: ShortcutCellViewModel) {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "top_icon_doc_leftclick"
            params["target"] = "ccm_docs_page_view"
            params["file_id"] = shortcut.preview.preview.docData.docURL
            Tracker.post(TeaEvent(Homeric.FEED_TOP_CLICK, params: params, md5AllowList: ["file_id"], bizSceneModels: []))
        }
    }
}
