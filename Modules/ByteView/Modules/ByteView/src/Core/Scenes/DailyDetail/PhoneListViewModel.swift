//
//  PhoneListViewModel.swift
//  ByteView
//
//  Created by 费振环 on 2020/8/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

struct DialInInfoModel {
    var country: String
    var dialInNumbers: [String]

    init(country: String, dialInNumbers: [String]) {
        self.country = country
        self.dialInNumbers = dialInNumbers
    }
}

final class PhoneListViewModel {
    private let rawMeetingNumber: String
    let meetingNumber: String
    let dialInInfoModels: [DialInInfoModel]
    let security: MeetingSecurityControl
    init(meetingNumber: String, pstnIncomingCallPhoneList: [PSTNPhone], security: MeetingSecurityControl) {
        self.rawMeetingNumber = meetingNumber
        self.meetingNumber = VideoChatInfo.formatMeetingNumber(meetingNumber)
        self.security = security
        self.dialInInfoModels = pstnIncomingCallPhoneList
            .filter { !$0.country.isEmpty && !$0.numberDisplay.isEmpty }
            .groupBy { $0.country }
            .map { (_, v) -> DialInInfoModel in
                return DialInInfoModel(country: v.first?.countryName ?? "", dialInNumbers: v.map { $0.numberDisplay })
            }
    }

    func copyInfo(dialInNumbers: [String]) {
        let copyMessage = dialInNumbers.map { "\($0),,\(rawMeetingNumber)" }.joined(separator: "\n")
        if security.copy(copyMessage, token: .phoneListCopyNumbers) {
            Toast.show(I18n.View_M_PhoneNumberAndMeetingIdCopied)
        }
    }

    func tapCall(dialInNumber: String) {
        let phoneNumber = dialInNumber.replacingOccurrences(of: " ", with: "")
        // 拨打电话
        var callStr: String = ""
        if #available(iOS 15.4, *) {
            callStr = "\(phoneNumber),,\(rawMeetingNumber)"
        } else {
            callStr = "\(phoneNumber),,\(rawMeetingNumber)#"
        }

        guard let number = callStr.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let url = URL(string: "telprompt://\(number)") else { return }
        UIApplication.shared.open(url)
    }
}
