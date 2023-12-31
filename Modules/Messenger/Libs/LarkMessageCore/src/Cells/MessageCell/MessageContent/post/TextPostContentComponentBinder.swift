//
//  TextPostContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/3/19.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkSearchCore
import Homeric
import LKCommonsTracker

final public class TextPostContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: ComponentBinder<C> {
    /// 原文style
    private let maskPostStyle = ASComponentStyle()
    /// 原文props
    private lazy var maskPostProps: MaskPostViewComponent<C>.Props = {
        let maskPostProps = MaskPostViewComponent<C>.Props()
        maskPostProps.titleComponentKey = PostViewComponentConstant.titleKey
        maskPostProps.contentComponentKey = PostViewComponentConstant.contentKey
        maskPostProps.contentComponentTag = PostViewComponentTag.contentTag
        return maskPostProps
    }()

    /// 分割style
    private lazy var centerStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.alignItems = .center
        return style
    }()

    /// 译文style
    private lazy var translateMaskPostStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        /// 让译文默认隐藏，避免跳动
        style.display = .none
        return style
    }()
    /// 译文props
    private let translateMaskPostProps: MaskPostViewComponent<C>.Props = {
        let translateMaskPostProps = MaskPostViewComponent<C>.Props()
        translateMaskPostProps.titleComponentKey = PostViewComponentConstant.translateTitleKey
        translateMaskPostProps.contentComponentKey = PostViewComponentConstant.translateContentKey
        translateMaskPostProps.contentComponentTag = PostViewComponentTag.translateContentTag
        translateMaskPostProps.isTranslate = true
        return translateMaskPostProps
    }()
    /// 翻译 action props
    private lazy var translateActionPostProps: TranslateActionComponent<C>.Props = {
        let props = TranslateActionComponent<C>.Props()
        return props
    }()
    /// 翻译 action style
    private lazy var translateActionStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        /// 让译文默认隐藏，避免跳动
        style.display = .none
        style.justifyContent = .spaceBetween
        return style
    }()

    /// 原文component
    private lazy var postViewComponent: MaskPostViewComponent<C> = {
        return MaskPostViewComponent<C>(props: maskPostProps, style: maskPostStyle)
    }()
    /// 分割Component：line
    private lazy var centerLineComponent: UIViewComponent<C> = {
        let lineStyle = ASComponentStyle()
        lineStyle.flexGrow = 1
        lineStyle.height = CSSValue(cgfloat: 1)
        return UIViewComponent<C>(props: .empty, style: lineStyle)
    }()
    private lazy var centerComponent: ASLayoutComponent<C> = {
        return ASLayoutComponent<C>(style: centerStyle, [centerLineComponent])
    }()
    /// 译文component
    private lazy var translatePostViewComponent: MaskPostViewComponent<C> = {
        return MaskPostViewComponent<C>(props: translateMaskPostProps, style: translateMaskPostStyle)
    }()

    /// 翻译 action component
    private lazy var translateActionComponent: TranslateActionComponent<C> = {
        return TranslateActionComponent<C>(props: translateActionPostProps, style: translateActionStyle)
    }()

    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? TextPostContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        /// 调整postView/translatePostView显示隐藏逻辑
        /// 消息更新，后端push到sdk，sdk再push到前端，此时会给到前端ONLY_TRANSLATION or WITH_ORIGINAL的display_rule，前端check translation信息，如果为空或者不为空但是translation信息中版本号小于消息中版本号，则UI层面如有译文就不再渲染，同时触发新的翻译请求
        switch vm.displayRule {
        /// 原文
        case .noTranslation, .unknownRule:
            maskPostStyle.display = .flex
            centerStyle.display = .none
            translateMaskPostStyle.display = .none
            translateActionStyle.display = .none
        /// 译文
        case .onlyTranslation:
            maskPostStyle.display = .none
            centerStyle.display = .none
            translateMaskPostStyle.display = .flex
            translateActionStyle.display = .flex
            translateMaskPostStyle.marginTop = 0
        /// 原文+译文
        case .withOriginal:
            maskPostStyle.display = .flex
            centerStyle.display = .flex
            centerStyle.marginTop = 8
            translateMaskPostStyle.display = .flex
            translateActionStyle.display = .flex
            translateMaskPostStyle.marginTop = 8
        @unknown default:
            assert(false, "new value")
            break
        }

        /// 群公告不展示翻译
        if vm.isGroupAnnouncement {
            maskPostStyle.display = .flex
            centerStyle.display = .none
            translateMaskPostStyle.display = .none
        }
        /// 拼装原文的一些属性
        self.configMaskPost(vm: vm)
        /// 拼装译文的一些属性
        self.configTranslateMaskPost(vm: vm)

        postViewComponent.props = maskPostProps
        translatePostViewComponent.props = translateMaskPostProps

        /// 分割线颜色调整
        self.centerLineComponent.style.backgroundColor = vm.lineColor
        ///  翻译反馈
        translateActionPostProps.translateFeedBackTapHandler = { [weak vm, weak self] in
            guard let vm = vm, let self = self else { return }
            var trackInfo = self.makeCommonTrackInfo(with: vm)
            trackInfo["click"] = "feedback"
            trackInfo["target"] = "asl_crosslang_translation_card_sub_view"
            Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_CLICK, params: trackInfo))
            vm.translateFeedBackTapHandler()
        }
        translateActionPostProps.translateMoreActionTapHandler = { [weak vm, weak self] view in
            guard let vm = vm, let self = self else { return }
            let trackInfo = self.makeCommonTrackInfo(with: vm)
            Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_SUB_VIEW, params: trackInfo))
            vm.translateMoreTapHandler(view)
        }
    }

    private func makeCommonTrackInfo(with viewModel: TextPostContentViewModel<M, D, C>) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.message.id
        trackInfo["message_language"] = viewModel.message.messageLanguage
        trackInfo["target_language"] = viewModel.message.translateLanguage
        return trackInfo
    }

    private func configMaskPost(vm: TextPostContentViewModel<M, D, C>) {
        guard maskPostStyle.display == .flex else {
            return
        }

        if vm.isGroupAnnouncement {
            maskPostProps.hasMargin = false
            maskPostProps.isNewGroupAnnouncement = true
            if vm.groupAnnouncementNeedBorder {
                maskPostStyle.cornerRadius = 10
                maskPostStyle.boxSizing = .borderBox
                maskPostStyle.border = Border(BorderEdge(width: 1, color: vm.groupAnnouncementBorderColor, style: .solid))
            }
            maskPostStyle.backgroundColor = UIColor.ud.bgFloat
            if vm.hasReaction {
                maskPostStyle.paddingBottom = 0
            } else {
                maskPostStyle.paddingBottom = 8
            }
            maskPostStyle.width = CSSValue(cgfloat: vm.contentMaxWidth)
        }

        maskPostProps.contentMaxWidth = vm.contentMaxWidth
        let showTitle = vm.isShowTitle && !vm.originContent.title.isEmpty && !vm.originContent.isUntitledPost
        maskPostProps.isShowTitle = showTitle
        maskPostProps.titleAttributedText = vm.originContent.titleAttributedString
        maskPostProps.titleText = vm.originContent.title

        maskPostProps.textLinkBlock = { [weak vm] (link) in
            vm?.openURL(link)
        }
        maskPostProps.linkAttributesColor = vm.contextScene == .newChat ? UIColor.ud.B700 : nil
        maskPostProps.activeLinkAttributes = vm.activeLinkAttributes
        maskPostProps.tapHandler = vm.needPostViewTapHandler ? { [weak vm] in
            vm?.postViewTapped()
        } : nil

        maskPostProps.richDelegate = vm
        maskPostProps.richElement = vm.originRichElement
        maskPostProps.richStyleSheets = vm.styleSheets
        maskPostProps.propagationSelectors = vm.propagationSelectors
        maskPostProps.configOptions = vm.configOptions
        maskPostProps.isNewRichComponent = true
        maskPostProps.contentLineSpacing = vm.contentLineSpacing
        maskPostProps.numberOfLines = vm.getContentNumberOfLines()
        maskPostProps.selectionDelegate = vm.getSelectionLabelDelegate()
        /// maskView属性
        maskPostProps.showMoreHandler = { [weak vm] in
            vm?.showMore()
        }
        let hasMargin = vm.isGroupAnnouncement
        // Thread的title、content需要和气泡等宽 但是群公告需要边距 -- 保持左右个12
        if vm.contextScene.isThreadScence(), !hasMargin {
            maskPostProps.marginToLeft = 0
            maskPostProps.marginToRight = 0
        }
        maskPostProps.splitLineColor = vm.lineColor
        maskPostProps.backgroundColors = vm.showMoreMaskBackgroundColors
        /// maskView style
        maskPostProps.isShowMore = vm.isShowMore
        // 流式消息不异步渲染，不然会一直闪
        maskPostProps.displayMode = vm.config.syncDisplayMode ? .sync : .auto
        maskPostProps.textCheckingDetecotor = vm.textCheckingDetecotor
    }

    private func configTranslateMaskPost(vm: TextPostContentViewModel<M, D, C>) {
        guard translateMaskPostStyle.display == .flex else {
            return
        }
        /**
         译文有两种展示模式 只有译文 & 原文加译文 可以在设置里面切换相关的译文展示方式
         如果onlyTranslation表示在原文的基础上直接翻译 故showLeftLine = false
         */
        translateMaskPostProps.isTranslate = true
        translateMaskPostProps.contentMaxWidth = vm.contentMaxWidth
        let showTitle = vm.isShowTitle && !vm.translateContent.title.isEmpty && !vm.translateContent.isUntitledPost
        translateMaskPostProps.isShowTitle = showTitle
        translateMaskPostProps.titleAttributedText = vm.translateContent.titleAttributedString
        translateMaskPostProps.titleText = vm.translateContent.title
        translateMaskPostProps.textLinkBlock = { [weak vm] (link) in
            vm?.openURL(link)
        }
        translateMaskPostProps.linkAttributesColor = vm.contextScene == .newChat ? UIColor.ud.B700 : nil
        translateMaskPostProps.activeLinkAttributes = vm.activeLinkAttributes
        translateMaskPostProps.tapHandler = vm.needPostViewTapHandler ? { [weak vm] in
            vm?.postViewTapped()
        } : nil
        translateMaskPostProps.isNewRichComponent = true
        translateMaskPostProps.richDelegate = vm
        translateMaskPostProps.richElement = vm.translateRichElement
        translateMaskPostProps.richStyleSheets = vm.styleSheets
        translateMaskPostProps.propagationSelectors = vm.propagationSelectors
        translateMaskPostProps.configOptions = vm.configOptions
        translateMaskPostProps.contentLineSpacing = vm.contentLineSpacing
        translateMaskPostProps.numberOfLines = vm.getContentNumberOfLines()
        translateMaskPostProps.selectionDelegate = vm.getSelectionLabelDelegate()
        /// maskView属性
        translateMaskPostProps.showMoreHandler = { [weak vm] in
            vm?.translateShowMore()
        }
        // Thread的title、content需要和气泡等宽,但是群公告的话 需要调整为chat一样
        let hasMargin = vm.isGroupAnnouncement
        if vm.contextScene.isThreadScence(), !hasMargin {
            translateMaskPostProps.marginToLeft = 0
            translateMaskPostProps.marginToRight = 0
        }
        translateMaskPostProps.splitLineColor = vm.lineColor
        /// 背景色
        translateMaskPostProps.backgroundColors = vm.showMoreMaskBackgroundColors
        /// maskView style
        translateMaskPostProps.isShowMore = vm.translateIsShowMore
        // 流式消息不异步渲染，不然会一直闪
        translateMaskPostProps.displayMode = vm.config.syncDisplayMode ? .sync : .auto
        translateMaskPostProps.textCheckingDetecotor = vm.textCheckingDetecotor
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        /// 主轴为y轴，方向为⬇️，原文、分割线、译文从上往下排列
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignSelf = .stretch
        /// 只有消息详情页面不展示翻译更多按钮
        if context is MessageDetailContext {
            translateActionPostProps.needDisplayMoreButton = false
        } else {
            translateActionPostProps.needDisplayMoreButton = true
        }

        var components = [postViewComponent,
                          centerComponent,
                          translatePostViewComponent]

        /// 转发页面不展示翻译相关的 component
        if !(context is MergeForwardContext) {
            components.append(translateActionComponent)
        }

        self._component = ASLayoutComponent<C>(style: style, context: context, components)
    }
}
