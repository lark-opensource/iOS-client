//
//  FeedbackRegenerateComponentBinder.swift
//  LarkAI
//
//  Created by 李勇 on 2023/6/16.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessageCore
import UniverseDesignIcon
import LarkMessengerInterface

public protocol FeedbackRegenerateBinderContext: FeedbackRegenerateViewModelContext & FeedbackRegenerateActionHanderContext {}

final class FeedbackRegenerateComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: FeedbackRegenerateBinderContext>: NewComponentBinder<M, D, C> {
    private lazy var _component: UIViewComponent<C> = .init(props: .init(), style: .init())
    public override var component: UIViewComponent<C> {
        return _component
    }
    private let answerFeedbackViewModel: FeedbackRegenerateComponentViewModel<M, D, C>?
    private let answerFeedbackActionHandler: FeedbackRegenerateComponentActionHandler<C>?

    /// 赞
    private let likeImageProps = UIImageViewComponentProps(key: "feedback_like_image_component_key")
    private lazy var likeImageView: UIImageViewComponent<C> = {
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: 16.auto())
        imageStyle.height = CSSValue(cgfloat: 16.auto())
        imageStyle.alignSelf = .center
        return UIImageViewComponent<C>(props: self.likeImageProps, style: imageStyle)
    }()
    private let likeTouchProps = TouchViewComponentProps(key: "feedback_like_touch_component_key")
    private lazy var likeTouchView: TouchViewComponent<C> = {
        // 增加热区，对TouchView设置hitTestEdgeInsets不生效
        let style = ASComponentStyle()
        style.position = .absolute
        style.left = CSSValue(cgfloat: -6.auto())
        style.top = CSSValue(cgfloat: -4.auto())
        style.height = CSSValue(cgfloat: 28.auto())
        style.width = CSSValue(cgfloat: 28.auto())
        return TouchViewComponent<C>(props: self.likeTouchProps, style: style)
    }()

    /// 踩
    private let dislikeImageProps = UIImageViewComponentProps(key: "feedback_dislike_image_component_key")
    private lazy var dislikeImageView: UIImageViewComponent<C> = {
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: 16.auto())
        imageStyle.height = CSSValue(cgfloat: 16.auto())
        imageStyle.marginLeft = 18.auto()
        imageStyle.alignSelf = .center
        return UIImageViewComponent<C>(props: self.dislikeImageProps, style: imageStyle)
    }()
    private let dislikeTouchProps = TouchViewComponentProps(key: "feedback_dislike_touch_component_key")
    private lazy var dislikeTouchView: TouchViewComponent<C> = {
        // 增加热区，对TouchView设置hitTestEdgeInsets不生效
        let style = ASComponentStyle()
        style.position = .absolute
        style.left = CSSValue(cgfloat: 28.auto())
        style.top = CSSValue(cgfloat: -4.auto())
        style.height = CSSValue(cgfloat: 28.auto())
        style.width = CSSValue(cgfloat: 28.auto())
        return TouchViewComponent<C>(props: self.dislikeTouchProps, style: style)
    }()

    /// 重新生成
    private var regenerateProps = RegenerateButtonComponentProps(key: "regenerate_component_key")
    private lazy var regenerateComponent: RegenerateButtonComponent<C> = {
        let regenerateStyle = ASComponentStyle()
        regenerateStyle.height = CSSValue(cgfloat: 20.auto())
        regenerateStyle.width = CSSValue(cgfloat: 20.auto())
        regenerateStyle.marginLeft = 16.auto()
        return RegenerateButtonComponent(props: self.regenerateProps, style: regenerateStyle)
    }()

    public init(
        key: String? = nil,
        context: C? = nil,
        viewModel: FeedbackRegenerateComponentViewModel<M, D, C>?,
        actionHandler: FeedbackRegenerateComponentActionHandler<C>?
    ) {
        self.answerFeedbackViewModel = viewModel
        self.answerFeedbackActionHandler = actionHandler
        // 快速点击赞icon，会出现此时vm是屏幕内另一条消息，导致在另一条消息留痕，我们把onTapped的赋值放到init中，看能不能避免这个问题
        self.likeTouchProps.onTapped = { [weak viewModel, weak actionHandler] in
            guard let vm = viewModel else { return }
            actionHandler?.didTapLike(chat: vm.metaModel.getChat(), message: vm.metaModel.message)
        }
        self.dislikeTouchProps.onTapped = { [weak viewModel, weak actionHandler] in
            guard let vm = viewModel else { return }
            actionHandler?.didTapDislike(chat: vm.metaModel.getChat(), message: vm.metaModel.message)
        }
        // 设置点击事件
        self.regenerateProps.onTapped = { [weak viewModel, weak actionHandler] in
            guard let vm = viewModel else { return }
            actionHandler?.regenerateClick(chat: vm.metaModel.getChat(), onSuccess: {}, onError: { [weak vm] in
                vm?.currIsLoading = false
            })
            vm.currIsLoading = true
        }
        super.init(key: key, context: context, viewModel: viewModel, actionHandler: actionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle(); style.flexDirection = .row; style.height = CSSValue(cgfloat: 20.auto())
        _component = UIViewComponent<C>(props: .init(key: "feedback_regenerate_component_key"), style: style, context: context)
        _component.setSubComponents([self.likeImageView, self.dislikeImageView, self.likeTouchView, self.dislikeTouchView, self.regenerateComponent])
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.answerFeedbackViewModel else {
            assertionFailure()
            return
        }
        // 控制显隐逻辑
        _component.style.display = vm.currIsShow ? .flex : .none
        // 赞
        let likeKey: UDIconType = vm.message.feedbackStatus == .like ? .thumbsupFilled : .thumbsupOutlined
        self.likeImageProps.setImage = {
            $0.set(image: UDIcon.getIconByKey(likeKey, iconColor: likeKey == .thumbsupFilled ? UIColor.ud.colorfulYellow : UIColor.ud.iconN3, size: CGSize(width: 16.auto(), height: 16.auto())))
        }
        self.likeImageView.props = self.likeImageProps
        // 踩
        let dislikeKey: UDIconType = vm.message.feedbackStatus == .dislike ? .thumbdownFilled : .thumbdownOutlined
        self.dislikeImageProps.setImage = {
            $0.set(image: UDIcon.getIconByKey(dislikeKey, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16.auto(), height: 16.auto())))
        }
        self.dislikeImageView.props = self.dislikeImageProps
        // 重新生成
        if vm.currIsLoading {
            self.regenerateProps.buttonEnable = false
            self.regenerateProps.iconKey = .loadingOutlined
            self.regenerateProps.iconColor = UIColor.ud.primaryContentDefault
            self.regenerateProps.iconRotate = true
        } else {
            self.regenerateProps.buttonEnable = true
            self.regenerateProps.iconKey = .resetOutlined
            self.regenerateProps.iconColor = UIColor.ud.iconN3
            self.regenerateProps.iconRotate = false
        }
        self.regenerateComponent.props = self.regenerateProps
    }
}
