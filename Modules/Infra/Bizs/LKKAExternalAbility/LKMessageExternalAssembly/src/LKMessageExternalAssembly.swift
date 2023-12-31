import Swinject
import Foundation
import LarkOpenChat
import LarkAssembler
import LarkAccountInterface
#if canImport(LKMessageExternal)
import LKMessageExternal
#endif

#if canImport(LKMessageExternal)
public class LKMessageExternalAssembly: LarkAssemblyInterface {
    public init() {}

    @_silgen_name("Lark.OpenChat.Messenger.KAMessage")
    static public func openChatRegister() {
        ChatMessageActionModule.register(KAMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(KAMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(KAMessageActionSubModule.self)
    }

    public func registPassportDelegate(container: Container) {
        (
            PassportDelegateFactory {
                return KAMessagePassportDelegate()
            },
            PassportDelegatePriority.high
        )
    }
}
#else
public class LKMessageExternalAssembly: LarkAssemblyInterface {
    public init() {}

    @_silgen_name("Lark.OpenChat.Messenger.KAMessage")
    static public func openChatRegister() {
    }

    public func registPassportDelegate(container: Container) {
    }
}
#endif