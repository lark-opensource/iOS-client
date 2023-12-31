//
//  MeetDialViewModel.swift
//  ByteView
//
//  Created by wangpeiran on 2021/7/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Action
import RxCocoa
import ByteViewNetwork

protocol DialVMProtocol {
    var title: String { get }

    var defaultValue: String { get }

    var dataSource: [(String, CGFloat, UIEdgeInsets?)] { get set }

    func selectedAction(chat: String, totalTitle: String)
}

class ParticipantDialData {
    var saveData: [String: String] = [:]
}

class MeetDialViewModel: DialVMProtocol {

    func selectedAction(chat: String, totalTitle: String) {
        participantDialData?.saveData.updateValue(totalTitle, forKey: participant.identifier)
        requestDTMF(num: chat, seqId: totalTitle.count)
    }

    var defaultValue: String {
        participantDialData?.saveData[participant.identifier] ?? ""
    }

    let title: String
    let meetingId: String
    var participant: Participant
    var participantDialData: ParticipantDialData?
    let leaveRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    // disable-lint: magic number
    var dataSource: [(String, CGFloat, UIEdgeInsets?)] = {
        return [("1", 30, nil), ("2", 30, nil), ("3", 30, nil),
                ("4", 30, nil), ("5", 30, nil), ("6", 30, nil),
                ("7", 30, nil), ("8", 30, nil), ("9", 30, nil),
                ("*", 40, UIEdgeInsets(top: 14, left: 0, bottom: 0, right: 0)), ("0", 30, nil), ("#", 30, nil)]
    }()
    // enable-lint: magic number
    let disposeBag = DisposeBag()
    let httpClient: HttpClient

    init(title: String, participant: Participant, meeting: InMeetMeeting) {
        self.title = title
        self.meetingId = meeting.meetingId
        self.httpClient = meeting.httpClient
        self.participant = participant
        self.participantDialData = meeting.participantDialData

        meeting.participant.addListener(self)
    }

    func requestDTMF(num: String, seqId: Int) {
        guard !num.isEmpty else {
            return
        }
        let userId = participant.user.id
        Logger.participant.info("ApplyDTMF \(num)--\(userId)--\(meetingId)---\(seqId)")
        let request = ApplyDTMFRequest(dtmfCmd: num, seqId: Int64(seqId), userId: userId, meetingId: meetingId)
        httpClient.send(request) { result in
            Logger.participant.info("ApplyDTMF Request finished: isSuccess = \(result.isSuccess)")
        }
    }
}

extension MeetDialViewModel: InMeetParticipantListener {

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        if output.modify.nonRinging.removes[participant.user] != nil {
            leaveRelay.accept(true)
        }
    }
}
