//
//  OpenMessageMenuRegister.swift
//  LarkOpenChat
//
//  Created by Ping on 2023/11/21.
//

open class OpenMessageMenuHandler {
    public required init() {}

    open func messageActions(context: OpenMessageMenuContext) -> [OpenMessageMenuItem] {
        return []
    }
}

public class OpenMessageMenuRegister {
    private static var handlers: [OpenMessageMenuHandler.Type] = []

    public static func register(handler: OpenMessageMenuHandler.Type) {
        self.handlers.append(handler)
    }

    public static func createHandlers() -> [OpenMessageMenuHandler] {
        return handlers.map({ $0.init() })
    }
}

public struct OpenMessageMenuItemFactory {
    public let handlers: [OpenMessageMenuHandler]

    public init() {
        handlers = OpenMessageMenuRegister.createHandlers()
    }

    public func getMenuItems(context: OpenMessageMenuContext) -> [OpenMessageMenuItem] {
        return handlers.flatMap({ $0.messageActions(context: context) })
    }
}
