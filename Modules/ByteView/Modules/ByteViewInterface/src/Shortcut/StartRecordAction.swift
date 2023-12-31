//
//  StartRecordAction.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/12/8.
//

import Foundation
import LarkShortcut

public struct StartRecordAction: Encodable, ShortcutActionBody {
    public static let actionId: ShortcutAction.Identifier = .vc.startRecord

    public var sessionId: String?
    public var meetingId: String?
    public var isFromNotes: Bool

    /// meetingId为空时，context中需要有meetingId/sessionId
    public init(meetingId: String?, isFromNotes: Bool = false) {
        self.meetingId = meetingId
        self.isFromNotes = isFromNotes
    }

    public init(sessionId: String?, isFromNotes: Bool = false) {
        self.sessionId = sessionId
        self.isFromNotes = isFromNotes
    }
}
