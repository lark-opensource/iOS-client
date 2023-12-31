//
//  ConnectFailedViewModel.swift
//  ByteView
//
//  Created by huangshun on 2019/3/31.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewMeeting

final class ConnectFailedViewModel {
    let session: MeetingSession

    init(session: MeetingSession) {
        self.session = session
    }
}
