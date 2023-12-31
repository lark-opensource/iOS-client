//
//  MagicShareTracks.swift
//  ByteView
//
//  Created by Prontera on 2020/4/24.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting

class MagicShareTracksManager {
    @RwAtomic
    var statesTimestampMap: [String: CGFloat] = [:]
    let queue = DispatchQueue(label: "byteview.magic.share.track.queue")

    func handleApplyStates(uuid: String,
                           timestamp: CGFloat) {
        queue.async {
            self.statesTimestampMap[uuid] = timestamp
        }
    }

}

// MARK: - Track on first position change
extension MagicShareTracksManager {

    func trackOnFirstPositionChangeAfterFollow(with shareID: String?,
                                               receiveFollowInfo: TimeInterval) {
        queue.async { [weak self] in
            self?.fetchReceiveFirstActionTimestamp { (timestamp: CGFloat?) in
                if let receiveFirstAction = timestamp {
                    MagicShareTracksV2.trackOnFirstPositionChangeAfterFollow(
                        with: shareID,
                        receiveFollowInfo: receiveFollowInfo,
                        receiveFirstAction: TimeInterval(receiveFirstAction) / 1000.0
                    )
                }
            }
        }
    }

    private func fetchReceiveFirstActionTimestamp(_ completion: @escaping ((CGFloat?) -> Void)) {
        queue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            if let firstActionTime = self.statesTimestampMap.values.min() {
                completion(firstActionTime)
            }
        }
    }

}

enum MagicShareTracks {
    private static let driveWindowPage = TrackEventName.vc_meeting_share_drive_window
    private static let onTheCallPage = TrackEventName.vc_meeting_page_onthecall
    private static let magicShareInit = TrackEventName.vc_meeting_magic_share_init_track
    private static let magicShareStat = TrackEventName.vc_meeting_magic_share_stat

    /// 点击“分享新内容”
    static func trackClickShareNew() {
        guard let vcType = MeetingManager.shared.currentSession?.meetType else {
            return
        }

        let params: TrackParams = [.action_name: "share_new"]
        switch vcType {
        case .call:
            VCTracker.post(name: .vc_call_page_onthecall, params: params)
        case .meet:
            VCTracker.post(name: onTheCallPage, params: params)
        default:
            break
        }
    }

    static func trackContainerBack(subType: Int,
                                   followType: Int,
                                   isPresenter: Int,
                                   shareId: String?,
                                   token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "backward",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackContainerReload(subType: Int,
                                     followType: Int,
                                     isPresenter: Int,
                                     shareId: String?,
                                     token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "refresh",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackAssignPresent(to participant: ByteviewUser,
                                   subType: Int,
                                   followType: Int,
                                   shareId: String?,
                                   token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "assign_present",
                                .extend_value: ["attendee_uuid": EncryptoIdKit.encryptoId(participant.id),
                                                "attendee_device_id": participant.deviceId,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "file_token": encToken,
                                                "share_id": shareId ?? ""]])
    }

    static func trackStopSharingDocument(subType: Int,
                                         followType: Int,
                                         shareId: String?,
                                         token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "stop_sharecontent",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "share_id": shareId ?? ""]])
    }

    static func trackToPresenter(subType: Int,
                                 followType: Int,
                                 shareId: String?,
                                 token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "follow",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "share_id": shareId ?? ""]])
    }

    static func trackTapPresenterIcon(subType: Int,
                                      followType: Int,
                                      shareId: String?,
                                      token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "follow",
                                .from_source: "presenter_icon",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "share_id": shareId ?? ""]])
    }

    static func trackTakeOver(subType: Int,
                              followType: Int,
                              shareId: String?,
                              token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "steal_present",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "share_id": shareId ?? ""]])
    }

    /// “成为共享人”弹窗二次确认埋点
    /// - Parameter status: true=确认，false=取消
    static func trackTakeOverDoubleCheck(isConfirm status: Bool) {
        VCTracker.post(name: .vc_meeting_magic_share_click,
                       params: [.click: "take_control_double_check",
                                "is_check": (status ? "true" : "false")])
    }

    static func trackMinimize(subType: Int,
                              followType: Int,
                              isPresenter: Int,
                              shareId: String?,
                              token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "return_to_full",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackMaximize(subType: Int,
                              followType: Int,
                              isPresenter: Int,
                              shareId: String?,
                              token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "return_to_share",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackDocumentDidReady(duration: Int64,
                                      subType: Int,
                                      followType: Int,
                                      isPresenter: Int,
                                      shareId: String?,
                                      token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "loading_finish",
                                .extend_value: ["file_token": encToken,
                                                "duration": duration,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackDocumentDidRenderFinish(duration: Int64,
                                             subType: Int,
                                             followType: Int,
                                             isPresenter: Int,
                                             shareId: String?,
                                             token: String?) {
        let encToken = encryptedToken(token: token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "first_render",
                                .extend_value: ["file_token": encToken,
                                                "duration": duration,
                                                "sub_type": subType,
                                                "follow_type": followType,
                                                "is_presenter": isPresenter,
                                                "share_id": shareId ?? ""]])
    }

    static func trackChangeToFree(document: MagicShareDocument, deviceId: String) {
        let encToken = encryptedToken(token: document.token)
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "unfollow",
                                .extend_value: ["file_token": encToken,
                                                "sub_type": document.shareSubType.rawValue,
                                                "follow_type": document.shareType.rawValue,
                                                "share_id": document.shareID ?? ""]])

        // https://bytedance.feishu.cn/sheets/shtcn4Fa9TqziMRvZL8gaUX4Xpf
        let extraParams: TrackParams = [
            "unfollow_reason": "click_screen",
            "click": "unfollow",
            "is_sharer": document.user.deviceId == deviceId
        ]
        VCTracker.post(name: .vc_meeting_magic_share_click, params: extraParams)
    }

    static func trackCopyFileLink(
        token: String?,
        shareType: FollowShareType,
        shareSubType: FollowShareSubType,
        isPresenter: Bool,
        shareId: String?) {
            let encToken = encryptedToken(token: token)
            let params: TrackParams = [
                .action_name: "copy_file_link",
                .extend_value: ["file_token": encToken,
                                "follow_type": shareType.rawValue,
                                "sub_type": shareSubType.rawValue,
                                "is_presenter": isPresenter ? 1 : 0,
                                "share_id": shareId ?? ""]]
            VCTracker.post(name: onTheCallPage, params: params)
        }

    static func trackClickFileLink(
        token: String?,
        shareType: FollowShareType,
        shareSubType: FollowShareSubType,
        isPresenter: Bool,
        shareId: String) {
            let encToken = encryptedToken(token: token)
            let params: TrackParams = [
                .action_name: "forward",
                "file_token": encToken,
                "follow_type": shareType.rawValue,
                "sub_type": shareSubType.rawValue,
                "is_presenter": isPresenter ? 1 : 0,
                "share_id": shareId]
            VCTracker.post(name: onTheCallPage, params: params)
        }

    static func trackStartShareContentOnOpenFile(
        token: String?,
        shareType: FollowShareType,
        shareSubType: FollowShareSubType,
        shareId: String
    ) {
        let encToken = encryptedToken(token: token)
        let params: TrackParams = [
            .action_name: "start_sharecontent",
            .from_source: "open_file",
            .extend_value: [
                "file_token": encToken,
                "sub_type": shareSubType.rawValue,
                "follow_type": shareType.rawValue,
                "share_id": shareId
            ]
        ]
        VCTracker.post(name: driveWindowPage, params: params)
    }

    static func trackReceiveNewShare(
        shareType: FollowShareType,
        shareSubType: FollowShareSubType,
        isPresenter: Int,
        shareId: String?
    ) {
        let params: TrackParams = [
            .action_name: "ms_received_new_share",
            .extend_value: [
                "sub_type": shareSubType.rawValue,
                "follow_type": shareType.rawValue,
                "is_presenter": isPresenter,
                "share_id": shareId ?? ""
            ]
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    static func trackGrootChannelOpenSuccess(
        isPresenter: Int,
        shareId: String?
    ) {
        let params: TrackParams = [
            .action_name: "ms_groot_channel_open",
            .extend_value: [
                "is_presenter": isPresenter,
                "share_id": shareId ?? ""
            ]
        ]
        VCTracker.post(name: onTheCallPage, params: params)
    }

    static func trackGrootChannelOpenFailed(
        isPresenter: Int,
        shareId: String?
    ) {
        let params: TrackParams = [
            .action_name: "ms_groot_channel_open_failed",
            .extend_value: [
                "is_presenter": isPresenter,
                "share_id": shareId ?? ""
            ]
        ]
        VCTracker.post(name: onTheCallPage, params: params)
    }

    static func trackShareContent(action: ShareContentAction) {
        guard let vcType = MeetingManager.shared.currentSession?.meetType else {
            return
        }
        let params: TrackParams = [.action_name: action.name]
        switch vcType {
        case .call:
            VCTracker.post(name: .vc_call_page_onthecall, params: params)
        case .meet:
            VCTracker.post(name: onTheCallPage, params: params)
        default:
            break
        }
    }

    /// https://bytedance.feishu.cn/sheets/shtcn2hC0dbJsRLOyvhSjqhvBbc?sheet=MZrDJf
    /// 在 Follow 流程出错（比如 webview 加载失败或手动刷新）或第一次收到/发送 action 时打点
    static func trackMagicShareInitFinished(isPresenter: Bool,
                                            finishReason: MagicShareInitFinishedReason,
                                            createSource: MagicShareRuntimeCreateSource,
                                            shareId: String,
                                            docCreateTime: Double? = nil,
                                            jssdkReadyTime: Double? = nil,
                                            injectStrategiesTime: Double? = nil,
                                            runtimeInitTime: Double? = nil) {
        // 过滤.untracked
        switch createSource {
        case .becomePresenter, .newShare, .reShare, .reload, .popBack, .toPresenter:
            break
        case .untracked:
            return
        }

        // reload过程中部分值无效，需要过滤
        var validDocCreateTime = docCreateTime ?? 0
        validDocCreateTime = validDocCreateTime > 0 ? validDocCreateTime : 0
        var validJssdkReadyTime = jssdkReadyTime ?? 0
        validJssdkReadyTime = validJssdkReadyTime > 0 ? validJssdkReadyTime : 0
        var validInjectStrategiesTime = injectStrategiesTime ?? 0
        validInjectStrategiesTime = validInjectStrategiesTime > 0 ? validInjectStrategiesTime : 0
        var validRuntimeInitTime = runtimeInitTime ?? 0
        validRuntimeInitTime = validRuntimeInitTime > 0 ? validRuntimeInitTime : 0

        let params: TrackParams = [
            "doc_create": validDocCreateTime,
            "jssdk_ready": validJssdkReadyTime,
            "inject_strategies": validInjectStrategiesTime,
            "initial_action": validRuntimeInitTime,
            "is_presenter": isPresenter ? 1 : 0,
            "is_aborted": finishReason.rawValue,
            .from_source: createSource.rawValue,
            "share_id": shareId
        ]
        VCTracker.post(name: magicShareInit,
                       params: params,
                       platforms: [.tea])
    }

    /// 在Follow流程出错/无需上报时，通知埋点平台忽略此次数据
    /// - Parameters:
    ///   - finishReason: 跳过init监控的原因
    ///   - isPresenter: 是否是共享人
    ///   - shareID: 共享ID
    static func trackMagicShareInitError(_ finishReason: MagicShareInitFinishedReason, isPresenter: Bool, shareID: String) {
        trackMagicShareInitFinished(
            isPresenter: isPresenter,
            finishReason: finishReason,
            createSource: .newShare,
            shareId: shareID)
    }

    /// 在 Follow 结束时，将统计的结果上报
    static func trackMagicShareStatus(strategy: String,
                                      isPresenter: Bool,
                                      timeCost: [Double],
                                      shareId: String) {
        guard !timeCost.isEmpty else {
            InMeetFollowViewModel.logger.info("track magic share status failed due to empty timeCostArray")
            return
        }
        // calc time cost data from timeCost
        let sortedTimeCost = timeCost.sorted { $0 < $1 }
        let sum = sortedTimeCost.map { Double($0) }.reduce(0, +)
        let aveCost: Double = sortedTimeCost.isEmpty ? 0 : (sum / Double(sortedTimeCost.count))
        let minCost = sortedTimeCost.first ?? 0
        let maxCost = sortedTimeCost.last ?? 0
        let midCost = sortedTimeCost[sortedTimeCost.count / 2]
        let params: TrackParams = [
            "strategy": strategy,
            "type": isPresenter ? "send" : "receive",
            "ave_cost": aveCost,
            "min_cost": minCost,
            "max_cost": maxCost,
            "mid_cost": midCost,
            "share_id": shareId
        ]
        VCTracker.post(name: magicShareStat,
                       params: params)
    }

    /// Follow 相关的 Webview 开始加载
    static func trackMagicShareWebViewLoadingStart(isPresenter: Bool,
                                                   shareId: String) {
        let params: TrackParams = [
            .action_name: "webview_loading_start",
            .extend_value: [
                "is_presenter": isPresenter ? 1 : 0,
                "share_id": shareId
            ]
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    /// Follow 相关的 Webview 加载成功
    static func trackMagicShareWebViewLoadingSuccess(isPresenter: Bool,
                                                     duration: Double,
                                                     shareId: String,
                                                     retryTimes: NSInteger) {
        let params: TrackParams = [
            .action_name: "webview_loading_success",
            .extend_value: [
                "is_presenter": isPresenter ? 1 : 0,
                "duration": duration,
                "share_id": shareId,
                "retry_times": 0
            ]
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    /// Groot Channel 创建成功时打点
    /// duration: 从 ms_groot_channel_open 这个点开始到成功的耗时
    static func trackMagicShareGrootChannelOpenSuccess(isPresenter: Bool,
                                                       shareId: String,
                                                       duration: Double) {
        let params: TrackParams = [
            .action_name: "ms_groot_channel_success",
            .extend_value: [
                "is_presenter": isPresenter ? 1 : 0,
                "share_id": shareId,
                "duration": duration
            ]
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    /// Magic Share 发起请求发出前（请求是 SHARE_FOLLOW）
    static func trackBeforeShareFollowRequest() {
        let params: TrackParams = [
            .action_name: "ms_follow_start"
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    /// Magic Share 发起请求成功后
    static func trackOnShareFollowRequestSuccess(duration: Double,
                                                 shareId: String) {
        let params: TrackParams = [
            .action_name: "ms_follow_success",
            .extend_value: [
                "duration": duration,
                "share_id": shareId
            ]
        ]
        VCTracker.post(name: onTheCallPage,
                       params: params)
    }

    /// Magic Share 发起请求失败后
    static func trackOnShareFollowRequestFail(error: Error) {
        let params: TrackParams = [
            .action_name: "ms_follow_fail",
            .extend_value: ["error_code": error.toErrorCode() ?? -1]
        ]
        VCTracker.post(name: onTheCallPage, params: params)
    }

    /// MagicShare 显示区域大小发生变化时记录展示的实际区域大小
    /// https://bytedance.feishu.cn/sheets/shtcnzkVs1UQkwiv7EXxRpgtYmd?sheet=d45b0b
    static func trackOnNavigationWrapperSizeChange(size: CGSize,
                                                   isPresenter: Bool,
                                                   shareId: String,
                                                   shareType: FollowShareType) {
        let params: TrackParams = [
            "display_width": size.width,
            "display_height": size.height,
            "ratio": 1,
            "is_presenter": isPresenter ? 1 : 0,
            "share_id": shareId,
            "is_main_display": 1,
            "follow_type": shareType.rawValue
        ]
        VCTracker.post(name: .vc_meeting_magic_share_display_size,
                       params: params)
    }

    private static func encryptedToken(token: String?) -> String {
        guard let token = token, !token.isEmpty else {
            return ""
        }
        return EncryptoIdKit.encryptoId(token)
    }
}

// MARK: - MS文档跳转浏览器打开 https://bytedance.feishu.cn/sheets/shtcnIpYqNK9TVirR5E1NrNlsfe
extension MagicShareTracks {
    /// 共享人点击MS文档中的非CCM链接，提醒弹窗展示时上报
    static func trackViewOpenUrlAlert() {
        VCTracker.post(name: .vc_meeting_magic_share_popup_view)
    }

    /// 共享人点击MS文档中的非CCM链接，点击弹窗上按钮时上报
    /// - Parameter isConfirm: confirm = true, cancel = false
    static func trackClickOpenUrlAlert(_ isConfirm: Bool) {
        VCTracker.post(name: .vc_meeting_magic_share_popup_click,
                       params: [.click: isConfirm ? "confirm" : "cancel"])
    }
}

extension MagicShareTracks {
    enum ShareContentAction {
        case shareContentClicked
        case shareScreenClicked
        case shareDriveFilesClicked
        case stopSharingScreenButtonClick
        case stopSharingScreenCellClick

        var name: String {
            switch self {
            case .shareContentClicked:
                return "share_content"
            case .shareScreenClicked:
                return "share_screen"
            case .shareDriveFilesClicked:
                return "share_drive_files"
            case .stopSharingScreenButtonClick:
                return "stop_sharing"
            case .stopSharingScreenCellClick:
                return "stop_sharing_confirm"
            }
        }
    }
}

final class MagicShareTracksV2 {

    /// "FOLLOW_TRACK"方式透传埋点的eventName对应的Key
    private static let eventNameKey: String = "type"
    /// "FOLLOW_TRACK"方式透传埋点的params对应的Key
    private static let paramsKey: String = "data"

    /// 会中共享主页展示时
    static func trackEnterShareWindow() {
        VCTracker.post(name: .vc_meeting_sharewindow_view)
    }

    /// 共享窗口中的点击事件
    static func trackShareWindowOperation(action: ShareWindowClickOperation, isLocal: Bool) {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: action.trackStr,
                                "is_vr_mirror": isLocal])
    }

    /// 点击搜索框
    static func trackTapSearchBar() {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "search",
                                .target: "vc_meeting_share_window_search_view"])
    }

    /// 点击分享屏幕
    static func trackOpenSearchedFile(rank: Int, isLocal: Bool) {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "search_file_open",
                                "rank": rank,
                                "is_vr_mirror": isLocal])
    }

    /// 点击分享屏幕
    static func trackShareScreen(rank: Int, isLocal: Bool) {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "share_screen",
                                "rank": rank,
                                "is_vr_mirror": isLocal])
    }

    /// 点击投屏中的开启白板
    static func trackStartWhiteboard(rank: Int, isLocal: Bool) {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "whiteboard",
                                "rank": rank,
                                "is_vr_mirror": isLocal])
    }

    /// 点击投屏中的停止白板
    static func trackQuitWhiteboard(rank: Int, isLocal: Bool) {
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "quit_board",
                                "rank": rank,
                                "is_vr_mirror": isLocal])
    }

    /// 点击 Magic Share
    static func trackClickMagicShare(rank: Int, token: String?, isLocal: Bool, isFileMeetingRelated: Bool) {
        let fileToken = encryptedToken(token: token)
        VCTracker.post(name: .vc_meeting_sharewindow_click,
                       params: [.click: "magic_share",
                                "rank": rank,
                                "file_token": fileToken,
                                "is_vr_mirror": isLocal,
                                "is_file_meeting_related": isFileMeetingRelated.stringValue])
    }

    /// 浏览 Magic Share
    static func trackEnterMagicShare() {
        VCTracker.post(name: .vc_meeting_magic_share_view)
    }

    /// Magic Share 中的简单点击事件
    static func trackMagicShareClickOperation(action: MagicShareClickOperation, isSharer: Bool = true) {
        VCTracker.post(name: .vc_meeting_magic_share_click,
                       params: [.click: action.trackStr,
                                "is_sharer": isSharer])
    }

    /// 点击复制共享文件的链接
    static func trackCopyFileLink(token: String?, isSharer: Bool) {
        let fileToken = encryptedToken(token: token)
        VCTracker.post(name: .vc_meeting_magic_share_click,
                       params: [.click: "copy_file_link",
                                "is_sharer": isSharer,
                                "file_token": fileToken])
    }

    /// 重新加载文档
    static func trackReloadFile(token: String?, isSharer: Bool) {
        let fileToken = encryptedToken(token: token)
        VCTracker.post(name: .vc_meeting_magic_share_click,
                       params: [.click: "reload",
                                "is_sharer": isSharer,
                                "file_token": fileToken])
    }

    /// 点击移交贡献权限所指定的 user
    static func trackAssignPresenter(user: ByteviewUser, isSharer: Bool) {
        let userId = EncryptoIdKit.encryptoId(user.id)
        VCTracker.post(name: .vc_meeting_magic_share_click,
                       params: [.click: "assign_presenter",
                                "is_sharer": isSharer,
                                "assigned_user_id": userId])
    }

    /// 透传上报VCSDK（前端）与CCM侧统计的埋点
    /// - Parameter trackInfo: 未解析的JSON埋点信息，其中"type"对应的是eventName，"data"对应的是额外参数
    /// 埋点方案 https://bytedance.feishu.cn/docs/doccnN2TmLgoVYxAL2pgKa8Jexc#
    static func trackWithPassThroughWebTrackInfo(_ trackInfo: String) {
        guard let jsonData = trackInfo.description.data(using: .utf8),
              let jsonDic = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let eventName = jsonDic[Self.eventNameKey] as? String,
              let paramsDic = jsonDic[Self.paramsKey] as? [String: Any] else {
            Logger.vcFollow.warn("trackWithPassThroughWebTrackInfo failed, json data is invalid")
            return
        }
        let event = TrackEvent.raw(name: eventName, params: paramsDic)
        VCTracker.post(event)
    }

    /// 一次magic_share过程中，跟随侧首个action的相关数据上报
    /// 埋点方案 https://bytedance.feishu.cn/docx/doxcnBumSYKjRdTsNDaOO1QeZdf
    /// 数据格式参考 https://bytedance.feishu.cn/sheets/shtcna5s0Gvu5C68xxBUbc6YoJg?sheet=KFuJbb
    static func trackOnFirstPositionChangeAfterFollow(with shareID: String?, receiveFollowInfo: TimeInterval, receiveFirstAction: TimeInterval) {
        let now = Date().timeIntervalSince1970
        VCTracker.post(name: .vc_magic_share_first_action_dev,
                       params: [
                        "share_id": shareID ?? "",                          // 共享ID，起点为请求一次文档url，终点为结束切换url请求或结束共享
                        "source": "vcsdk",                                  // 区分上报类型，目前移动端不使用此字段，固定上报“vcsdk”
                        "local_time_ms": now * 1000,                        // 事件在客户端发生的时间（毫秒）
                        "elapse": (now - receiveFollowInfo) * 1000,         // 服务端推送FollowInfo～首个action apply的耗时（毫秒）
                        "apply_elapse": (now - receiveFirstAction) * 1000   // 收到首个action～首个action apply的耗时（毫秒）
                       ])
    }

    /// 统计新sender格式下收到的GrootCell总数与其中被拦截的数量
    /// https://bytedance.feishu.cn/sheets/shtcnazZ6rqacAKlCkp4jZ5CWJh
    static func trackGrootCellValidStatistics(totalCount: Int,
                                              invalidCount: Int,
                                              duration: Int,
                                              isPresenterChange: Bool) {
        VCTracker.post(name: .vc_ms_pkg_valid_dev,
                       params: ["total_cnt": totalCount,
                                "presenter_invalid_cnt": invalidCount,
                                "duration_ms": duration,
                                "is_presenter_change": isPresenterChange ? 1 : 0])
    }

    /// 文档加载埋点
    /// https://bytedance.feishu.cn/sheets/shtcna5s0Gvu5C68xxBUbc6YoJg?sheet=hPofk5
    static func trackDocumentLoad(shareId: String,
                                  followType: MagicShareDocumentStatus,
                                  subLoadType: MagicShareDocumentSubLoadType,
                                  pageToken: String,
                                  isUseUniqueWebView: Bool) {
        let encryptedToken = encryptedToken(token: pageToken)
        VCTracker.post(name: .vc_magic_share_ccm_load_dev,
                       params: [
                        "share_id": shareId,
                        "follow_type": followType.trackFollowTypeDesc,
                        "load_type": "mobile",
                        "sub_load_type": subLoadType.trackSubLoadTypeDesc,
                        "page_token": encryptedToken,
                        "use_unique_webview": isUseUniqueWebView
                       ])
    }

    /// v7.9 妙享降级数据变化
    /// https://bytedance.larkoffice.com/wiki/VO9CwvV2TiaAlrklDkickjTpnMb
    static func trackDowngradeInfoChange(token: String,
                                         level: CGFloat,
                                         systemLoadScore: CGFloat,
                                         dynamicScore: CGFloat,
                                         thermalScore: CGFloat,
                                         openDocScore: CGFloat,
                                         degradeReason: String) {
        let encryptedToken = encryptedToken(token: token)
        VCTracker.post(name: .vc_magic_share_degrade_dev,
                       params: [
                        "file_id": encryptedToken,
                        "template_log_id": encryptedToken,
                        "is_degrade_request_sent": 1,
                        "is_degrade_response_received": 1,
                        "degrade_level": level,
                        "degrade_system_load": systemLoadScore,
                        "degrade_dynamic": dynamicScore,
                        "degrade_thermal": thermalScore,
                        "degrade_open_doc": openDocScore,
                        "degrade_reason": degradeReason
                       ])
    }

    /// 加密 CCM 文件的 file token
    private static func encryptedToken(token: String?) -> String {
        guard let token = token, !token.isEmpty else {
            return ""
        }
        return EncryptoIdKit.encryptoId(token)
    }

}

extension MagicShareTracksV2 {

    enum ShareWindowClickOperation: String {
        case clickNewDocs = "new_docs"
        case clickNewSheets = "new_sheets"
        case clickNewMindNotes = "new_mindnotes"
        case clickNewDocX = "new_docx"
        case clickSearch = "search"
        case clickNewBitable = "new_bitable"

        var trackStr: String {
            return self.rawValue
        }
    }

    enum MagicShareClickOperation: String {
        case clickSubmitFeedback = "submit_feedback"    // todo
        case clickPermissionSettings = "permission_settings"
        case clickPassSharing = "pass_sharing"
        case clickStopSharing = "stop_sharing"
        case clickViewComments = "view_comments"    // todo
        case clickBackward = "backward"
        case clickTakeControl = "take_control"
        case clickFollow = "follow"
        case clickFollowIcon = "follow_icon"
        case clickMore = "more"

        var trackStr: String {
            return self.rawValue
        }
    }

    enum MagicShareDocumentSubLoadType {
        /// 普通
        case normal
        /// 加载失败，用户重新刷新
        case retry
        /// Webview Crash，自动重试加载
        case autoReload
        /// 用户手动刷新
        case refresh

        var trackSubLoadTypeDesc: String {
            switch self {
            case .normal: return "normal"
            case .retry: return "retry"
            case .autoReload: return "auto_reload"
            case .refresh: return "refresh"
            }
        }
    }
}

private extension MagicShareDocumentStatus {
    var trackFollowTypeDesc: String {
        switch self {
        case .following: return "follow"
        case .free: return "free_browse"
        case .sharing: return "presenter"
        case .sstomsFollowing, .sstomsFree: return "sharescreen_free_browse"
        }
    }
}
