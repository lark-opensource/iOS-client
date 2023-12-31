//
//  EngineComponentFactory.swift
//  RenderRouterInterface
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import LarkContainer

// canCreate时机使用，canCreate时机比较早，可能无法提供EngineComponentDependency和EngineComponentAbility
public protocol EngineComponentFactoryContext: AnyObject {
    // 用户态容器
    var userResolver: UserResolver { get }
}

open class EngineComponentFactory {
    open class var type: Basic_V1_CardComponent.EngineProperty.EngineType {
        fatalError("must overrid")
    }

    open class func canCreate(
        previewID: String,
        componentID: String,
        engineEntity: Basic_V1_EngineEntity,
        context: EngineComponentFactoryContext
    ) -> Bool {
        assertionFailure("must be override")
        return false
    }

    open class func create(
        previewID: String,
        componentID: String,
        engineEntity: Basic_V1_EngineEntity,
        dependency: EngineComponentDependency,
        ability: EngineComponentAbility
    ) -> EngineComponentInterface {
        fatalError("must be override")
    }

    // 注册URLSDK级别服务，service的生命周期与URLSDK相同，
    // 即URLSDK初始化一次则调用一次，URLSDK销毁时service销毁，如会话内进群时初始化URLSDK，退出时URLSDK销毁，service生命周期同
    open class func registerServices(container: URLCardContainer, dependency: EngineComponentDependency) {
    }
}
