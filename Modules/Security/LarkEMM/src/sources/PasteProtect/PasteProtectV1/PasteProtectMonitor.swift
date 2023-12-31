//
//  PasteProtectMonitor.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/4/28.
//

import Foundation
import LarkSecurityComplianceInfra

extension SCPasteboard {
    enum Action: String {
        case get
        case set
    }

    enum ContentType: String {
        case string
        case image
        case color
        case url
        case strings
        case images
        case colors
        case urls
        case items
        case addedItems
        case itemProviders
        case data

    }

    func monitorPasteProtectGetFail(_ contentType: ContentType, error: Error, params: [String: Any]? = nil) {
        monitorPasteProtectActions(.get, contentType: contentType, error: error, params: params)
    }

    func monitorPasteProtectSetFail(_ contentType: ContentType, error: Error, params: [String: Any]? = nil) {
        monitorPasteProtectActions(.set, contentType: contentType, error: error, params: params)
    }

    private func monitorPasteProtectActions(_ action: Action, contentType: ContentType, error: Error, params: [String: Any]? = nil) {
        var extraParams = params ?? [:]
        extraParams["action"] = action.rawValue
        extraParams["content_type"] = contentType.rawValue
        SCMonitor.error(business: .paste_protect, eventName: "clipboard_actions", error: error, extra: params)
    }
}
