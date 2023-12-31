//
//  InMeetMediaServiceManager.swift
//  ByteView
//
//  Created by fakegourmet on 2023/5/12.
//

import Foundation
import ByteViewMeeting
import LarkMedia
import RxSwift
import ByteViewCommon

// https://bytedance.feishu.cn/wiki/Utshw31SgiwqdZkUuyVcNrEJnVg#Awm2dCaqooUm6IxMZSscHWqFnbd
final class InMeetMediaServiceManager: NSObject {

    @RwAtomic
    private(set) var isMediaServiceLost: Bool = false

    private let session: MeetingSession
    init(session: MeetingSession) {
        self.session = session
        super.init()
        if let config = session.setting?.mediaServiceToastConfig,
           Util.isOsVersionBetween(min: config.min.systemVersion, max: config.max.systemVersion) {
            bindMediaServiceLost()
        }
    }

    private func bindMediaServiceLost() {
        LarkAudioSession.rx.mediaServicesLostObservable
            .subscribe(onNext: { [weak self] in
                self?.isMediaServiceLost = true
            }).disposed(by: rx.disposeBag)
    }
}
