//
//  RenderRouterCardContainerComponent.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/17.
//

import Logger
import ECOProbe
import Foundation
import RustPB
import EEAtomic
import UniversalCardInterface
import TangramComponent
import RenderRouterInterface

final class RenderRouterCardContainerComponentProps: Props {
    let entity: Basic_V1_EngineEntity

    public init(entity: Basic_V1_EngineEntity) {
        self.entity = entity
    }

    func clone() -> RenderRouterCardContainerComponentProps {
        return RenderRouterCardContainerComponentProps(entity: entity)
    }

    func equalTo(_ old: TangramComponent.Props) -> Bool {
        return entity == (old as? RenderRouterCardContainerComponentProps)?.entity
    }
}

class RenderRouterCardContext: Context {
    let trace: OPTrace
    let dependency: EngineComponentDependency
    let ability: EngineComponentAbility
    init(trace: OPTrace, dependency: EngineComponentDependency, ability: EngineComponentAbility) {
        self.trace = trace
        self.dependency = dependency
        self.ability = ability
    }
}

class RenderRouterCardContainerComponent: RenderComponent<RenderRouterCardContainerComponentProps, UIView, RenderRouterCardContext> {
    private let logger = Logger.log(RenderRouterCardContainerComponent.self, category: "RenderRouterCardContainerComponent")
    @AtomicObject
    private var _props: RenderRouterCardContainerComponentProps
    public override var props: RenderRouterCardContainerComponentProps {
        set {
            guard !_props.equalTo(newValue) else { return }
            _props = newValue
            cardComponent.props = RenderRouterCardContentComponentProps(
                card: _props.entity.universalCardEntity
            )
        }
        get { _props }
    }

    private lazy var cardComponent: RenderRouterCardContentComponent = {
        let cardProps = RenderRouterCardContentComponentProps(
            card: self.props.entity.universalCardEntity
        )
        return RenderRouterCardContentComponent(props: cardProps, context: _context)
    }()

    public let _context: RenderRouterCardContext

    init(props: RenderRouterCardContainerComponentProps, context: RenderRouterCardContext) {
        _props = props
        _context = context
        super.init(props: props, context: context)
        setupSubComponent()
    }

    func setupSubComponent() {
        let props = FlexLayoutComponentProps()
        let layout = FlexLayoutComponent(children: [cardComponent], props: props)
        self.setLayout(layout)
    }
}
