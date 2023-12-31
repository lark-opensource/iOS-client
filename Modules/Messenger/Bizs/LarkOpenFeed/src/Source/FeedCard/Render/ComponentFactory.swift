//
//  FeedCardBaseComponentFactory.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2022/12/6.
//  Copyright © 2022 cactus. All rights reserved.
//

import Foundation
import UIKit
import RustPB
import LarkModel

// 组件工厂管理器
public class FeedCardComponentFactoryRegister {
    public typealias FeedCardComponentFactoryBuilder = (_ context: FeedCardContext) -> FeedCardBaseComponentFactory?

    private static var factoryBuilderList: [FeedCardComponentFactoryBuilder] = []
    // 注入组件工厂
    public static func register(factory: @escaping FeedCardComponentFactoryBuilder) {
        factoryBuilderList.append(factory)
    }

    // 获取所有组件工厂，准备生产组件
    public static func getAllFactory(feedCardContext: FeedCardContext) -> [FeedCardComponentType: FeedCardBaseComponentFactory] {
        var factoryMap: [FeedCardComponentType: FeedCardBaseComponentFactory] = [:]
        Self.factoryBuilderList.forEach { builder in
            if let factory = builder(feedCardContext) {
                factoryMap[factory.type] = factory
            }
        }
        return factoryMap
    }
}

// 组件工厂协议
public protocol FeedCardBaseComponentFactory {
    // 组件类型
    var type: FeedCardComponentType { get }

    // 创建一个组件 vm 类
    func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM

    // 创建一个组件 view 类
    func creatView() -> FeedCardBaseComponentView
}
