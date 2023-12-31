//
//  BTLynxContainer+Init.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit
import LarkContainer

extension BTLynxContainer {
    
    public static func registerAll() {
        registerLynxExtension()
        registerLynxGroup()
        registerLynxGlobalData()
        registerLynxDispatcher()
    }
    
    private static func registerLynxExtension() {
        //如果有本地实现的 lynx 组件，在这里注册
        LarkLynxInitializer.shared.registerCustomComponents(tag: Self.Tag,
                                                            customComponentDic: [:])
    }
    
    private static func registerLynxGroup() {
        let group = LynxGroup(name: LynxGroup.singleGroupTag(),
                              withPreloadScript: nil,
                              useProviderJsEnv: false,
                              enableCanvas: true)
        LarkLynxInitializer.shared.registerLynxGroup(groupName: Self.Tag,
                                                     lynxGroup: group)
    }
    
    private static func registerLynxGlobalData() {
        @Injected var containerEnvService: BTLynxContainerEnvService
        LarkLynxInitializer.shared.registerGlobalData(tag: Self.Tag,
                                                      globalData: containerEnvService.env.toDictionary()
        )
    }
    
    private static func registerLynxDispatcher() {
        LarkLynxInitializer.shared.registerBridgeMethodDispatcher(tag: Self.Tag,
                                                                  impl: BTLynxAPIManager.sharedInstance)
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
}
