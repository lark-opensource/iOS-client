//
//  InMeetSpeechViewModel.swift
//  ByteView
//
//  Created by ZhangJi on 2022/8/24.
//

import Foundation
import ByteViewNetwork
import RxRelay
import RxSwift

final class InMeetSpeechViewModel: InMeetDataListener, InMeetViewChangeListener, MyselfListener, InMeetShareDataListener, InMeetParticipantListener {
    static let logger = Logger.ui
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    let context: InMeetViewContext
    let gridVM: InMeetGridViewModel?
    private var isCallConnected = false
    let shareWatermark: ShareWatermarkManager

    let floatingScreenShareDataRelay: BehaviorRelay<ScreenSharedData?>
    let floatingMagicDocumentRelay: BehaviorRelay<MagicShareDocument?>
    let floatingWhiteBoardInfoRelay: BehaviorRelay<WhiteboardInfo?>
    let forceHiddenFloatingViewRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let selfIsHost: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.resolver = resolver
        self.gridVM = resolver.resolve(InMeetGridViewModel.self)
        self.shareWatermark = resolver.resolve()!

        self.floatingScreenShareDataRelay = BehaviorRelay<ScreenSharedData?>(value: meeting.shareData.shareContentScene.shareScreenData)
        if meeting.shareData.shareContentScene.shareSceneType == .magicShare {
            self.floatingMagicDocumentRelay = BehaviorRelay<(MagicShareDocument?)>(value: meeting.shareData.shareContentScene.magicShareDocument)
        } else if meeting.shareData.shareContentScene.shareSceneType == .shareScreenToFollow {
            self.floatingMagicDocumentRelay = BehaviorRelay<(MagicShareDocument?)>(value: meeting.shareData.shareContentScene.shareScreenToFollowData)
        } else {
            self.floatingMagicDocumentRelay = BehaviorRelay<(MagicShareDocument?)>(value: nil)
        }
        self.floatingWhiteBoardInfoRelay = BehaviorRelay<WhiteboardInfo?>(value: meeting.shareData.shareContentScene.whiteboardData)

        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        context.addListener(self, for: [.hideSelf, .hideNonVideoParticipants])
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        updateForcedHiddenFloatingView()
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updateForcedHiddenFloatingView()
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        selfIsHost.accept(myself.isHost)
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .hideSelf || change == .hideNonVideoParticipants {
            updateForcedHiddenFloatingView()
        }
    }

    private func updateForcedHiddenFloatingView() {
        // 演讲者视图+非共享+隐藏自己，需要收起小窗且不允许手动展开
        // 隐藏非视频参会人+非共享+演讲者视图+本地未开启摄像头，收起小窗且不允许手动展开
        let hideEnable = !meeting.shareData.isSharingContent || meeting.participant.currentRoom.nonRingingCount == 1
        let shouldForceFloating = (context.isHideNonVideoParticipants && meeting.myself.settings.isCameraMuted) || context.isHideSelf
        forceHiddenFloatingViewRelay.accept(shouldForceFloating && hideEnable)
    }

    lazy var shareScreenVM: InMeetShareScreenVM? = {
        return meeting.shareData.isOthersSharingScreen ? resolver.resolve(InMeetShareScreenVM.self) : nil
    }()

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        floatingWhiteBoardInfoRelay.accept(newScene.whiteboardData)
        if newScene.shareSceneType == .magicShare {
            floatingMagicDocumentRelay.accept(newScene.magicShareData)
        } else if newScene.shareSceneType == .shareScreenToFollow {
            floatingMagicDocumentRelay.accept(newScene.shareScreenToFollowData)
        } else {
            floatingMagicDocumentRelay.accept(nil)
        }
        floatingScreenShareDataRelay.accept(newScene.shareScreenData)
        updateForcedHiddenFloatingView()
    }

}
