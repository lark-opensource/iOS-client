//
//  MessageCardComponent.swift
//  LarkOpenPlatform
//
//  Created by majiaxin.jx on 2022/11/20.
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

final class MessageCardComponentProps2: ASComponentProps {
    @AtomicObject
    var cardContainerData: MessageCardContainer.ContainerData?
    @AtomicObject
    var identify: MessageCardIdentify?
    @AtomicObject
    var cardSize: CGSize?
    @AtomicObject
    var updateCardSize : ((CGSize) -> Void)?

    let reuseKey: UUID

    private weak var lifeCycleClient: MessageCardContainerLifeCycle?

    let lock = NSLock()

    func update(lifeCycleClient: MessageCardContainerLifeCycle?) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.lifeCycleClient = lifeCycleClient
    }

    func getLifeCycleClient() -> MessageCardContainerLifeCycle? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.lifeCycleClient
    }

    init(reuseKey: UUID,
         cardContainerData: MessageCardContainer.ContainerData? = nil,
         identify: MessageCardIdentify? = nil,
         cardSize: CGSize? = nil,
         updateCardSize: ((CGSize) -> Void)? = nil) {
        self.reuseKey = reuseKey
        self.cardContainerData = cardContainerData
        self.identify = identify
        self.cardSize = cardSize
        self.updateCardSize = updateCardSize
        super.init()
    }
}

class LynxContainerView: UIView {
    var lynxView: LynxView? {
        didSet {
            if let view = lynxView {
                view.removeFromSuperview()
                self.addSubview(view)
            }
        }
    }

    var darkModeDidChangeCallback: (() -> Void)?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if let previousTraitCollection = previousTraitCollection,
               previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                darkModeDidChangeCallback?()
            }
        }
    }
}

final class MessageCardComponent2<C: MessageCardViewModelContext>:
    ASComponent<MessageCardComponentProps2, EmptyState, LynxContainerView, C> {
    public typealias Props = MessageCardComponentProps2

    private var preferSize: CGSize?
    // 以下三个元素, isLeaf, isSelfSizing, isComplex 一同决定该节点是否自己计算大小
    public override var isLeaf: Bool { true }
    public override var isSelfSizing: Bool { true }
    public override var isComplex: Bool { true }
    //标识当前正展示UI，仅用于标识高度缓存是否有效
    private var identify: MessageCardIdentify?

    private let reuseKey: UUID

    let logger = Logger.log(MessageCardComponent2.self, category: "MessageCardComponent2")

    let createTrace = OPTraceService.default().generateTrace()

    @InjectedSafeLazy
    private var messageCardLayoutService: MessageCardLayoutService


    var messageCardContainerSharePool: MessageCardContainerSharePoolService?

    //标识位，如果通过算高容器获得的高度一定要重新渲染
    var forceRender: Bool = false

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        //复用标识符，仅一次给值，后续不在更新
        self.reuseKey = props.reuseKey
        super.init(props: props, style: style, context: context)
        messageCardContainerSharePool = context?.pageContainer.resolve(MessageCardContainerSharePoolService.self)
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        //新的数据与当前UI内容标识不一致，需要重新计算高度
        if let isEqual = new.identify?.isEqual(identify: self.identify), !isEqual {
            self.preferSize = nil
            return true
        }
        if let size = new.cardSize {
            self.preferSize = size
        }
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        if let preferSize = self.preferSize {
            logger.info("messageCard: \(self.identify?.messageID) sizeToFit: useCache\(preferSize)")
            return preferSize
        }

        if let cardContainerData = self.props.cardContainerData{
            let size = messageCardLayoutService.processLayout(cardContainerData)
            self.identify = props.identify
            self.preferSize = size
            self.props.updateCardSize?(size)
            forceRender = true
            logger.info("messageCard: \(self.identify?.messageID) sizeToFit: layout \(preferSize)")
            return size
        }
        logger.error("messageCard: \(self.identify?.messageID) sizeToFit: default zero")
        return .zero
    }

    public override func create(_ rect: CGRect) -> LynxContainerView {
        let lynxContainerView = LynxContainerView()
        guard let cardContainerData = props.cardContainerData else {
            return lynxContainerView
        }
        let view = messageCardContainerSharePool?.get(cardContainerData, reuseKey: self.reuseKey).createView()
        lynxContainerView.lynxView = view
        return lynxContainerView
    }

    public override func update(view: LynxContainerView) {
        guard let cardContainerData = props.cardContainerData,
        let identify = props.identify else {
            super.update(view: view)
            return
        }
        //页面重绘的的缓存机制/避免重复绘制，由container控制。
        let container = messageCardContainerSharePool?.get(cardContainerData, reuseKey: self.reuseKey)
        if let container = container {
            container.lifeCycleClient = props.getLifeCycleClient()
            view.darkModeDidChangeCallback = { [weak container] in
                container?.updateEnvData()
                container?.render()
            }
            let reuseMessageID = (container.identify as? MessageCardIdentify)?.messageID ?? "nil"
            logger.info("updateView:\(Unmanaged.passUnretained(view).toOpaque()), current:\(identify.messageID) reuse:\(reuseMessageID)")
            if Thread.isMainThread {
                container.renderView(cardContainerData,
                                     identify: identify, forceRender: forceRender)
                forceRender = false
            } else {
                DispatchQueue.main.async { [self] in
                    container.renderView(cardContainerData,
                                         identify: identify, forceRender: self.forceRender)
                    forceRender = false
                }
            }
        } else {
            logger.error("lynxContainerView miss container \(identify.messageID)")
        }
        super.update(view: view)
        return
    }

    func forceRenderCard() {
        guard let cardContainerData = props.cardContainerData, let identify = props.identify else {
            return
        }
        guard let container = messageCardContainerSharePool?.get(cardContainerData, reuseKey: self.reuseKey) else {
            return
        }
        container.lifeCycleClient = props.getLifeCycleClient()
        DispatchQueue.main.async {
            container.renderView(cardContainerData, identify: identify, forceRender: true)
        }
    }
}

