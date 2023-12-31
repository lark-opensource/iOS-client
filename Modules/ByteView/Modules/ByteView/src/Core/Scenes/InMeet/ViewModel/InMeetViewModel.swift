//
//  InMeetViewModel.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/1/6.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting

final class InMeetViewModel: InMeetMeetingProvider {
    let meeting: InMeetMeeting
    let viewContext: InMeetViewContext
    var resolver: InMeetViewModelResolver { container.resolver }
    private let container: InMeetViewModelContainer
    private lazy var logDescription = metadataDescription(of: self)
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.viewContext = InMeetViewContext(meetingId: meeting.meetingId)
        self.container = InMeetViewModelContainer(meeting: self.meeting, context: viewContext)
        container.resolveNonLazyObjects()
        Logger.ui.debug("init \(logDescription)")
    }

    deinit {
        Logger.ui.debug("deinit \(logDescription)")
    }

    func updateScope(_ scope: InMeetViewScope) {
        viewContext.updateScope(scope)
    }
}
