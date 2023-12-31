//
//  TransitionViewModel.swift
//  ByteView
//
//  Created by wulv on 2021/3/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class TransitionViewModel {
    private let disposeBag = DisposeBag()
    private let breakoutRoomInfoRelay: BehaviorRelay<BreakoutRoomInfo?>
    private var breakoutRoomInfoObs: Observable<BreakoutRoomInfo?> {
        breakoutRoomInfoRelay.asObservable().distinctUntilChanged()
    }

    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting, firstInfo: BreakoutRoomInfo?, roomManager: BreakoutRoomManager?) {
        self.meeting = meeting
        self.breakoutRoomInfoRelay = BehaviorRelay<BreakoutRoomInfo?>(value: firstInfo)
        roomManager?.addObserver(self, fireImmediately: false)
    }

    enum MediaStatus: String {
        case normal // 进入页面时恢复音频、麦克风、摄像头的状态
        case muteAll // 离开页面时时静音、闭麦、关摄像头
    }
    var isAudioMutedBeforeTransition: Bool?
    func updateMediaStatus(_ status: MediaStatus) {
        Logger.transition.info("updateMediaStatus \(status.rawValue)")
        switch status {
        case .muteAll:
            isAudioMutedBeforeTransition = meeting.audioDevice.output.isMuted
            meeting.audioDevice.output.setMuted(true)
            meeting.microphone.stopAudioCapture()
            meeting.camera.muteRtcOnly(true)
        case .normal:
            if let isMuted = isAudioMutedBeforeTransition {
                isAudioMutedBeforeTransition = nil
                meeting.audioDevice.output.setMuted(isMuted)
            }
            if meeting.audioMode == .internet {
                meeting.microphone.startAudioCapture(scene: .breakroomTransiton)
            }
            meeting.camera.muteRtcOnly(meeting.camera.isMuted)
        }
    }
}

extension TransitionViewModel: BreakoutRoomManagerObserver {

    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        breakoutRoomInfoRelay.accept(info)
    }
}

extension TransitionViewModel {

    var titleDriver: Driver<String?> {
        breakoutRoomInfoObs
            .map { info in
                guard let topic = info?.topic else {
                    // 主会场
                    return I18n.View_G_ReturningToMainRoom
                }
                return I18n.View_G_HostInvitedYouToJoinRoom(topic)
            }
            .asDriver(onErrorJustReturn: nil)
    }

    var contentDriver: Driver<String?> {
        breakoutRoomInfoObs
            .map { info -> String? in
                guard info?.topic != nil else {
                    // 主会场
                    return nil
                }
                return I18n.View_M_JoiningEllipsis
            }
            .asDriver(onErrorJustReturn: nil)
    }

    var floatingTitleDriver: Driver<String?> {
        breakoutRoomInfoObs
            .map { info -> String? in
                // 主会场
                if let topic = info?.topic {
                    return I18n.View_G_JoiningRoom(topic)
                } else {
                    return I18n.View_G_ReturningToMainRoom
                }
            }
            .asDriver(onErrorJustReturn: nil)
    }

    func leaveMeeting() {
        meeting.leave()
    }
}
