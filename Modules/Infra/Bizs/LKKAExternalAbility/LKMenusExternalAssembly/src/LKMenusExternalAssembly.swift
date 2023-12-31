import UIKit
import LKCommonsLogging
import LarkOpenChat
import LarkAssembler
#if canImport(LKMenusExternal)
import LKMenusExternal
#endif

#if canImport(LKMenusExternal)
public class LKMenusExternalAssembly: LarkAssemblyInterface {
    public init() {
    }
    @_silgen_name("Lark.OpenChat.Messenger.KAMenu")
    static public func openChatRegister() {
        OpenMessageMenuRegister.register(handler: KAMessageActionHandler.self)
    }
}


public class KAMessageActionHandler: OpenMessageMenuHandler {
    var logger: Log {
        Logger.log(KAMessageActionHandler.self, category: "KAMessageActionHandler")
    }
    var menusDelegates: [KAMenusProtocol] = KAMenusExternal.shared.delegates
    public override func messageActions(context: OpenMessageMenuContext) -> [OpenMessageMenuItem] {
        let openMessageMenuItems = menusDelegates.map { delegate in
            OpenMessageMenuItem.init(text: delegate.label, icon: delegate.icon) { [weak self] _ in
                guard let self = self else { return false }
                return delegate.canInitialize(ActionContext(
                actionChat: ActionChat(chatId: context.chat.id),
                actionMode: self.transportActionContextToMode(context),
                actionMessages: self.transportActionContextToMessages(context)))
            } tapAction: { [weak self] context in
                guard let self = self else { return }
                delegate.onClick(ActionContext(
                    actionChat: ActionChat(chatId: context.chat.id),
                    actionMode: self.transportActionContextToMode(context),
                    actionMessages: self.transportActionContextToMessages(context)))
            }
        }
        return openMessageMenuItems
    }
    
    func transportActionContextToMode(_ context: OpenMessageMenuContext) -> ActionMode {
        switch context.menuType {
        case .single:
            self.logger.info("KAMessageActionHandler: actionContext is single mode.")
            return .single
        case .multi:
            self.logger.info("KAMessageActionHandler: actionContext is multi mode.")
            return .multi
        @unknown default:
            self.logger.info("KAMessageActionHandler: actionContext is unknown, use single mode.")
            return .single
        }
    }
    
    func transportActionContextToMessages(_ context: OpenMessageMenuContext) -> [ActionMessage] {
        var actionMessages: [ActionMessage] = []
        if !context.messageInfos.isEmpty {
            for messageInfo in context.messageInfos {
                var type = ActionMessage.MessageType.others
                switch messageInfo.type {
                case .image:
                    self.logger.info("KAMessageActionHandler: messageInfo type is image")
                    type = .image
                case .file:
                    self.logger.info("KAMessageActionHandler: messageInfo type is file")
                    type = .file
                case .videoChat:
                    self.logger.info("KAMessageActionHandler: messageInfo type is video")
                    type = .video
                @unknown default:
                    self.logger.info("KAMessageActionHandler: messageInfo type is others")
                    type = .others
                }
                let actionMessage = ActionMessage(id: messageInfo.id, type: type)
                actionMessages.append(actionMessage)
            }
            return actionMessages
        } else {
            self.logger.error("KAMessageActionHandler: messageInfo is empty in context.")
            return []
        }
        
    }
}
#else
public class LKMenusExternalAssembly: LarkAssemblyInterface {
    public init() {}

    @_silgen_name("Lark.OpenChat.Messenger.KAMenu")
    static public func openChatRegister() {}
}
#endif
