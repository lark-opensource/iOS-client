//
//  MomentsCommentCellComponent.swift
//  Moment
//
//  Created by zc09v on 2021/1/7.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageCore
import LarkSetting
import LarkContainer

final class CommentCellProps: ASComponentProps {
    var contentComponent: ComponentWithContext<BaseMomentContext>
    // 子组件
    var subComponents: [MomentsEntitySubType: ComponentWithContext<BaseMomentContext>] = [:]
    // 头像和名字
    var userName: String = ""
    var isOfficialUser: Bool = false
    var extraFields: [String] = []
    var avatarKey: String = ""
    var avatarId: String = ""
    var replyCommentMaxWidth: CGFloat = 0
    var replyCommentAttributedString: NSAttributedString?
    var createFormatTime: String = ""
    var avatarTapped: (() -> Void)?
    var thumbsupTapped: (() -> Void)?
    var thumbsUpUseAnimation = false
    var reactionCount: Int32 = 0
    var canReaction = true
    var canComment = true
    var isRecommend: Bool = false
    init(contentComponent: ComponentWithContext<BaseMomentContext>) {
        self.contentComponent = contentComponent
    }
}

struct MomentCommentCellConsts {
    static let avatarKey = "comment-cell-avatar"
    static let contentContainerKey = "post_content_container"
}

final class MomentsCommentCellComponent: ASComponent<CommentCellProps, EmptyState, UIView, BaseMomentContext> {
    let userResolver: UserResolver
    init(userResolver: UserResolver, props: CommentCellProps, style: ASComponentStyle, context: BaseMomentContext? = nil) {
        self.userResolver = userResolver
        super.init(props: props, style: style, context: context)
        setSubComponents([
            contentComponent
        ])
    }

    /// warp topConatiner and backConatiner
    private lazy var contentComponent: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [topConatiner, backConatiner])
    }()

    /// 最顶部区域 头像、名称
    lazy var topConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.marginTop = 8
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.extra_fields_ui") ?? false
        if fgValue {
            return ASLayoutComponent(style: style, context: context, [avatar, newName])
        } else {
            return ASLayoutComponent(style: style, context: context, [avatar, oldName])
        }
    }()

    /// 头像
    lazy var avatar: AvatarComponent<BaseMomentContext> = {
        let props = AvatarComponent<BaseMomentContext>.Props()
        props.key = MomentPostCellConsts.avatarKey
        props.showMedalImageView = false
        let style = ASComponentStyle()
        style.width = 24
        style.height = 24
        style.flexGrow = 0
        style.flexShrink = 0
        style.marginLeft = 16
        return AvatarComponent(props: props, style: style)
    }()

    /// 名字
    lazy var newName: NewMomentsUserInfoAndCreateTimeComponent<BaseMomentContext> = {
        let props = NewMomentsUserInfoAndCreateTimeComponentProps()
        props.nameFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        props.nameColor = UIColor.ud.N900
        props.subInfoFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        style.flexGrow = 1
        style.marginRight = 16
        style.marginBottom = 4
        return NewMomentsUserInfoAndCreateTimeComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 名字
    lazy var oldName: MomentsUserNameLabelComponent<BaseMomentContext> = {
        let props = MomentsUserNameLabelComponent<BaseMomentContext>.Props()
        props.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        props.textColor = UIColor.ud.N900
        props.numberOfLines = 1
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        style.flexGrow = 1
        return MomentsUserNameLabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    lazy var replyComponent: MomentsCommentReplyCellComponent<BaseMomentContext> = {
        let props = MomentsCommentReplyCellComponent<BaseMomentContext>.Props()
        let style = ASComponentStyle()
        return MomentsCommentReplyCellComponent<BaseMomentContext>(props: props, style: style)
    }()

    lazy var contentContainComponent: UIViewComponent<BaseMomentContext> = {
        let props = ASComponentProps()
        props.key = MomentCommentCellConsts.contentContainerKey
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.marginTop = 1
        return UIViewComponent<BaseMomentContext>(props: props, style: style, context: context)
    }()

    /// 内容 +  footer统一容器，用于统一控制边距
    lazy var backConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginBottom = 16
        style.marginLeft = 48
        style.marginRight = 16
        return ASLayoutComponent(style: style, context: context, [])
    }()

    //(subcomponents) + 时间 + 快速点赞等
    private lazy var footerContainer: ASLayoutComponent<BaseMomentContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.flexDirection = .column
        return ASLayoutComponent<BaseMomentContext>(style: wrapperStyle, [])
    }()

    //时间 + 快速点赞
    private lazy var timeAndReactionContainer: ASLayoutComponent<BaseMomentContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.flexDirection = .row
        wrapperStyle.justifyContent = .spaceBetween
        wrapperStyle.width = 100%
        wrapperStyle.alignItems = .center
        wrapperStyle.marginTop = 6
        return ASLayoutComponent<BaseMomentContext>(style: wrapperStyle, [createTime, thumbActionContainer])
    }()

    /// 创建时间
    lazy var createTime: UILabelComponent<BaseMomentContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 12)
        props.textColor = UIColor.ud.N500
        props.numberOfLines = 1
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 快速点赞
    private lazy var thumbActionContainer: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.justifyContent = .center
        style.marginTop = -7
        return ASLayoutComponent(style: style, context: context, [thumbsUpComponent, self.countLabelComponent])
    }()

    private lazy var countLabelComponent: UILabelComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.marginLeft = -5
        style.backgroundColor = .clear
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 12)
        props.textAlignment = .center
        props.numberOfLines = 1
        return UILabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    private lazy var thumbsUpComponent: LOTAnimationTapComponent<BaseMomentContext> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        let props = LOTAnimationTapComponent<BaseMomentContext>.Props()
        props.imageDisabled = Resources.momentsThumbsupDisabled
        props.isEnabled = self.props.canReaction
        if self.props.isRecommend {
            /// 当前为推荐序布局方式
            props.animationFilePath = BundleConfig.MomentBundle.path(forResource: "data",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/lightMode") ?? ""
            props.animationFilePathDarkMode = BundleConfig.MomentBundle.path(forResource: "data",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/darkMode")
            /// 评论区的点赞统一变为16大小
            style.height = 33.6
            style.width = 28.8
        } else {
            props.animationFilePath = BundleConfig.MomentBundle.path(forResource: "oldData",
                                                                                       ofType: "json",
                                                                                       inDirectory: "lottie/MomentsThumbsUp/lightMode") ?? ""
            props.animationFilePathDarkMode = BundleConfig.MomentBundle.path(forResource: "oldData",
                                                                                               ofType: "json",
                                                                                               inDirectory: "lottie/MomentsThumbsUp/darkMode")
            /// 评论区的点赞统一变为16大小
            style.height = 37.3
            style.width = 32
        }
        return LOTAnimationTapComponent(props: props, style: style)
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: CommentCellProps, _ new: CommentCellProps) -> Bool {
        setupTopConatiner(props: new)
        setupBackConatiner(props: new)
        setupReplyComponent(props: new)
        return true
    }

    private func setupTopConatiner(props: CommentCellProps) {
        avatar.props.onTapped.value = { [weak props] _ in
            guard let props = props else { return }
            props.avatarTapped?()
        }
        // 名字
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.extra_fields_ui") ?? false
        if fgValue {
            newName.props.name = props.userName
            newName.props.isOfficialUser = props.isOfficialUser
            newName.props.extraFields = props.extraFields
        } else {
            oldName.props.name = props.userName
            oldName.props.isOfficialUser = props.isOfficialUser
        }
        avatar.props.avatarKey = props.avatarKey
        avatar.props.id = props.avatarId
    }

    private func setupReplyComponent(props: CommentCellProps) {
        if let comment = props.replyCommentAttributedString, comment.length != 0 {
            replyComponent.props.preferredMaxWidth = props.replyCommentMaxWidth
            replyComponent.props.replyComment = props.replyCommentAttributedString
            replyComponent.style.display = .flex
        } else {
            replyComponent.style.display = .none
        }
    }

    private func setupBackConatiner(props: CommentCellProps) {
        contentContainComponent.setSubComponents([props.contentComponent])
        createTime.props.text = props.createFormatTime
        if let statusComponent = props.subComponents[.commentStatus], statusComponent._style.display == .flex {
            backConatiner.setSubComponents([replyComponent, contentContainComponent, statusComponent])
        } else {
            var footerSubComponents: [ComponentWithContext<BaseMomentContext>] = []
            /// 不支持展示的内容
            if let partUnsupport = props.subComponents[.partUnsupport], partUnsupport._style.display == .flex {
                partUnsupport._style.marginTop = 12
                footerSubComponents.append(partUnsupport)
            }
            /// reaction
            if let reaction = props.subComponents[.reaction], reaction._style.display == .flex {
                reaction._style.marginTop = 8
                reaction._style.marginRight = 28
                footerSubComponents.append(reaction)
            }
            if props.isRecommend {
                ///当前为推荐序布局方式
                countLabelComponent.props.text = props.reactionCount == 0 ? BundleI18n.Moment.Moments_Like_Button : "\(props.reactionCount)"
                countLabelComponent.props.textColor = self.props.canReaction ? UIColor.ud.textCaption : UIColor.ud.textDisabled
            } else {
                countLabelComponent.props.text = props.reactionCount == 0 ? "" : "\(props.reactionCount)"
                countLabelComponent.props.textColor = self.props.canReaction ? UIColor.ud.N500 : UIColor.ud.textDisabled
            }
            thumbsUpComponent.props.autoPlayWhenTap = props.thumbsUpUseAnimation
            if props.thumbsUpUseAnimation {
                thumbsUpComponent.props.playCompletion = props.thumbsupTapped
                thumbsUpComponent.props.tapHandler = nil
            } else {
                thumbsUpComponent.props.tapHandler = props.thumbsupTapped
                thumbsUpComponent.props.playCompletion = nil
            }
            footerSubComponents.append(timeAndReactionContainer)
            footerContainer.setSubComponents(footerSubComponents)
            backConatiner.setSubComponents([replyComponent, contentContainComponent, footerContainer])
        }
    }
}
