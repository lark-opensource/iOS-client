//
//  MailTracker+EditorBusinesses.swift
//  MailSDK
//
//  Created by jiayi on 2021/8/4.
//

import Foundation

// 写信页埋点上报
extension MailTracker {

    // 写信页事件
    enum ClickType: String {
        case editView = "email_email_edit_view"
        case editClick = "email_email_edit_click"
        case cancelSendClick = "email_mail_cancel_send_click"
        case sendStatusClick = "email_send_status_toast_click"
    }

    // 写信页来源性质
    class func getParmaEditType() -> String {
        return "edit_type"
    }

    // MARK: 对文字操作的工具栏点击行为
    class func getParamEditClick() -> String {
        return "click"
    }

    class func getParamEditFontFamily() -> String {
        return "fontfamily"
    }

    class func getParamEditFontSize() -> String {
        return "fontsize"
    }

    enum FontFamily: String {
        case FixedWidth
        case System
        case PingFangHK
        case PingFangSC
        case PingFangTC
        case Arial
        case ComicSansMS
        case SanFrancisco
        case SansSerif
        case Serif
        case TimesNewRoman
        case Tahoma
        case TrebuchetMS
        case Verdana
        case Georgia
        case Garamond
        case KakuGothic
        case Mincho
    }

    enum FontSize: String {
        case FontSmall
        case FontNormal
        case FontLarge
        case FontHuge

        func toInt() -> Int {
            switch self {
            case .FontSmall:
                return EditorFontSize.fontSmall
            case .FontNormal:
                return EditorFontSize.fontNormal
            case .FontLarge:
                return EditorFontSize.fontLarge
            case .FontHuge:
                return EditorFontSize.fontHuge
            }
        }
    }

    enum ToolBarElse: String {
        case bold
        case underline
        case italic
        case strikethrough
        case align
        case numberList
        case orderedList
        case unorderedList
        case alignLeft
        case alignCenter
        case alignRight
    }

    // MARK: 在editor里面插入东西的行为
    enum InsertType: String {
        case image
        case attachment
        case large_attachement
        case add_doc_link
    }

    // MARK: 草稿行为
    enum DraftActionType: String {
        case draftSave = "draft_save"
        case draftAbort = "draft_abort"
    }

    class func insertLog(insertType: InsertType) {
        let clickType = ClickType.editClick.rawValue
        switch insertType {
        case .add_doc_link, .image:
            MailTracker.log(event: clickType, params: [getParamEditClick(): insertType.rawValue, "target": "none"])
        default:
            var isLargeAttachment = (insertType == .large_attachement)
            MailTracker.log(event: clickType, params: [getParamEditClick(): InsertType.attachment.rawValue, "is_large": isLargeAttachment, "target": "none"])
        }

    }

    class func editViewLog(clickType: ClickType, editType: SourcesType) {
        if clickType == ClickType.editView, let editTypeString = MailTracker.editType(type: editType) {
            MailTracker.log(event: clickType.rawValue, params: [getParmaEditType(): editTypeString])
        }
    }

    class func toastCancelSendLog() {
        let param = ["click": "cancel_send", "target": "none"]
        MailTracker.log(event: ClickType.cancelSendClick.rawValue, params: param)
        MailTracker.log(event: ClickType.sendStatusClick.rawValue, params: param)
    }

    class func toolBarAboutStringLog(id: String) {
        let event = ClickType.editClick.rawValue
        if let key = ToolBarElse.init(rawValue: id) {
            MailTracker.log(event: event, params: [getParamEditClick(): id, "target": "none"])
        } else if let key = FontSize.init(rawValue: id) {
            MailTracker.log(event: event, params: [getParamEditClick(): getParamEditFontSize(), "target": "none", "value": key.toInt()])
        } else if let key = FontFamily.init(rawValue: id) {
            let param = [getParamEditClick(): getParamEditFontFamily(), "target": "none", "value": key.rawValue]
            MailTracker.log(event: event, params: param)
        }
    }

    class func addressLog() {
        MailTracker.log(event: ClickType.editClick.rawValue, params: [getParamEditClick(): "change_from", "target": "none"])
    }

    class func draftLog(event: DraftActionType) {
        MailTracker.log(event: MailTracker.ClickType.editClick.rawValue, params: [MailTracker.getParamEditClick(): event.rawValue])
    }

    class func sendLog(send_status: Bool, toCount: Int, ccCount: Int, bccCount: Int,
                              largeAttachment: Int, attachment: Int, isSchedule: Bool, isSeparately: Bool) {
        MailTracker.log(event: MailTracker.ClickType.editClick.rawValue, params: ["target": "none", "send_status": send_status, "to": toCount,
                                                                                  "cc": ccCount, "bcc": bccCount, "large_attachment": largeAttachment,
                                                                                  "attachment": attachment, "isSchedule": isSchedule, "isSeparately": isSeparately])
    }
}
