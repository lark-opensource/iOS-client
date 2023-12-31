//
//  NewVoteContentComponent.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/2.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkVote
import UIKit
import UniverseDesignIcon
import UniverseDesignTag
import RichLabel
import LarkRichTextCore
import LKRichView

public final class NewVoteContainerComponent<C: ComponentContext>: ASComponent<NewVoteContentComponent<C>.Props, EmptyState, UIView, C> {

    /// 图标
    private lazy var icon: UIImageViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.width = 16
        style.height = 16
        style.marginTop = 2
        let props = UIImageViewComponentProps()
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    /// 标题
    private lazy var titlelabel: RichViewComponent<C> = {
        let labelProps = RichViewComponentProps()
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 8
        labelStyle.marginRight = 8
        let label = RichViewComponent<C>(props: labelProps, style: labelStyle)
        return label
    }()

    /// 头部容器
    lazy var headerConatiner: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginBottom = 16
        style.marginTop = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        style.width = 100%
        style.alignItems = .flexStart
        style.justifyContent = .flexStart
        return ASLayoutComponent(style: style, context: context, [icon, titlelabel])
    }()

    private lazy var contentContainer: NewVoteContentComponent<C> = {
        let contentProps = NewVoteContentComponent<C>.Props()
        let labelStyle = ASComponentStyle()
        return NewVoteContentComponent(props: contentProps, style: labelStyle)
    }()

    public override init(props: NewVoteContentComponent<C>.Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        setSubComponents([headerConatiner, contentContainer])
        let element = self.getRichTitleElement(props: props)
        self.titlelabel.props.element = element
    }

    public override func willReceiveProps(_ old: NewVoteContentComponent<C>.Props, _ new: NewVoteContentComponent<C>.Props) -> Bool {
        icon.props.image = UDIcon.voteColorful
        self.contentContainer.props = new
        let element = self.getRichTitleElement(props: new)
        let titleProps = RichViewComponentProps()
        titleProps.element = element
        self.titlelabel.props = titleProps
        self.titlelabel._style.width = CSSValue(cgfloat: new.contentPreferMaxWidth - 2 * 12 - 16 - 8)
        return true
    }

    func getRichTitleElement(props: NewVoteContentComponent<C>.Props) -> LKRichElement {
        let props = props.voteViewProps
        let titleFont = UIFont.systemFont(ofSize: 16)
        let element = LKBlockElement(tagName: RichViewAdaptor.Tag.p)
        let textElement = LKTextElement(
            classNames: [RichViewAdaptor.ClassName.text],
            text: props.voteTitle
        ).style(LKRichStyle().font(titleFont).fontSize(.point(titleFont.pointSize)).fontWeight(.bold).color(UIColor.ud.textTitle))
        var children: [Node] = [textElement]
        for tagInfo in props.voteTagInfos {
            let config = UDTag.Configuration(icon: nil,
                                             text: tagInfo,
                                             height: 18,
                                             backgroundColor: UIColor.ud.udtokenTagBgIndigo,
                                             cornerRadius: 4,
                                             horizontalMargin: 4,
                                             iconTextSpacing: 0,
                                             textAlignment: .center,
                                             textColor: UIColor.ud.udtokenTagTextSIndigo,
                                             iconSize: .zero,
                                             iconColor: nil,
                                             font: UIFont.systemFont(ofSize: 12))
            let tagSize = UDTag.sizeToFit(configuration: config)
            let ascentRatio = titleFont.ascender / titleFont.lineHeight
            let tagMargin = 4.0
            let containerSize = CGSize(width: tagSize.width + 2 * tagMargin, height: tagSize.height)
            let typeAttachment = LKAsyncRichAttachmentImp(
                size: containerSize,
                viewProvider: {
                    let tagContainer = UIView(frame: .zero)
                    tagContainer.backgroundColor = .clear
                    let voteTypeTag = UDTag(configuration: config)
                    voteTypeTag.frame.size = tagSize
                    tagContainer.addSubview(voteTypeTag)
                    voteTypeTag.snp.makeConstraints { make in
                        make.centerX.equalToSuperview()
                    }
                    tagContainer.frame.size = containerSize
                    return tagContainer
                },
                ascentProvider: { _ in
                    return containerSize.height * ascentRatio
                },
                verticalAlign: .baseline
            )
            let tagElement = LKAttachmentElement(attachment: typeAttachment)
            children.append(tagElement)
        }
        element.children(children)
        return element
    }
}

public final class NewVoteContentComponent<C: ComponentContext>: ASComponent<NewVoteContentComponent.Props, EmptyState, LarkVoteContentView, C> {
    public final class Props: ASComponentProps {
        public var voteViewProps: LarkVoteContentProps = LarkVoteContentProps()
        // 是否允许折叠
        public var flodEnable: Bool = true
        public var contentPreferMaxWidth: CGFloat = 0
        public var contentPreferMaxHeight: CGFloat = 0
    }

    // 内部有很多view，所以是复合组件
    public override var isComplex: Bool {
        return true
    }

    // 是自己计算大小的
    public override var isSelfSizing: Bool {
        return true
    }

    // 高度计算
    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let width = props.contentPreferMaxWidth
        var height = LarkVoteContentView.calculateContentHeight(props: props.voteViewProps)
        if height > props.contentPreferMaxHeight && props.flodEnable {
            props.voteViewProps.showMoreButtonHidden = false
            height = props.contentPreferMaxHeight
        } else {
            props.voteViewProps.showMoreButtonHidden = true
        }
        return CGSize(width: width, height: height)
    }

    // 更新视图（主线程操作)
    public override func update(view: LarkVoteContentView) {
        super.update(view: view)
        view.updateUI(props.voteViewProps)
    }

    // 创建view
    public override func create(_ rect: CGRect) -> LarkVoteContentView {
        return LarkVoteContentView(props.voteViewProps)
    }
}

public final class NewVoteContentMergeForwardComponent<C: ComponentContext>: ASComponent<NewVoteContentMergeForwardComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        public var title: String = ""
    }
    public override init(props: NewVoteContentMergeForwardComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .stretch
        style.backgroundColor = UDMessageColorTheme.imMessageBgBubblesBlue
        super.init(props: props, style: style, context: context)
        setSubComponents([content])
    }
    private lazy var content: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        props.textColor = UIColor.ud.textTitle
        props.numberOfLines = 1
        props.textAlignment = .center
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.padding = CSSValue(cgfloat: 12)
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        content.props.text = new.title
        return true
    }
}

public final class NewVoteContentPinComponent<C: ComponentContext>: ASComponent<NewVoteContentPinComponent.Props, EmptyState, UIView, C> {

    public final class Props: ASComponentProps {
        public var title: String = ""
        public var setIcon: ((UIImageView) -> Void)?
        public var content: [ComponentWithContext<C>] = []
        public var contentPreferMaxWidth: CGFloat = 0
    }

    private let innerMargin: CSSValue = CSSValue(cgfloat: 12)

    public override init(props: NewVoteContentPinComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .stretch
        style.alignContent = .flexStart
        style.alignSelf = .flexStart
        style.cornerRadius = 4
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        super.init(props: props, style: style, context: context)
        setSubComponents([titleContainer, container])
        updateUI(props: props)
    }

    // header
    private lazy var icon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 18.67.auto()
        style.height = style.width
        style.flexShrink = 0
        style.alignSelf = .center
        style.position = .absolute
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    private lazy var iconBg: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 32.auto()
        style.height = style.width
        style.flexShrink = 0
        style.alignSelf = .center
        style.position = .absolute
        style.cornerRadius = 16
        style.backgroundColor = UIColor.ud.colorfulIndigo
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    private lazy var iconContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.width = 32.auto()
        style.height = style.width
        style.flexShrink = 0
        style.alignSelf = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [iconBg, icon])
    }()

    // Title
    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline
        props.textColor = UIColor.ud.N900
        props.numberOfLines = 1

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        style.marginBottom = 4
        style.height = CSSValue(cgfloat: 22)
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var titleContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        style.marginLeft = 8
        style.marginRight = 36
        style.flexDirection = .row
        style.alignSelf = .flexStart
        style.alignItems = .center
        return ASLayoutComponent(style: style, context: context, [iconContainer, titleLabel])
    }()

    // Container
    lazy var container: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = 48
        style.marginRight = 8
        style.marginBottom = 12
        style.flexDirection = .column
        style.alignSelf = .flexStart
        return ASLayoutComponent(style: style, context: context, [])
    }()

    public override func willReceiveProps(_ old: NewVoteContentPinComponent.Props,
                                          _ new: NewVoteContentPinComponent.Props) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: NewVoteContentPinComponent.Props) {
        style.width = CSSValue(cgfloat: props.contentPreferMaxWidth)
        titleLabel.props.text = props.title
        icon.props.setImage = { [weak props] task in
            props?.setIcon?(task.view)
        }
        container.setSubComponents(props.content)
    }
}

// pin circle
final public class NewVotePinCircleComponentProps: ASComponentProps {
    public var borderWidth = 0.5
    public var borderColor = UIColor.ud.N500
    public var backgroundColor: UIColor = .clear
    public var circleSize = 8.0
}

public final class NewVotePinCircleComponent<C: ComponentContext>: ASComponent<NewVotePinCircleComponentProps, EmptyState, UIView, C> {
    public override func create(_ rect: CGRect) -> UIView {
        return UIView()
    }

    public override func update(view: UIView) {
        view.backgroundColor = props.backgroundColor
        view.layer.borderWidth = props.borderWidth
        view.ud.setLayerBorderColor(props.borderColor)
        view.frame.size = CGSize(width: props.circleSize, height: props.circleSize)
        view.layer.cornerRadius = props.circleSize / 2
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return CGSize(width: props.circleSize, height: props.circleSize)
    }
}
