//
//  CurrentStartState.swift
//  ByteView
//
//  Created by kiri on 2021/2/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting

final class StartState: MeetingComponent {
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {}
    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {}
}
