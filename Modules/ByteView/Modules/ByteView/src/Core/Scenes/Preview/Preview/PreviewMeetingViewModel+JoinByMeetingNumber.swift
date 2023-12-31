//
//  PreviewMeetingViewModel+JoinByMeetingNumber.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/8/19.
//

import Foundation

extension PreviewMeetingViewModel {
    static func isMeetingNumberValid(_ meetingNumber: String) -> Bool {
        return meetingNumber.allSatisfy { $0.isASCII && $0.isNumber }
        && meetingNumber.count == 9
    }
}
