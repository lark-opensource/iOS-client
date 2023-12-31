//
//  FloatingSubtitleViewModel.swift
//  ByteView
//
//  Created by panzaofeng on 2022/4/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

final class FloatingSubtitleViewModel {
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    let subtitle: InMeetSubtitleViewModel

    init(meeting: InMeetMeeting, context: InMeetViewContext, subtitle: InMeetSubtitleViewModel) {
        self.meeting = meeting
        self.context = context
        self.subtitle = subtitle
    }

    func isFlowPageControlVisible() -> Bool {
        return self.context.isFlowPageControlVisible
    }
}
