//
//  CardClientMessageService.swift
//  UniversalCardBase
//
//  Created by zhangjie.alonso on 2023/10/24.
//

import Foundation
import UniversalCardInterface
import UniverseDesignToast
import EENavigator
import LKCommonsLogging
import LarkEMM
import LarkContainer
import OPFoundation


final public class CardClientMessageServiceImpl: CardClientMessageService, CardClientMessagePublishService {

    let lock = NSLock()
    private static let logger = Logger.log(CardClientMessageServiceImpl.self, category: "CardClientMessageServiceImpl")

    private var clientMessageHandler: [String: [CardClientMessageHandler]] = [:]

    public init(resolver: UserResolver) {
        #if DEBUG || ALPHA
        let handler: CardClientMessageHandler = CardClientMessageHandler(){ (value) in
            guard let targetView = resolver.navigator.mainSceneWindow?.fromViewController?.view else {
                print(" CardClientMessageService debug showToast fail: currentVC or targetView is nil")
                return
            }
            let toastConfig = UDToastConfig(toastType: .info, text: value, operation: nil)
            UDToast.showToast(with: toastConfig, on: targetView)
            let pasteboardConfig = PasteboardConfig(token: OPSensitivityEntryToken.debug.psdaToken)
            SCPasteboard.general(pasteboardConfig).string = value
        }
        self.register(channel: "test__card", handler: handler)
        #endif
    }

    //业务方注册channel 以及对应的 handler
    public func register(channel: String, handler: CardClientMessageHandler) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if clientMessageHandler[channel] != nil {
            clientMessageHandler[channel]?.append(handler)
        }else {
            clientMessageHandler[channel] = [handler]
        }
    }

    //取消注册单个handler
    public func unRegister(channel: String, unRegisterHandler: CardClientMessageHandler) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if var handlers = clientMessageHandler[channel] {
            handlers.removeAll() { (handler) -> Bool in
                return handler == unRegisterHandler
            }
            clientMessageHandler[channel] = handlers
        }
    }

    //取消注册指定channel下所有Handler
    public func unRegisterAll(channel: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        clientMessageHandler.removeValue(forKey: channel)
    }

    //发布端通信消息
    public func publish(channel: String, value: String) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let handlers = clientMessageHandler[channel] else {
            Self.logger.error("get handler failed, channel: \(channel)")
            return false
        }
        
        DispatchQueue.main.async {
            for handler in handlers {
                handler.exec(value)
            }
        }
        return true
    }
}
