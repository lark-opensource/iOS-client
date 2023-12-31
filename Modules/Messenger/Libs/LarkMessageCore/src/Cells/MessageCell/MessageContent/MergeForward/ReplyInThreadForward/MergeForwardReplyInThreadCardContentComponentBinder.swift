//
//  MergeForwardReplyInThreadCardContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/5/24.
//
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkUIKit

class MergeForwardReplyInThreadCardContentBaseComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: NewComponentBinder<M, D, C> {
    let mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel<M, D, C>?
    let mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler<C>?

    init(
        key: String? = nil,
        context: C? = nil,
        mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel<M, D, C>?,
        mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler<C>?
    ) {
        self.mergeForwardViewModel = mergeForwardViewModel
        self.mergeForwardActionHandler = mergeForwardActionHandler
        super.init(key: key, context: context, viewModel: mergeForwardViewModel, actionHandler: mergeForwardActionHandler)
    }
}

final class MergeForwardReplyInThreadCardContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>:
    MergeForwardReplyInThreadCardContentBaseComponentBinder<M, D, C> {
    private var props = MergeForwardReplyInThreadCardContentComponent<C>.Props()
    private lazy var _component: MergeForwardReplyInThreadCardContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: MergeForwardReplyInThreadCardContentComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.mergeForwardViewModel else {
            assertionFailure()
            return
        }
        component.style.width = CSSValue(cgfloat: min(MergeForwardPostCardContentConfig.contentMaxWidth, vm.contentMaxWidth))
        props.title = vm.title
        props.content = vm.contextText
        props.fromTitle = vm.fromTitle
        props.fromAvatarKey = vm.fromAvatar
        props.tapAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.tapAction(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.fromAvatarAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.fromAvatarTap(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.fromTitleAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.fromTitleTap(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.entityId = vm.entityId
        props.showFromSource = vm.isFromChatMember
        if vm.originSize != .zero {
            let imageWarpperProps = ChatImageViewWrapperComponent<C>.Props()
            imageWarpperProps.shouldAnimating = vm.shouldAnimating
            imageWarpperProps.imageMaxSize = vm.imageMaxSize
            imageWarpperProps.imageMinSize = imageWarpperProps.imageMaxSize
            imageWarpperProps.originSize = vm.originSize
            imageWarpperProps.setImageAction = vm.setImageAction
            imageWarpperProps.settingGifLoadConfig = vm.userSettings?.gifLoadConfig
            imageWarpperProps.isShowProgress = false
            imageWarpperProps.isSmallPreview = true
            imageWarpperProps.previewPermission = vm.permissionPreview
            imageWarpperProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
            imageWarpperProps.needShowLoading = false
            imageWarpperProps.imageTappedCallback = { [weak vm] (chatWrapper) in
                vm?.previewImageWith(visibleThumbnail: chatWrapper.imageView)
            }
            component.props.imageWarpperProps = imageWarpperProps
        } else {
            component.props.imageWarpperProps = nil
        }
        component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        _component = MergeForwardReplyInThreadCardContentComponent(props: props, style: style, context: context)
    }
}

final class MergeForwardReplyInThreadCardContentBorderComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>:
    MergeForwardReplyInThreadCardContentBaseComponentBinder<M, D, C> {
    private var props = MergeForwardReplyInThreadCardContentComponent<C>.Props()
    private lazy var _component: MergeForwardReplyInThreadCardContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: MergeForwardReplyInThreadCardContentComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.mergeForwardViewModel else {
            assertionFailure()
            return
        }
        component.style.width = CSSValue(cgfloat: min(MergeForwardPostCardContentConfig.contentMaxWidth, vm.contentMaxWidth))
        props.title = vm.title
        props.content = vm.contextText
        props.fromTitle = vm.fromTitle
        props.fromAvatarKey = vm.fromAvatar
        props.tapAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.tapAction(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.fromAvatarAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.fromAvatarTap(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.fromTitleAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.fromTitleTap(chat: vm.metaModel.getChat(), message: vm.message, content: vm.content)
        }
        props.entityId = vm.entityId
        props.showFromSource = vm.isFromChatMember
        if vm.originSize != .zero {
            let imageWarpperProps = ChatImageViewWrapperComponent<C>.Props()
            imageWarpperProps.shouldAnimating = vm.shouldAnimating
            imageWarpperProps.imageMaxSize = vm.imageMaxSize
            imageWarpperProps.imageMinSize = imageWarpperProps.imageMaxSize
            imageWarpperProps.originSize = vm.originSize
            imageWarpperProps.setImageAction = vm.setImageAction
            imageWarpperProps.settingGifLoadConfig = vm.userSettings?.gifLoadConfig
            imageWarpperProps.isShowProgress = false
            imageWarpperProps.isSmallPreview = true
            imageWarpperProps.previewPermission = vm.permissionPreview
            imageWarpperProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
            imageWarpperProps.needShowLoading = false
            component.props.imageWarpperProps = imageWarpperProps
            imageWarpperProps.imageTappedCallback = { [weak vm] (chatWrapper) in
                vm?.previewImageWith(visibleThumbnail: chatWrapper.imageView)
            }
        } else {
            component.props.imageWarpperProps = nil
        }
        component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.cornerRadius = 10
        style.boxSizing = .borderBox
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        _component = MergeForwardReplyInThreadCardContentComponent(props: props, style: style, context: context)
    }
}
