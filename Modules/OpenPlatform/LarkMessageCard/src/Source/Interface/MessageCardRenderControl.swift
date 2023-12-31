//
//  MessageCardSettings.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/20.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import LarkModel
import RustPB

public final class MessageCardRenderControl {
    public struct LynxCardRenderSetting: Codable {
        // 允许使用 Lynx 渲染的最早消息时间, 只有在这个时间之后的消息允许使用 Lynx 渲染
        let startTime: Int
        static var `default`: LynxCardRenderSetting {
            return LynxCardRenderSetting(startTime: Int.max)
        }
    }
    
    // 卡片使用新的配置,目前是 message 开始时间
    public static let lynxCardRenderSetting: LynxCardRenderSetting = {
        @Setting(key: UserSettingKey.make(userKeyLiteral: "lynx_card_message_render_start_time"))
        var setting: LynxCardRenderSetting?
        return setting ?? .default
    }()
    
    // 是否允许卡片使用新的渲染架构
    public static let lynxCardRenderEnable: Bool = {
        // 同样的 FG 在 MessageCardAssembly 中也存在
        @FeatureGatingValue(key: "lynxcard.client.render.enable")
        var featureGating: Bool
        return featureGating
    }()
    
    // 是否允许ipad使用使用新的渲染架构
    public static let lynxCardRenderIpadEnable: Bool = {
        // 同样的 FG 在 MessageCardAssembly 中也存在
        @FeatureGatingValue(key: "lynxcard.client.render.ipad.enable")
        var featureGating: Bool
        return featureGating
    }()
    
    // 是否允许可更新卡片使用新的渲染架构
    public static let lynxUpdateableCardRenderEnable: Bool = {
        // 同样的 FG 在 MessageCardAssembly 中也存在
        @FeatureGatingValue(key: "lynxcard.client.update.enable")
        var featureGating: Bool
        return featureGating
    }()
    
    // 通过 CardContent 判断是否使用 lynx 渲染
    // 用于非 message 场景, 无 message 时间判断, 仅适用于不需要落库的场景
    public static func lynxCardRenderEnable(content: Basic_V1_CardContent) -> Bool {
        if UI_USER_INTERFACE_IDIOM() == .pad && !self.lynxCardRenderIpadEnable {
            return false
        }
        // 注意与 lynxCardRenderEnable(message:) 内部保持条件同步
        // 这两者的 Content 类型不同, 一个是 PB 类型,一个是 LarkModel 类型
        guard Self.lynxCardRenderEnable && content.jsonBody != nil && content.jsonBody != "" else {
            return false
        }
        return true
    }

    // 通过 CardContent 判断是否使用 lynx 渲染
    public static func lynxCardRenderEnable(content: CardContent) -> Bool {
        if UI_USER_INTERFACE_IDIOM() == .pad && !self.lynxCardRenderIpadEnable {
            return false
        }
        // 注意与 lynxCardRenderEnable(message:) 内部保持条件同步
        // 这两者的 Content 类型不同, 一个是 PB 类型,一个是 LarkModel 类型
        guard Self.lynxCardRenderEnable && content.jsonBody != nil && content.jsonBody != "" else {
            return false
        }
        var haveRequest = false
        content.actions.forEach { (_: String, value: CardContent.CardAction) in
            if value.method != .openURL { haveRequest = true }
        }
        if haveRequest && Self.lynxUpdateableCardRenderEnable {
            return true
        } else if haveRequest && !Self.lynxUpdateableCardRenderEnable {
            return false
        }
        return true
    }
    
    // 通过 Message 判断是否使用 lynx 渲染
    public static func lynxCardRenderEnable(message: Message) -> Bool {
        guard message.createTime > TimeInterval(Self.lynxCardRenderSetting.startTime) else {
            return false
        }

        guard let content = message.content as? CardContent else {
            return false
        }
        // 注意与 lynxCardRenderEnable(content:) 内部保持条件同步
        // 这两者的 Content 类型不同,一个是 PB 类型,一个是 LarkModel 类型

        return Self.lynxCardRenderEnable(content: content)
    }
     
    
}
