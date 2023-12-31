//
//  MessageUniversalCardComponent.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation
import AsyncComponent
import LarkModel
import LarkMessageBase
import struct LarkSDKInterface.PushCardMessageActionResult
import RustPB
import LKCommonsLogging
import LarkMessageCard
import Lynx
import EEFlexiable
import ECOProbeMeta
import ECOProbe
import LarkSetting
import LarkContainer
import EEAtomic
import UniversalCardInterface
import UniversalCard

final class MessageUniversalCardComponentProps: ASComponentProps {

    private var cardID: String? { self.cardData?.data.cardID }
    @AtomicObject
    var cardData: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)?
    @AtomicObject
    var cardSize: CGSize?
    @AtomicObject
    var updateCardSize : ((CGSize) -> Void)?

    var maxHeight: CGFloat?

    let lock = NSLock()

    let reuseKey: UniversalCardSharePool.ReuseKey

    private weak var lifeCycleClient: UniversalCardLifeCycleDelegate?

    func update(lifeCycleClient: UniversalCardLifeCycleDelegate?) {
        lock.lock(); defer { lock.unlock() }
        self.lifeCycleClient = lifeCycleClient
    }

    func getLifeCycleClient() -> UniversalCardLifeCycleDelegate? {
        lock.lock(); defer { lock.unlock() }
        return self.lifeCycleClient
    }

    init(
        reuseKey: UniversalCardSharePool.ReuseKey,
        cardData: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)? = nil,
        cardSize: CGSize? = nil,
        maxHeight: CGFloat? = nil,
        updateCardSize: ((CGSize) -> Void)? = nil
    ) {
        self.reuseKey = reuseKey
        self.cardData = cardData
        self.cardSize = cardSize
        self.maxHeight = maxHeight
        self.updateCardSize = updateCardSize
        super.init()
    }
}

final class MessageUniversalCardComponent<C: MessageCardViewModelContext>:
    ASComponent<MessageUniversalCardComponentProps, EmptyState, UniversalCardContainerView, C> {
    typealias Props = MessageUniversalCardComponentProps

    private var preferSize: CGSize?
    // 以下三个元素, isLeaf, isSelfSizing, isComplex 一同决定该节点是否自己计算大小
    override var isLeaf: Bool { true }
    override var isSelfSizing: Bool { true }
    override var isComplex: Bool { true }

    let logger = Logger.log(MessageUniversalCardComponent.self, category: "MessageUniversalCardComponent")

    let createTrace = OPTraceService.default().generateTrace()

    @FeatureGatingValue(key: "universalcard.updatemessagelocaldata.enable")
    var enableUpdateLocalData: Bool

    private var layoutService: UniversalCardLayoutServiceProtocol
    private var cardSharePoolService: UniversalCardSharePoolProtocol

    //标识位，如果通过算高容器获得的高度一定要重新渲染
    private var forceRender: Bool = false

    private var cardID: String? { self.cardData?.data.cardID }
    @AtomicObject
    var cardData: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)?

    public init(props: Props, context: C) {
        if let layoutService = context.pageContainer.resolve(UniversalCardLayoutServiceProtocol.self),
           let cardSharePoolService = context.pageContainer.resolve(UniversalCardSharePoolProtocol.self) {
            self.layoutService = layoutService
            self.cardSharePoolService = cardSharePoolService
        } else {
            self.logger.error("MessageUniversalCardComponent init with fatalError: layoutService or cardSharePoolService is nil")
            self.layoutService = UniversalCardLayoutService(resolver: context.userResolver)
            self.cardSharePoolService = UniversalCardSharePool(resolver: context.userResolver)
        }
        super.init(props: props, style: ASComponentStyle(), context: context)
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        if let currentData = self.cardData, let newData = new.cardData,
           UniversalCard.isSameSource(left: currentData, right: newData) {
            if let size = new.cardSize {
                self.preferSize = size
            }
        } else {
            self.preferSize = nil
            if !enableUpdateLocalData {
                self.cardData = new.cardData
            }
        }
        if enableUpdateLocalData {
            self.cardData = new.cardData
        }
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        self.cardData?.config.displayConfig.preferWidth = size.width
        guard let cardData = cardData else { return size }
        if let preferSize = preferSize, size.width == preferSize.width  { return preferSize }
        let layoutConfig = UniversalCardLayoutConfig(preferWidth: size.width, maxHeight: props.maxHeight)
        var layoutSize = size
        if let fg = context?.userResolver.fg.staticFeatureGatingValue(with: "universalcard.async_render.enable"), fg {
            let card: UniversalCard = cardSharePoolService.get(props.reuseKey)
            // 若在主线程, 直接渲染,增加上屏速度
            if Thread.isMainThread {
                card.render(layout: layoutConfig, source: cardData, lifeCycle: props.getLifeCycleClient(), force: true)
                forceRender = false
            } else {
                card.layout(layout: layoutConfig, source: cardData, lifeCycle: props.getLifeCycleClient(), force: true)
                forceRender = true
            }
            layoutSize = card.getContentSize()
            self.logger.info("UniversalCardComponent sizeToFit finish", additionalData: [
                "trace": cardData.context.renderingTrace?.traceId ?? "",
                "asyncRender": "true",
                "isMainThread": String(Thread.isMainThread),
                "layoutSize": "(width:\(layoutSize.width), height: \(layoutSize.height))"
            ])
        } else {
            layoutSize = layoutService.layout(layoutConfig: layoutConfig, source: cardData)
            forceRender = true
            self.logger.info("UniversalCardComponent sizeToFit finish", additionalData: [
                "trace": cardData.context.renderingTrace?.traceId ?? "",
                "asyncRender": "false",
                "isMainThread": String(Thread.isMainThread),
                "layoutSize": "(width:\(layoutSize.width), height: \(layoutSize.height))"
            ])
        }
        preferSize = CGSize(width: size.width, height: layoutSize.height)
        props.updateCardSize?(layoutSize)
        return layoutSize
    }

    override func create(_ rect: CGRect) -> UniversalCardContainerView {
        let containerView = UniversalCardContainerView()
        containerView.bounds.size = preferSize ?? rect.size
        guard let card = render(rect.width) else {
            logger.error("create card fail", additionalData: ["cardID": self.cardID ?? ""])
            return containerView
        }
        containerView.setCardView(view: card.getView())
        return containerView
    }

    override func update(view: UniversalCardContainerView) {
        defer { super.update(view: view) }
        guard let card = render(preferSize?.width ?? view.bounds.width) else {
            logger.error("update card fail", additionalData: ["cardID": self.cardID ?? ""])
            return
        }
        view.setCardView(view: card.getView())
        view.traitCollectionDidChange = { [weak card] in card?.render() }
    }

    // 渲染卡片, 需要在主线程调用
    private func render(_ width: CGFloat) -> UniversalCard? {
        guard let cardID = self.cardID, let cardData = self.cardData else {
            logger.error("render card fail because source is nil", additionalData: ["CardID": self.cardID ?? ""])
            return nil
        }
        let card = cardSharePoolService.get(props.reuseKey)
        let layoutConfig = UniversalCardLayoutConfig(preferWidth: width, maxHeight: props.maxHeight)
        card.render(
            layout: layoutConfig,
            source: cardData,
            lifeCycle: props.getLifeCycleClient(),
            force: forceRender
        )
        forceRender = false
        return card
    }
}

// 外部接口
extension MessageUniversalCardComponent {
    // 渲染卡片, 外部调用, 使用内部数据直接渲染
    public func forceRenderCard() {
        DispatchQueue.main.async {
            guard let width = self.preferSize?.width else {
                self.logger.error("forceRenderCard fail because preferSize is nil", additionalData: ["CardID": self.cardID ?? ""])
                return
            }
            self.forceRender = false
            let _ = self.render(width)
        }
    }
}

