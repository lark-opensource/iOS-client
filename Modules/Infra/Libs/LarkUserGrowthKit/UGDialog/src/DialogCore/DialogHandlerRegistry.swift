//
//  DialogHandlerRegistry.swift
//  UGDialog
//
//  Created by Aslan on 2022/01/11.
//

import Foundation

public protocol UGDialogHandler {
    // 是否可展示
    func isDialogEnable(dialogData: UGDialogData) -> Bool
}

public extension UGDialogHandler {
    func isDialogEnable(dialogData: UGDialogData) -> Bool {
        return false
    }
}

public final class DialogHandlerRegistry {
    var dialogHandlers: [String: UGDialogHandler] = [:]

    public init() {}

    public func register(dialogName: String, for handler: UGDialogHandler) {
        dialogHandlers[dialogName] = handler
    }

    public func getDialogHandler(dialogName: String) -> UGDialogHandler? {
        return dialogHandlers[dialogName]
    }
}
