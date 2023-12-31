//
//  MomentPostCellComponent.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageCore
import UniverseDesignColor
import LarkFeatureGating
import LKCommonsTracker
import UIKit

final class RecommendMomentPostCellProps: ASComponentProps {
    var config: MomentPostCellConfig
    var contentComponent: ComponentWithContext<BaseMomentContext>
    // 子组件
    var subComponents: [MomentsEntitySubType: ComponentWithContext<BaseMomentContext>] = [:]
    /// 用户信息组件场景（包含名称，部门，动态创建时间等信息）
    var userInfoScene: UserInfoComponentScene = .feed
    /// actionBar的排列方式
    var arrangementMode: ArrangementMode = .alignLeft
    /// actionBar的组件内容
    var actionBarArray: [String] = []
    // 头像和名字
    var userName: String = ""
    var isOfficialUser: Bool = false
    var avatarKey: String = ""
    var avatarId: String = ""

    /// 当前页面的头像是否可点击（profile页不可点击）
    var avatarCanTap: Bool = true
    var userDepartment: String = ""
    /// 动态交互icon
    var interactiveIcon: String = ""
    /// 动态交互详情
    var interactiveDescription: String = ""
    var createFormatTime: String = ""
    var categoryName: String = ""
    var categoryIconKey: String = ""
    var categoryId: String = ""
    var commentCount: Int32 = 0

    var shareCount: Int32 = 0
    var reactionCount: Int32 = 0
    var avatarTapped: (() -> Void)?
    /// 点赞
    var thumbTapHandler: (() -> Void)?
    /// 点踩
    var trampleTapHandler: (() -> Void)?
    /// 点踩状态
    var trampleState: MomentPostCellViewModel.TrampleIconState = .normal
    var replyTapHandler: (() -> Void)?
    /// 转发
    var forwardTapHandler: (() -> Void)?
    /// 菜单
    var menuTapHandler: ((UIView) -> Void)?
    /// 板块的点击
    var categoryTapHandler: (() -> Void)?
    var thumbsUpUseAnimation = false

    var canReaction = true
    var canComment = true
    var categoryReadable = true
    /// 当前是否有交互信息
    var hasInteractiveInfo: Bool {
        return !interactiveIcon.isEmpty && !interactiveDescription.isEmpty
    }

    /// 当前页面是否可以显示交互信息，profile页面目前不允许显示互动交互信息
    var canShowInteractive: Bool = true

    var shouldShowLastReadTip: Bool = false
    var lastReadTipTap: (() -> Void)?

    init(config: MomentPostCellConfig, contentComponent: ComponentWithContext<BaseMomentContext>) {
        self.config = config
        self.contentComponent = contentComponent
    }
}

final class RecommendMomentPostCellComponent: ASComponent<RecommendMomentPostCellProps, EmptyState, UIView, BaseMomentContext> {

    static let lastReadTipComponentkey = "lastReadTipComponent"

    override init(props: RecommendMomentPostCellProps, style: ASComponentStyle, context: BaseMomentContext? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            interactiveContainer,
            detailContainer
        ])
    }
    /// 新增动态交互信息
    lazy var interactiveContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 40
        style.marginTop = 16
        style.marginRight = 16
        return ASLayoutComponent(style: style, context: context, [momentsinteractiveComponent])
    }()

    /// 上次阅读位置
    private lazy var lastReadTipComponent: LastReadTipComponent<BaseMomentContext> = {
        let props = LastReadTipComponent<BaseMomentContext>.Props()
        props.key = Self.lastReadTipComponentkey
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.width = 100%
        style.marginTop = 4
        style.marginBottom = 12
        return LastReadTipComponent(props: props, style: style)
    }()

    private lazy var momentsinteractiveComponent: MomentsInteractiveBarComponent<BaseMomentContext> = {
        let iconImage = Resources.momentsinteractiveIcon
        let props = MomentsInteractiveBarComponent<BaseMomentContext>.Props()
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return MomentsInteractiveBarComponent(props: props, style: style)
    }()

    lazy var detailContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 0
        style.marginTop = 9
        style.flexDirection = .row
        let detailContainer = ASLayoutComponent(style: style, context: context, [avatarContainer, informationContainer])
        return detailContainer
    }()

    lazy var avatarContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 16
        style.marginTop = 0
        let avatarContainer = ASLayoutComponent(style: style, context: context, [avatar])
        return avatarContainer
    }()

    /// 头像
    lazy var avatar: AvatarComponent<BaseMomentContext> = {
        let props = AvatarComponent<BaseMomentContext>.Props()
        props.key = MomentPostCellConsts.avatarKey
        props.showMedalImageView = false
        let style = ASComponentStyle()
        style.width = 40
        style.height = 40
        /// 防止头像被压缩
        style.flexShrink = 0
        return AvatarComponent(props: props, style: style)
    }()

    lazy var informationContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 0
        style.marginTop = 0
        style.flexGrow = 1
        style.width = 0
        style.flexDirection = .column
        let informationContainer = ASLayoutComponent(style: style, context: context, [topContainer, backContainer])
        return informationContainer
    }()

    /// 用户信息，动态时间
    lazy var topContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.marginTop = 0
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent(style: style, context: context, [userInfoAndCreateTimeContainer, timeComponent])
    }()

    private lazy var timeComponent: UILabelComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginRight = 16
        style.marginLeft = 8
        style.backgroundColor = UIColor.clear
        style.flexShrink = 0
        style.marginTop = 1
        let props = UILabelComponentProps()
        props.text = ""
        props.textColor = UIColor.ud.textPlaceholder
        props.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        props.numberOfLines = 1
        return UILabelComponent(props: props, style: style)
    }()

    /// 用户信息，动态时间相关
    lazy var userInfoAndCreateTimeContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [userInfoAndCreateTimeComponent])
    }()

    lazy var userInfoAndCreateTimeComponentProps: MomentsUserInfoAndCreateTimeComponentProps = {
       return MomentsUserInfoAndCreateTimeComponentProps()
    }()

    /// 这个组件再内部判断了feed detail profile的场景
    /// 在feed的场景不展示时间
    lazy var userInfoAndCreateTimeComponent: MomentsUserInfoAndCreateTimeComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return MomentsUserInfoAndCreateTimeComponent<BaseMomentContext>(props: userInfoAndCreateTimeComponentProps,
                                                                        style: style)
    }()

    private lazy var fromCategoryComponent: FromCategoryBarComponent<BaseMomentContext> = {
        let backgroundColorNormal = UDColor.N50 & UDColor.N300
        let backgroundColorPress = UDColor.N200 & UDColor.N400
        let props = FromCategoryBarComponent<BaseMomentContext>.Props(
            backgroundColorNormal: backgroundColorNormal,
            backgroundColorPress: backgroundColorPress)
        let style = ASComponentStyle()
        style.backgroundColor = backgroundColorNormal
        style.cornerRadius = 4
        return FromCategoryBarComponent(props: props, style: style)
    }()

    lazy var postCagegoryContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        return ASLayoutComponent(style: style, context: context, [fromCategoryComponent])
    }()

    lazy var contentContainComponent: UIViewComponent<BaseMomentContext> = {
        let props = ASComponentProps()
        props.key = MomentPostCellConsts.contentContainerKey
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        return UIViewComponent<BaseMomentContext>(props: props, style: style, context: context)
    }()

    /// 内容 + footer统一容器，用于统一控制边距
    lazy var backContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginLeft = self.props.config.contentNeedAlignAvatar ? 16 : 8
        style.marginRight = 16
        return ASLayoutComponent(style: style, context: context, [])
    }()

    //(subcomponents)热评、reaction
    private lazy var footerContainer: ASLayoutComponent<BaseMomentContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.flexDirection = .column
        return ASLayoutComponent<BaseMomentContext>(style: wrapperStyle, [])
    }()

    /// 工具栏区props
    private lazy var actionBarProps: MomentsActionBarComponent<BaseMomentContext>.Props = {
        let actionBarProps = MomentsActionBarComponent<BaseMomentContext>.Props()
        actionBarProps.thumbTapHandler = { [weak self] in
            self?.props.thumbTapHandler?()
        }

        actionBarProps.trampleTapHandler = { [weak self] in
            self?.props.trampleTapHandler?()
        }

        actionBarProps.replyTapHandler = { [weak self] in
            self?.props.replyTapHandler?()
        }

        actionBarProps.forwardTapHandler = { [weak self] in
            self?.props.forwardTapHandler?()
        }

        actionBarProps.menuTapHandler = { [weak self] view in
            self?.props.menuTapHandler?(view)
        }

        return actionBarProps
    }()

    // 工具栏
    private lazy var actionBarComponent: MomentsActionBarComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginBottom = 4
        style.marginTop = 8
        style.marginLeft = -8
        return MomentsActionBarComponent<BaseMomentContext>(
            props: self.actionBarProps,
            style: style
        )
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: RecommendMomentPostCellProps, _ new: RecommendMomentPostCellProps) -> Bool {
        setuptopContainer(props: new)
        setupbackContainer(props: new)
        updateStyle(props: new)
        return true
    }

    private func setuptopContainer(props: RecommendMomentPostCellProps) {
        avatar.props.onTapped.value = { [weak props] _ in
            guard let props = props, props.avatarCanTap else { return }
            props.avatarTapped?()
        }
        avatar.props.avatarKey = props.avatarKey
        avatar.props.id = props.avatarId
        momentsinteractiveComponent.props.title = props.interactiveDescription
        momentsinteractiveComponent.props.iconKey = props.interactiveIcon
        userInfoAndCreateTimeComponentProps.scene = props.userInfoScene
        userInfoAndCreateTimeComponentProps.name = props.userName
        userInfoAndCreateTimeComponentProps.isOfficialUser = props.isOfficialUser
        userInfoAndCreateTimeComponentProps.department = props.userDepartment
        userInfoAndCreateTimeComponentProps.createTime = props.createFormatTime
        userInfoAndCreateTimeComponent.props = userInfoAndCreateTimeComponentProps
        timeComponent.props.text = props.createFormatTime
    }

    private func setupbackContainer(props: RecommendMomentPostCellProps) {
        fromCategoryComponent.props.title = props.categoryName
        fromCategoryComponent.props.onTapped = props.categoryTapHandler
        fromCategoryComponent.props.iconKey = props.categoryIconKey
        fromCategoryComponent.props.enable = props.categoryReadable
        fromCategoryComponent.style.display = (props.categoryName.isEmpty && props.categoryIconKey.isEmpty && props.categoryId.isEmpty) ? .none : .flex
        contentContainComponent.setSubComponents([props.contentComponent])
        actionBarComponent.props.arrangementMode = props.arrangementMode
        actionBarComponent.props.actionBarArray = props.actionBarArray
        actionBarComponent.props.trampleState = props.trampleState
        actionBarComponent.props.iconColor = .ud.iconN2
        actionBarComponent.props.titleColor = .ud.textCaption
        //有状态时，不会有其他元素
        if let statusComponent = props.subComponents[.postStatus], statusComponent._style.display == .flex {
            statusComponent._style.marginTop = 20
            statusComponent._style.marginBottom = 16
            backContainer.setSubComponents([contentContainComponent, postCagegoryContainer, statusComponent])
        } else {
            var footerSubComponents: [ComponentWithContext<BaseMomentContext>] = []

            /// 存在不支持的内容
            if let partUnsupport = props.subComponents[.partUnsupport], partUnsupport._style.display == .flex {
                partUnsupport._style.marginTop = 15
                footerSubComponents.append(partUnsupport)
            }

            //评论
            if let postComments = props.subComponents[.postComments], postComments._style.display == .flex {
                postComments._style.marginTop = 12
                footerSubComponents.append(postComments)
            }

            /// reaction
            actionBarComponent._style.marginBottom = 8
            if let reaction = props.subComponents[.reaction], reaction._style.display == .flex {
                reaction._style.marginTop = 9
                footerSubComponents.append(reaction)
                actionBarComponent._style.marginBottom = 5
                lastReadTipComponent.style.marginBottom = 7
            }

            /// 设置Toolbar
            setupActionToolBar(props: props)
            if footerSubComponents.isEmpty {
                footerContainer.style.display = .none
                footerContainer.setSubComponents([])
                backContainer.setSubComponents([contentContainComponent, postCagegoryContainer, actionBarComponent])
            } else {
                footerContainer.style.display = .flex
                footerContainer.setSubComponents(footerSubComponents)
                backContainer.setSubComponents([contentContainComponent, postCagegoryContainer, footerContainer, actionBarComponent])
            }
        }
        backContainer.style.marginLeft = props.config.contentNeedAlignAvatar ? 16 : 8
    }

    private func setupActionToolBar(props: RecommendMomentPostCellProps) {
        actionBarProps.forwardCount = props.shareCount
        actionBarProps.thumbCount = props.reactionCount
        actionBarProps.replayCount = props.commentCount
        actionBarProps.thumbsUpUseAnimation = props.thumbsUpUseAnimation
        actionBarProps.canComment = props.canComment
        actionBarProps.canReaction = props.canReaction
        actionBarComponent.props = actionBarProps
    }

    private func updateStyle(props: RecommendMomentPostCellProps) {
        lastReadTipComponent.props.tap = props.lastReadTipTap
        lastReadTipComponent.style.display = props.shouldShowLastReadTip ? .flex : .none
        switch props.config.topLayoutStyle {
        case .horizontal:
            postCagegoryContainer.style.marginTop = fromCategoryComponent.style.display == .flex ? 8 : 0
            topContainer.style.marginBottom = backContainer.style.display == .flex ? 4 : 0
            var subComponents: [AsyncComponent.ComponentWithContext<BaseMomentContext>] = []
            if props.hasInteractiveInfo, props.canShowInteractive {
                topContainer.style.marginTop = 0
                subComponents.append(contentsOf: [interactiveContainer, detailContainer])
            } else {
                detailContainer.style.marginTop = 16
                subComponents.append(contentsOf: [detailContainer])
            }
            if props.shouldShowLastReadTip {
                subComponents.append(lastReadTipComponent)
            }
            setSubComponents(subComponents)
        case .vertical:
            userInfoAndCreateTimeContainer.style.marginLeft = 8
            userInfoAndCreateTimeContainer.style.marginRight = 16
            postCagegoryContainer.style.marginTop = fromCategoryComponent.style.display == .flex ? 12 : 4
            userInfoAndCreateTimeContainer.style.marginBottom = backContainer.style.display == .flex ? 4 : 3
            userInfoAndCreateTimeContainer.style.flexGrow = 1
            userInfoAndCreateTimeContainer.style.width = 0
            topContainer.setSubComponents([avatarContainer, userInfoAndCreateTimeContainer])
            topContainer.style.flexDirection = .row
            /// 详情页时，topContainer与avatarContainer设置一个marginLeft即可
            topContainer.style.marginLeft = 0
            if props.hasInteractiveInfo, props.canShowInteractive {
                interactiveContainer.style.marginTop = 0
                topContainer.style.marginTop = 9
                setSubComponents([interactiveContainer, topContainer, backContainer])
            } else {
                topContainer.style.marginTop = 16
                setSubComponents([topContainer, backContainer])
            }
        }
    }

}
