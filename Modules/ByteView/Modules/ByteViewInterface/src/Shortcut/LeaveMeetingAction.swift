//
//  LeaveMeetingAction.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/12/15.
//

import Foundation
import LarkShortcut

public struct LeaveMeetingAction: Encodable, ShortcutActionBody {
    public static var actionId: ShortcutAction.Identifier = .vc.leaveMeeting

    public let sessionId: String?
    public var reason: LeaveReason
    public var shouldWaitServerResponse: Bool

    /// sessionId为空时，context中需要有sessionId
    public init(sessionId: String?, reason: LeaveReason, shouldWaitServerResponse: Bool = false) {
        self.sessionId = sessionId
        self.reason = reason
        self.shouldWaitServerResponse = shouldWaitServerResponse
    }

    public enum LeaveReason: String, Encodable, CustomStringConvertible {
        case accountInterruption
        case securityInterruption

        public var description: String { rawValue }
    }
}
