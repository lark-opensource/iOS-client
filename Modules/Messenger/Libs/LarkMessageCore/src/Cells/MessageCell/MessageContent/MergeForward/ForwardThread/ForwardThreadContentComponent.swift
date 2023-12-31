//
//  ForwardThreadContentComponent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/3/29.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignFont

public protocol ForwardThreadComponentContext: RevealReplyInTreadComponentContext {}

public protocol ForwardThreadPropsDelegate: AnyObject {
    /// 内部是否还是一个话题转发消息
    func subMessageIsForwardThread(_ message: Message) -> Bool
    /// 发帖人头像、名称
    func senderInfo(_ message: Message) -> (entityID: String, key: String, name: NSAttributedString)
    /// "在 xxx 发布"内容
    func tripInfo(_ message: Message) -> NSAttributedString
    /// 话题回复信息：总数 + 最近5条回复
    func replyInfo(_ message: Message) -> (replyCount: Int32, infos: [RevealReplyInfo])
    /// 得到消息链接化的根消息Renderer
    func componentRenderer(_ message: Message, contentMaxWidth: CGFloat) -> ASComponentRenderer?
}

/// 只是为了方便查看视图层级
final class ForwardThreadContentView: UIView {}

/// 「转发话题外露回复」需求：话题回复、话题使用一套逻辑 & 使用嵌套UI
final class ForwardThreadContentComponent<C: ForwardThreadComponentContext>: ASComponent<ForwardThreadContentComponent.Props, EmptyState, ForwardThreadContentView, C> {
    final class Props: ASComponentProps {
        /// 因为ForwardThreadContentComponent是嵌套结构，所以向内层传递部分属性时需要最终从ForwardThreadContentViewModel获取
        public weak var delegate: ForwardThreadPropsDelegate?
        /// 内容区域的最大宽度
        public var contentMaxWidth: CGFloat = 0
        /// 当前层要渲染的消息
        public var message = Message.transform(pb: Message.PBModel())

        /// 发帖人信息：头像 + 名称
        public var senderInfo: (entityID: String, key: String, name: NSAttributedString) = ("", "", NSAttributedString(string: ""))
        /// "在 xxx 发布"内容
        public var tripInfo: NSAttributedString = NSAttributedString(string: "")

        /// 内部是否还是一个话题转发消息
        public var subMessageIsForwardThread: Bool = false
        /// 是否需要底部间距，在Chat内，border是上层添加的，reaction和卡片会包在一起，
        /// 此时需要去掉卡片内的底部padding，因为上层会统一添加
        public var needPaddingBottom: Bool = true

        /// 话题回复信息：总数 + 最近5条回复
        public var replyInfo: (replyCount: Int32, infos: [RevealReplyInfo]) = (0, [])
    }

    /// 头部：发帖人 + 发帖群
    private let forwardThreadHeaderProps = ForwardThreadHeaderProps()
    private lazy var forwardThreadHeaderComponent: ForwardThreadHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        style.marginLeft = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        style.marginRight = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        return ForwardThreadHeaderComponent<C>(props: self.forwardThreadHeaderProps, style: style)
    }()

    /// 内容：需要动态判断
    private lazy var contentComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        style.marginLeft = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        style.marginRight = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        return ASLayoutComponent(style: style, [])
    }()

    /// 底部评论：复用RevealReplyInTreadComponent
    private lazy var revealReplyInTreadProps: RevealReplyInTreadComponentProps = {
        let props = RevealReplyInTreadComponentProps()
        props.showReplyTip = false
        props.viewColor = UIColor.ud.textPlaceholder
        return props
    }()
    private lazy var revealReplyInTreadComponent: RevealReplyInTreadComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        style.marginBottom = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        style.flexDirection = .column
        style.alignSelf = .stretch
        style.flexGrow = 1
        return RevealReplyInTreadComponent<C>(props: self.revealReplyInTreadProps, style: style)
    }()

    private var messageEngineComponent: MessageListEngineWrapperComponent<C>?

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        // 设置从上往下排列
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        self.setSubComponents([self.forwardThreadHeaderComponent, self.contentComponent, self.revealReplyInTreadComponent])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        // 一定得有子消息、delegate
        guard let subMessage = (self.props.message.content as? MergeForwardContent)?.messages.first, let delegate = self.props.delegate else {
            assertionFailure("should have sub message & delegate, @yuanping")
            return false
        }

        // 头部区域
        self.forwardThreadHeaderProps.senderInfo = self.props.senderInfo
        self.forwardThreadHeaderProps.tripInfo = self.props.tripInfo
        self.forwardThreadHeaderComponent.props = self.forwardThreadHeaderProps
        self.forwardThreadHeaderComponent._style.maxWidth = CSSValue(cgfloat: self.props.contentMaxWidth)
        // reset
        self.contentComponent._style.marginLeft = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)
        self.contentComponent._style.marginRight = CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding)

        // 内容区域需要动态判断，如果小于 150
        if self.props.contentMaxWidth < 150 {
            // 去掉边框
            self.contentComponent._style.cornerRadius = 0
            self.contentComponent._style.boxSizing = .contentBox
            self.contentComponent._style.border = nil
            // 设置占位内容
            let props = UILabelComponentProps()
            props.numberOfLines = 0
            let labelComponent = UILabelComponent(props: props, style: ASComponentStyle(), context: context)
            labelComponent.style.backgroundColor = UIColor.clear
            self.contentComponent.setSubComponents([labelComponent])
            props.attributedText = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_TooNarrow_ViewTopic_Button,
                                                      attributes: [.font: UDFont.title4, .foregroundColor: UIColor.ud.textTitle])
            labelComponent.props = props
        }
        // 如果内部依然是一个话题转发
        else if self.props.subMessageIsForwardThread {
            // 添加边框
            self.contentComponent._style.cornerRadius = ForwardThreadContentConfig.cornerRadius
            self.contentComponent._style.boxSizing = .borderBox
            self.contentComponent._style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
            // 获取第一条子消息继续嵌套，需要设置边框
            let forwardThreadProps = ForwardThreadContentComponent<C>.Props()
            let style = ASComponentStyle()
            style.cornerRadius = 8
            style.boxSizing = .borderBox
            style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
            let forwardThreadComponent = ForwardThreadContentComponent(props: forwardThreadProps, style: style, context: context)
            self.contentComponent.setSubComponents([forwardThreadComponent])
            // 更新内容
            forwardThreadProps.delegate = delegate
            forwardThreadProps.message = subMessage
            forwardThreadProps.contentMaxWidth = self.props.contentMaxWidth - 2 * ForwardThreadContentConfig.contentPadding
            forwardThreadProps.subMessageIsForwardThread = delegate.subMessageIsForwardThread(subMessage)
            forwardThreadProps.senderInfo = delegate.senderInfo(subMessage)
            forwardThreadProps.tripInfo = delegate.tripInfo(subMessage)
            forwardThreadProps.replyInfo = delegate.replyInfo(subMessage)
            forwardThreadComponent.props = forwardThreadProps
        }
        // 如果内部是一个普通消息，则使用消息链接化方案进行渲染，去掉边框
        else {
            self.contentComponent._style.cornerRadius = 0
            self.contentComponent._style.boxSizing = .contentBox
            self.contentComponent._style.border = nil
            // 消息内容的左右间距渲染引擎内部决定，因为复用的子组件内部自己处理了contentPadding
            self.contentComponent._style.marginLeft = 0
            self.contentComponent._style.marginRight = 0
            if let renderer = delegate.componentRenderer(subMessage, contentMaxWidth: self.props.contentMaxWidth + 2 * ForwardThreadContentConfig.contentPadding) { // 加上左右间距
                if let engineComponent = messageEngineComponent {
                    engineComponent.props.renderer = renderer
                    self.contentComponent.setSubComponents([engineComponent])
                } else {
                    let props = MessageListEngineWrapperComponent<C>.Props(renderer: renderer)
                    let messageEngineComponent = MessageListEngineWrapperComponent(props: props, style: ASComponentStyle(), context: context)
                    messageEngineComponent.props = props
                    self.messageEngineComponent = messageEngineComponent
                    self.contentComponent.setSubComponents([messageEngineComponent])
                }
            }
        }

        // 底部评论，如果没有话题回复，则不展示
        if self.props.replyInfo.replyCount <= 0 {
            self.contentComponent._style.marginBottom = props.needPaddingBottom ? CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding) : 0
            self.revealReplyInTreadComponent._style.display = .none
        } else {
            self.contentComponent._style.marginBottom = 8
            self.revealReplyInTreadComponent._style.display = .flex
            self.revealReplyInTreadComponent._style.marginBottom = props.needPaddingBottom ? CSSValue(cgfloat: ForwardThreadContentConfig.contentPadding) : 0
            self.revealReplyInTreadProps.totalReplyCount = self.props.replyInfo.replyCount
            self.revealReplyInTreadProps.replyInfos = self.props.replyInfo.infos
            self.revealReplyInTreadProps.contentPreferMaxWidth = self.props.contentMaxWidth
            self.revealReplyInTreadProps.outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.ud.textCaption])
            self.revealReplyInTreadComponent.props = self.revealReplyInTreadProps
        }

        return true
    }
}
