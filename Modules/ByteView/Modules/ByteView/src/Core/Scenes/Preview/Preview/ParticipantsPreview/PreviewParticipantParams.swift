//
//  PreviewParticipantParams.swift
//  ByteView
//
//  Created by kiri on 2023/6/29.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

public struct PreviewParticipantParams {
    public var participants: [PreviewParticipant]
    public var isPopover: Bool
    public var totalCount: Int
    public var meetingId: String?
    public var chatId: String?
    public var isInterview: Bool
    public var isWebinar: Bool
    public var selectCellAction: ((PreviewParticipant, UIViewController) -> Void)?

    public init(participants: [PreviewParticipant], isPopover: Bool, totalCount: Int = 0,
                meetingId: String? = nil, chatId: String? = nil, isInterview: Bool, isWebinar: Bool,
                selectCellAction: ((PreviewParticipant, UIViewController) -> Void)? = nil) {
        self.participants = participants
        self.isPopover = isPopover
        self.totalCount = totalCount
        self.meetingId = meetingId
        self.chatId = chatId
        self.isInterview = isInterview
        self.isWebinar = isWebinar
        self.selectCellAction = selectCellAction
    }
}
