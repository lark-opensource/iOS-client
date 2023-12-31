//
//  CryptoChatTextContentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/10.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import EEFlexiable
import AsyncComponent
import RichLabel
import EENavigator
import LarkContainer
import Swinject
import LarkUIKit
import LarkMessageBase
import ByteWebImage
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFoundation
import LarkSetting
import RustPB
import TangramService

open class CryptoChatTextContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: MessageSubViewModel<M, D, C> {
    private var logger = Logger.log(CryptoChatTextContentViewModel.self, category: "LarkMessage.CryptoChatTextContent")

    public override var identifier: String {
        return "post"
    }

    private let disposeBag = DisposeBag()

    public var contextScene: ContextScene {
        return context.contextScene
    }

    /// 内容的最大宽度
    public var contentMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    /// 链接按压态样式
    public lazy var activeLinkAttributes: [NSAttributedString.Key: Any] = {
        let color = self.context.getColor(for: .Message_Text_ActionPressed, type: self.isFromMe ? .mine : .other)
        return [LKBackgroundColorAttributeName: color]
    }()

    public func isMe(_ id: String) -> Bool {
        return self.context.isMe(id, chat: self.metaModel.getChat())
    }

    /// 是不是我发的消息
    public lazy var isFromMe: Bool = {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }()

    public var hasReaction: Bool {
        return !message.reactions.isEmpty
    }

    public var contentTextFont: UIFont {
        return UIFont.ud.title4
    }

    /// size 发生变化，处理富文本中 attachment size
    override public func onResize() {
        super.onResize()
    }

    /// 原文是否展开，原文译文支持分别展开
    private var isExpand: Bool

    /// 原文showMore
    public var isShowMore: Bool = false {
        didSet {
            if isShowMore != oldValue {
                binder.update(with: self)
                self.update(component: binder.component, animation: isShowMore ? .none : .fade)
            }
        }
    }

    /// 显示的一些常规配置：最大行数等，vm中的部分逻辑会依赖config
    private var config: TextPostConfig

    public var contentLineSpacing: CGFloat {
        return config.contentLineSpacing
    }

    /// 文本内容检查
    public var textCheckingDetecotor: NSRegularExpression?

    /// PostView是否需要添加点击事件
    public var needPostViewTapHandler: Bool = false

    private var phoneNumAndLinkdetecotor: NSRegularExpression? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

    public init(metaModel: M,
                metaModelDependency: D,
                context: C,
                binder: CryptoTextContentComponentBinder<M, D, C>,
                config: TextPostConfig = TextPostConfig()) {
        self.isExpand = config.isAutoExpand
        self.config = config
        /// 新版群公告 -- > 不展示译文
        let sence = context.contextScene
        self.needPostViewTapHandler = config.needPostViewTapHandler

        textCheckingDetecotor = phoneNumAndLinkdetecotor
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override var contentConfig: ContentConfig? {
        return ContentConfig(supportMutiSelect: true)
    }

    /// 当message发生变化时，上层会调用到本方法，后面会调用binder的update(vm)方法
    /// 此方法用来更新vm的数据
    public override func update(metaModel: M, metaModelDependency: D?) {
        /// 获取content
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    /// 点击了原文"显示更多"，该方法会最终由原文maskView调用
    public func showMore() {
        self.isExpand = true
        self.isShowMore = false
    }

    /// 原文最大行数
    public func getContentNumberOfLines() -> Int {
        if isExpand { return 0 }
        return 10
    }

    /// 计算一行最多可以展示的字符数量
    public func getMaxCharCountAtOneLine() -> Int {
        return self.config.calculateMaxCharCountAtOneLine(self.contentMaxWidth)
    }

    public func openURL(_ url: String) {
        do {
            let url = try URL.forceCreateURL(string: url)
            context.navigator(type: .push, url: url, params: nil)
        } catch {
            logger.warn(logId: "url_parse", error.localizedDescription)
        }
    }

    /// 获取 label 选中态 delegate
    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.context.getSelectionLabelDelegate()
    }
}
