import Foundation
@objc
public protocol KAMessageBodyProtocol: AnyObject {
}

@objc
public protocol KAFileMessageProtocol: KAMessageBodyProtocol {
    var filePath: String { get }
}

@objc
public enum KAMessageType: Int {
    case file
    case image
    case video
    case others
}

@objcMembers
public class KAMessage: NSObject {
    public var type: KAMessageType
    // messageID
    public var id: String
    public var body: KAMessageBodyProtocol

    public init(type: KAMessageType, id: String, body: KAMessageBodyProtocol) {
        self.type = type
        self.id = id
        self.body = body
    }
}

@objc
public enum KAMessageInfoType: Int {
    case file
    case image
    case video
}

@objcMembers
public class KAMessageInfo: NSObject {
    public var type: KAMessageInfoType
    public var key: String
    public var messageID: String
    public var channelID: String
    public var name: String
    public var size: UInt64
    public var mime: String

    public init(
        type: KAMessageInfoType,
        key: String,
        messageID: String,
        channelID: String,
        name: String,
        size: UInt64,
        mime: String
    ) {
        self.type = type
        self.key = key
        self.messageID = messageID
        self.channelID = channelID
        self.name = name
        self.size = size
        self.mime = mime
    }
}

public protocol KAMessageNavigator {
    func forward(message: KAMessage)

    func getResources(
        messages: [KAMessage],
        onSuccess: @escaping ([KAMessageInfo]) -> Void,
        onError: @escaping (Error) -> Void
    )

    func downloadResource(
        messageInfo: KAMessageInfo,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    )
}

@objcMembers
public class KAMessageExternal: NSObject {
    public static let shared = KAMessageExternal()
    public override init() {
        super.init()
    }

    public var navigator: KAMessageNavigator?

    public func forward(message: KAMessage) {
        navigator?.forward(message: message)
    }

    public func getResources(
        messages: [KAMessage],
        onSuccess: @escaping ([KAMessageInfo]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        navigator?.getResources(messages: messages, onSuccess: onSuccess, onError: onError)
    }

    public func downloadResource(
        messageInfo: KAMessageInfo,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        navigator?.downloadResource(messageInfo: messageInfo, onSuccess: onSuccess, onError: onError)
    }
}
