//
//  FoldMessageContentComponent.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/9/16.
//

import Foundation
import UIKit
import LarkModel
import RichLabel
import AsyncComponent
import LKRichView
import EEFlexiable
import LarkMessageBase
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignCardHeader

public final class FoldMessageContentComponent<C: AsyncComponent.Context>: ASComponent<FoldMessageContentComponent.Props, EmptyState, FoldMessageView, C> {

    public final class Props: ASComponentProps {

        public var lineStyleColor: UIColor = UIColor.ud.lineDividerDefault
        public var corveStyleColor: UIColor = UIColor.ud.bgFloat

        public var hasMore: Bool = false
        public var foldText: String = ""

        /// 用户头像
        public var foldChatters: [FlodChatter] = []
        public weak var chatterViewDelegate: FlodChatterViewDelegate?
        /// +1按钮
        public weak var approveViewDelegate: FlodApproveViewDelegate?

        public var foldCount: Int32?
        public var foldUserCount: Int32?
        public var foldStyle: FoldMessageStyle = .card

        public weak var richDelegate: LKRichViewDelegate?
        public var richElement: LKRichElement?
        public var richStyleSheets: [CSSStyleSheet] = []
        public var propagationSelectors: [[CSSSelector]] = [] // 冒泡事件
        public var recallAttributedStr: NSAttributedString?
        public var recallTextLinks: [LKTextLink] = []
        public var showFollowBtn: Bool = true
        public var tapBlock: (() -> Void)?
    }

    lazy var labelComponent: RichLabelComponent<C> = {
        let labelProps = RichLabelProps()
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 3
        labelStyle.marginRight = 3
        return RichLabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    lazy var labelComponentContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [labelComponent])
    }()

    lazy var contentLayoutContainter: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.paddingLeft = 12
        style.paddingRight = 12
        style.marginTop = 12
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [contentContainComponent])
    }()

    lazy var contentContainComponent: UDCardHeaderComponent<C> = {
        let props = UDCardHeaderComponentProps()
        var neural = UDCardHeaderHue.neural
        neural.color = UDColor.N50 & UDColor.N200
        neural.maskColor = UDColor.N00.withAlphaComponent(0.2) & UDColor.N00.withAlphaComponent(0.15)
        props.colorHue = neural
        let style = ASComponentStyle()
        style.width = 100%
        style.cornerRadius = 8
        style.alignItems = .center
        style.flexDirection = .column
        style.alignItems = .center
        return UDCardHeaderComponent<C>(props: props, style: style)
    }()

    lazy var contentComponent: RichViewComponent<C> = {
        return RichViewComponent<C>(
            props: RichViewComponentProps(),
            style: ASComponentStyle()
        )
    }()

    lazy var richViewContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 12
        style.marginLeft = 12
        style.marginRight = 12
        return ASLayoutComponent(style: style, context: context, [contentComponent])
    }()

    /// 数量
    private lazy var countLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 1
        props.font = UIFont(name: "DINAlternate-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        props.text = ""
        props.textAlignment = .center
        props.textColor = UIColor.ud.colorfulOrange
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 12
        style.marginRight = 12
        style.marginTop = 6
        style.marginBottom = 12
        return UILabelComponent<C>(props: props, style: style)
    }()

    /// 多少人点赞
    private lazy var userCountContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 16
        style.height = 19
        style.flexDirection = .row
        return ASLayoutComponent(style: style, context: context, [leftLine, userCountLabel, rightLine])
    }()

    private lazy var userCountLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 0
        props.font = .systemFont(ofSize: 12)
        props.text = ""
        props.textColor = UIColor.ud.textCaption
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexGrow = 0
        style.flexShrink = 0
        return UILabelComponent<C>(props: props, style: style)
    }()

    var leftLineProps = GradientComponent<C>.Props()

    lazy var leftLine: ASLayoutComponent<C> = {
        leftLineProps.colors = [props.lineStyleColor.withAlphaComponent(0), props.lineStyleColor.withAlphaComponent(0.15)]
        leftLineProps.locations = [0.0, 1.0]
        leftLineProps.direction = .horizontal
        let leftStyle = ASComponentStyle()
        leftStyle.marginLeft = 12
        leftStyle.marginRight = 15
        leftStyle.width = 100%
        leftStyle.cornerRadius = 0.5
        leftStyle.height = CSSValue(cgfloat: 1)
        leftStyle.backgroundColor = UIColor.clear

        let leftLayoutStyle = ASComponentStyle()
        leftLayoutStyle.flexGrow = 1
        leftLayoutStyle.alignSelf = .center

        return ASLayoutComponent<C>(style: leftLayoutStyle, [
            GradientComponent<C>(props: leftLineProps, style: leftStyle)
        ])
    }()

    var rightLineProps = GradientComponent<C>.Props()

    lazy var rightLine: ASLayoutComponent<C> = {
        rightLineProps.colors = [props.lineStyleColor.withAlphaComponent(0), props.lineStyleColor.withAlphaComponent(0.15)]
        rightLineProps.locations = [1.0, 0.0]
        rightLineProps.direction = .horizontal
        let rightStyle = ASComponentStyle()
        rightStyle.marginLeft = 15
        rightStyle.marginRight = 12
        rightStyle.width = 100%
        rightStyle.cornerRadius = 0.5
        rightStyle.height = CSSValue(cgfloat: 1)
        rightStyle.backgroundColor = UIColor.clear

        let rightLayoutStyle = ASComponentStyle()
        rightLayoutStyle.flexGrow = 1
        rightLayoutStyle.alignSelf = .center
        return ASLayoutComponent<C>(style: rightLayoutStyle, [
            GradientComponent<C>(props: rightLineProps, style: rightStyle)
        ])
    }()

    /// 更多按钮
    private lazy var moreContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 12
        style.marginBottom = 20
        style.width = 100%
        style.justifyContent = .center
        style.alignItems = .center
        return ASLayoutComponent(style: style, context: context, [moreLabel, arrowIcon])
    }()

    private lazy var moreLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 1
        props.font = UIFont.systemFont(ofSize: 12)
        props.text = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_ViewDetails_Button
        props.textColor = UIColor.ud.textCaption
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    private lazy var arrowIcon: TappedImageComponent<C> = {
        let props = TappedImageComponentProps()
        props.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.textCaption)
        props.iconSize = CGSize(width: 12, height: 12)
        let style = ASComponentStyle()
        return TappedImageComponent<C>(props: props, style: style)
    }()

    /// 用户头像容器 用户头像 + 遮罩
    private lazy var userAvatarContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 14
        style.marginLeft = 12
        style.marginRight = 12
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [flodChatterViewComponent,
                                                                  moreCoverComponent])
    }()

    /// 用户头像
    private var flodChatterViewProps = FlodChatterViewComponent<C>.Props()
    private lazy var flodChatterViewComponent: FlodChatterViewComponent<C> = {
        // 撑满容器
        let flodChatterViewStyle = ASComponentStyle()
        flodChatterViewStyle.left = 0
        flodChatterViewStyle.right = 0
        return FlodChatterViewComponent(props: self.flodChatterViewProps, style: flodChatterViewStyle, context: self.context)
    }()
    /// 遮罩
    var moreCoverProps = GradientComponent<C>.Props()

    lazy var moreCoverComponent: ASLayoutComponent<C> = {
        let rightStyle = ASComponentStyle()
        rightStyle.width = 100%
        rightStyle.height = 52
        rightStyle.backgroundColor = UIColor.clear
        rightStyle.position = .absolute
        rightStyle.bottom = -1
        let rightLayoutStyle = ASComponentStyle()
        rightLayoutStyle.position = .absolute
        rightLayoutStyle.left = 0
        rightLayoutStyle.right = 0
        rightLayoutStyle.height = 52
        rightLayoutStyle.backgroundColor = UIColor.clear
        let moreCoverProps = GradientComponent<C>.Props()
        moreCoverProps.colors = [props.corveStyleColor.withAlphaComponent(0),
                                 props.corveStyleColor.withAlphaComponent(1.0)]
        moreCoverProps.locations = [0, 1.0]
        moreCoverProps.direction = .vertical
        let gradientComponent = GradientComponent<C>(props: moreCoverProps, style: rightLayoutStyle)
        return ASLayoutComponent<C>(style: rightStyle, [gradientComponent])
    }()

    /// +1按钮
    private var flodApproveViewProps = FlodApproveViewComponent<C>.Props()
    private lazy var flodApproveViewComponent: FlodApproveViewComponent<C> = {
        // 居中
        let flodApproveViewStyle = ASComponentStyle()
        flodApproveViewStyle.marginTop = 26
        flodApproveViewStyle.height = 36
        flodApproveViewStyle.marginBottom = 24
        flodApproveViewStyle.alignSelf = .center
        // 不能用style.border设置圆角，AsyncComponent会设置masksToBounds，导致烟花动画被裁剪
        // flodApproveViewStyle.border = Border(BorderEdge(width: 1, color: UIColor.ud.primaryContentDefault, style: .solid))
        // flodApproveViewStyle.cornerRadius = 18
        return FlodApproveViewComponent(props: self.flodApproveViewProps, style: flodApproveViewStyle, context: self.context)
    }()

    public override init(props: FoldMessageContentComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
    }

    public override func willReceiveProps(_ old: FoldMessageContentComponent.Props,
                                          _ new: FoldMessageContentComponent.Props) -> Bool {
        if let attr = new.recallAttributedStr {
            labelComponent.props.attributedText = attr
            labelComponent.props.textLinkList = props.recallTextLinks
            setSubComponents([labelComponentContainer])
        } else {
            // 配置用户头像
            flodChatterViewProps.foldChatters = new.foldChatters
            // 配置点击事件
            flodChatterViewProps.delegate = new.chatterViewDelegate
            // 配置+1按钮
            flodApproveViewProps.delegate = new.approveViewDelegate
            flodApproveViewComponent.props = flodApproveViewProps
            flodChatterViewComponent.props = flodChatterViewProps
            flodApproveViewComponent.style.display = new.showFollowBtn ? .flex : .none
            moreCoverComponent.style.display = new.hasMore ? .flex : .none
            moreContainer.style.display = new.hasMore ? .flex : .none
            flodChatterViewComponent.style.marginBottom = 0
            if new.hasMore {
                moreContainer.style.marginBottom = new.showFollowBtn ? 20 : 26
            } else {
                flodChatterViewComponent.style.marginBottom = new.showFollowBtn ? 0 : 26
            }
            countLabel.props.text = "×\(new.foldCount ?? 0)"
            userCountLabel.props.text = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_SentByTotalNum_Text("\(new.foldUserCount ?? 0)")
            countLabel.style.display = new.foldCount == nil ? .none : .flex
            richViewContainer.style.marginBottom = new.foldCount == nil ? 12 : 0
            userCountLabel.style.display = new.foldUserCount == nil ? .none : .flex
            let props = RichViewComponentProps()
            props.delegate = new.richDelegate
            props.element = new.richElement
            props.styleSheets = new.richStyleSheets
            props.propagationSelectors = new.propagationSelectors
            contentComponent.props = props
            contentContainComponent.setSubComponents([richViewContainer, countLabel])
            setSubComponents([contentLayoutContainter,
                              userCountContainer,
                              userAvatarContainer,
                              moreContainer,
                              flodApproveViewComponent])
        }
        return true
    }

    public override func update(view: FoldMessageView) {
        super.update(view: view)
        view.tapBlock = props.tapBlock
    }

}
