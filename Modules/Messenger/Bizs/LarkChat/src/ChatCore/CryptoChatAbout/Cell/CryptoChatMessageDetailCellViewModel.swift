//
//  CryptoChatMessageDetailCellViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2021/12/1.
//

import UIKit
import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkCore
import LarkUIKit
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkExtensions
import SuiteAppConfig
import LKCommonsLogging
import RxSwift

final class CryptoChatMessageDetailCellViewModel: MessageDetailMessageCellViewModel {
    init(
        metaModel: MessageDetailMetaModel,
        context: MessageDetailContext,
        contentFactory: MessageDetailMessageSubFactory,
        getContentFactory: @escaping (MessageDetailMetaModel, MessageDetailCellModelDependency) -> MessageSubFactory<MessageDetailContext>,
        metaModelDependency: MessageDetailCellModelDependency,
        subFactories: [SubType: MessageDetailMessageSubFactory]) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { contentComponent in
                return CryptoChatMessageDetailCellComponentBinder(message: metaModel.message, contentComponent: contentComponent, context: context)
            },
            cellLifeCycleObseverRegister: nil
        )
    }

}

final class CryptoChatMessageDetailCellComponentBinder: ComponentBinder<MessageDetailContext> {
    var props: MessageDetailCellProps
    private var _component: MessageDetailCellComponent
    private var chatId: String

    override var component: ComponentWithContext<MessageDetailContext> {
        return _component
    }

    init(message: Message, contentComponent: ComponentWithContext<MessageDetailContext>, context: MessageDetailContext) {
        self.chatId = message.channel.id
        self.props = MessageDetailCellProps(
            contentComponent: contentComponent
        )

        _component = MessageDetailCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatMessageDetailCellViewModel else {
            assertionFailure()
            return
        }
        let chatId = self.chatId
        let userId = vm.message.fromId
        props.showSecretAvatarIcon = true
        props.avatarTapped = { [weak vm] in
            guard let vm, let targetVC = vm.context.pageAPI else { return }
            let body = PersonCardBody(chatterId: userId,
                                      chatId: chatId,
                                      source: .chat)
            vm.context.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        props.avatarLongPressed = { [weak vm] in
            vm?.insertAt()
        }
        props.name = vm.displayName
        props.time = vm.time
        props.messageType = vm.message.type
        props.messageLocalStatus = vm.messageLocalStatus
        props.contentComponent = vm.contentComponent
        props.didTappedLocalStatus = { [weak vm] (_, status) in
            guard status == .failed else {
                return
            }
            vm?.resend()
        }
        props.title = vm.title
        props.translateStatus = .origin
        props.isAutoTranslatedByReceiver = false
        props.isFromMe = vm.isFromMe
        props.isRootMessage = vm.isRootMessage
        props.fromChatter = vm.message.fromChatter
        props.hideUserInfo = vm.hideUserInfo
        props.subComponents = vm.getSubComponents()
        _component.props = props
    }
}
