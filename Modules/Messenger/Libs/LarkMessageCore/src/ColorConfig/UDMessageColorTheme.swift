//
//  UDMessageColorTheme.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/5/25.
//

import UIKit
import Foundation
import UniverseDesignColor

public extension UDColor.Name {
    static let imMessageTextBubblesBlue = UDColor.Name("imtoken-message-text-bubbles-blue")
    static let imMessageTextPin = UDColor.Name("imtoken-message-text-pin")
    static let imMessageVoiceTextTimeBlue = UDColor.Name("imtoken-message-voice-text-time-blue")
    static let imMessageVoiceTextTimeGrey = UDColor.Name("imtoken-message-voice-text-time-gray")

    static let imMessageVoiceLineScheduleBlue = UDColor.Name("imtoken-message-voice-line-schedule-blue")
    static let imMessageVoiceLineScheduleGrey = UDColor.Name("imtoken-message-voice-line-schedule-grey")

    static let imMessageBgReactionBlue = UDColor.Name("imtoken-message-bg-reaction-blue")
    static let imMessageBgReactiongrey = UDColor.Name("imtoken-message-bg-reaction-grey")
    static let imMessageBgPin = UDColor.Name("imtoken-message-bg-pin")
    static let imMessageBgLocation = UDColor.Name("imtoken-message-bg-location")
    static let imMessageBgBubblesBlue = UDColor.Name("imtoken-message-bg-bubbles-blue")
    static let imMessageBgBubblesGrey = UDColor.Name("imtoken-message-bg-bubbles-grey")

    static let imMessageIconRead = UDColor.Name("imtoken-message-icon-read")
    static let imMessageIconUnread = UDColor.Name("imtoken-message-icon-unread")
    static let imMessageIconPin = UDColor.Name("imtoken-message-icon-pin")
    static let imMessageIconVoiceBlueBg = UDColor.Name("imtoken-message-icon-voice-blue-bg")
    static let imMessageIconVoiceGreyBg = UDColor.Name("imtoken-message-icon-voice-grey-bg")

    static let imMessageSecrectKeyBoardItemTint = UDColor.Name("imtoken-message-secrect-keyBoardItem-tint")

    static let imMessageCardBorder = UDColor.Name("imtoken-message-card-border")
    static let imMessageCardBGBody = UDColor.Name("imtoken-message-card-bg-body")
    static let imMessageCardBGBodyEmbed = UDColor.Name("imtoken-message-card-bg-body-embed")

    static let imMessageIconPinList = UDColor.Name("imtoken-message-icon-pin-list")
}

/// UDMenu Color Theme
public struct UDMessageColorTheme {
    public static var imMessageTextBubblesBlue: UIColor {
        return UDColor.getValueByKey(.imMessageTextBubblesBlue) ?? UDColor.B600
    }
    public static var imMessageTextPin: UIColor {
        return UDColor.getValueByKey(.imMessageTextPin) ?? UDColor.T400 & UDColor.T500
    }
    public static var imMessageVoiceTextTimeBlue: UIColor {
        return UDColor.getValueByKey(.imMessageVoiceTextTimeBlue) ?? UDColor.B700
    }
    public static var imMessageVoiceTextTimeGrey: UIColor {
        return UDColor.getValueByKey(.imMessageVoiceTextTimeGrey) ?? UDColor.N900 & UDColor.N700
    }

    public static var imMessageVoiceLineScheduleBlue: UIColor {
        return UDColor.getValueByKey(.imMessageVoiceLineScheduleBlue) ?? UDColor.B700 & UDColor.B700
    }
    public static var imMessageVoiceLineScheduleGrey: UIColor {
        return UDColor.getValueByKey(.imMessageVoiceLineScheduleGrey) ?? UDColor.N700
    }

    public static var imMessageBgReactionBlue: UIColor {
        return UDColor.getValueByKey(.imMessageBgReactionBlue) ?? UDColor.B600.withAlphaComponent(0.15) & UDColor.rgb(0x102954)
    }
    public static var imMessageBgReactiongrey: UIColor {
        return UDColor.getValueByKey(.imMessageBgReactiongrey) ?? UDColor.N900.withAlphaComponent(0.05) & UDColor.rgb(0x1F1F1F)
    }
    public static var imMessageBgPin: UIColor {
        return UDColor.getValueByKey(.imMessageBgPin) ?? UDColor.rgb(0xFCF5DF) & UDColor.Y100
    }
    public static var imMessageBgEditing: UIColor {
        //正在被二次编辑时的背景色，目前对其pin
        return imMessageBgPin
    }
    public static var imMessageBgLocation: UIColor {
        return UDColor.getValueByKey(.imMessageBgLocation) ?? UDColor.rgb(0xFAEEC4) & UDColor.Y200
    }
    public static var imMessageBgBubblesBlue: UIColor {
        return UDColor.getValueByKey(.imMessageBgBubblesBlue) ?? UDColor.rgb(0xD1E3FF) & UDColor.rgb(0x133063)
    }
    public static var imMessageBgBubblesGrey: UIColor {
        return UDColor.getValueByKey(.imMessageBgBubblesGrey) ?? UDColor.rgb(0xF3F4F5) & UDColor.rgb(0x262626)
    }

    public static var imMessageIconRead: UIColor {
        return UDColor.getValueByKey(.imMessageIconRead) ?? UDColor.T400 & UDColor.T500
    }
    public static var imMessageIconUnread: UIColor {
        return UDColor.getValueByKey(.imMessageIconUnread) ?? UDColor.N500
    }
    public static var imMessageIconPin: UIColor {
        return UDColor.getValueByKey(.imMessageIconPin) ?? UDColor.T400 & UDColor.T500
    }
    public static var imMessageIconVoiceBlueBg: UIColor {
        return UDColor.getValueByKey(.imMessageIconVoiceBlueBg) ?? UDColor.B700 & UDColor.B500
    }
    public static var imMessageIconVoiceGreyBg: UIColor {
        return UDColor.getValueByKey(.imMessageIconVoiceGreyBg) ?? UIColor.ud.N700 & UIColor.ud.N500
    }
    public static var imMessageSecrectKeyBoardItemTint: UIColor {
        /// 和UI确认 需要修改密聊icon的颜色
        return UIColor.ud.iconN1
    }

    public static var imMessageCardBorder: UIColor {
        return UDColor.getValueByKey(.imMessageCardBorder) ?? UDColor.N300 & UDColor.N900.withAlphaComponent(0)
    }

    public static var imMessageCardBGBody: UIColor {
        return UDColor.getValueByKey(.imMessageCardBGBody) ?? UDColor.N00 & UDColor.N200
    }

    public static var imMessageCardBGBodyEmbed: UIColor {
        return UDColor.getValueByKey(.imMessageCardBGBodyEmbed) ?? UDColor.N00 & UDColor.N200
    }

    public static var imMessageIconPinList: UIColor {
        return UDColor.getValueByKey(.imMessageIconPinList) ?? UIColor.ud.T400 & UIColor.ud.T600
    }
}

struct UDMessageBizColor: UDBizColor {
    public func getValueByToken(_ token: String) -> UIColor? {
        let tokenName = UDColor.Name(token)
        switch tokenName {
        case .imMessageTextBubblesBlue: return UDMessageColorTheme.imMessageTextBubblesBlue
        case .imMessageTextPin: return UDMessageColorTheme.imMessageTextPin
        case .imMessageVoiceTextTimeBlue: return UDMessageColorTheme.imMessageVoiceTextTimeBlue
        case .imMessageVoiceTextTimeGrey: return UDMessageColorTheme.imMessageVoiceTextTimeGrey
        case .imMessageVoiceLineScheduleBlue: return UDMessageColorTheme.imMessageVoiceLineScheduleBlue
        case .imMessageVoiceLineScheduleGrey: return UDMessageColorTheme.imMessageVoiceLineScheduleGrey
        case .imMessageBgReactionBlue: return UDMessageColorTheme.imMessageBgReactionBlue
        case .imMessageBgReactiongrey: return UDMessageColorTheme.imMessageBgReactiongrey
        case .imMessageBgPin: return UDMessageColorTheme.imMessageBgPin
        case .imMessageBgLocation: return UDMessageColorTheme.imMessageBgLocation
        case .imMessageBgBubblesBlue: return UDMessageColorTheme.imMessageBgBubblesBlue
        case .imMessageBgBubblesGrey: return UDMessageColorTheme.imMessageBgBubblesGrey
        case .imMessageIconRead: return UDMessageColorTheme.imMessageIconRead
        case .imMessageIconUnread: return UDMessageColorTheme.imMessageIconUnread
        case .imMessageIconVoiceBlueBg: return UDMessageColorTheme.imMessageIconVoiceBlueBg
        case .imMessageIconVoiceGreyBg: return UDMessageColorTheme.imMessageIconVoiceGreyBg
        case .imMessageSecrectKeyBoardItemTint: return UDMessageColorTheme.imMessageSecrectKeyBoardItemTint
        case .imMessageCardBorder: return UDMessageColorTheme.imMessageCardBorder
        case .imMessageCardBGBody: return UDMessageColorTheme.imMessageCardBGBody
        case .imMessageCardBGBodyEmbed: return UDMessageColorTheme.imMessageCardBGBodyEmbed
        case .imMessageIconPinList: return UDMessageColorTheme.imMessageIconPinList
        default: return nil
        }
    }
}
