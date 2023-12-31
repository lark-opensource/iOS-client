//
//  StickerContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

class BaseStickerContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: NewComponentBinder<M, D, C> {
    let stickerViewModel: StickerContentViewModel<M, D, C>?
    let stickerActionHandler: StickerContentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        stickerViewModel: StickerContentViewModel<M, D, C>?,
        stickerActionHandler: StickerContentActionHandler<C>?
    ) {
        self.stickerViewModel = stickerViewModel
        self.stickerActionHandler = stickerActionHandler
        super.init(key: key, context: context, viewModel: stickerViewModel, actionHandler: stickerActionHandler)
    }
}

final class StickerContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: BaseStickerContentComponentBinder<M, D, C> {
    private let imageviewStyle = ASComponentStyle()
    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.stickerViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.dynamicAuthorityEnum = .allow //表情不受权限管控
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.stickerViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.stickerActionHandler?.imageDidTapped(view: view, chat: vm.metaModel.getChat(), message: vm.message, allMessages: vm.allMessages)
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
            _component.style.cornerRadius = 8
        } else {
            _component.style.cornerRadius = 0
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "StickerContent"
        imageviewProps.needMask = false
        imageviewProps.needBackdrop = false
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle)
    }
}

final class ThreadStickerContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: BaseStickerContentComponentBinder<M, D, C> {
    private let imageviewStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        return style
    }()

    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.stickerViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.dynamicAuthorityEnum = .allow
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.stickerViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.stickerActionHandler?.imageDidTapped(view: view, chat: vm.metaModel.getChat(), message: vm.message, allMessages: vm.allMessages)
        }
        _component.style.border = nil
        _component.style.cornerRadius = 8
        _component.props = imageviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "StickerContent"
        imageviewProps.needMask = false
        imageviewProps.needBackdrop = false
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle)
    }
}

final class MessageDetailStickerContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: BaseStickerContentComponentBinder<M, D, C> {
    private let imageviewStyle = ASComponentStyle()
    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.stickerViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.dynamicAuthorityEnum = .allow
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.stickerViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.stickerActionHandler?.imageDidTapped(view: view, chat: vm.metaModel.getChat(), message: vm.message, allMessages: vm.allMessages)
        }
        imageviewProps.animatedDelegate = vm
        imageviewProps.getGifCurrentIndex = { [weak vm] in
            return vm?.currentFrameIndex ?? 0
        }
        imageviewProps.getGifCurrentFrame = { [weak vm] in
            return vm?.currentFrame
        }
        if vm.shouldAddBorder {
            _component.style.cornerRadius = 8
        } else {
            _component.style.cornerRadius = 0
        }
        _component.props = imageviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "StickerContent"
        imageviewProps.needMask = false
        imageviewProps.needBackdrop = false
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle)
    }
}

final class PinStickerContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: BaseStickerContentComponentBinder<M, D, C> {
    private let imageviewStyle = ASComponentStyle()
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
        guard let vm = self.stickerViewModel else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.dynamicAuthorityEnum = .allow
        imageviewProps.imageTappedCallback = { [weak self] view in
            guard let self = self, let vm = self.stickerViewModel, let view = view as? ChatImageViewWrapper else { return }
            self.stickerActionHandler?.imageDidTapped(view: view, chat: vm.metaModel.getChat(), message: vm.message, allMessages: vm.allMessages)
        }
        _component.props = imageviewProps

        _component.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        _component.style.cornerRadius = 4
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        imageviewProps.key = key ?? "StickerContent"
        imageviewProps.needMask = false
        imageviewProps.needBackdrop = false
        self._component = ChatImageViewWrapperComponent<C>(props: imageviewProps, style: imageviewStyle)
    }
}
