//
//  InMeetShareDataManager.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/2/14.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

/// 会中共享数据管理器
/// - 处理服务端推送的会中共享数据
/// - 提供会中共享数据获取方法
/// - 推送会中共享数据的变化
final class InMeetShareDataManager: VideoChatCombinedInfoPushObserver {

    private let info: VideoChatInfo
    private let service: MeetingBasicService
    private var account: ByteviewUser { service.account }
    private var httpClient: HttpClient { service.httpClient }

    /// 当前共享场景的类型+数据
    @RwAtomic private(set) var shareContentScene: InMeetShareScene = .defaultNone
    /// 本场会议中曾共享过白板
    @RwAtomic private(set) var hasSharedWhiteboard: Bool = false
    /// 本场会议中曾共享过标注
    @RwAtomic private(set) var hasSharedSketch: Bool = false
    /// 本地投屏会议
    @RwAtomic private(set) var isLocalProjection: Bool = false
    /// 自己正在共享屏幕
    @RwAtomic private(set) var isMySharingScreen: Bool = false
    /// 本场会议的会议信息
    @RwAtomic private var inMeetingInfo: VideoChatInMeetingInfo?
    /// 在看投屏转妙享
    @RwAtomic private var isShareScreenToFollow: Bool = false

    @RwAtomic var isSketchSaved: Bool = false
    @RwAtomic var isWhiteBoardSaved: Bool = false

    private let listeners = Listeners<InMeetShareDataListener>()

    private var meetingId: String { info.id }
    private var meetType: MeetingType { inMeetingInfo?.vcType ?? info.type }

    init(info: VideoChatInfo, service: MeetingBasicService) {
        self.info = info
        self.service = service
        self.isLocalProjection = info.settings.subType == .screenShare
        service.push.combinedInfo.addObserver(self)
    }

    func addListener(_ listener: InMeetShareDataListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetShareDataListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetShareDataListener) {
        listener.didChangeShareContent(to: shareContentScene, from: .defaultNone)
    }

    func didReceiveCombinedInfo(inMeetingInfo: ByteViewNetwork.VideoChatInMeetingInfo, calendarInfo: ByteViewNetwork.CalendarInfo?) {
        guard inMeetingInfo.id == meetingId,
              inMeetingInfo != self.inMeetingInfo else { return }
        handleInMeetingInfo(inMeetingInfo)
    }

    private func handleInMeetingInfo(_ info: VideoChatInMeetingInfo) {
        Logger.shareContent.debug("inMeetingInfo changed")

        guard !needfilt(info) else {
            Logger.shareContent.warn("inMeetingInfo changed filter by seq: \(info.minutesStatusData?.seq)")
            return
        }

        // 记录新旧Info
        let oldValue = self.inMeetingInfo
        self.inMeetingInfo = info

        // 判断共享人授权状态，改变投屏转妙享状态
        if isShareScreenToFollow && !info.isFreeToBrowseEnabled {
            isShareScreenToFollow = false
        }

        // 处理会议类型变化
        let oldSubType = oldValue?.meetingSettings.subType ?? self.info.settings.subType
        Logger.shareContent.info("inMeetingInfo subType now:\(info.meetingSettings.subType) oldSubType:\(oldSubType)")
        if oldSubType != info.meetingSettings.subType {
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                self.setSelfSharingScreenShow(self.isMySharingScreen)
            }
        }

        let newShareScreenToFollowDocument = (isShareScreenToFollow && info.isSharingScreen && info.isFreeToBrowseEnabled) ? self.shareContentScene.shareScreenToFollowData : nil
        let isLocalProjection = self.isLocalProjection
        generateShareScene(shareSceneType: getShareContentType(from: info),
                           shareScreenData: info.isSharingScreen ? info.shareScreen : nil,
                           magicShareRawData: info.isSharingDocument ? info.followInfo : nil,
                           whiteboardData: info.isSharingWhiteboard ? info.whiteboardInfo : nil,
                           shareScreenToFollowDocument: newShareScreenToFollowDocument,
                           isLocalProjection: isLocalProjection) { [weak self] (newShareScene: InMeetShareScene) in
            guard let self = self, newShareScene != self.shareContentScene else {
                Logger.shareContent.debug("change share scene skipped due to equal share scene")
                return
            }
            let oldShareScene = self.shareContentScene
            self.shareContentScene = newShareScene
            if newShareScene.shareSceneType == .whiteboard { self.hasSharedWhiteboard = true }
            Logger.shareContent.info("did change share content to: \(newShareScene.shareSceneType), from: \(oldShareScene.shareSceneType)")
            self.listeners.forEach { $0.didChangeShareContent(to: newShareScene, from: oldShareScene) }
            self.service.postMeetingChanges({ $0.shareSceneType = newShareScene.shareSceneType })
        }
    }

    private func generateShareScene(shareSceneType: InMeetShareSceneType,
                                    shareScreenData: ScreenSharedData? = nil,
                                    magicShareRawData: FollowInfo? = nil,
                                    whiteboardData: WhiteboardInfo? = nil,
                                    shareScreenToFollowDocument: MagicShareDocument? = nil,
                                    isLocalProjection: Bool = false,
                                    completion: @escaping ((InMeetShareScene) -> Void)) {
        if let msRawData = magicShareRawData {
            httpClient.participantService.participantInfo(pid: msRawData.user,
                                                          meetingId: meetingId) { (p) in
                let magicShareDocument = MagicShareDocument.from(followInfo: msRawData, userName: p.name)
                completion(InMeetShareScene(shareSceneType: shareSceneType,
                                            shareScreenData: shareScreenData,
                                            magicShareData: magicShareDocument,
                                            whiteboardData: whiteboardData,
                                            isLocalProjection: isLocalProjection))
            }
        } else if let sstomsDocument = shareScreenToFollowDocument {
            completion(InMeetShareScene(shareSceneType: shareSceneType,
                                        shareScreenData: shareScreenData,
                                        whiteboardData: whiteboardData,
                                        shareScreenToFollowData: sstomsDocument,
                                        isLocalProjection: isLocalProjection))
        } else if let sstomsRawData = shareScreenData, let ccmInfo = sstomsRawData.ccmInfo {
            httpClient.participantService.participantInfo(pid: sstomsRawData.participant,
                                                          meetingId: meetingId) { (p) in
                let sstomsDocument = MagicShareDocument.from(ccmInfo: ccmInfo,
                                                             shareID: sstomsRawData.shareScreenID,
                                                             userID: p.id,
                                                             userName: p.name,
                                                             userType: sstomsRawData.participant.type,
                                                             deviceID: sstomsRawData.participant.deviceId)
                completion(InMeetShareScene(shareSceneType: shareSceneType,
                                            shareScreenData: shareScreenData,
                                            whiteboardData: whiteboardData,
                                            shareScreenToFollowData: sstomsDocument,
                                            isLocalProjection: isLocalProjection))
            }
        } else {
            completion(InMeetShareScene(shareSceneType: shareSceneType,
                                        shareScreenData: shareScreenData,
                                        whiteboardData: whiteboardData,
                                        isLocalProjection: isLocalProjection))
        }
    }

    private func triggerReloadData() {
        Logger.shareContent.info("trigger reload inMeetingInfo")
        guard let info = inMeetingInfo else {
            Logger.shareContent.warn("inMeetingInfo is nil, reload failed")
            return
        }
        handleInMeetingInfo(info)
    }

    private func getIsShareScreenToFollowEnabled(with info: VideoChatInMeetingInfo?) -> Bool {
        guard let newInfo = info else { return false }
        return newInfo.isShareScreenToFollowEnabled
    }

    private func getShareContentType(from newInfo: VideoChatInMeetingInfo?) -> InMeetShareSceneType {
        guard let newInfo = newInfo else { return .none }
        let isShareScreenToFollow = self.isShareScreenToFollow

        if newInfo.isSharingDocument {
            return .magicShare
        } else if newInfo.isSharingScreen && newInfo.shareScreen?.participant != account {
            return isShareScreenToFollow ? .shareScreenToFollow : .othersSharingScreen
        } else if newInfo.isSharingWhiteboard {
            return .whiteboard
        } else if isMySharingScreen {
            if !newInfo.isSharingScreen { return .none }
            return .selfSharingScreen
        } else {
            return .none
        }
    }

    /// 面试会议，打开速记，会给候选人弹popover提醒
    /// 如果处理时发现收到新info的seq比之前的小，说明是一条旧消息，直接抛弃新info，不做任何事
    private func needfilt(_ info: VideoChatInMeetingInfo) -> Bool {
        var filt = false
        if let oldValue = inMeetingInfo?.minutesStatusData, let newValue = info.minutesStatusData {
            if oldValue.seq > newValue.seq {
                Logger.meeting.warn("update info error: minutesStatusData.seq illegal, old: \(oldValue), new: \(newValue)")
                filt = true
            }
        }
        return filt
    }

}

extension InMeetShareDataManager {

    /// 更新本地在看投屏转妙享的状态
    /// - Parameter isShow: 本地在看投屏转妙享
    func setShareScreenToFollowShow(_ isShow: Bool) {
        Logger.shareScreenToFollow.info("set shareScreenToFollow to: \(isShow)")
        if isShareScreenToFollow != isShow {
            isShareScreenToFollow = isShow
            triggerReloadData()
        }
    }

    /// 更新自己正在共享屏幕的状态
    /// - Parameter isShow: 自己正在共享屏幕
    func setSelfSharingScreenShow(_ isShow: Bool) {
        Logger.selfShareScreen.info("set selfSharingScreen to: \(isShow)")
        let isLocalProjection = (inMeetingInfo?.meetingSettings.subType == .screenShare)
        if isShow != self.isMySharingScreen || isLocalProjection != self.isLocalProjection {
            self.isMySharingScreen = isShow
            self.isLocalProjection = isLocalProjection
            triggerReloadData()
        }
    }

}

extension InMeetShareDataManager {

    /// 共享唯一标识（共享屏幕、妙享、白板）
    var shareID: String? {
        if isSharingDocument {
            return inMeetingInfo?.followInfo?.shareID
        } else if isSharingScreen {
            return inMeetingInfo?.shareScreen?.shareScreenID
        } else if isSharingWhiteboard {
            if let whiteboardID = inMeetingInfo?.whiteboardInfo?.whiteboardID {
                return "\(whiteboardID)"
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    /// 有人正在共享屏幕、文档或白板
    var isSharingContent: Bool {
        return isSharingScreen || isSharingDocument || isSharingWhiteboard
    }

    /// 自己正在共享屏幕、文档或白板
    var isSelfSharingContent: Bool {
        return isSelfSharingScreen || isSelfSharingDocument || isSelfSharingWhiteboard
    }

    /// 其他人正在共享屏幕、文档或白板
    var isOthersSharingContent: Bool {
        isSharingContent && !isSelfSharingContent
    }

    /// 有人正在共享屏幕
    var isSharingScreen: Bool {
        return isSelfSharingScreen || isOthersSharingScreen
    }

    /// 自己正在共享屏幕
    var isSelfSharingScreen: Bool {
        return isMySharingScreen
    }

    /// 其他人正在共享屏幕
    var isOthersSharingScreen: Bool {
        return (inMeetingInfo?.isSharingScreen ?? false) ? inMeetingInfo?.shareScreen?.participant != account : false
    }

    /// 有人正在共享文档
    var isSharingDocument: Bool {
        return inMeetingInfo?.isSharingDocument ?? false
    }

    /// 自己正在共享文档
    var isSelfSharingDocument: Bool {
        return isSharingDocument && inMeetingInfo?.followInfo?.user == account
    }

    /// 其他人正在共享文档
    var isOthersSharingDocument: Bool {
        return isSharingDocument && inMeetingInfo?.followInfo?.user != account
    }

    /// 有人正在共享白板
    var isSharingWhiteboard: Bool {
        return inMeetingInfo?.isSharingWhiteboard ?? false
    }

    /// 自己正在共享白板
    var isSelfSharingWhiteboard: Bool {
        return isSharingWhiteboard && inMeetingInfo?.whiteboardInfo?.sharer == account
    }

    /// 其他人正在共享白板
    var isOthersSharingWhiteboard: Bool {
        return isSharingWhiteboard && inMeetingInfo?.whiteboardInfo?.sharer != account
    }

    /// 检查特定用户是否在共享屏幕、文档或白板
    /// - Parameter account: 特定用户
    /// - Returns: 特定用户是否在共享内容
    func checkIsUserSharingContent(with account: ByteviewUser?) -> Bool {
        guard let account = account else { return false }
        return inMeetingInfo?.checkIsUserSharingContent(with: account) ?? false
    }
}
