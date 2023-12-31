//
//  InMeetWebSpaceViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2022/12/1.
//

import Foundation
import ByteViewNetwork

class InMeetWebSpaceViewModel {

    let manager: InMeetWebSpaceManager
    let meeting: InMeetMeeting
    let context: InMeetViewContext

    init(manager: InMeetWebSpaceManager, resolver: InMeetViewModelResolver) {
        self.manager = manager
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        manager.loadIfNeeded()
    }

    func reload() {
        manager.currentRuntime?.reload()
    }
}
