//
//  MomentPostCellComponent.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageCore
import UniverseDesignColor
import LarkFeatureGating
import LKCommonsTracker
import LarkSetting
import LarkContainer

struct MomentPostCellConfig {
    enum Style: Int {
        case horizontal
        case vertical
    }
    // 默认
    static let `default` = MomentPostCellConfig()
    var contentNeedAlignAvatar: Bool = false
    var needShowFollowBut: Bool = false
    var categoryLabelColor: UIColor = UIColor.ud.textCaption
    var topLayoutStyle: Style = .horizontal
}

struct FolowButStyleInfo {
    let border: Border
    let backGroundColor: UIColor
}

struct MomentPostCellConsts {
    static let avatarKey = "post-cell-avatar"
    static let contentContainerKey = "post_content_container"
}

final class MomentPostCellProps: ASComponentProps {
    var config: MomentPostCellConfig
    var contentComponent: ComponentWithContext<BaseMomentContext>
    // 子组件
    var subComponents: [MomentsEntitySubType: ComponentWithContext<BaseMomentContext>] = [:]

    // 头像和名字
    var userName: String = ""
    var isOfficialUser: Bool = false
    var extraFields: [String] = []
    var avatarKey: String = ""
    var avatarId: String = ""

    /// 当前页面的头像是否可点击（profile页不可点击）
    var avatarCanTap: Bool = true
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
    /// 回复
    var replyTapHandler: (() -> Void)?
    /// 转发
    var forwardTapHandler: (() -> Void)?
    /// 菜单
    var menuTapHandler: ((UIView) -> Void)?
    /// 板块的点击
    var categoryTapHandler: (() -> Void)?
    var thumbsUpUseAnimation = false
    var topContainerBottom: CGFloat = 0
    /// 如果需要展示关注，需要提供关注按钮相关参数
    var followButConfig: (CustomIconTextTapComponentProps, FolowButStyleInfo)?

    var canReaction = true
    var canComment = true
    var categoryReadable = true

    init(config: MomentPostCellConfig, contentComponent: ComponentWithContext<BaseMomentContext>) {
        self.config = config
        self.contentComponent = contentComponent
    }
}

final class MomentPostCellComponent: ASComponent<MomentPostCellProps, EmptyState, UIView, BaseMomentContext> {
    let userResolver: UserResolver
    init(userResolver: UserResolver, props: MomentPostCellProps, style: ASComponentStyle, context: BaseMomentContext? = nil) {
        self.userResolver = userResolver
        super.init(props: props, style: style, context: context)
        setSubComponents([
            avatar,
            topConatiner,
            backConatiner
        ])
    }
    /// 最顶部区域 名字 时间、关注
    lazy var topConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.paddingLeft = 64
        style.paddingRight = 16
        style.marginBottom = CSSValue(cgfloat: props.topContainerBottom)
        style.justifyContent = .spaceBetween
        style.width = 100%
        return ASLayoutComponent(style: style, context: context, [userInfoConatiner, followButContainer])
    }()

    /// 用户信息相关
    lazy var userInfoConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexGrow = 1
        return ASLayoutComponent(style: style, context: context, [userPostInfoConatiner])
    }()

    lazy var userPostInfoConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.width = 100%
        return ASLayoutComponent(style: style, context: context, [nameAndTimeContainer, postCagegoryConatiner])
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

    lazy var postCagegoryConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        return ASLayoutComponent(style: style, context: context, [fromCategoryComponent])
    }()

    //名字+时间
    private lazy var nameAndTimeContainer: ASLayoutComponent<BaseMomentContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.flexDirection = .row
        wrapperStyle.marginTop = 16
        wrapperStyle.justifyContent = .spaceBetween
        wrapperStyle.flexGrow = 1
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.extra_fields_ui") ?? false
        if fgValue {
            return ASLayoutComponent<BaseMomentContext>(style: wrapperStyle, [newName, createTime])
        } else {
            return ASLayoutComponent<BaseMomentContext>(style: wrapperStyle, [oldName, createTime])
        }
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
    lazy var backConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginLeft = self.props.config.contentNeedAlignAvatar ? 16 : 64
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
        actionBarProps.replyTapHandler = { [weak self] in
            self?.props.replyTapHandler?()
        }

        actionBarProps.forwardTapHandler = { [weak self] in
            self?.props.forwardTapHandler?()
        }

        actionBarProps.menuTapHandler = { [weak self] (view) in
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

    /// 头像
    lazy var avatar: AvatarComponent<BaseMomentContext> = {
        let props = AvatarComponent<BaseMomentContext>.Props()
        props.key = MomentPostCellConsts.avatarKey
        props.showMedalImageView = false
        let style = ASComponentStyle()
        style.width = 40
        style.height = 40
        style.marginTop = 16
        style.marginLeft = 16
        style.position = .absolute
        return AvatarComponent(props: props, style: style)
    }()

    /// 名字
    lazy var newName: NewMomentsUserInfoAndCreateTimeComponent<BaseMomentContext> = {
        let props = NewMomentsUserInfoAndCreateTimeComponentProps()
        props.nameFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 2
        style.flexGrow = 1
        /// 异常处理 防止服务端返回的name为空，UI展示问题
        style.minHeight = CSSValue(cgfloat: props.nameFont.lineHeight)
        return NewMomentsUserInfoAndCreateTimeComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 名字
    lazy var oldName: MomentsUserNameLabelComponent<BaseMomentContext> = {
        let props = MomentsUserNameLabelComponent<BaseMomentContext>.Props()
        props.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        props.textColor = UIColor.ud.N900
        props.numberOfLines = 2
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 2
        style.flexGrow = 1
        /// 异常处理 防止服务端返回的name为空，UI展示问题
        style.minHeight = CSSValue(cgfloat: props.font.lineHeight)
        return MomentsUserNameLabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 创建时间
    lazy var createTime: UILabelComponent<BaseMomentContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        props.textColor = UIColor.ud.N500
        props.numberOfLines = 1
        let style = ASComponentStyle()
        style.marginTop = 4
        style.backgroundColor = .clear
        // 防止时间被挤压
        style.flexShrink = 0
        return UILabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 关注按钮容器
    lazy var followButContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.height = 28
        style.marginTop = 16
        style.flexShrink = 0
        return ASLayoutComponent(style: style, context: context, [followBut])
    }()

    /// 关注按钮
    lazy var followBut: CustomIconTextTapComponent<BaseMomentContext> = {
        let props = CustomIconTextTapComponentProps()
        let style = ASComponentStyle()
        style.cornerRadius = 8
        style.backgroundColor = .clear
        style.minWidth = 70
        style.alignItems = .center
        style.justifyContent = .center
        return CustomIconTextTapComponent<BaseMomentContext>(props: props, style: style)
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: MomentPostCellProps, _ new: MomentPostCellProps) -> Bool {
        setupTopConatiner(props: new)
        setupBackConatiner(props: new)
        updateStyle(props: new)
        return true
    }

    private func setupTopConatiner(props: MomentPostCellProps) {
        avatar.props.onTapped.value = { [weak props] _ in
            guard let props = props, props.avatarCanTap else { return }
            props.avatarTapped?()
        }
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.extra_fields_ui") ?? false

        if fgValue {
            newName.props.name = props.userName
            newName.props.isOfficialUser = props.isOfficialUser
            //profile页不展示extraFields
            if self.context?.pageAPI?.scene != .profile {
                newName.props.extraFields = props.extraFields
            }
            if props.config.topLayoutStyle == .horizontal {
                newName.props.createTime = nil
                createTime.props.text = props.createFormatTime
                createTime.style.display = .flex
                newName.props.newLineAfterName = false
            } else {
                newName.props.createTime = props.createFormatTime
                createTime.style.display = .none
                newName.props.newLineAfterName = true
            }
        } else {
            oldName.props.name = props.userName
            oldName.props.isOfficialUser = props.isOfficialUser
            createTime.props.text = props.createFormatTime
            createTime.style.display = .flex
        }
        avatar.props.avatarKey = props.avatarKey
        avatar.props.id = props.avatarId
        if let followButConfig = self.props.followButConfig {
            followBut.props = followButConfig.0
            followBut.style.backgroundColor = followButConfig.1.backGroundColor
            followBut.style.border = followButConfig.1.border
            followButContainer.style.display = .flex
        } else {
            followButContainer.style.display = .none
        }
        fromCategoryComponent.props.title = props.categoryName
        fromCategoryComponent.props.onTapped = props.categoryTapHandler
        fromCategoryComponent.props.iconKey = props.categoryIconKey
        fromCategoryComponent.props.enable = props.categoryReadable
        fromCategoryComponent.style.display = (props.categoryName.isEmpty && props.categoryIconKey.isEmpty && props.categoryId.isEmpty) ? .none : .flex
    }

    private func setupBackConatiner(props: MomentPostCellProps) {
        contentContainComponent.setSubComponents([props.contentComponent])
        //有状态时，不会有其他元素
        if let statusComponent = props.subComponents[.postStatus], statusComponent._style.display == .flex {
            statusComponent._style.marginTop = 20
            statusComponent._style.marginBottom = 16
            backConatiner.setSubComponents([contentContainComponent, statusComponent])
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
            }

            /// 设置Toolbar
            setupActionToolBar(props: props)
            if footerSubComponents.isEmpty {
                footerContainer.style.display = .none
                footerContainer.setSubComponents([])
                backConatiner.setSubComponents([contentContainComponent, actionBarComponent])
            } else {
                footerContainer.style.display = .flex
                footerContainer.setSubComponents(footerSubComponents)
                backConatiner.setSubComponents([contentContainComponent, footerContainer, actionBarComponent])
            }
        }
        backConatiner.style.marginLeft = props.config.contentNeedAlignAvatar ? 16 : 64
    }

    private func setupActionToolBar(props: MomentPostCellProps) {
        actionBarProps.forwardCount = props.shareCount
        actionBarProps.thumbCount = props.reactionCount
        actionBarProps.replayCount = props.commentCount
        actionBarProps.thumbsUpUseAnimation = props.thumbsUpUseAnimation
        actionBarProps.canComment = props.canComment
        actionBarProps.canReaction = props.canReaction
        actionBarComponent.props = actionBarProps
    }

    private func updateStyle(props: MomentPostCellProps) {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.extra_fields_ui") ?? false

        switch props.config.topLayoutStyle {
        case .horizontal:
            userPostInfoConatiner.style.paddingLeft = 0
            userPostInfoConatiner.style.paddingRight = 0
            userPostInfoConatiner.style.marginBottom = 0
            nameAndTimeContainer.style.flexDirection = .row
            nameAndTimeContainer.style.justifyContent = .spaceBetween

            if fgValue {
                newName.style.marginRight = 8
            } else {
                oldName.style.marginRight = 8
            }
            userPostInfoConatiner.style.marginBottom = 0
            nameAndTimeContainer.style.alignItems = .flexStart
            postCagegoryConatiner.style.marginTop = fromCategoryComponent.style.display == .flex ? 8 : 4
            userPostInfoConatiner.style.marginBottom = fromCategoryComponent.style.display == .flex ? 8 : 0
            userPostInfoConatiner.setSubComponents([nameAndTimeContainer, postCagegoryConatiner])
            userInfoConatiner.setSubComponents([userPostInfoConatiner])
            setSubComponents([avatar, topConatiner, backConatiner])
        case .vertical:
            userPostInfoConatiner.style.paddingLeft = 16
            userPostInfoConatiner.style.paddingRight = 16
            nameAndTimeContainer.style.flexDirection = .column
            nameAndTimeContainer.style.justifyContent = .flexStart
            if fgValue {
                newName.style.marginRight = 0
            } else {
                oldName.style.marginRight = 0
            }
            postCagegoryConatiner.style.marginTop = fromCategoryComponent.style.display == .flex ? 12 : 4
            userPostInfoConatiner.style.marginBottom = fromCategoryComponent.style.display == .flex ? 8 : 3
            userPostInfoConatiner.setSubComponents([postCagegoryConatiner])
            userInfoConatiner.setSubComponents([nameAndTimeContainer])
            setSubComponents([avatar, topConatiner, userPostInfoConatiner, backConatiner])
        }
    }

}
