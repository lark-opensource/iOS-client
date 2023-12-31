import Foundation
import UIKit

@objc
public protocol KAMenusProtocol: AnyObject {
    var icon: UIImage { get }
    
    var label: String { get }
    
    func canInitialize(_ actionContext: ActionContext) -> Bool
    
    func onClick(_ actionContext: ActionContext) -> Void
    
}

@objcMembers
public class ActionContext: NSObject {
    public var actionChat: ActionChat
    public var actionMode: ActionMode
    public var actionMessages: [ActionMessage]
    public init(actionChat: ActionChat, actionMode: ActionMode, actionMessages: [ActionMessage]) {
        self.actionChat = actionChat
        self.actionMode = actionMode
        self.actionMessages = actionMessages
    }
}

@objcMembers
public class ActionChat: NSObject {
    public var chatId: String
    public init(chatId: String) {
        self.chatId = chatId
    }
}

@objc
public enum ActionMode: Int {
    case single = 0
    case multi = 1
}

@objcMembers
public class ActionMessage: NSObject {
    public var id: String
    public var type: MessageType

    public enum MessageType {
        case image
        case video
        case file
        case others
    }
    public init(id: String, type: MessageType) {
        self.id = id
        self.type = type
    }
}

@objcMembers
public class KAMenusExternal: NSObject {
    
    public override init() {
        super.init()
    }

    public static let shared = KAMenusExternal()
    
    public var delegates: [KAMenusProtocol] = []
    
    public static func register(delegate: KAMenusProtocol) {
        shared.delegates.append(delegate)
    }
}
