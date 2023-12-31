//
//  MessageCardViewModel.swift
//  LarkOpenPlatform
//
//  Created by majiaxin.jx on 2022/11/20.
//

import Foundation
import EENavigator
import EEAtomic
import RxSwift
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import RustPB
import LKCommonsLogging
import LarkFeatureGating
import LarkMessengerInterface
import UniverseDesignIcon
import EEMicroAppSDK
import LarkSetting
import LarkMessageCard
import LarkContainer
import UniversalCardInterface
import UniversalCard

private struct Styles {
    static let PinContentMaxHeight: CGFloat = 240.0
    
}

final class MessageCardViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: MessageCardViewModelContext>: MessageSubViewModel<M, D, C> {

    private var useUniversalCard: Bool
    override var identifier: String { "MessageCard" }
    let logger = Logger.log(MessageCardViewModel.self, category: "MessageCardViewModel")
    let trace: OPTrace
    var messageCardContainerSharePool: MessageCardContainerSharePoolService?
    var universalCardSharePool: UniversalCardSharePoolProtocol?
    //卡片的高度缓存
    var currentSize: CGSize?
    //单张卡片仅预加载其他业务一次
    var didSetupBizsEnv = false
    @Injected private var cardContextManager: MessageCardContextManagerProtocol

    @FeatureGatingValue(key: "universalcard.resuepooluseuuid.enable")
    var enableReusePoolUseUUID

    @FeatureGatingValue(key: "universalcard.forceupdatecell.enable")
    var enableForceUpdateCell

    //用于卡片复用池标识符
    private let reuseKey: UUID

    var content: CardContent? { message.content as? CardContent }
    var translateContent: CardContent? { message.translateContent as? CardContent }
    var getChat: ()->Chat { metaModel.getChat }
    @AtomicObject
    var timing: MessageCardTiming = (
        initCard: nil, setupFinish: nil,
        renderStart: nil, loadStart: nil, loadFinish: nil, renderFinish: nil
    )
    var preferMaxHeight: CGFloat? {
        if context.scene == .pin {
            return Styles.PinContentMaxHeight
        } else {
            return nil
        }
    }

    override func shouldUpdate(_ new: Message) -> Bool { true }

    override var contentConfig: ContentConfig? {
        let backgroundStyle: ContentConfig.BackgroundStyle = context.isMe(message.fromId) ? .white : .gray
        let hasBorder = !(message.isTranslated() && context.scene != .pin)
        // 话题回复不固定气泡的最大宽度，会导致话题回复区域渲染超出气泡
        if (context.scene == .newChat || context.scene == .mergeForwardDetail),
            (message.showInThreadModeStyle && !message.displayInThreadMode) {
            var config = ContentConfig(
                hasMargin: false,
                backgroundStyle: backgroundStyle,
                maskToBounds: true,
                supportMutiSelect: !message.isEphemeral,
                hasBorder: hasBorder
            )
            config.isCard = true
            config.threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
            return config
        } else {
            var config = ContentConfig(
                hasMargin: false,
                backgroundStyle: backgroundStyle,
                maskToBounds: true,
                supportMutiSelect: !message.isEphemeral,
                contentMaxWidth: context.maxCardWidthLimit(message, metaModelDependency.getContentPreferMaxWidth(message)),
                hasBorder: hasBorder
            )
            config.isCard = true
            return config
        }
    }

    init(trace: OPTrace, metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>, reuseKey: UUID) {
        self.trace = trace
        self.reuseKey = reuseKey
        self.useUniversalCard = context.userResolver.fg.staticFeatureGatingValue(with: "messagecard.use.universalcard.enable")
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        self.didStartSetup()
        if useUniversalCard {
            universalCardSharePool = context.pageContainer.resolve(UniversalCardSharePoolProtocol.self)
        } else {
            // FIXME: 迁移统一卡片后删除
            messageCardContainerSharePool = context.pageContainer.resolve(MessageCardContainerSharePoolService.self)
        }
        logger.info("mesageCard: id: \(message.id)  reuseKey: \(reuseKey)")
    }

    // NOTE: 为什么这里要override？
    // 因为经这里会导致隐式的 upcast，导致 crash，这里面通过 as 告诉编译器生成的代码不要做 upcast 绕过此问题
    override func syncToBinder() {
        self.binder.update(with: self as MessageCardViewModel<M, D, C>)
    }

    override func willDisplay() {
        let key: AnyHashable = enableReusePoolUseUUID ? self.reuseKey : message.id
        if useUniversalCard {
            universalCardSharePool?.retainInUse(key)
        } else {
            // FIXME: 迁移统一卡片后删除
            messageCardContainerSharePool?.retainInuse(key)
        }
    }

    override func didEndDisplay() {
        let key: AnyHashable = enableReusePoolUseUUID ? self.reuseKey : message.id
        if useUniversalCard {
            universalCardSharePool?.addReuse(key)
        } else {
            // FIXME: 迁移统一卡片后删除
            messageCardContainerSharePool?.addReuse(key)
        }
    }

    deinit {
        let key: AnyHashable = enableReusePoolUseUUID ? self.reuseKey : message.id
        if useUniversalCard {
            universalCardSharePool?.remove(key)
        } else {
            // FIXME: 迁移统一卡片后删除
            messageCardContainerSharePool?.remove(key)
        }
    }
}


// MARK: 迁移统一卡片后删除
extension MessageCardViewModel: MessageCardActionEventHandler {
    func actionSuccess() {

    }
    
    func actionFail(_ error: Error) {
        self.syncToBinder()
    }
    
    func actionTimeout() {
        if let binder = binder as? MessageCardCommonViewModelBinder<M, D, C> {
            binder.forceRender()
        }
    }
}

extension Message {
    fileprivate func isTranslated() -> Bool {
        return translateContent != nil && (displayRule == .onlyTranslation || displayRule == .withOriginal)
    }
}

