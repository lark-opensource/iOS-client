//
//  NotesTracks.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/6/15.
//

import Foundation
import ByteViewTracker

// 有效会议-会议纪要 https://bytedance.feishu.cn/sheets/T9ZDspVqfhX9eStxfs8cJvnVntg
final class NotesTracks {

    enum ShowNotesFromSource: String {
        case eventJoin = "event_join"
        case instantJoin = "instant_join"
        case notesButton = "notes_buttom"
    }

    enum NotesNavigationItem: String {
        /// 纪要按钮
        case notes = "notes"
        /// 关闭
        case close = "close_notes"
        /// 更多
        case more = "notes_more"
        /// 分享
        case share = "notes_share"
        /// 通知
        case notification = "notes_notification"
    }

    /// 会议纪要展示事件 token
    static func trackShowNotes(with notesUrl: String?, fromSource: ShowNotesFromSource) {
        let token = Self.encryptedContent(content: notesUrl)
        VCTracker.post(name: .vc_meeting_notes_view,
                       params: ["token": token,
                                "from_source": fromSource.rawValue])
    }

    /// 点击快速共享的Alert按钮
    static func trackClickNotesQuickShareAlert(_ isSharing: Bool, fileUrl: String) {
        let encryptedToken = Self.encryptedContent(content: fileUrl)
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: [.click: isSharing ? "notes_share_confirm_interrupt_sharing" : "notes_share_confirm",
                                "file_id": encryptedToken])
    }

    /// 会议纪要相关点击
    static func trackClickNotesNavigationBar(on item: NotesNavigationItem, isOpen: Bool? = nil) {
        var params: TrackParams = [.click: item.rawValue]
        if let isOpen = isOpen {
            params["option"] = isOpen ? "open" : "close"
        }
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: params)
    }

    /// 点击文档导航栏的快速共享按钮
    static func trackClickNotesQuickMagicShareWithUrl(_ fileUrl: String) {
        let encryptedToken = Self.encryptedContent(content: fileUrl)
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "notes_magicshare",
                                "file_id": encryptedToken])
    }

    /// 点击模板详情页的“使用模板”
    static func trackClickTemplate(with token: String) {
        let encryptedToken = Self.encryptedContent(content: token)
        VCTracker.post(name: .vc_meeting_notes_click,
                       params: ["token": encryptedToken,
                                "is_meeting_onthecall": "true",
                                .click: "use_template",
                                "location": "template_preview"])
    }

    /// web埋点透传给各端，增加通参再上报
    static func trackPassThroughEvents(_ eventName: String, params: [String: Any]) {
        let event = TrackEvent.raw(name: eventName, params: params)
        VCTracker.post(event)
    }

    /// 加密会议纪要url，作为token使用
    private static func encryptedContent(content: String?) -> String {
        guard let content = content, !content.isEmpty else {
            return ""
        }
        return EncryptoIdKit.encryptoId(content)
    }
}
