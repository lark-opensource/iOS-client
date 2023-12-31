//
//  InMeetHandler.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

struct InMeetBody: RouteBody {
    static let pattern = "//client/videoconference/inMeet"
    let meeting: InMeetMeeting
}

final class InMeetHandler: RouteHandler<InMeetBody> {

    override func handle(_ body: InMeetBody) -> UIViewController? {
        Logger.phoneCall.info("inmeetBody handle \(body.meeting.subType) \(body.meeting.type)") // 临时
        return InMeetPresentationViewController(viewModel: InMeetViewModel(meeting: body.meeting))
    }
}

struct InMeetOfPhoneCallBody: RouteBody {
    static let pattern = "//client/videoconference/inMeetOfPhoneCall"
    let session: MeetingSession
    let meeting: InMeetMeeting
}

final class InMeetOfPhoneCallHandler: RouteHandler<InMeetOfPhoneCallBody> {

    override func handle(_ body: InMeetOfPhoneCallBody) -> UIViewController? {
        let meeting = body.meeting
        guard let participant = meeting.info.participants.first(where: { $0.user.id != meeting.userId }) else { return nil }
        Logger.phoneCall.info("InMeetOfPhoneCallBody handle \(meeting.subType)  \(meeting.type)")
        let handle: PhoneCallHandle
        if let info = participant.pstnInfo {
            handle = info.bindType == .lark ? .ipPhoneBindLark(participant.participantId) : .ipPhone(info.mainAddress)
        } else {
            handle = .enterprisePhoneNumber("")
        }

        if let viewModel = EnterpriseCallViewModel(session: body.session, meeting: meeting, handle: handle) {
            return EnterpriseCallPresentationViewController(viewModel: viewModel)
        }
        return nil
    }
}
