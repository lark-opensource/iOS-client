//
//  CryptoChatFileAndFolderContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/24.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessengerInterface

public class CryptoBaseFileAndFolderContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext & PageContext>: NewComponentBinder<M, D, C> {
    let fileAndFolderViewModel: FileAndFolderBaseContentViewModel<M, D, C>?
    let fileAndFolderActionHandler: FileAndFolderContentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        fileAndFolderViewModel: FileAndFolderBaseContentViewModel<M, D, C>?,
        fileAndFolderActionHandler: FileAndFolderContentActionHandler<C>?
    ) {
        self.fileAndFolderViewModel = fileAndFolderViewModel
        self.fileAndFolderActionHandler = fileAndFolderActionHandler
        super.init(key: key, context: context, viewModel: fileAndFolderViewModel, actionHandler: fileAndFolderActionHandler)
    }
}

/// 目前file/folder 逻辑及ui侧表现几乎一致，binder层有较大的复用价值
/// 后面二者如果有差异化，可以考虑，两种类型独立binder或实现新子类继承等方式进行扩展
public final class CryptoChatFileAndFolderContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext & PageContext>:
    CryptoBaseFileAndFolderContentComponentBinder<M, D, C> {
    fileprivate let style = ASComponentStyle()
    fileprivate let props = FileViewComponent<C>.Props()

    fileprivate lazy var _component: UIViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private var contentComponent: FileViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = fileAndFolderViewModel else {
            assertionFailure()
            return
        }
        props.preferMaxWidth = vm.contentPreferMaxWidth
        props.limitMaxWidth = true
        props.fileName = vm.name
        props.size = vm.size
        props.icon = vm.icon
        props.statusText = vm.statusText
        props.progress = vm.progress
        props.progressAnimated = vm.progressAnimated
        props.showTopBorder = vm.showTopBorder
        props.dynamicAuthorityEnum = .allow //密聊不用鉴权
        //当scence为聊天界面 且 cell上有reactions情况下 根据UI要求 需要调整底部的间距
        if vm.context.scene == .newChat, vm.showBottomBorder {
            props.bottomSpaceHeight = 0
        } else {
            props.bottomSpaceHeight = 12
        }
        // 这里如果为聊天的话 不展示 BottomBorder
        if vm.context.scene == .newChat {
            props.showBottomBorder = false
        } else {
            props.showBottomBorder = vm.showBottomBorder
        }
        if vm.hasPaddingTop {
            style.paddingTop = 12
        } else {
            style.paddingTop = 0
        }

        props.tapAction = { [weak vm, weak self] _ in
            guard let vm = vm else { return }
            self?.fileAndFolderActionHandler?.tapAction(
                chat: vm.metaModel.getChat(),
                message: vm.message,
                isLan: vm.isLan,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                useLocalChat: vm.useLocalChat,
                canViewInChat: vm.canViewInChat,
                canForward: vm.canForward,
                canSearch: vm.canSearch,
                canSaveToDrive: vm.canSaveToDrive,
                canOfficeClick: vm.canOfficeClick
            )
        }
        props.isShowLanTransIcon = vm.isLan

        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "FileContent"
        let contentStyle = ASComponentStyle()
        self.contentComponent = FileViewComponent(props: props, style: contentStyle, context: context)
        _component = UIViewComponent<C>(props: .empty, style: style)
        _component.setSubComponents([contentComponent])
    }
}

// nolint: duplicated_code - 密聊隔离，不处理
public final class CryptoChatMessageDetailFileAndFolderContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext & PageContext>:
    CryptoBaseFileAndFolderContentComponentBinder<M, D, C> {
    fileprivate let style = ASComponentStyle()
    fileprivate let props = FileViewComponent<C>.Props()

    fileprivate lazy var _component: FileViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = fileAndFolderViewModel else {
            assertionFailure()
            return
        }
        props.preferMaxWidth = vm.contentPreferMaxWidth
        props.limitMaxWidth = true
        props.fileName = vm.name
        props.size = vm.size
        props.icon = vm.icon
        props.statusText = vm.statusText
        props.progress = vm.progress
        props.progressAnimated = vm.progressAnimated

        props.showBottomBorder = vm.showBottomBorder
        props.dynamicAuthorityEnum = .allow //密聊不用鉴权

        props.tapAction = { [weak vm, weak self] _ in
            guard let vm = vm else { return }
            self?.fileAndFolderActionHandler?.tapAction(
                chat: vm.metaModel.getChat(),
                message: vm.message,
                isLan: vm.isLan,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                useLocalChat: vm.useLocalChat,
                canViewInChat: vm.canViewInChat,
                canForward: vm.canForward,
                canSearch: vm.canSearch,
                canSaveToDrive: vm.canSaveToDrive,
                canOfficeClick: vm.canOfficeClick
            )
        }
        props.isShowLanTransIcon = vm.isLan
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "FileContent"
        style.cornerRadius = 10
        style.boxSizing = .borderBox
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        self._component = FileViewComponent<C>(props: props, style: style)
    }
}
// enable-lint: duplicated_code
