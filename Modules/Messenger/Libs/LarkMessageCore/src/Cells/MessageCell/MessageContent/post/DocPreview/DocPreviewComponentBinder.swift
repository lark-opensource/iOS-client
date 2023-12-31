//
//  DocPreviewComponentBinder.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/19.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkSetting
import LarkContainer
import LarkMessengerInterface
import SwiftyJSON
import ByteWebImage
import LarkModel

final class DocPreviewComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DocPreviewComponentContext & DocPreviewViewModelContext>: ComponentBinder<C> {
    private let props = DocPreviewComponentProps()
    private lazy var _component: DocPreviewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: DocPreviewComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DocPreviewComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.delegate = vm
        props.docAbstract = vm.message.docAbstract
        props.fromVc = vm.context.targetVC
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.permissionText = vm.permissionText
        props.permissionDesc = vm.permissionDesc
        props.singlePageDesc = vm.singlePageDesc
        props.shareText = vm.message.shareText
        props.isFromMe = vm.isFromMe
        props.canSelectPermission = vm.message.docPermission?.optionalPermissions.count ?? 0 > 1 ? true : false
        //判断是否显示底部的提示
        props.bottomHintViewType = getBottomHintViewType(viewModel: vm)
        props.shareStatusText = vm.message.getShareStatusText(chat: vm.metaModel.getChat(), name: vm.metaModel.getChat().name)
        props.contentPadding = vm.contentPadding
        props.shareStatus = vm.message.shareStatus
        props.thumbnailDetail = vm.message.thumbnailDetail
        props.isChatWithMe = vm.isChatMyself
        props.docType = vm.message.docType //文档类型
        props.docKey = vm.message.docKey //文档ID
        props.docOwner = vm.message.doc?.ownerName //文档所有者名字
        props.docOwnerID = vm.message.doc?.ownerID //文档所有者ID
        //如果会话是群，则为群ID，如果是单聊，则为接收方ID
        props.chatID = vm.metaModel.getChat().type == .p2P ? vm.metaModel.getChat().chatterId : vm.metaModel.getChat().id
        props.chatName = vm.metaModel.getChat().name //会话名称
        props.chatIcon = vm.metaModel.getChat().imageKey //会话头像key
        props.description = vm.metaModel.getChat().description //会话描述
        props.isCrossTenanet = vm.metaModel.getChat().isCrossTenant //是否跨租户，用来判断是否显示外部标签
        props.roleType = vm.metaModel.getChat().type == .p2P ? 0 : 2 //会话类型：0:单聊；2:群
        props.receiverPerm = vm.message.docPermission?.receiverPerm ?? 0
        props.userPerm = vm.message.docPermission?.userPerm ?? 0
        props.singlePageState = vm.message.singlePageState
        props.askOwnerDependency = vm.askOwnerDependency
        props.docPermissionDependency = vm.docPermissionDependency
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = DocPreviewComponent(props: props, style: ASComponentStyle(), context: context)
    }

    private func getBottomHintViewType(viewModel: DocPreviewComponentViewModel<M, D, C>) -> BottomHintViewType {
        // 首先要是自己发送的信息
        guard viewModel.isFromMe else {
            return .none
        }
        // 无分享权限 && 接收方无权限 && owner在当前会话中，需要展示 Ask Owner 的提示
        if (viewModel.message.shareStatus == 6 || viewModel.message.shareStatus == 7) &&
            viewModel.message.docPermission?.receiverPerm == 0 &&
            (!viewModel.message.chatIsGroup(chat: viewModel.metaModel.getChat()) || viewModel.message.ownerIsInGroup) {
            return .askOwnerTips
        }
        guard let permission = viewModel.message.docPermission else {
            return .none
        }
        let extraJSON = JSON(parseJSON: permission.extra)
        // 是否是首次分享授权
        let sendCardAuthPerm = extraJSON["send_card_auth_perm"].boolValue
        // 发送者和文档owner是否同租户
        let senderIsExternal = permission.senderIsExternal
        let isCrossTenant = viewModel.metaModel.getChat().isCrossTenant
        if senderIsExternal && !isCrossTenant && sendCardAuthPerm {
            return .internalTips
        } else if !senderIsExternal && isCrossTenant && sendCardAuthPerm {
            return .externalTips
        }
        return .none
    }
}

final class PinDocPreviewComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DocPreviewViewModelContext & DocPreviewComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = MessageBriefComponent<C>.Props()
    private lazy var _component: MessageBriefComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: MessageBriefComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MessageBriefComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinDocPreviewComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.title = vm.message.docTitle
        props.content = vm.displayContent
        let fg = vm.context.getStaticFeatureGating(.init(key: .docCustomAvatarEnable))
        props.setIcon = { [weak vm, weak self] view in
            view.bt.setLarkImage(with: .default(key: self?.customIconKey(message: vm?.message, fg: fg) ?? ""),
                                 placeholder: vm?.message.docIcon,
                                 cacheName: LarkImageService.shared.thumbCache.name,
                                 trackStart: {
                                    TrackInfo(biz: .Messenger, scene: .Chat, fromType: .unknown)
                                 })
        }
        _component.props = props
    }

    /// 当前要预览的Doc自定义图标，pin列表使用
    private func customIconKey(message: Message?, fg: Bool) -> String {
        guard let message = message, let doc = message.doc else { return "" }
        if fg, doc.hasIcon, doc.icon.type == .image {
            return doc.icon.value
        }
        return ""
    }
}
