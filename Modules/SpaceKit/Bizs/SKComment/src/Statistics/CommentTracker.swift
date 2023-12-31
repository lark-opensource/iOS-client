//
//  CommentTracker.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/5/23.
// swiftlint:disable identifier_name

import SKFoundation
import SpaceInterface
import SKCommon
import SKInfra

public enum ClientCommentAction: String {
    case input_comment
    case cancel_comment
    case submit_re_edit
    case finish_comment
    case submit_comment
    case re_input_audio
    case cancel_audiocomment
    case finish_input_audio
    case re_edit_comment
    case delete_comment
    case play_audiocomment
    case create_audiocomment
    case record_audiocomment
    case click_audiocomment_action
    case reply_comment
    case click_image_icon

    /// Reaction
    case show_reaction_panel
    case show_reaction_page
    case directional_reply_comment
    
    /// 点击回复按钮上报。上报参数:
    /// `comment_card_id`:评论卡片id
    case addition_click
    
    /// 点击编辑时就报一次。上报参数:
    /// `comment_card_id `: 评论卡片id
    /// `comment_id`: 对应的评论id
    /// `is_full_comment_flag`:  是否全文评论,枚举值：true、false
    case edit_click
    
    /// 收起译文时上报。上报参数: 同edit_click
    case cancel_translate_click
    
    /// 点击展示原文时上报。上报参数: 同edit_click
    case show_original_click
    
    /// 新增/编辑 取消就上报一次。上报参数：无
    case cancel_click
    
    /// 只有Drive评论需要
    case add_comment
    /// drive/局部评论
    case reaction_comment
    /// drive/局部评论
    case cancel_reaction_comment
    /// drive
    case finish_click
    /// drive 发送编辑请求前
    case edit_confirm
    /// drive点击确认删除时上报
    case delete_click
    
    /// 点击定位到评论输入框时触发上报 https://bytedance.feishu.cn/wiki/wikcnYRfKjgoQtW28lvNmaKoju4?sheet=GG3Bmj
    case begin_edit = "input_box"
    /// 点击"翻译"时上报
    case translate_click
    /// 展开评论reaction面板
    case reaction_comment_panel
    /// 点击评论卡片上的“复制链接”时上报
    case copy_link
    /// 点击评论卡片上的“发送至会话”时上报
    case send_to_chat
}

public final class CommentTracker {

    /// 存放公参
    public static var commonParams: [String: Any] = [:]
    
    static func log(_ action: ClientCommentAction, atInputTextView: AtInputTextView, extraInfo: [String: Any] = [:]) {
        if Thread.isMainThread {
            mainThreadLog(action, atInputTextView: atInputTextView, extraInfo: extraInfo)
        } else {
            DispatchQueue.main.sync {
                mainThreadLog(action, atInputTextView: atInputTextView, extraInfo: extraInfo)
            }
        }
    }

    static private func mainThreadLog(_ action: ClientCommentAction, atInputTextView: AtInputTextView, extraInfo: [String: Any] = [:]) {

        var commonParams: [String: Any] = extraInfo

        commonParams["action"] = action.rawValue

        let inputViewDependency: AtInputTextViewDependency? = atInputTextView.dependency

        if let inputViewDependency = inputViewDependency {
            if inputViewDependency.atInputTextType == .cards {
                commonParams["comment_type"] = "part_comment"
            } else if inputViewDependency.atInputTextType == .global {
                commonParams["comment_type"] = "full_comment"
            }

            commonParams["file_type"] = inputViewDependency.fileType.name
            commonParams["file_id"] = DocsTracker.encrypt(id: inputViewDependency.fileToken)
            commonParams["module"] = inputViewDependency.fileType.name

            let haveEdit = SpacePermissionManager.share.canEdit(inputViewDependency.fileToken) ? "true" : "false"

            commonParams["file_is_have_edit"] = haveEdit
            let docsInfo = inputViewDependency.commentDocsInfo as? DocsInfo
            if let creator = docsInfo?.ownerID,
                let uid = User.current.info?.userID,
                creator == uid {
                commonParams["is_owner"] = "true"
            } else {
                commonParams["is_owner"] = "false"
            }
        } else {
            DocsLogger.info("inputViewDependency = nil", component: LogComponents.comment)
        }

        if atInputTextView.superview is CommentFooterView || atInputTextView.focusType == .edit {
            commonParams["is_first"] = "false"
        } else {
            commonParams["is_first"] = "true"
        }

        commonParams["is_audiocomnent"] = "false"

        let style = SettingConfig.commentVoiceButtonStyle ?? 0
        if style == 1 {
            commonParams["record_audiocomment"] = "click"
        } else if style == 2 {
            commonParams["record_audiocomment"] = "press"
        }

        if extraInfo.keys.contains("operation") {
            commonParams["is_audiocomment"] = "true"
        }

        DocsTracker.log(enumEvent: .clientComment, parameters: commonParams)
    }
}


extension CommentTracker {
    
    public static func retryLoadImage(docsInfo: DocsInfo?, isActive: Bool, commentId: String) {
        if docsInfo?.isInCCMDocs == false {
            return
        }
        let parameter: [String: Any] = ["card_status": "\(isActive)",
                                        "comment_card_id": commentId]
        _report(eventType: .commentLoadImgRetryClick, parameter: parameter, docsInfo: docsInfo)
    }
    
    /// 页面曝光
    public static func expose(docsInfo: DocsInfo?) {
        if docsInfo?.isInCCMDocs == false {
            return
        }
        var parameter: [String: Any] = [:]
        if let info = docsInfo {
            parameter["file_type"] = info.type.name
        }
        _report(eventType: .commentView, parameter: parameter, docsInfo: docsInfo)
    }
    
    /// 评论点击事件埋点
    /// - Parameters:
    ///   - action: 行为
    ///   - cardId: 评论卡片id，可选值，根据action行为上报
    ///   - id: 评论id，可选值，根据action行为上报
    ///   - isFullComment: 是否全文评论，可选值，根据action行为上报
    public static func commentReport(action: ClientCommentAction, docsInfo: DocsInfo?, cardId: String?, id: String?, isFullComment: Bool?, extra: [String: Any] = [:]) {
        if let info = docsInfo, !info.isInCCMDocs {
            return
        }
        var parameter: [String: Any] = [:]
        if let comment_card_id = cardId {
            parameter["comment_card_id"] = comment_card_id
        }
        if let comment_id = id {
            parameter["comment_id"] = comment_id
        }
        if let is_full_comment_flag = isFullComment {
            parameter["is_full_comment_flag"] = "\(is_full_comment_flag)"
        }
        if let info = docsInfo {
            let token = info.wikiInfo?.objToken ?? info.objToken
            parameter["file_id"] = DocsTracker.encrypt(id: token)
            parameter["file_type"] = info.type.name
        }
        parameter.merge(extra) { (_, new) in new }
        parameter["click"] = action.rawValue
        parameter["target"] = "none"
        _report(eventType: .commentClick, parameter: parameter, docsInfo: docsInfo)
    }
    
    public enum CardType: String {
        case reaction
        case partComment = "part_comment"
        case fullComment = "full_comment"
    }
    
    public static func commentCopyLinkSuccess(cardType: CardType, docsInfo: DocsInfo?) {
        var parameter: [String: Any] = [:]
        parameter["click"] = "success"
        parameter["target"] = "none"
        parameter["card_type"] = cardType.rawValue
        _report(eventType: .commentCopyLinkSuccess, parameter: parameter, docsInfo: docsInfo)
    }
    
    public enum ReactionClick: String {
        case copyLink = "copy_link"
        case sendLark = "send_to_chat"
    }
    
    public static func commentReactionClick(click: ReactionClick,
                                            cardId: String,
                                            docsInfo: DocsInfo?) {
        var parameter: [String: Any] = [:]
        parameter["reaction_card_id"] = "xx"
        parameter["click"] = click.rawValue
        parameter["reaction_card_id"] = cardId
        _report(eventType: .contentReactionEvent, parameter: parameter, docsInfo: docsInfo)
    }
    
    
    public static func commentShareLinkToLark(cardType: CardType, docsInfo: DocsInfo?) {
        var parameter: [String: Any] = [:]
        parameter["card_type"] = cardType.rawValue
        _report(eventType: .permissionShareLarkView, parameter: parameter, docsInfo: docsInfo)
    }
    
    static func reportSubmit(params: [PerformanceKey: Any]) {
        var parameter: [String: Any] = [:]
        for (key, value) in params {
            parameter[key.rawValue] = value
        }
        _report(eventType: .commentSuccRate, parameter: parameter, docsInfo: nil)
    }

    static private func _report(eventType: DocsTracker.EventType, parameter: [String: Any], docsInfo: DocsInfo?) {
        var params = parameter
        if let info = docsInfo {
            params.merge(baseParametera(docsInfo: info)) { (old, _) in old }
        }
        if !commonParams.isEmpty {
            params.merge(commonParams) { (_, new) in new }
        }
        if Thread.isMainThread {
            DocsTracker.newLog(event: eventType.rawValue, parameters: params)
        } else {
            DispatchQueue.main.sync {
                DocsTracker.newLog(event: eventType.rawValue, parameters: params)
            }
        }
    }
    
    static func baseParametera(docsInfo: DocsInfo) -> [String: Any] {
        let token = docsInfo.wikiInfo?.objToken ?? docsInfo.objToken
        var module = docsInfo.type.name
        if docsInfo.type == .file {
            module = "drive"
        }
        let (userPerm, filePerm) = permission(token: token)
        let parameter: [String: Any] = ["app_form": docsInfo.getAppForm(),
                                        "module": module,
                                        "sub_module": "none",
                                        "page_token": DocsTracker.encrypt(id: token),
                                        "user_permission": userPerm,
                                        "file_permission": filePerm,
                                        "sub_file_type": docsInfo.fileType ?? ""]
        return parameter
    }

    private static func permission(token: String) -> (String, String) {
        let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self)!
        // TODO: PermissionSDK 埋点用，暂时不改
        let userPermission = permissonMgr.getUserPermissions(for: token)?.rawValue ?? 1
        let filePermission = permissonMgr.getPublicPermissionMeta(token: token)?.rawValue ?? "0"
        return ("\(userPermission)", filePermission)
    }
}

// MAKR: - 性能埋点
extension CommentTracker {
    public enum PerformanceKey: String {
        case fps
        case refreshRate = "refresh_rate"
        case commentStyle = "comment_style"
        case commentCount = "comment_count"
        case commentId = "comment_id"
        case replyCount = "reply_count"
        case totalReplyCount = "total_reply_count"
        case imageCount = "image_count"
        case totalImageCounthRate = "total_image_count"
        case fileType = "file_type"
        case fileId = "file_id"
        case isVC = "is_vc"
        case from
        case cost
        case webStageCost = "web_stage_cost"
        case nativeStageCost = "native_stage_cost"
        case domain
        case type
        case dataLength = "raw_data_length"
        case succResult = "res"
        case failReason = "fail_reason"
    }

    static func fpsRecord(params: [PerformanceKey: Any],
                          docsInfo: DocsInfo) {
        var parameter: [String: Any] = [:]
        for (key, value) in params {
            parameter[key.rawValue] = value
        }
        _report(eventType: .commentFPS, parameter: parameter, docsInfo: docsInfo)
    }
    
    static func renderRecord(params: [PerformanceKey: Any],
                             docsInfo: DocsInfo) {
        var parameter: [String: Any] = [:]
        for (key, value) in params {
            parameter[key.rawValue] = value
        }
        _report(eventType: .commentLoadCost, parameter: parameter, docsInfo: docsInfo)
    }
    
    static func editRecord(params: [PerformanceKey: Any],
                           docsInfo: DocsInfo) {
        var parameter: [String: Any] = [:]
        for (key, value) in params {
            parameter[key.rawValue] = value
        }
        _report(eventType: .commentEditCost, parameter: parameter, docsInfo: docsInfo)
    }
}

class CommentTrackerImp: CommentTrackerInterface {
    init() {}
    
    func commentReport(action: String, docsInfo: CommentDocsInfo?, cardId: String?, id: String?, isFullComment: Bool?, extra: [String: Any]) {
        guard let innerAction = ClientCommentAction(rawValue: action) else {
            DocsLogger.error("report fail, action:\(action) is not supported", component: LogComponents.comment)
            return
        }
        CommentTracker.commentReport(action: innerAction, docsInfo: docsInfo as? DocsInfo, cardId: cardId, id: id, isFullComment: isFullComment, extra: extra)
    }
    
    func baseParametera(docsInfo: CommentDocsInfo) -> [String: Any] {
        guard let info = docsInfo as? DocsInfo else {
            return [:]
        }
        return CommentTracker.baseParametera(docsInfo: info)
    }
    
    func update(baseParams: [String: Any]) {
        CommentTracker.commonParams = baseParams
    }
}
