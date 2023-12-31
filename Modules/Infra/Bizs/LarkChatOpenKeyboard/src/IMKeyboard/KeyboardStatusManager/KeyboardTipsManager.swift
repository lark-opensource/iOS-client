//
//  KeyboardTipsManager.swift
//  LarkMessageBase
//
//  Created by ByteDance on 2022/8/16.
//

import RustPB
import LarkModel
import Foundation

public struct ScheduleSendModel {
    public var parentMessage: Message?
    public var threadId: String?
    public var messageId: String
    public var cid: String
    public var itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType

    public init(parentMessage: Message? = nil,
                messageId: String = "",
                cid: String = "",
                itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType = .scheduleMessage,
                threadId: String? = nil) {
        self.cid = cid
        self.messageId = messageId
        self.itemType = itemType
        self.parentMessage = parentMessage
        self.threadId = threadId
    }
}

public enum KeyboardTipsType: Equatable {
    case multiEditCountdown(TimeInterval) //二次编辑倒计时
    case atWhenMultiEdit //二次编辑at人时提示
    case scheduleSend(_ time: Date,
                      _ showExit: Bool,
                      _ is12HourStyle: Bool,
                      _ sendMessageModel: ScheduleSendModel) // 定时发送
    case none

    //用rawValue来排优先级，rawValue越小优先级越高
    var rawValue: Int {
        switch self {
        case .multiEditCountdown:
            return 0
        case .atWhenMultiEdit, .scheduleSend:
            return 1
        case .none:
            return 2
        }
    }

    public static func == (lhs: KeyboardTipsType, rhs: KeyboardTipsType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.atWhenMultiEdit, .atWhenMultiEdit):
            return true
        case (.scheduleSend(let time1, let showExit1, let isLhs24, let msg1), .scheduleSend(let time2, let showExit2, let isRhs24, let msg2)):
            return (time1 == time2) && (showExit1 == showExit2) && (isLhs24 == isRhs24)
        case (.multiEditCountdown(let deadline1), .multiEditCountdown(let deadline2)):
            return deadline1 == deadline2
        default:
            return false
        }
    }
}

final class KeyboardTipsManager {
    weak var delegate: KeyboardTipsManagerDelegate?
    var tips: [KeyboardTipsType] = [] {
        didSet {
            if oldValue.first != tips.first {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.onDisplayTipChanged(tip: self?.tips.first ?? .none)
                }
            }
        }
    }
    
    func containsTipType(_ tip: KeyboardTipsType) -> Bool {
        self.tips.contains { type in
            switch (type, tip) {
            case (.none, .none):
                return true
            case (.atWhenMultiEdit, .atWhenMultiEdit):
                return true
            case (.scheduleSend(let time1, let showExit1, let isLhs24, let msg1), .scheduleSend(let time2, let showExit2, let isRhs24, let msg2)):
                return true
            case (.multiEditCountdown(let deadline1), .multiEditCountdown(let deadline2)):
                return true
            default:
                return false
            }
        }
    }

    func addTip(_ value: KeyboardTipsType) {
        //根据优先级排序来插入
        for (i, tip) in tips.enumerated() {
            if tip.rawValue < value.rawValue {
                continue
            }
            if tip.rawValue > value.rawValue {
                tips.insert(value, at: i)
                return
            }
            //同一个rawValue的情况，
            if tip != value {
                tips[i] = value
            }
            return
        }
        tips.append(value)
    }

    func getDisplayTip() -> KeyboardTipsType {
        return tips.first ?? .none
    }

    init(delegate: KeyboardTipsManagerDelegate) {
        self.delegate = delegate
    }
}

protocol KeyboardTipsManagerDelegate: AnyObject {
    func onDisplayTipChanged(tip: KeyboardTipsType)
}
