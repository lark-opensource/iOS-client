//
//  EngineComponentRegistry.swift
//  RenderRouterInterface
//
//  Created by Ping on 2023/7/31.
//

import RustPB

public class EngineComponentRegistry {
    // register在Assembly阶段，不存在同时读写，暂不加锁
    private static var factories: [Basic_V1_CardComponent.EngineProperty.EngineType: EngineComponentFactory.Type] = [:]

    public static func register(factory: EngineComponentFactory.Type) {
        factories[factory.type] = factory
    }

    public static func getFactory(type: Basic_V1_CardComponent.EngineProperty.EngineType) -> EngineComponentFactory.Type? {
        return factories[type]
    }

    public static func getAllFactories() -> [Basic_V1_CardComponent.EngineProperty.EngineType: EngineComponentFactory.Type] {
        return factories
    }
}
