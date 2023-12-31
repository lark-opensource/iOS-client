//
//  ShareWatermarkManager.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/8/30.
//

import Foundation
import ByteViewNetwork
import RxSwift
import RxRelay

final class ShareWatermarkManager {
    let showWatermarkRelay = BehaviorRelay(value: false)

    private let meeting: InMeetMeeting
    @RwAtomic
    private var whiteboardInfo: WhiteboardInfo?
    @RwAtomic
    private var shareScreenData: ScreenSharedData?
    @RwAtomic
    private var document: MagicShareDocument?

    private var shareSceneType: InMeetShareSceneType
    private var sharerFromParticipant: ByteviewUser?

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.shareSceneType = meeting.shareData.shareContentScene.shareSceneType
        self.sharerFromParticipant = Self.sharerFromParticipant(meeting)

        let follow = resolver.resolve(InMeetFollowManager.self)
        meeting.participant.addListener(self)
        meeting.shareData.addListener(self)
        follow?.addListener(self)

        self.whiteboardInfo = meeting.shareData.shareContentScene.whiteboardData
        self.shareScreenData = meeting.shareData.shareContentScene.shareScreenData
        self.document = follow?.localDocuments.last
        self.updateWatermark()
    }

    private func updateWatermark(_ f: String = #function) {
        let selfTenantID = meeting.myself.tenantId
        var sharerTenantID: String?
        if let sharer = meeting.shareData.shareContentScene.sharer {
            // webinar 观众和普通参会人查询 sharer 的通道不一样，而且服务端无法保证参会人推送通道
            // TODO: 调整查找参会人的 API
            sharerTenantID = meeting.participant.find(user: sharer)?.tenantId ?? meeting.participant.find(user: sharer, in: .attendeePanels)?.tenantId
        }
        let show: Bool
        switch meeting.shareData.shareContentScene.shareSceneType {
        case .none:
            show = false
        case .whiteboard:
            show = whiteboardInfo?.shouldShowWatermark(selfTenantID: selfTenantID, sharerTenantID: sharerTenantID) ?? false
        case .selfSharingScreen, .othersSharingScreen:
            show = shareScreenData?.shouldShowWatermark(selfTenantID: selfTenantID, sharerTenantID: sharerTenantID) ?? false
        case .magicShare, .shareScreenToFollow:
            show = document?.showWatermark(selfTenantID: selfTenantID) ?? false
        }
        Logger.ui.info("Update share watermark from \(f): self.tenantID = \(selfTenantID), sharer.identifier = \(meeting.shareData.shareContentScene.sharer?.identifier), sharer.tenantID = \(sharerTenantID), shareScene = \(meeting.shareData.shareContentScene.shareSceneType.rawValue), show = \(show)")
        showWatermarkRelay.accept(show)
    }

    private static func sharerFromParticipant(_ meeting: InMeetMeeting) -> ByteviewUser? {
        if let sharer = meeting.shareData.shareContentScene.sharer {
            return meeting.participant.find(user: sharer)?.user
        } else {
            return nil
        }
    }
}

extension ShareWatermarkManager: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        self.whiteboardInfo = meeting.shareData.shareContentScene.whiteboardData
        self.shareScreenData = meeting.shareData.shareContentScene.shareScreenData
        updateWatermark()
    }
}

extension ShareWatermarkManager: InMeetFollowListener {
    func didUpdateLocalDocuments(_ documents: [MagicShareDocument], oldValue: [MagicShareDocument]) {
        document = documents.last
        updateWatermark()
    }
}

// 从 sharer 模块拿到的共享人跟从 participant 模块查询 tenantID 之间存在时序问题，必须通过监听参会人变更来更新水印。
// 为了防止参会人频繁变更导致的不必要方法调用，判断 shareType 和 (从 participant 模块查询到的) sharer 是否变化
extension ShareWatermarkManager: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        guard [.whiteboard, .selfSharingScreen, .othersSharingScreen].contains(shareSceneType) && Self.sharerFromParticipant(meeting) != sharerFromParticipant else { return }
        updateWatermark()
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        guard [.whiteboard, .selfSharingScreen, .othersSharingScreen].contains(shareSceneType) && Self.sharerFromParticipant(meeting) != sharerFromParticipant else { return }
        updateWatermark()
    }
}
