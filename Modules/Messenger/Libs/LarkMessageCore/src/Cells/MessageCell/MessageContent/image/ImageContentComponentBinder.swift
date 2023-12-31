//
//  ImageContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/29.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignColor
import UIKit

class BaseImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: NewComponentBinder<M, D, C> {
    let imageViewModel: ImageContentViewModel<M, D, C>?
    let imageActionHandler: ImageContentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        imageViewModel: ImageContentViewModel<M, D, C>?,
        imageActionHandler: ImageContentActionHandler<C>?
    ) {
        self.imageViewModel = imageViewModel
        self.imageActionHandler = imageActionHandler
        super.init(key: key, context: context, viewModel: imageViewModel, actionHandler: imageActionHandler)
    }
}

final class ImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: BaseImageContentComponentBinder<M, D, C> {
    private let imageviewStyle = ASComponentStyle()
    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.imageViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.previewPermission = vm.permissionPreview
        imageviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.imageViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.imageActionHandler?.imageDidTapped(
                view,
                chat: vm.metaModel.getChat(),
                message: vm.metaModel.message,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                allMessages: vm.allMessages,
                canViewInChat: vm.canViewInChat,
                showAddToSticker: vm.showAddToSticker
            )
        }
        imageviewProps.animatedDelegate = vm
        imageviewProps.getGifCurrentIndex = { [weak vm] in
            return vm?.currentFrameIndex ?? 0
        }
        imageviewProps.getGifCurrentFrame = { [weak vm] in
            return vm?.currentFrame
        }
        _component.props = imageviewProps

        if vm.shouldAddBorder {
            _component.style.border = Border(BorderEdge(width: 1 / UIScreen.main.scale, color: UIColor.ud.lineBorderCard, style: .solid))
            _component.style.cornerRadius = 4
        } else {
            _component.style.border = nil
            _component.style.cornerRadius = 0
        }

        _component.style.ui.masksToBounds = true
        _component.style.ui.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase // 对齐聊天页面颜色
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "ImageContent"
        imageviewStyle.ui.masksToBounds = true
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle, context: context)
    }
}

final class ThreadImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: BaseImageContentComponentBinder<M, D, C> {
    private let imageviewStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.border = Border(BorderEdge(width: 1 / UIScreen.main.scale, color: UIColor.ud.lineBorderCard, style: .solid))
        style.cornerRadius = 4
        style.ui.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase // 对齐聊天页面颜色
        return style
    }()

    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.imageViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.previewPermission = vm.permissionPreview
        imageviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.imageViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.imageActionHandler?.imageDidTapped(
                view,
                chat: vm.metaModel.getChat(),
                message: vm.metaModel.message,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                allMessages: vm.allMessages,
                canViewInChat: vm.canViewInChat,
                showAddToSticker: vm.showAddToSticker
            )
        }
        _component.props = imageviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "ImageContent"
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle, context: context)
    }
}

final class MessageDetailImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: BaseImageContentComponentBinder<M, D, C> {
    private let imageviewStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.border = Border(BorderEdge(width: 1 / UIScreen.main.scale, color: UIColor.ud.lineBorderCard, style: .solid))
        style.cornerRadius = 4
        style.ui.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase // 对齐聊天页面颜色
        return style
    }()

    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.imageViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.previewPermission = vm.permissionPreview
        imageviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.imageViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.imageActionHandler?.imageDidTapped(
                view,
                chat: vm.metaModel.getChat(),
                message: vm.metaModel.message,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                allMessages: vm.allMessages,
                canViewInChat: vm.canViewInChat,
                showAddToSticker: vm.showAddToSticker
            )
        }
        imageviewProps.animatedDelegate = vm
        imageviewProps.getGifCurrentIndex = { [weak vm] in
            return vm?.currentFrameIndex ?? 0
        }
        imageviewProps.getGifCurrentFrame = { [weak vm] in
            return vm?.currentFrame
        }
        _component.props = imageviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "ImageContent"
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle, context: context)
    }
}

final class PinImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: BaseImageContentComponentBinder<M, D, C> {
    private lazy var imageviewProps: ChatImageViewWrapperComponent<C>.Props = {
        let props = ChatImageViewWrapperComponent<C>.Props()
        props.imageMaxSize = CGSize(width: 280, height: 310)
        return props
    }()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.imageViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.previewPermission = vm.permissionPreview
        imageviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        imageviewProps.originSize = vm.originSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.imageViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.imageActionHandler?.imageDidTapped(
                view,
                chat: vm.metaModel.getChat(),
                message: vm.metaModel.message,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                allMessages: vm.allMessages,
                canViewInChat: vm.canViewInChat,
                showAddToSticker: vm.showAddToSticker
            )
        }
        _component.props = imageviewProps

        _component.style.border = Border(BorderEdge(width: 1 / UIScreen.main.scale, color: UIColor.ud.lineBorderCard, style: .solid))
        _component.style.cornerRadius = 4
        _component.style.ui.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase // 对齐聊天页面颜色
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "ImageContent"
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: ASComponentStyle(), context: context)
    }
}
