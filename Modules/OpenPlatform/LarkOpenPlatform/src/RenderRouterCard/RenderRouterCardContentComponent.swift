//
//  RenderRouterCardContentComponent.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
import ECOProbe
import RustPB
import UniversalCardInterface
import TangramComponent
import LKCommonsLogging
import LarkContainer
import UniversalCard
import Lynx
import UniversalCardBase
import LarkMessageCard
import LarkLynxKit
import RenderRouterInterface
import EEAtomic

final class RenderRouterCardContentComponentProps: Props {
    let card: Basic_V1_UniversalCardEntity

    init(card: Basic_V1_UniversalCardEntity) { self.card = card }

    func clone() -> RenderRouterCardContentComponentProps { RenderRouterCardContentComponentProps(card: card) }

    func equalTo(_ old: TangramComponent.Props) -> Bool { card == (old as? RenderRouterCardContentComponentProps)?.card }
}

final class UniversalCardContainerView: UIView {
    var traitCollectionDidChange: (() -> Void)?

    // 监听黑暗模式变化
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if let previousTraitCollection = previousTraitCollection,
               previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                traitCollectionDidChange?()
            }
        }
    }

    // 空实现，拦截掉didSelete事件，避免卡片多次点击闪烁问题
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}

    func setCardView(view: UIView) {

        guard !subviews.contains(view) else { return }
        view.removeFromSuperview()
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(view)
    }
}


final class RenderRouterCardContentComponent: RenderComponent<RenderRouterCardContentComponentProps, UniversalCardContainerView, RenderRouterCardContext> {

    public static let logger = Logger.log(RenderRouterCardContentComponent.self, category: "RenderRouterCardContentComponent")
    private let layoutService: UniversalCardLayoutServiceProtocol
    private let cardSharePoolService: UniversalCardSharePoolProtocol

    //标识位，如果通过算高容器获得的高度一定要重新渲染
    private var forceRender: Bool = false
    var preferSize: CGSize?

    private var cardID: String { self.cardData.data.cardID }
    @AtomicObject
    var cardData: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)

    @AtomicObject
    private var _props: RenderRouterCardContentComponentProps
    public override var props: RenderRouterCardContentComponentProps {
        set {
            guard _props.card != newValue.card else { return }
            _props = newValue
            self.cardData = universalCardData(
                from: newValue.card,
                context: context,
                preferWidth: 0,
                userResolver: context?.dependency.userResolver
            )
        }
        get { return _props }
    }
    public override var isSelfSizing: Bool { return true }

    init(props: RenderRouterCardContentComponentProps, context: RenderRouterCardContext) {
        if let layoutService = context.ability.cardContainer.resolve(UniversalCardLayoutServiceProtocol.self),
           let cardSharePoolService = context.ability.cardContainer.resolve(UniversalCardSharePoolProtocol.self) {
            self.layoutService = layoutService
            self.cardSharePoolService = cardSharePoolService
        } else {
            assertionFailure("RenderRouterCardContentComponent init with fatalError: layoutService or cardSharePoolService is nil")
            Self.logger.error("RenderRouterCardContentComponent init with fatalError: layoutService or cardSharePoolService is nil")
            self.layoutService = UniversalCardLayoutService(resolver: context.dependency.userResolver)
            self.cardSharePoolService = UniversalCardSharePool(resolver: context.dependency.userResolver)
        }
        cardData = universalCardData(
            from: props.card,
            context: context,
            preferWidth: 0,
            userResolver: context.dependency.userResolver
        )
        _props = props
        super.init(props: props, context: context)
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        cardData.config.displayConfig.preferWidth = size.width
        if let preferSize = preferSize, size.width == preferSize.width  { return preferSize }
        let layoutConfig = UniversalCardLayoutConfig(preferWidth: size.width, maxHeight: nil)
        let layoutSize = layoutService.layout(layoutConfig: layoutConfig, source: cardData)
        preferSize = CGSize(width: size.width, height: layoutSize.height)
        forceRender = true
        return layoutSize
    }

    override func create(_ rect: CGRect) -> UniversalCardContainerView {
        let containerView = UniversalCardContainerView()
        containerView.bounds.size = preferSize ?? rect.size
        let card = cardSharePoolService.get(cardID)
        containerView.setCardView(view: card.getView())
        return containerView
    }

    override func update(_ view: UniversalCardContainerView) {
        let render: () -> Void = { [weak self] in
            guard let self = self else { return }
            let card = self.cardSharePoolService.get(self.cardID)
            card.render(
                layout: UniversalCardLayoutConfig(
                    preferWidth: self.preferSize?.width ?? view.bounds.size.width,
                    maxHeight: nil
                ),
                source: self.cardData,
                lifeCycle: self,
                force: self.forceRender
            )
            self.forceRender = false
            view.setCardView(view: card.getView())
            view.traitCollectionDidChange = { [weak card] in card?.render() }
        }
        if Thread.isMainThread { render() }
        else { DispatchQueue.main.async { render() } }
        super.update(view)
    }
}

