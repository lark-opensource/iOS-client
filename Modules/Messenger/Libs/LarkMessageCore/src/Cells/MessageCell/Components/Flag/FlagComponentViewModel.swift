//
//  FlagComponentViewModel.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/6/2.
//

import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import RxSwift
import Swinject
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import LarkRustClient
import LKCommonsLogging
import UniverseDesignToast
import LarkSetting
import LKCommonsTracker
import Homeric
import LarkCore

public final class FlagComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: MessageSubViewModel<M, D, C> {

    let logger = Logger.log(FlagComponentViewModel.self, category: "Chat.FlagComponentViewModel")

    var isFlag: Bool {
        return message.isFlag
    }

    func flagIconDidClick() {
        let logStr = self.message.isFlag ? "unflag" : "flag"
        let chat = self.metaModel.getChat()
        let flagAPI = try? self.context.resolver.resolve(assert: FlagAPI.self, cache: true)
        flagAPI?.updateMessage(isFlaged: !self.message.isFlag, messageId: message.id).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            let title = !self.isFlag ? "msg_mark" : "msg_unmark"
            var params: [AnyHashable: Any] = [ "click": title, "target": "none", "message_id": self.message.id]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(self.message)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK, params: params))
            self.logger.info("messageID >>> \(self.message.id), \(logStr) success!!!")
        }, onError: { [weak self] error in
            guard let self = self else { return }
            self.logger.error("messageID >>> \(self.message.id), \(logStr) failed!!!")
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                DispatchQueue.main.async {
                    if let window = self.context.targetVC?.view {
                        UDToast.showFailure(with: info.displayMessage, on: window)
                    }
                }
            }
        })
    }
}

final class FlagComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = FlagComponent<C>.Props()
    private lazy var _component: FlagComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: FlagComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = FlagComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? FlagComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.isFlag = vm.isFlag
        props.flagClickEvent = { [weak vm] in
            vm?.flagIconDidClick()
        }
        _component.props = props
    }
}
