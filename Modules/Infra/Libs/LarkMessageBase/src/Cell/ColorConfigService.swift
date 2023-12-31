//
//  ColorConfigService.swift
//  LarkMessageBase
//
//  Created by qihongye on 2020/5/19.
//

import UIKit
import Foundation

// swiftlint:disable identifier_name
/// 抽象的部分区域key
public enum ColorKey {
    /// 姓名+签名
    case NameAndSign
    /// 消息时间
    case Message_Time
    /// 分割线颜色（分割线、回复图片边框、reaction分割线）
    case Message_BubbleSplitLine
    /// 背景色-底色
    case Message_Bubble_Background
    case Message_Bubble_Foreground
    /// 文本-交互区域（撤回消息按钮，DocsURL，URL，Doc-title+icon，电话号，邮箱，重拨）
    case Message_Text_ActionDefault
    case Message_Text_ActionPressed
    case Message_Text_Foreground
    /// 文本-at-背景色
    case Message_At_Background_Me
    case Message_At_Background_InnerGroup
    case Message_At_Background_OutterGroup
    case Message_At_Background_All
    case Message_At_Background_Chat
    /// 文本-at-文字色
    case Message_At_Foreground_Me
    case Message_At_Foreground_InnerGroup
    case Message_At_Foreground_OutterGroup
    case Message_At_Foreground_All
    case Message_At_Foreground_Chat
    case Message_At_Foreground_Anonymous
    /// 文本-at-已读未读
    case Message_At_Read
    case Message_At_UnRead
    /// 文本-正文-​系统文字颜色（备注：此消息已撤回、转为群组）
    case Message_SystemText_Foreground
    /// 文本-企业词典
    case Message_Abbreviation_Foreground
    case Message_Abbreviation_Underline
    /// 文本-遮罩
    case Message_Mask_GradientTop
    case Message_Mask_GradientBottom
    /// URLPreview
    case Message_URLPreview_Foreground
    /// DocPreview
    case DocPreview_Foreground
    case DocPreview_DescForeground
    /// 语音
    case Message_Audio_BubbleBackground
    case Message_Audio_ProgressBarBackground
    case Message_Audio_ProgressBarForeground
    case Message_Audio_ButtonBackground
    case Message_Audio_ConvertStateButtonBackground
    case Message_Audio_ConvertState
    case Message_Audio_TimeTextForeground
    case Message_Audio_PlayButtonBackground
    /// 回复
    case Message_Reply_SplitLine
    case Message_Reply_Foreground
    case Message_Reply_Card_SplitLine
    case Message_Reply_Card_Foreground
    case Message_Reply_Card_Custom_SplitLine
    case Message_Reply_Card_Custom_Foreground
    case Message_Reply_Background
    /// reaction
    case Reaction_Background
    case Reaction_Foreground
    /// 合并转发
    case MergeForward_Title
    case MergeForward_Foreground
    case MergeForward_Splitline
    /// 选中
    case Message_Selection_Background
    case Message_Selection_Icon
    /// 卡片-reaction
    case Reaction_Card_Background
    case Reaction_Card_Foreground
    /// 转发
    case Message_Assitant_Forward_Icon
    case Message_Assitant_Forward_Foreground
    case Message_Assitant_Forward_UserName
    /// 回复
    case Message_Assitant_Reply_Icon
    case Message_Assitant_Reply_Foreground
    /// 加急
    case Message_Assitant_Buzz_Icon
    case Message_Assitant_Buzz_Foreground
    case Message_Assitant_Buzz_UserName
    case Message_Assitant_Buzz_Read
    case Message_Assitant_Buzz_Unread
    /// Pin
    case Message_Assitant_Pin_Icon
    case Message_Assitant_Pin_Foreground
    /// 背景色
    case Cell_Background_Selected
    case Cell_Background_Highlighted
}
// swiftlint:enable identifier_name

/// https://www.figma.com/file/y72xpLSYEPG74t1sfc2UwB/%E4%BC%9A%E8%AF%9D%E5%86%85%E6%B6%88%E6%81%AF%E7%B1%BB%E5%9E%8B?node-id=74%3A20
/// Mine、Other并不一定是按照是不是自己发的来区分，只是说有两套色板
public enum Type {
    case mine
    case other
}

/// 需求文档：https://bytedance.feishu.cn/docs/doccno2NanGFIOHv2I4N72W8rmb#
public protocol ColorConfigService {
    /// 获取某个Key对应的颜色，根据type不同去对应色板取值，兜底按照是不是自己发的来传
    func getColor(for key: ColorKey, type: Type) -> UIColor
}
