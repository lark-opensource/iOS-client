//
//  MessageStatusViewModel.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/4/22.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import AsyncComponent
import EEFlexiable
import RxSwift
import Swinject
import LKCommonsLogging
import LarkMessageBase
import EENavigator
import LarkUIKit
import LarkMessengerInterface
import LarkAlertController

public protocol StatusViewModelContext: ViewModelContext {
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func resend(message: Message)
    func isBurned(message: Message) -> Bool
    var scene: ContextScene { get }
    var supportAvatarLeftRightLayout: Bool { get }
}

open class MessageStatusViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StatusViewModelContext>: MessageSubViewModel<M, D, C> {
    public enum StatusType {
        case none
        case fail
        case loading
        case read(readCount: Int32, unreadCount: Int32)
        case ackUrgent(ackCount: Int32, unackCount: Int32)
    }

    // 通过lazy保护下，防止频繁去获取对象，可能导致退出时崩溃
    private lazy var chat: Chat = {
        return metaModel.getChat()
    }()

    // 图片/视频不显示locoal状态
    public var ignoreLocalStatus: Bool {
        return (message.type == .media || message.type == .image) ? message.localStatus != .fail : false
    }

    // 被服务端物理清理的消息不显示已读状态
    public var ignoreReadStatus: Bool {
        return message.isCleaned
    }

    public var status: StatusType = .none
    public var percent: CGFloat = 0
    // UI展示的最小百分比
    public let minSectorPercent: CGFloat = 0.125
    // UI展示的最大百分比
    public let maxSectorPercent: CGFloat = 0.875
    public private(set) var burnTimeText: String?

    public lazy var marginLeft: CGFloat = {
        if self.context.supportAvatarLeftRightLayout {
            return context.isMe(metaModel.message.fromId, chat: metaModel.getChat()) ? 0 : StatusComponentLayoutConstraints.margin
        }
        return StatusComponentLayoutConstraints.margin
    }()

    public lazy var marginRight: CGFloat = {
        if self.context.supportAvatarLeftRightLayout {
            return context.isMe(metaModel.message.fromId, chat: metaModel.getChat()) ? StatusComponentLayoutConstraints.margin : 0
        }
        return 0
    }()

    open override func initialize() {
        calculateStatus(message: self.message)
    }

    open override func update(metaModel: M, metaModelDependency: D?) {
        calculateStatus(message: metaModel.message)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    open override func shouldUpdate(_ new: Message) -> Bool {
        return self.message.localStatus != new.localStatus
            || self.message.unreadCount != new.unreadCount
            || self.message.readCount != new.readCount
            || self.message.burnLife != new.burnLife
            || self.message.burnTime != new.burnTime
            || !context.isBurned(message: message)
    }

    open func showReadStatusDetail() {
        // 单聊不能点击
        guard chat.type != .p2P else { return }
        let body = ReadStatusBody(
            chatID: chat.id,
            messageID: message.id,
            type: .message
        )
        if Display.phone {
            context.navigator(type: .push, body: body, params: nil)
        } else {
            context.navigator(
                type: .present,
                body: body, params: NavigatorParams(
                    wrap: LkNavigationController.self,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                )
            )
        }
    }

    open func resend() {
        if message.localStatus == .fail {
            context.resend(message: message)
        }
    }

    private func calculateStatus(message: Message) {
        percent = 0
        if !context.isMe(message.fromId, chat: metaModel.getChat()) {
            status = .none
            return
        }

        // DLP检测若不通过没有状态
        if message.dlpState == .dlpBlock {
            status = .none
            return
        }

        // 自己发的才有下面状态
        switch message.localStatus {
        case .fakeSuccess:
            status = .none
        case .fail:
            status = .fail
        case .process:
            status = .loading
        case .success:
            status = successStatusType(message: message)
        @unknown default:
            assert(false, "new value")
            status = .none
        }
    }

    private func successStatusType(message: Message) -> StatusType {
        // 和自己的聊天、超大群、和自己的MyAI聊天 不显示已读状态
        if (chat.type == .p2P && context.isMe(chat.chatterId, chat: metaModel.getChat())) || chat.isSuper || chat.isP2PAi { return .none }
        percent = processPercent(
            readCount: message.readCount - 1,
            totalCount: message.unreadCount + message.readCount - 1
        )
        return .read(readCount: message.readCount, unreadCount: message.unreadCount)
    }

    /// 计算已读未读百分比
    private func calculatePercent(readCount: Int32, totalCount: Int32) -> CGFloat {
        //通过response更新到成功态readCount == -1，进度为0
        if readCount == -1 {
            return 0.0
        }
        if totalCount == 0 {
            return 1.0
        }
        let percent = CGFloat(readCount) / CGFloat(totalCount) * 100.0
        if percent == 0 {
            return 0.0
        } else if percent > 0 && percent < 5.56 {
            /// 20度
            return CGFloat(20) / CGFloat(360) * 1.0
        } else if percent >= 5.56 && percent < 90.56 {
            /// 实际百分比
            return percent / 100.0
        } else if percent >= 90.56 && percent < 100.0 {
            /// 326度
            return CGFloat(326) / CGFloat(360) * 1.0
        } else if percent == 100.0 {
            /// 360度
            return 1.0
        } else {
            return 0.0
        }
    }
    /// 在UI展示上对已读未读百分比进行限制
    private func limitPercent(percent: CGFloat) -> CGFloat {
        if (percent > 0) && (percent < minSectorPercent) { return minSectorPercent }
        if (percent > maxSectorPercent) && (percent < 1) { return maxSectorPercent }
        return percent
    }

    private func processPercent(readCount: Int32, totalCount: Int32) -> CGFloat {
        var percent = calculatePercent(readCount: readCount, totalCount: totalCount)
        percent = limitPercent(percent: percent)
        return percent
    }

    // 确认重新发送弹窗
    fileprivate func showResendCheckAlert() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Message_Mobilesendfailedalerttip)
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Message_Mobilesendfailedalertbuttoncancel)
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Message_Mobilesendfailedalertbuttonresend, dismissCompletion: {
            self.resend()
        })
        self.context.navigator(type: .present, controller: alertController, params: nil)
    }
}

final public class MessageStatusComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: StatusContext>: ComponentBinder<C> {
    lazy var props: StatusComponent<C>.Props = {
        let props = StatusComponent<C>.Props()
        return props
    }()

    lazy var style: ASComponentStyle = {
        let style = ASComponentStyle()
        return style
    }()

    private lazy var _component: StatusComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageStatusViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        switch vm.status {
        case .none:
            props.messageStatus = .none
        case .fail:
            props.messageStatus = .failed
        case .loading:
            props.messageStatus = .loading
        case .read, .ackUrgent:
            props.messageStatus = .success(percent: vm.percent)
        }

        props.didTappedLocalStatus = { [weak vm] (_, status) in
            guard status == .failed else {
                return
            }
            vm?.showResendCheckAlert()
        }
        props.didTappedReadStatus = { [weak vm] _ in
            vm?.showReadStatusDetail()
        }
        props.ignoreLocalStatus = vm.ignoreLocalStatus
        props.ignoreReadStatus = vm.ignoreReadStatus
        props.marginLeft = vm.marginLeft
        props.marginRight = vm.marginRight
        self._component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "MessageStatus"
        self._component = StatusComponent(props: props, style: style, context: context)
    }
}
