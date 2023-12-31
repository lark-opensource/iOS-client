//
//  AIChatOnboardCardComponent.swift
//  LarkChat
//
//  Created by Zigeng on 2023/11/7.
//

import Foundation
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import EEFlexiable
import UniverseDesignLoading
import UniverseDesignColor
import UniverseDesignIcon
import LarkAI

class AIChatOnboardCardComponent: ASComponent<AIChatOnboardCardComponent.Props, EmptyState, UIView, ChatContext> {
    typealias CardProps = AIChatOnboardCardContentComponent.Props
    final class Props: ASComponentProps {
        var title: String = ""
        var subTitle: String = ""
        var scenes: [OnboardScene] = []
        var hasMoreScene: Bool = true
        var newTopicAction: (Int64, UIView) -> Void = { _, _ in }
        var avatarKey: String = ""
        var isWaitingNewTopic = false
        var avatarTapped: () -> Void = {}
        var allSceneButtonTapAction: () -> Void = {}
        var seceneWillDisplay: ((String) -> Void)?
    }

    public override func render() -> BaseVirtualNode {
        let maxCellWidth = (context?.maxCellWidth ?? UIScreen.main.bounds.width)
        style.width = CSSValue(cgfloat: maxCellWidth)
        return super.render()
    }

    /// 头像
    private lazy var avatarComponent: AvatarComponent<ChatContext> = {
        let avatarProps = AvatarComponent<ChatContext>.Props()
        let avatarStyle = ASComponentStyle()
        avatarStyle.flexShrink = 0
        avatarStyle.width = CSSValue(cgfloat: .auto(30))
        avatarStyle.height = avatarStyle.width
        avatarStyle.display = .flex
        avatarStyle.marginLeft = 4
        return AvatarComponent<ChatContext>(props: avatarProps, style: avatarStyle)
    }()

    private lazy var contentComponent: AIChatOnboardCardContentComponent = {
        let props = CardProps()
        let style = ASComponentStyle()
        style.alignSelf = .stretch
        style.flexGrow = 2
        style.marginLeft = 8
        return AIChatOnboardCardContentComponent(props: props, style: style)
    }()

    lazy var loadingComponent: AIChatOnboardCardLoadingComponent<ChatContext> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.height = 40
        style.alignSelf = .stretch
        style.flexGrow = 2
        style.cornerRadius = 8
        style.marginLeft = 8
        style.ui.masksToBounds = false
        return AIChatOnboardCardLoadingComponent<ChatContext>(props: props, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.flexDirection = .row
        self.style.alignSelf = .flexStart
        self.style.alignItems = .flexStart
        self.style.justifyContent = .flexStart
        self.style.paddingTop = 18
        self.style.paddingBottom = 12
        setSubComponents([avatarComponent, contentComponent, loadingComponent])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        // 更新头像参数
        avatarComponent.props.avatarKey = new.avatarKey
        avatarComponent.props.onTapped.value = { [weak self] _ in
            self?.props.avatarTapped()
        }
        if new.isWaitingNewTopic {
            contentComponent.style.display = .none
            loadingComponent.style.display = .flex
        } else {
            contentComponent.style.display = .flex
            loadingComponent.style.display = .none
            let contentProps = AIChatOnboardCardContentComponent.Props()
            contentProps.scenes = new.scenes
            contentProps.title = new.title
            contentProps.subTitle = new.subTitle
            contentProps.hasMoreScene = new.hasMoreScene
            contentProps.newTopicAction = new.newTopicAction
            contentProps.allSceneButtonTapAction = new.allSceneButtonTapAction
            contentProps.seceneWillDisplay = new.seceneWillDisplay
            contentComponent.props = contentProps
        }
        return true
    }
}

final class AIChatOnboardCardContentComponent: ASComponent<AIChatOnboardCardContentComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var title: String = ""
        var subTitle: String = ""
        var scenes: [OnboardScene] = []
        var hasMoreScene: Bool = true
        var newTopicAction: (Int64, UIView) -> Void = { _, _ in }
        var allSceneButtonTapAction: () -> Void = {}
        var seceneWillDisplay: ((String) -> Void)?
    }

    lazy var collectionComponent: AIChatOnboardCollectionViewComponent = {
        let props = AIChatOnboardCollectionViewComponent.Props()
        let style = ASComponentStyle()
        style.height = 304
        style.alignSelf = .stretch
        style.flexGrow = 2
        return AIChatOnboardCollectionViewComponent(props: props, style: style)
    }()

    lazy var titleLabel: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.font = .boldSystemFont(ofSize: 17.0)
        props.textAlignment = .center
        props.numberOfLines = 0
        props.textColor = .ud.textTitle
        let style = ASComponentStyle()
        style.marginLeft = 11
        style.marginRight = 8
        style.marginTop = 12
        style.marginBottom = 4
        style.alignSelf = .flexStart
        style.backgroundColor = .clear
        let label = UILabelComponent<ChatContext>(props: props, style: style)
        return label
    }()

    lazy var subTitleLabel: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.font = .systemFont(ofSize: 16.0)
        props.numberOfLines = 0
        props.textColor = .ud.textTitle
        let style = ASComponentStyle()
        style.marginLeft = 11
        style.marginRight = 8
        style.marginTop = 4
        style.marginBottom = 8
        style.alignSelf = .flexStart
        style.backgroundColor = .clear
        let label = UILabelComponent<ChatContext>(props: props, style: style)
        return label
    }()

    lazy var allSceneButtonWrapper: UIViewComponent<ChatContext> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.marginLeft = 16
        style.marginRight = 16
        style.marginTop = 8
        style.marginBottom = 16
        style.alignSelf = .center
        style.justifyContent = .center
        style.alignItems = .center
        style.backgroundColor = .clear
        style.flexDirection = .row
        let wrapper = UIViewComponent<ChatContext>(props: props, style: style)
        wrapper.setSubComponents([allSceneButton])
        return wrapper
    }()

    lazy var allSceneButton: OnboardAllSceneButtonViewComponent = {
        let props = OnboardAllSceneButtonViewComponent.Props()
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.justifyContent = .center
        style.alignItems = .center

        style.backgroundColor = .clear
        style.flexDirection = .row
        style.marginLeft = 12
        style.marginRight = 12
        style.height = 32

        style.cornerRadius = 16
//        style.border = Border(BorderEdge(width: 1, color: .ud.lineBorderComponent, style: .solid))
        style.backgroundColor = UDColor.bgBodyOverlay
        let btn = OnboardAllSceneButtonViewComponent(props: props, style: style)
        btn.setSubComponents([allSceneIcon, allSceneLabel])
        return btn
    }()

    lazy var allSceneIcon: UIImageViewComponent<ChatContext> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(
            image: UDIcon.getIconByKey(.scenarioOutlined, iconColor: UIColor.ud.iconN2)
        )}
        let style = ASComponentStyle()
        style.width = 16
        style.height = 16
        style.marginLeft = 12
        style.marginRight = 4
        style.alignSelf = .center
        style.backgroundColor = .clear
        let label = UIImageViewComponent<ChatContext>(props: props, style: style)
        return label
    }()

    lazy var allSceneLabel: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body0
        props.textAlignment = .center
        props.text = BundleI18n.AI.MyAI_IM_AllScenarios_Card_Button
        props.textColor = UDColor.iconN2
        let style = ASComponentStyle()
        style.marginRight = 12
        style.alignSelf = .center
        style.backgroundColor = .clear
        let label = UILabelComponent<ChatContext>(props: props, style: style)
        return label
    }()

    public override init(props: Props, style: ASComponentStyle, context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.flexDirection = .column
        self.style.alignItems = .stretch
        self.style.backgroundColor = .ud.bgBody
        self.style.cornerRadius = 8
        self.style.border = Border(BorderEdge(width: 1, color: .ud.lineBorderCard, style: .solid))
        setSubComponents([titleLabel, subTitleLabel, collectionComponent, allSceneButtonWrapper])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        allSceneButton.props.allSceneButtonTapAction = new.allSceneButtonTapAction
        collectionComponent.props.scenes = new.scenes
        collectionComponent.props.newTopicAction = new.newTopicAction
        collectionComponent.props.seceneWillDisplay = new.seceneWillDisplay
        titleLabel.props.text = new.title
        subTitleLabel.props.text = new.subTitle
        return true
    }
}

final class AIChatOnboardCollectionViewComponent: ASComponent<AIChatOnboardCollectionViewComponent.Props, EmptyState, AIChatOnboardCollectionView, ChatContext> {
    final class Props: ASComponentProps {
        var scenes: [OnboardScene] = []
        var newTopicAction: (Int64, UIView) -> Void = { _, _ in }
        var seceneWillDisplay: ((String) -> Void)?
    }

    override func create(_ rect: CGRect) -> AIChatOnboardCollectionView {
        AIChatOnboardCollectionView(rect)
    }

    public override func update(view: AIChatOnboardCollectionView) {
        super.update(view: view)
        view.scenes = props.scenes
        view.newTopicAction = props.newTopicAction
        view.seceneWillDisplay = props.seceneWillDisplay
        view.reloadData()
    }
}

final class OnboardAllSceneButtonView: UIView {
    var allSceneButtonTapAction: (() -> Void)?
    init(_ frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapped)))
    }

    @objc
    func didTapped() {
        allSceneButtonTapAction?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OnboardAllSceneButtonViewComponent: ASComponent<OnboardAllSceneButtonViewComponent.Props, EmptyState, OnboardAllSceneButtonView, ChatContext> {
    final class Props: ASComponentProps {
        var allSceneButtonTapAction: () -> Void = {}
    }

    override func create(_ rect: CGRect) -> OnboardAllSceneButtonView {
        OnboardAllSceneButtonView(rect)
    }

    public override func update(view: OnboardAllSceneButtonView) {
        super.update(view: view)
        view.allSceneButtonTapAction = props.allSceneButtonTapAction
    }
}
