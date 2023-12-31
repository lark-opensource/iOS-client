//
//  MessengerDependencies.swift
//  LarkByteView
//
//  Created by liuning.cn on 2019/10/17.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

public protocol ByteViewMessengerDependency {
    func showPreviewParticipants(body: PreviewParticipantsBody, from: UIViewController)
    func showRvcImageSentToast()
}

public struct PreviewParticipantsBody {
    public var participants: [PreviewParticipant]
    public var totalCount: Int
    public var meetingId: String
    public var chatId: String
    public var isInterview: Bool
    public var isWebinar: Bool
    public var selectCellAction: (PreviewParticipant, UIViewController) -> Void
}
