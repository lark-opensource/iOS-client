//
//  CallKitAnsweringVM.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/10/30.
//

import Foundation
import RxSwift
import Action
import RxCocoa
import ByteViewCommon
import ByteViewMeeting
import ByteViewSetting

class CallKitAnsweringVM {
    let avatarInfo: Driver<AvatarInfo>
    let inviterName: Driver<String>

    let meetSetting: MicCameraSetting
    var cameraEnabled: Bool {
        return meetSetting.isCameraEnabled
    }

    let isMeet: Bool
    let session: MeetingSession

    init?(session: MeetingSession, meetSetting: MicCameraSetting) {
        guard let info = session.videoChatInfo else { return nil }
        self.session = session
        let avatarSubject = ReplaySubject<AvatarInfo>.create(bufferSize: 1)
        let nameSubject = ReplaySubject<String>.create(bufferSize: 1)
        let avatarInfoDriver: Driver<AvatarInfo> = avatarSubject.asDriver(onErrorRecover: { _ in .empty() })
        let nameDriver: Driver<String> = nameSubject.asDriver(onErrorRecover: { _ in .just("") })

        let participantService = session.httpClient.participantService
        if info.type == .call {
            self.isMeet = false
            participantService.participantInfo(pid: info.host, meetingId: info.id) { ap in
                avatarSubject.onNext(ap.avatarInfo)
                nameSubject.onNext(ap.name)
            }
        } else {
            self.isMeet = true
            participantService.participantInfo(pid: info.inviterPid, meetingId: info.id) { ap in
                avatarSubject.onNext(ap.avatarInfo)
                nameSubject.onNext(ap.name)
            }
        }

        self.avatarInfo = avatarInfoDriver
        self.inviterName = nameDriver
        self.meetSetting = meetSetting
    }

    @objc func decline() {
        session.declineRinging()
    }
}
