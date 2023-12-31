//
//  KeyboardTipsView.swift
//  LarkMessageCore
//
//  Created by bytedance on 7/25/22.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkChatOpenKeyboard

public enum KeyboardTipScene {
    case normal
    case compose
}

public extension KeyboardTipsType {
    public func createView(delegate: KeyboardSchuduleSendButtonDelegate? = nil,
                           scene: KeyboardTipScene) -> KeyboardTipsView? {
        switch self {
        case .none:
            return nil
        case .atWhenMultiEdit:
            return AtWhenMultiEditTipsView(scene: scene)
        case .multiEditCountdown(let deadline):
            return MultiEditCountdownTipsView(deadline: deadline, scene: scene)
        case .scheduleSend(let time, let showExit, let is12HourStyle, let sendMessageModel):
            let model = SendMessageModel(parentMessage: sendMessageModel.parentMessage,
                                         messageId: sendMessageModel.messageId,
                                         cid: sendMessageModel.cid,
                                         itemType: sendMessageModel.itemType,
                                         threadId: sendMessageModel.threadId)
            let timeDesc = ScheduleSendManager.formatScheduleTimeWithDate(time, is12HourStyle: is12HourStyle, isShowYear: Date().year != time.year)
            return ScheduleSendTipsView(time: time,
                                        timeDesc: timeDesc,
                                        is12HourStyle: is12HourStyle,
                                        sendMessageModel: model,
                                        showExit: showExit,
                                        delegate: delegate)
        }
    }
}

public protocol KeyboardTipsView: UIView {
    func suggestHeight(maxWidth: CGFloat) -> CGFloat
}

extension KeyboardTipsView {
    var displayable: Bool {
        return true
    }
}
