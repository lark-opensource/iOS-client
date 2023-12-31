//
//  MessageCardContainer+OPLynxContainer.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/11.
//

import Foundation
import ECOProbe
import Lynx
import LarkSetting
import LarkLynxKit
import LarkContainer
import LKCommonsLogging
import UniversalCardBase

// MessageCardContainer: OPLynxContainer 相关
extension MessageCardContainer {
    static let logger = Logger.log(MessageCardContainer.self, category: "MessageCardContainer")

    static func registerLynxExtension() {
        Self.logger.info("MessageCardContaienr registerLynxExtension")
        @Injected var messageCardEnvService: MessageCardEnvService
        @FeatureGatingValue(
            key: "messagecard.lynximageshadownode.enable"
        ) var lynxImageUseShadowNodeEnable: Bool

        @FeatureGatingValue(
            key: "messagecard.chart.enable"
        ) var chartEnable: Bool

        let customComponents: [String: (AnyClass, LynxShadowNode.Type?)] = [
            MsgCardLynxTextView.name: (
                MsgCardLynxTextView.self,
                MsgCardLynxTextViewShadowNode.self
            ),
            MsgCardLynxHeaderBGView.name:(
                MsgCardLynxHeaderBGView.self,
                nil
            ),
            MsgCardLynxImageView.name:(
                MsgCardLynxImageView.self,
                lynxImageUseShadowNodeEnable ? MsgCardLynxImageViewShadowNode.self : nil
            ),
            MsgCardLynxIconView.name:(
                MsgCardLynxIconView.self,
                nil
            ),
            UniversalCardLynxCheckBox.name:(
                UniversalCardLynxCheckBox.self,
                nil
            ),
            MsgCardLynxPersonListView.name:(
                MsgCardLynxPersonListView.self,
                MsgCardLynxPersonListViewShadowNode.self
            ),
            MsgCardLynxAvatar.name:(
                MsgCardLynxAvatar.self,
                nil
            )
        ]
        LarkLynxInitializer.shared.registerCustomComponents(
            tag: Self.Tag,
            customComponentDic: customComponents
        )
        if chartEnable {
            LarkLynxInitializer.shared.registerLynxGroup(groupName: Self.Tag, lynxGroup: LynxGroup(name: LynxGroup.singleGroupTag(), withPreloadScript: nil, useProviderJsEnv: false, enableCanvas: true))
        }
        LarkLynxInitializer.shared.registerBridgeMethodDispatcher(
            tag: Self.Tag,
            impl: MessageCardLynxBridgeMethodImpl()
        )
        LarkLynxInitializer.shared.registerGlobalData(
            tag: Self.Tag, globalData: messageCardEnvService.env.toDictionary()
        )
    }
    
    // 使用消息卡片的 配置, 构造 LynxContainer 的 Layout 配置
    static func opLynxLayoutConfig(
        fromConfig config: Config
    ) -> LynxViewSizeConfig {
        return LynxViewSizeConfig(
            layoutWidthMode: .exact,
            layoutHeightMode: config.perferHeight != nil ? .exact : config.maxHeight != nil ? .max : nil,
            preferredMaxLayoutHeight: config.maxHeight != nil ? config.maxHeight : nil,
            preferredLayoutWidth: config.perferWidth,
            preferredLayoutHeight: config.perferHeight
        )
    }
    
    // 构造 OPLynxContainer 需要的上下文
    static func opLynxContext(
        context: MessageCardContainer.Context?
    ) -> LynxContainerContext {
        return LynxContainerContext(
            containerType: Self.Tag,
            bizExtra: ["bizContext": context as Any]
        )
    }
}
