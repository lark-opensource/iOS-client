//
//  RenderRouterCardFactory.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
import RustPB
import Logger
import ECOProbe
import TangramComponent
import UniversalCard
import UniversalCardInterface
import EENavigator
import RenderRouterInterface
import LarkSetting


class RenderRouterCardFactory: EngineComponentFactory {
    open class override var type: Basic_V1_CardComponent.EngineProperty.EngineType {
        return .smartcard
    }

    open class override func canCreate(
        previewID: String,
        componentID: String,
        engineEntity: Basic_V1_EngineEntity,
        context: EngineComponentFactoryContext
    ) -> Bool {
        @FeatureGatingValue(key: "urlcard.client.render.enable")
        var renderEnable: Bool
        switch engineEntity.entity {
            case .universalCardEntity(_): return renderEnable
            case .defaultEntity(_): return false
            default: return false
        }
    }

    open class override func create(
        previewID: String,
        componentID: String,
        engineEntity: Basic_V1_EngineEntity,
        dependency: EngineComponentDependency,
        ability: EngineComponentAbility
    ) -> EngineComponentInterface {
        return RenderRouterCardComponent(engineEntity: engineEntity, dependency: dependency, ability: ability)
    }

    // 注册URLSDK级别服务，service的生命周期与URLSDK相同，
    // 即URLSDK初始化一次则调用一次，URLSDK销毁时service销毁，如会话内进群时初始化URLSDK，退出时URLSDK销毁，service生命周期同
    open class override func registerServices(container: URLCardContainer, dependency: EngineComponentDependency) {
        let userResolver = dependency.userResolver
        container.register(UniversalCardLayoutServiceProtocol.self) {
            return UniversalCardLayoutService(resolver: userResolver)
        }
        container.register(UniversalCardSharePoolProtocol.self) {
            return UniversalCardSharePool(resolver: userResolver)
        }
    }
}

class RenderRouterCardComponent: EngineComponentInterface {
    var tcComponent: TangramComponent.BaseRenderComponent
    let traceID: String
    var cardID: String
    let ability: EngineComponentAbility

    init(engineEntity: RustPB.Basic_V1_EngineEntity, dependency: EngineComponentDependency, ability: EngineComponentAbility) {
        let trace = OPTraceService.default().generateTrace()
        traceID = trace.traceId
        let props = RenderRouterCardContainerComponentProps(entity: engineEntity)
        let context = RenderRouterCardContext(trace: trace, dependency: dependency, ability: ability)
        tcComponent = RenderRouterCardContainerComponent(props: props, context: context)
        cardID = engineEntity.getCardID()
        self.ability = ability
    }

    func update(previewID: String, componentID: String, engineEntity: RustPB.Basic_V1_EngineEntity) {
        cardID = engineEntity.getCardID()
        let props = RenderRouterCardContainerComponentProps(entity: engineEntity)
        (tcComponent as? RenderRouterCardContainerComponent)?.props = props
    }

    func willDisplay() {
        ability.cardContainer.resolve(UniversalCardSharePoolProtocol.self)?.retainInUse(cardID)
    }

    func didEndDisplay() {
        ability.cardContainer.resolve(UniversalCardSharePoolProtocol.self)?.addReuse(cardID)
    }

    deinit {
        ability.cardContainer.resolve(UniversalCardSharePoolProtocol.self)?.remove(cardID)
    }

    func onResize() {
    }
}

extension RustPB.Basic_V1_EngineEntity {
    func getCardID() -> String { universalCardEntity.cardID }
}



