//
//  ChatColorConfig.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/5/11.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkMessageBase
import LarkSetting
import UniverseDesignColor
import EEAtomic

private let mineColorMap: [ColorKey: UIColor] = [
    .NameAndSign: UIColor.ud.N500,
    // TODO: Use semantic color token.
    .Message_Bubble_Background: UDMessageColorTheme.imMessageBgBubblesBlue,
    .Message_Bubble_Foreground: UIColor.ud.N900,
    .Reaction_Background: UDMessageColorTheme.imMessageBgReactionBlue,
    .Reaction_Foreground: UIColor.ud.textCaption,
    .Message_BubbleSplitLine: UIColor.ud.lineDividerDefault,
    .Message_Reply_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Card_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_Custom_SplitLine: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5),
    .Message_Reply_Card_Custom_Foreground: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),

    .Message_At_Read: UIColor.ud.T400 & UIColor.ud.T500,
    .Message_At_UnRead: UIColor.ud.iconN3,
    .Message_At_Foreground_Me: UIColor.ud.primaryOnPrimaryFill,
    .Message_At_Background_Me: UIColor.ud.functionInfoContentDefault,
    .Message_At_Foreground_All: UIColor.ud.textLinkNormal,
    .Message_At_Foreground_InnerGroup: UIColor.ud.textLinkNormal,
    .Message_At_Background_InnerGroup: UIColor.ud.colorfulBlue.withAlphaComponent(0.16) & UIColor.ud.B600.withAlphaComponent(0.16),
    .Message_At_Foreground_OutterGroup: UIColor.ud.textCaption,
    .Message_At_Foreground_Chat: UIColor.ud.N900,
    .Message_At_Background_Chat: UIColor.clear,
    .Message_At_Foreground_Anonymous: UIColor.ud.N900,

    .Message_Mask_GradientTop: UDMessageColorTheme.imMessageBgBubblesBlue.withAlphaComponent(0),
    .Message_Mask_GradientBottom: UDMessageColorTheme.imMessageBgBubblesBlue,
    .Message_Text_Foreground: UIColor.ud.textTitle,
    .Message_Text_ActionDefault: UIColor.ud.textLinkNormal,
    .Message_Text_ActionPressed: UIColor.ud.N900.withAlphaComponent(0.16),
    .Message_SystemText_Foreground: UIColor.ud.textCaption,

    .Message_Assitant_Buzz_Icon: UIColor.ud.colorfulRed,
    .Message_Assitant_Buzz_Foreground: UIColor.ud.textPlaceholder,
    .Message_Assitant_Buzz_UserName: UIColor.ud.primaryPri700,
    .Message_Assitant_Buzz_Read: UIColor.ud.T400 & UIColor.ud.T500,
    .Message_Assitant_Buzz_Unread: UIColor.ud.iconN3,

    .Message_Assitant_Forward_Icon: UIColor.ud.N500,
    .Message_Assitant_Forward_Foreground: UIColor.ud.N500,
    .Message_Assitant_Forward_UserName: UIColor.ud.B700 & UIColor.ud.colorfulBlue,
    .Message_Assitant_Reply_Icon: UIColor.ud.primaryContentPressed,
    .Message_Assitant_Reply_Foreground: UIColor.ud.primaryContentPressed,

    .Message_Audio_BubbleBackground: UIColor.ud.colorfulBlue.withAlphaComponent(0.15),
    .Message_Audio_ProgressBarBackground: UDMessageColorTheme.imMessageVoiceLineScheduleBlue.withAlphaComponent(0.3),
    .Message_Audio_ProgressBarForeground: UDMessageColorTheme.imMessageVoiceLineScheduleBlue,
    .Message_Audio_ButtonBackground: UIColor.ud.primaryOnPrimaryFill,
    .Message_Audio_ConvertStateButtonBackground: UIColor.ud.N900.withAlphaComponent(0.4),
    .Message_Audio_ConvertState: UIColor.ud.textCaption,
    .Message_Audio_TimeTextForeground: UDMessageColorTheme.imMessageVoiceTextTimeBlue,
    .Message_Audio_PlayButtonBackground: UDMessageColorTheme.imMessageIconVoiceBlueBg
]

private let otherColorMap: [ColorKey: UIColor] = [
    .NameAndSign: UIColor.ud.N500,

    .Message_Bubble_Background: UDMessageColorTheme.imMessageBgBubblesGrey,
    .Message_Bubble_Foreground: UIColor.ud.textTitle,

    .Reaction_Background: UDMessageColorTheme.imMessageBgReactiongrey,
    .Reaction_Foreground: UIColor.ud.textCaption,
    .Message_BubbleSplitLine: UIColor.ud.lineDividerDefault,
    .Message_Reply_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Card_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_Custom_SplitLine: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5),
    .Message_Reply_Card_Custom_Foreground: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),

    .Message_At_Read: UIColor.ud.T400 & UIColor.ud.T500,
    .Message_At_UnRead: UIColor.ud.iconN3,
    .Message_At_Foreground_Me: UIColor.ud.primaryOnPrimaryFill,
    .Message_At_Background_Me: UIColor.ud.functionInfoContentDefault,
    .Message_At_Foreground_All: UIColor.ud.textLinkNormal,
    .Message_At_Foreground_InnerGroup: UIColor.ud.textLinkNormal,
    .Message_At_Background_InnerGroup: UIColor.ud.colorfulBlue.withAlphaComponent(0.16) & UIColor.ud.B600.withAlphaComponent(0.16),
    .Message_At_Foreground_OutterGroup: UIColor.ud.textCaption,
    .Message_At_Foreground_Chat: UIColor.ud.N900,
    .Message_At_Background_Chat: UIColor.clear,
    .Message_At_Foreground_Anonymous: UIColor.ud.N900,

    .Message_Mask_GradientTop: UDMessageColorTheme.imMessageBgBubblesGrey.withAlphaComponent(0),
    .Message_Mask_GradientBottom: UDMessageColorTheme.imMessageBgBubblesGrey,
    .Message_Text_Foreground: UIColor.ud.textTitle,
    .Message_Text_ActionDefault: UIColor.ud.textLinkNormal,
    .Message_Text_ActionPressed: UIColor.ud.N900.withAlphaComponent(0.16),
    .Message_SystemText_Foreground: UIColor.ud.textCaption,

    .Message_Assitant_Buzz_Icon: UIColor.ud.colorfulRed,
    .Message_Assitant_Buzz_Foreground: UIColor.ud.textPlaceholder,
    .Message_Assitant_Buzz_UserName: UIColor.ud.primaryPri700,
    .Message_Assitant_Buzz_Read: UIColor.ud.T400 & UIColor.ud.T500,
    .Message_Assitant_Buzz_Unread: UIColor.ud.iconN3,

    .Message_Assitant_Forward_Icon: UIColor.ud.N500,
    .Message_Assitant_Forward_Foreground: UIColor.ud.N500,
    .Message_Assitant_Forward_UserName: UIColor.ud.B700 & UIColor.ud.colorfulBlue,
    .Message_Assitant_Reply_Icon: UIColor.ud.primaryContentPressed,
    .Message_Assitant_Reply_Foreground: UIColor.ud.primaryContentPressed,

    .Message_Audio_BubbleBackground: UIColor.ud.N900.withAlphaComponent(0.05),
    .Message_Audio_ProgressBarBackground: UDMessageColorTheme.imMessageVoiceLineScheduleGrey.withAlphaComponent(0.3),
    .Message_Audio_ProgressBarForeground: UDMessageColorTheme.imMessageVoiceLineScheduleGrey,
    .Message_Audio_ButtonBackground: UIColor.ud.primaryOnPrimaryFill,
    .Message_Audio_ConvertStateButtonBackground: UIColor.ud.N900.withAlphaComponent(0.4),
    .Message_Audio_ConvertState: UIColor.ud.textCaption,
    .Message_Audio_TimeTextForeground: UDMessageColorTheme.imMessageVoiceTextTimeGrey,
    .Message_Audio_PlayButtonBackground: UDMessageColorTheme.imMessageIconVoiceGreyBg
]

/// Chat、MergeForwardDetail、MessageDetail、Pin
public struct ChatColorConfig: ColorConfigService {
    public init() {}

    public func getColor(for key: ColorKey, type: Type) -> UIColor {
        if type == .mine { return mineColorMap[key] ?? .clear }
        return otherColorMap[key] ?? .clear
    }
}

public final class StaticColorizeIcon {
    private let mineOnceToken = AtomicOnce()
    private let otherOnceToken = AtomicOnce()

    private var mineIcon: UIImage?
    private var otherIcon: UIImage?
    private let icon: UIImage

    public init(icon: UIImage) {
        self.icon = icon
    }

    public func get(textColor: UIColor, type: Type) -> UIImage {
        switch type {
        case .mine:
            mineOnceToken.once {
                mineIcon = icon.lu.colorize(color: textColor, resizingMode: .stretch)
            }
            guard let icon = mineIcon else {
                fatalError("mineOnceToken.once does not run.")
            }
            return icon
        case .other:
            otherOnceToken.once {
                otherIcon = icon.lu.colorize(color: textColor, resizingMode: .stretch)
            }
            guard let icon = otherIcon else {
                fatalError("mineOnceToken.once does not run.")
            }
            return icon
        @unknown default:
            fatalError("new value")
        }
    }
}
