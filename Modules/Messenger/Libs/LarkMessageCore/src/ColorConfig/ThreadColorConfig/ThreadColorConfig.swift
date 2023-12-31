//
//  ThreadColorConfig.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/5/13.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkMessageBase
import LarkSetting
import UniverseDesignColor

private let mineColorMap: [ColorKey: UIColor] = [
    .NameAndSign: UIColor.ud.N500,
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
    .Message_At_UnRead: UIColor.ud.N600,
    .Message_At_Foreground_Me: UIColor.ud.primaryOnPrimaryFill,
    .Message_At_Background_Me: UIColor.ud.functionInfoContentDefault,
    .Message_At_Foreground_All: UIColor.ud.textLinkNormal,
    .Message_At_Foreground_InnerGroup: UIColor.ud.textLinkNormal,
    .Message_At_Background_InnerGroup: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
    .Message_At_Foreground_OutterGroup: UIColor.ud.textCaption,
    .Message_At_Foreground_Chat: UIColor.ud.N900,
    .Message_At_Background_Chat: UIColor.clear,
    .Message_At_Foreground_Anonymous: UIColor.ud.N900,

    .Message_Mask_GradientTop: UIColor.ud.bgBody.withAlphaComponent(0),
    .Message_Mask_GradientBottom: UIColor.ud.bgBody,
    .Message_Text_Foreground: UIColor.ud.textTitle,
    .Message_Text_ActionDefault: UIColor.ud.textLinkNormal,
    .Message_Text_ActionPressed: UIColor.ud.N900.withAlphaComponent(0.16),
    .Message_SystemText_Foreground: UIColor.ud.textCaption,

    .Message_Assitant_Buzz_Icon: UIColor.ud.colorfulRed,
    .Message_Assitant_Buzz_Foreground: UIColor.ud.textPlaceholder,
    .Message_Assitant_Buzz_UserName: UIColor.ud.primaryPri700,
    .Message_Assitant_Buzz_Read: UIColor.ud.T600 & UIColor.ud.T400,
    .Message_Assitant_Buzz_Unread: UIColor.ud.iconN3,

    .Message_Assitant_Forward_Icon: UIColor.ud.N500,
    .Message_Assitant_Forward_Foreground: UIColor.ud.N500,
    .Message_Assitant_Forward_UserName: UIColor.ud.B700 & UIColor.ud.colorfulBlue,
    .Message_Assitant_Reply_Icon: UIColor.ud.primaryContentPressed,
    .Message_Assitant_Reply_Foreground: UIColor.ud.primaryContentPressed,

    .Message_Audio_BubbleBackground: UIColor.ud.colorfulBlue.withAlphaComponent(0.2),
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
    .Message_Bubble_Foreground: UIColor.ud.N900,

    .Reaction_Background: UIColor.ud.udtokenReactionBgGrey,
    .Reaction_Foreground: UIColor.ud.textCaption,
    .Message_BubbleSplitLine: UIColor.ud.lineDividerDefault,
    .Message_Reply_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_SplitLine: UIColor.ud.udtokenQuoteBarBg,
    .Message_Reply_Card_Foreground: UIColor.ud.N600,
    .Message_Reply_Card_Custom_SplitLine: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5),
    .Message_Reply_Card_Custom_Foreground: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),

    .Message_Assitant_Buzz_Icon: UIColor.ud.colorfulRed,
    .Message_Assitant_Buzz_Foreground: UIColor.ud.textPlaceholder,
    .Message_Assitant_Buzz_UserName: UIColor.ud.primaryPri700,
    .Message_Assitant_Buzz_Read: UIColor.ud.T600 & UIColor.ud.T400,
    .Message_Assitant_Buzz_Unread: UIColor.ud.iconN3,

    .Message_At_Read: UIColor.ud.T600 & UIColor.ud.T400,
    .Message_At_UnRead: UIColor.ud.N600,
    .Message_At_Foreground_Me: UIColor.ud.primaryOnPrimaryFill,
    .Message_At_Background_Me: UIColor.ud.functionInfoContentDefault,
    .Message_At_Foreground_All: UIColor.ud.textLinkNormal,
    .Message_At_Foreground_InnerGroup: UIColor.ud.textLinkNormal,
    .Message_At_Background_InnerGroup: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
    .Message_At_Foreground_OutterGroup: UIColor.ud.textCaption,
    .Message_At_Foreground_Chat: UIColor.ud.N900,
    .Message_At_Background_Chat: UIColor.clear,
    .Message_At_Foreground_Anonymous: UIColor.ud.N900,

    .Message_Mask_GradientTop: UIColor.ud.bgBody.withAlphaComponent(0),
    .Message_Mask_GradientBottom: UIColor.ud.bgBody,
    .Message_Text_Foreground: UIColor.ud.textTitle,
    .Message_Text_ActionDefault: UIColor.ud.textLinkNormal,
    .Message_Text_ActionPressed: UIColor.ud.N900.withAlphaComponent(0.16),
    .Message_SystemText_Foreground: UIColor.ud.textCaption,
    .Message_Assitant_Forward_Icon: UIColor.ud.N500,
    .Message_Assitant_Forward_Foreground: UIColor.ud.N500,
    .Message_Assitant_Forward_UserName: UIColor.ud.B700 & UIColor.ud.colorfulBlue,
    .Message_Assitant_Reply_Icon: UIColor.ud.primaryContentPressed,
    .Message_Assitant_Reply_Foreground: UIColor.ud.primaryContentPressed,
    .Message_Audio_BubbleBackground: UIColor.ud.N300,
    .Message_Audio_ProgressBarBackground: UDMessageColorTheme.imMessageVoiceLineScheduleGrey.withAlphaComponent(0.3),
    .Message_Audio_ProgressBarForeground: UDMessageColorTheme.imMessageVoiceLineScheduleGrey,
    .Message_Audio_ButtonBackground: UIColor.ud.primaryOnPrimaryFill,
    .Message_Audio_ConvertStateButtonBackground: UIColor.ud.N900.withAlphaComponent(0.4),
    .Message_Audio_ConvertState: UIColor.ud.textCaption,
    .Message_Audio_TimeTextForeground: UDMessageColorTheme.imMessageVoiceTextTimeGrey,
    .Message_Audio_PlayButtonBackground: UDMessageColorTheme.imMessageIconVoiceGreyBg
]

/// ThreadDetail、ThreadChat、ThreadFilter、ThreadRecommend
public struct ThreadColorConfig: ColorConfigService {
    public init() {}

    public func getColor(for key: ColorKey, type: Type) -> UIColor {
        if type == .mine { return mineColorMap[key] ?? .clear }
        return otherColorMap[key] ?? .clear
    }
}
