//
//  MomentsActionBarComponent.swift
//  Moment
//
//  Created by bytedance on 2021/1/10.
//

import Foundation
import RichLabel
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import UIKit

enum MomentsActionBarComponentConstant: String {
    case thumbsUpKey = "MomentsActionBarComponent_thumbsUp_key"
    case trampleDownKey = "MomentsActionBarComponent_trampleDown_key"
    case replykey = "MomentsActionBarComponent_reply_key"
    case forwardKey = "MomentsActionBarComponent_forward_key"
    case moreKey = "MomentsActionBarComponent_more_key"
}
/// MomentsActionBar的排列方式
enum ArrangementMode {
    /// 靠左排列，推荐序的feed页面排列方式
    case alignLeft
    /// 均分显示，推荐序的detail页面排列方式
    case spaceBetween
    /// 无推荐序的排列方式
    case noRecommend
}

final class MomentsActionBarComponent<C: BaseMomentContext>: ASComponent<MomentsActionBarComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {

        public var thumbCount: Int32 = 0
        public var replayCount: Int32 = 0
        public var forwardCount: Int32 = 0
        public var maxWidth: CGFloat = 0
        /// 点赞是否需要动画
        public var thumbsUpUseAnimation: Bool = false
        /// 点赞
        public var thumbTapHandler: (() -> Void)?
        /// 点踩
        public var trampleTapHandler: (() -> Void)?
        public var trampleState: MomentPostCellViewModel.TrampleIconState = .normal
        /// 回复
        public var replyTapHandler: (() -> Void)?
        /// 转发
        public var forwardTapHandler: (() -> Void)?
        /// 菜单
        public var menuTapHandler: ((UIView) -> Void)?
        public var canComment = true
        public var canReaction = true
        /// 将要添加的actionBar的数组，暂时用的MomentsActionBarComponentConstant枚举类进行数组填充，看是否还需要新写一个枚举类
        public var actionBarArray: [String] =
        [MomentsActionBarComponentConstant.thumbsUpKey.rawValue,
         MomentsActionBarComponentConstant.replykey.rawValue,
         MomentsActionBarComponentConstant.forwardKey.rawValue]
        /// actionBar的排列方式
        public var arrangementMode: ArrangementMode = ArrangementMode.noRecommend
        /// action的icon和title颜色
        public var iconColor: UIColor = UIColor.ud.iconN3
        public var titleColor: UIColor = UIColor.ud.N500
    }
    private let thumbText = BundleI18n.Moment.Moments_Like_Button
    private let trampleText = BundleI18n.Moment.Moments_Dislike_Button
    private let replyText = BundleI18n.Moment.Moments_PostMoments_Button
    private let forwardText = BundleI18n.Moment.Moments_ShareMoments_Button

    private lazy var LeftContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.alignItems = .center
        return ASLayoutComponent(style: style, context: context, [thumbActionContainer, replyComponent, forwardButtonComponent])
    }()

    private lazy var thumbActionContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [thumbsUpComponent, countLabelComponent])
    }()

    private lazy var thumbsUpComponent: LOTAnimationTapComponent<C> = {
        var style = ASComponentStyle()
        let props = LOTAnimationTapComponent<C>.Props()
        style.height = 42
        style.width = 36
        if self.props.arrangementMode == .noRecommend {
            props.animationFilePath = BundleConfig.MomentBundle.path(forResource: "oldData",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/lightMode") ?? ""
            props.animationFilePathDarkMode = BundleConfig.MomentBundle.path(forResource: "oldData",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/darkMode")
        } else {
            props.animationFilePath = BundleConfig.MomentBundle.path(forResource: "data",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/lightMode") ?? ""
            props.animationFilePathDarkMode = BundleConfig.MomentBundle.path(forResource: "data",
                                                                         ofType: "json",
                                                                         inDirectory: "lottie/MomentsThumbsUp/darkMode")
        }
        props.key = MomentsActionBarComponentConstant.thumbsUpKey.rawValue
        props.imageDisabled = Resources.momentsThumbsupDisabled
        return LOTAnimationTapComponent(props: props, style: style)
    }()

    private lazy var countLabelComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = -5
        style.backgroundColor = .clear
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 12)
        props.textAlignment = .center
        props.numberOfLines = 1
        if self.props.arrangementMode == .noRecommend {
            props.textColor = self.props.canReaction ? .ud.N500 : .ud.textDisabled
        } else {
            props.textColor = self.props.canReaction ? .ud.textCaption : .ud.textDisabled
        }

        return UILabelComponent<C>(props: props, style: style)
    }()

    private lazy var trampleActionContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        return ASLayoutComponent(style: style, context: context, [trampleDownComponent])
    }()

    private lazy var trampleDownComponent: ActionButtonComponent<C> = {
        var style = ASComponentStyle()
        style.height = 25
        let props = ActionButtonComponent<C>.Props(icon: Resources.momentsTrampleLight, iconSize: 20, titleFont: UIFont.systemFont(ofSize: 12))
        props.title = trampleText
        props.onTapped = { [weak self] (_) in
            self?.props.trampleTapHandler?()
        }
        props.key = MomentsActionBarComponentConstant.trampleDownKey.rawValue
        return ActionButtonComponent(props: props, style: style)
    }()

    private lazy var replyActionContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [replyComponent])
    }()

    private lazy var replyComponent: ActionButtonComponent<C> = {
        var style = ASComponentStyle()
        style.height = 25
        style.alignItems = .center
        let props = ActionButtonComponent<C>.Props(icon: Resources.momentsReply, iconSize: 20, titleFont: UIFont.systemFont(ofSize: 12))
        props.onTapped = { [weak self] (_) in
            self?.props.replyTapHandler?()
        }
        props.key = MomentsActionBarComponentConstant.replykey.rawValue
        return ActionButtonComponent(props: props, style: style)
    }()

    private lazy var forwardActionContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [forwardButtonComponent])
    }()

    private lazy var forwardButtonComponent: ActionButtonComponent<C> = {
        var style = ASComponentStyle()
        style.height = 25
        style.alignItems = .center
        let props = ActionButtonComponent<C>.Props(icon: Resources.momentsForward, iconSize: 20, titleFont: UIFont.systemFont(ofSize: 12))
        props.onTapped = { [weak self] (_) in
            self?.props.forwardTapHandler?()
        }
        props.title = self.props.arrangementMode == .noRecommend ? "" : forwardText
        props.key = MomentsActionBarComponentConstant.forwardKey.rawValue
        return ActionButtonComponent(props: props, style: style)
    }()

    private lazy var moreButtonContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [moreButtonComponent])
    }()

    /// 旧公司圈需要，新公司圈不使用此button
    private lazy var moreButtonComponent: ActionButtonComponent<C> = {
        var style = ASComponentStyle()
        style.justifyContent = .center
        style.alignItems = .center
        style.width = 25
        style.height = 25
        let props = ActionButtonComponent<C>.Props(icon: Resources.momentsMore, iconSize: 20, titleFont: UIFont.systemFont(ofSize: 12))
        props.onTapped = { [weak self] (button) in
            self?.props.menuTapHandler?(button)
        }
        props.key = MomentsActionBarComponentConstant.moreKey.rawValue
        return ActionButtonComponent(props: props, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        //子容器沿主轴均匀分布，位于首尾两端的子容器到父容器的距离是子容器间距的一半。
        style.justifyContent = .spaceBetween
        style.height = 42
        setSubComponents()
    }

    public override func willReceiveProps(_ old: MomentsActionBarComponent<C>.Props, _ new: MomentsActionBarComponent<C>.Props) -> Bool {
        switch props.arrangementMode {
        case .noRecommend:
            replyComponent.props.title = props.replayCount == 0 ? "" : "\(new.replayCount)"
            countLabelComponent.props.text = props.thumbCount == 0 ? "" : "\(new.thumbCount)"
        case .alignLeft, .spaceBetween:
            trampleDownComponent.props.iconColor = props.iconColor
            trampleDownComponent.props.titleColor = props.titleColor
            replyComponent.props.iconColor = props.iconColor
            replyComponent.props.titleColor = props.titleColor
            forwardButtonComponent.props.iconColor = props.iconColor
            forwardButtonComponent.props.titleColor = props.titleColor
            moreButtonComponent.props.iconColor = props.titleColor
            replyComponent.props.title = props.replayCount == 0 ? replyText : "\(new.replayCount)"
            countLabelComponent.props.text = props.thumbCount == 0 ? thumbText : "\(new.thumbCount)"

            switch props.trampleState {
            case .normal:
                trampleDownComponent.props.icon = Resources.momentsTrampleLight
                trampleDownComponent.props.isRotate = false
            case .loading:
                trampleDownComponent.props.icon = Resources.momentsTrampleLoad
                trampleDownComponent.props.isRotate = true
            case .dislike:
                trampleDownComponent.props.icon = Resources.momentsTrampleDark
                trampleDownComponent.props.isRotate = false
            }
        }
        thumbsUpComponent.props.autoPlayWhenTap = props.thumbsUpUseAnimation
        if props.thumbsUpUseAnimation {
            thumbsUpComponent.props.playCompletion = props.thumbTapHandler
            thumbsUpComponent.props.tapHandler = nil
        } else {
            thumbsUpComponent.props.tapHandler = props.thumbTapHandler
            thumbsUpComponent.props.playCompletion = nil
        }

        self.replyComponent.props.isEnabled = props.canComment
        self.thumbsUpComponent.props.isEnabled = props.canReaction

        /// 根据排列方式，和actionBarArray中的内容，返回指定排列方式的所需actionBar
        var actionBarList: [ASLayoutComponent<C>] = []
        if props.arrangementMode != .noRecommend {
            for str in props.actionBarArray {
                switch str {
                case MomentsActionBarComponentConstant.thumbsUpKey.rawValue:
                    actionBarList.append(thumbActionContainer)
                case MomentsActionBarComponentConstant.trampleDownKey.rawValue:
                    actionBarList.append(trampleActionContainer)
                case MomentsActionBarComponentConstant.replykey.rawValue:
                    actionBarList.append(replyActionContainer)
                case MomentsActionBarComponentConstant.forwardKey.rawValue:
                    actionBarList.append(forwardActionContainer)
                case MomentsActionBarComponentConstant.moreKey.rawValue:
                    actionBarList.append(moreButtonContainer)
                default:
                    continue
                }
            }
        }
        /// 根据排列方式，进行布局
        switch props.arrangementMode {
        case .noRecommend:
            replyComponent.style.marginLeft = 48
            replyComponent.props.iconSize = 18
            forwardButtonComponent.style.marginLeft = 48
            forwardButtonComponent.props.iconSize = 18
            moreButtonComponent.props.iconSize = 18
            self.setSubComponents([LeftContainer,
                              moreButtonComponent])
        case .alignLeft:
            for i in 1 ..< actionBarList.count {
                actionBarList[i].style.marginLeft = 48
            }
            self.style.justifyContent = .flexStart
            self.setSubComponents(actionBarList)
        case .spaceBetween:
            self.style.justifyContent = .spaceBetween
            self.setSubComponents(actionBarList)
        }
        return true
    }
}
