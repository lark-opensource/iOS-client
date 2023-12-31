//
//  Card+LarkLynxKit.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/8.
//

import Lynx
import Foundation
import LarkLynxKit
import LarkContainer
import UniversalCardBase
import UniversalCardInterface
import LKCommonsLogging
import LarkSetting

extension UniversalCard {
    static func createLynxBuilder(
        resolver: UserResolver,
        layout: LynxViewSizeConfig,
        wrapper: UniversalCardLynxBridgeContextWrapper,
        lifeCycleClient: LynxViewLifecycle,
        renderThreadMode: UniversalCardRenderThreadMode
    ) -> LarkLynxContainerBuilder {
        let lynxContext = Self.createLynxContext(wrapper: wrapper)
        Self.registerLynxExtension(resolver: resolver)
        let builder = LarkLynxContainerBuilder()
            .setupContext(context: lynxContext)
            .tagForCustomComponent(tag: Self.Tag)
            .tagForBridgeMethodDispatcher(tag: Self.Tag)
            .tagForGlobalData(tag: Self.Tag)
            .lynxViewSizeConfig(sizeConfig: layout)
            .lynxViewLifeCycle(lynxViewLifeCycle: lifeCycleClient)
            .tagForLynxGroup(tag: Self.Tag)
        if FeatureGatingManager.shared.featureGatingValue(with: "universalcard.async_render.enable") {
            _ = builder.setThreadStrategyForRender(renderThreadMode == .async ? .mostOnTASM : .allOnUI)
        }
        return builder
    }

    static func registerLynxExtension(resolver: UserResolver) {
        Self.logger.info("UniversalCard registerLynxExtension")
        let customComponents: [String: (LynxUIView.Type, LynxShadowNode.Type?)] = [
            UniversalCardLynxTextView.name: (
                UniversalCardLynxTextView.self,
                UniversalCardLynxTextViewShadowNode.self
            ),
            UniversalCardLynxHeaderBGView.name:(
                UniversalCardLynxHeaderBGView.self,
                nil
            ),
            UniversalCardLynxImageView.name:(
                UniversalCardLynxImageView.self,
                UniversalCardLynxImageViewShadowNode.self
            ),
            UniversalCardLynxCheckBox.name:(
                UniversalCardLynxCheckBox.self,
                nil
            ),
            UniversalCardLynxIconView.name:(
                UniversalCardLynxIconView.self,
                nil
            ),
            UniversalCardLynxPersonListView.name:(
                UniversalCardLynxPersonListView.self,
                UniversalCardLynxPersonListViewShadowNode.self
            ),
            UniversalCardLynxAvatar.name:(
                UniversalCardLynxAvatar.self,
                nil
            )]
        
        @FeatureGatingValue(
            key: "messagecard.chart.enable"
        ) var chartEnable: Bool
        if chartEnable {
            LarkLynxInitializer.shared.registerLynxGroup(groupName: Self.Tag, lynxGroup: LynxGroup(name: LynxGroup.singleGroupTag(), withPreloadScript: nil, useProviderJsEnv: false, enableCanvas: true))
        }
        
        LarkLynxInitializer.shared.registerCustomComponents(
            tag: Self.Tag,
            customComponentDic: customComponents
        )
        LarkLynxInitializer.shared.registerBridgeMethodDispatcher(
            tag: Self.Tag,
            impl: UniversalCardLynxBridge()
        )
        do {
            let cardEnvService = try resolver.resolve(assert: UniversalCardEnvironmentServiceProtocol.self)
            let globalData = try cardEnvService.env.toDictionary()
            LarkLynxInitializer.shared.registerGlobalData(
                tag: Self.Tag, globalData: globalData
            )
        } catch let error {
            Self.logger.error("CardEnv conver to dictionary fail, error:\(error)")
        }
    }

    // 使用消息卡片的 配置, 构造 LynxContainer 的 Layout 配置
    static func createLynxLayoutConfig(
        fromConfig config: UniversalCardLayoutConfig
    ) -> LynxViewSizeConfig {
        return LynxViewSizeConfig(
            layoutWidthMode: .exact,
            layoutHeightMode: config.preferHeight != nil ? .exact : config.maxHeight != nil ? .max : nil,
            preferredMaxLayoutHeight: config.maxHeight != nil ? config.maxHeight : nil,
            preferredLayoutWidth: config.preferWidth,
            preferredLayoutHeight: config.preferHeight
        )
    }

    // 构造 OPLynxContainer 需要的上下文
    static func createLynxContext(
        wrapper: UniversalCardLynxBridgeContextWrapper
    ) -> LynxContainerContext {
        return LynxContainerContext(
            containerType: Self.Tag,
            bizExtra: [Self.Tag: wrapper as Any]
        )
    }
}
