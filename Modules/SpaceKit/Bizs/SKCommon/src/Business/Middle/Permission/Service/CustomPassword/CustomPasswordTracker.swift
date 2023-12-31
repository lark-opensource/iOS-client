//
//  CustomPasswordTracker.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/12/5.
//

import Foundation
import SKFoundation
import SKInfra

struct CustomPasswordTracker {
    private var isRandomPassword = false

    func reportView() {
        DocsTracker.newLog(enumEvent: .permissionChangePasswordView, parameters: nil)
    }

    func reportCancel() {
        DocsTracker.newLog(enumEvent: .permissionChangePasswordClick, parameters: [
            "click": "cancel",
            "target": "none"
        ])
    }

    enum SaveResult: Equatable {
        case success
        case weakPassword
        case otherFailed(code: Int)

        fileprivate var errorCode: String? {
            switch self {
            case .success:
                nil
            case .weakPassword:
                String(DocsNetworkError.Code.saveDocsPasswordFailed.rawValue)
            case let .otherFailed(code):
                String(code)
            }
        }
    }

    func reportSave(result: SaveResult) {
        DocsTracker.newLog(enumEvent: .permissionChangePasswordClick, parameters: [
            "click": "save",
            "change_type": isRandomPassword ? "random" : "customized",
            "is_success": String(result == .success),
            "is_credential_stuffing": String(result == .weakPassword),
            "error_code": result.errorCode
        ])
    }

    mutating func reportGeneratedRandomPassword() {
        isRandomPassword = true
    }

    mutating func reportEdit() {
        isRandomPassword = false
    }
}
