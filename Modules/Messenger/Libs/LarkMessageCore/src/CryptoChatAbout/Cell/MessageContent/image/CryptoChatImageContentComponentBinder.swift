//
//  CryptoChatImageContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/17.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignColor
import LarkSDKInterface

final class CryptoChatImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ComponentBinder<C> {
    private let imageviewStyle = ASComponentStyle()
    private let imageviewProps = ChatImageViewWrapperComponent<C>.Props()

    private lazy var _component: ChatImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatImageContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.shouldAnimating = vm.shouldAnimating
        imageviewProps.isShowProgress = vm.isShowProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.dynamicAuthorityEnum = .allow
        imageviewProps.imageTappedCallback = { [weak vm] view in
            if let view = view as? ChatImageViewWrapper {
                vm?.imageDidTapped(view)
            }
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

final class CryptoChatMessageDetailImageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ComponentBinder<C> {
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

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatMessageDetailImageContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        imageviewProps.originSize = vm.originSize
        imageviewProps.imageMaxSize = vm.imageMaxSize
        imageviewProps.setImageAction = vm.setImageAction
        imageviewProps.settingGifLoadConfig = vm.userGeneralSettings?.gifLoadConfig
        imageviewProps.sendProgress = vm.sendProgress
        imageviewProps.needShowLoading = !vm.hasInlinePreview
        imageviewProps.imageTappedCallback = { [weak vm] view in
            if let view = view as? ChatImageViewWrapper {
                vm?.imageDidTapped(view)
            }
        }
        imageviewProps.animatedDelegate = vm
        imageviewProps.dynamicAuthorityEnum = .allow
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
