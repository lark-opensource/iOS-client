//
//  PSTNInviteViewModel.swift
//  ByteView
//
//  Created by yangyao on 2020/4/15.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

final class PSTNInviteViewModel: InMeetMeetingProvider {
    var pstnUserStatusRelay: BehaviorRelay<PSTNStatus> = BehaviorRelay(value: .initial)
    var selectedRelay: BehaviorRelay<MobileCode?> = BehaviorRelay(value: nil)
    var selectedObservable: Observable<MobileCode?> {
        return selectedRelay.asObservable()
    }

    let logger = Logger.ui

    var nameRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    var phoneRelay: BehaviorRelay<String> = BehaviorRelay(value: "")

    deinit {
        logger.info("PSTNInviteViewModel deinit")
    }

    let meeting: InMeetMeeting
    let participant: InMeetParticipantManager
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.participant = meeting.participant
        self.reloadData()
    }

    func inviteUsers(mainAddress: String, displayName: String, participantType: ParticipantType) {
        let pstnInfo = PSTNInfo(participantType: participantType, mainAddress: mainAddress, displayName: displayName)
        participant.inviteUsers(pstnInfos: [pstnInfo])
        logger.info("Call out via PSTN")
    }

    func reloadData() {
        let pstnOutgoingCallCountryDefault = self.setting.pstnOutgoingCallCountryDefault
        let pstnOutgoingCallCountryList = self.setting.pstnOutgoingCallCountryList
        var mobileCode: MobileCode?
        // 对齐PC的逻辑，优先看pstnOutgoingCallCountryDefault，如果都为空，则不显示区号，无区号则不能拨打电话
        if let resultFromDefaultList = pstnOutgoingCallCountryDefault.first(where: { !$0.code.isEmpty }) {
            mobileCode = resultFromDefaultList
        } else if let resultFromList = pstnOutgoingCallCountryList.first(where: { !$0.code.isEmpty }) {
            mobileCode = resultFromList
        }
        Util.runInMainThread { [weak self] in
            self?.selectedRelay.accept(mobileCode)
        }
    }

    var pstnUserStatus: Observable<PSTNStatus> {
        return pstnUserStatusRelay.asObservable()
    }
}
