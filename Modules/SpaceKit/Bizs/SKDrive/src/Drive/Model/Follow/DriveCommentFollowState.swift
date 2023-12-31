//
//  DriveCommentFollowState.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/3.
//  

import Foundation
import SwiftyJSON
import SpaceInterface

enum DriveCommentFollowState {
    case collapse
    case expanded(focusedID: String?)

    static var `default`: Self {
        return .collapse
    }
}

extension DriveCommentFollowState: Equatable {
    static func == (lhs: DriveCommentFollowState, rhs: DriveCommentFollowState) -> Bool {
        switch (lhs, rhs) {
        case (.collapse, .collapse):
            return true
        case let (.expanded(lhsID), .expanded(rhsID)):
            return lhsID == rhsID
        default:
            return false
        }
    }
}

extension DriveCommentFollowState: DriveFollowModuleState {

    static var module: String {
        return "comment"
    }

    var actionType: String {
        return "drive_comment_update"
    }

    var data: JSON {
        var data: [String: Any] = [:]
        switch self {
        case .collapse:
            data["isCommentExpanded"] = false
        case let .expanded(focusedID):
            data["isCommentExpanded"] = true
            data["focusedCommentId"] = focusedID
        }
        return JSON(data)
    }

    init?(data: JSON) {
        let isCommentExpanded = data["isCommentExpanded"].bool ?? false
        if isCommentExpanded {
            let focusedCommentID = data["focusedCommentId"].string
            self = .expanded(focusedID: focusedCommentID)
        } else {
            self = .collapse
        }
    }
}
