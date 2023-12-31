//
//  ChatComponentThemeManager.swift
//  LarkChat
//
//  Created by JackZhao on 2023/1/4.
//

// 适配聊天背景更换后chat其他组件的颜色
import UIKit
import Foundation
import LarkMessageBase
import UniverseDesignColor
import LarkMessengerInterface

public struct ChatComponentTheme {
    public var isDefaultScene: Bool {
        scene == .defaultScene
    }
    var scene: ChatThemeScene = .defaultScene
    // 系统消息
    public var systemTextColor: UIColor
    public var systemMessageBlurColor: UIColor

    // 回复
    var replyIconAndTextColor: UIColor

    // 加急提示
    var urgentTipNameColor: UIColor
    var urgentTipColor: UIColor
    var urgentIconColor: UIColor
    var urgentReadColor: UIColor
    var urgentUnReadColor: UIColor

    // pin
    var pinTipColor: UIColor

    // pin高亮颜色
    public var pinHighlightColor: UIColor

    // 话题回复
    var threadReplyTipColor: UIColor

    // 人名、个性签名
    public var nameAndDescColor: UIColor
    public var chatterStatusDivider: UIColor
    public var chatterDescDocIconColor: UIColor

    // 底部时间文字
    public var bottomTimeTextColor: UIColor

    public static func getChatDefault(isMe: Bool = false) -> ChatComponentTheme {
        let chatColorConfig = ChatColorConfig()
        let colorThemeType: Type = isMe ? .mine : .other
        return ChatComponentTheme(systemTextColor: UIColor.ud.textPlaceholder,
                                  systemMessageBlurColor: .clear,
                                  replyIconAndTextColor: chatColorConfig.getColor(for: .Message_Assitant_Reply_Foreground, type: colorThemeType),
                                  urgentTipNameColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_UserName, type: colorThemeType),
                                  urgentTipColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Foreground, type: colorThemeType),
                                  urgentIconColor: UIColor.ud.functionDangerContentDefault,
                                  urgentReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Read, type: colorThemeType),
                                  urgentUnReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Unread, type: colorThemeType),
                                  pinTipColor: UDMessageColorTheme.imMessageTextPin,
                                  pinHighlightColor: .clear,
                                  threadReplyTipColor: UIColor.ud.textLinkNormal,
                                  nameAndDescColor: UIColor.ud.textPlaceholder,
                                  chatterStatusDivider: UIColor.ud.lineDividerDefault,
                                  chatterDescDocIconColor: UIColor.ud.textLinkNormal,
                                  bottomTimeTextColor: UIColor.ud.textPlaceholder)
    }
}

public class ChatComponentThemeManager {
    /// 适配规则详见： 聊天其他组件适配 =》颜色适配细节
    /// doc: https://bytedance.feishu.cn/docx/G5Yqd9TNxoHQlwxWLRIcwEU8nSb
    static public func getComponentTheme(scene: ChatThemeScene,
                                         isMe: Bool = false) -> ChatComponentTheme {
        let chatColorConfig = ChatColorConfig()
        let colorThemeType: Type = isMe ? .mine : .other
        switch scene {
        case .defaultScene:
            return ChatComponentTheme.getChatDefault(isMe: isMe)
        case .bright:
            return ChatComponentTheme(scene: .bright,
                                      systemTextColor: UIColor.ud.textCaption,
                                      systemMessageBlurColor: UIColor.ud.N00.withAlphaComponent(0.8) & UIColor.ud.N00.withAlphaComponent(0.2),
                                      replyIconAndTextColor: chatColorConfig.getColor(for: .Message_Assitant_Reply_Foreground, type: colorThemeType),
                                      urgentTipNameColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_UserName, type: colorThemeType),
                                      urgentTipColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Foreground, type: colorThemeType),
                                      urgentIconColor: UIColor.ud.functionDangerContentDefault,
                                      urgentReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Read, type: colorThemeType),
                                      urgentUnReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Unread, type: colorThemeType),
                                      pinTipColor: UDMessageColorTheme.imMessageTextPin,
                                      pinHighlightColor: .clear,
                                      threadReplyTipColor: UIColor.ud.textLinkNormal,
                                      nameAndDescColor: UIColor.ud.textPlaceholder,
                                      chatterStatusDivider: UIColor.ud.lineDividerDefault,
                                      chatterDescDocIconColor: UIColor.ud.textLinkNormal,
                                      bottomTimeTextColor: UIColor.ud.textPlaceholder)
        case .dark:
            let lightSceneTheme = Self.getComponentTheme(scene: .bright, isMe: isMe)
            return ChatComponentTheme(scene: .dark,
                                      systemTextColor: UIColor.ud.textCaption.alwaysLight,
                                      systemMessageBlurColor: UIColor.ud.N00.withAlphaComponent(0.8) & UIColor.ud.N00.withAlphaComponent(0.2),
                                      replyIconAndTextColor: chatColorConfig.getColor(for: .Message_Assitant_Reply_Foreground, type: isMe ? .mine : .other).alwaysDark &
                                        lightSceneTheme.replyIconAndTextColor.alwaysDark,
                                      urgentTipNameColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_UserName, type: colorThemeType).alwaysDark,
                                      urgentTipColor: UIColor.ud.primaryOnPrimaryFill & lightSceneTheme.urgentTipColor.alwaysDark,
                                      urgentIconColor: UIColor.ud.functionDangerContentDefault.alwaysDark & lightSceneTheme.urgentIconColor.alwaysDark,
                                      urgentReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Read, type: colorThemeType).alwaysDark & lightSceneTheme.urgentReadColor.alwaysDark,
                                      urgentUnReadColor: chatColorConfig.getColor(for: .Message_Assitant_Buzz_Unread, type: colorThemeType).alwaysDark,
                                      pinTipColor: UDMessageColorTheme.imMessageTextPin.alwaysDark & lightSceneTheme.pinTipColor.alwaysDark,
                                      pinHighlightColor: UIColor.ud.Y400.withAlphaComponent(0.2) & lightSceneTheme.pinHighlightColor.alwaysDark,
                                      threadReplyTipColor: UIColor.ud.textLinkNormal.alwaysDark & lightSceneTheme.threadReplyTipColor.alwaysDark,
                                      nameAndDescColor: UIColor.ud.primaryOnPrimaryFill & lightSceneTheme.nameAndDescColor.alwaysDark,
                                      chatterStatusDivider: UIColor.ud.lineDividerDefault.alwaysDark & lightSceneTheme.chatterStatusDivider.alwaysDark,
                                      chatterDescDocIconColor: UIColor.ud.textLinkNormal.alwaysDark & lightSceneTheme.chatterStatusDivider.alwaysDark,
                                      bottomTimeTextColor: UIColor.ud.primaryOnPrimaryFill & lightSceneTheme.bottomTimeTextColor.alwaysDark)
        @unknown default:
            return ChatComponentTheme.getChatDefault(isMe: isMe)
        }
    }
}
