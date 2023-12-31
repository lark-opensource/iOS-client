//
//  FloatWindowAction.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/12/15.
//

import Foundation
import LarkShortcut

public struct FloatWindowAction: Encodable, ShortcutActionBody {
    public static var actionId: ShortcutAction.Identifier = .vc.floatWindow

    public let sessionId: String?
    public var isFloating: Bool
    public var leaveWhenUnfloatable: Bool

    /// sessionId为空时，context中需要有meetingId/sessionId
    public init(sessionId: String?, isFloating: Bool, leaveWhenUnfloatable: Bool = false) {
        self.sessionId = sessionId
        self.isFloating = isFloating
        self.leaveWhenUnfloatable = leaveWhenUnfloatable
    }
}
