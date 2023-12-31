//
//  MailRecoverAction.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/8/5.
//

import Foundation

public struct MailRecoverAction {
    public static let NotificationKey = "MailRecoverAction"

    public enum ActionType {
        case reloadThreadData
        case refreshMigration
        case refreshOutBox
    }

    public let actionType: Set<ActionType>

    public init(actionType: Set<ActionType>) {
        self.actionType = actionType
    }
}
