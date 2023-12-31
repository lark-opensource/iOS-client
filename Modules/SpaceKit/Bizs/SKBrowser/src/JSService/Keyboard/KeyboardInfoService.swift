//
//  KeyboardInfoService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/1/3.
//

import Foundation
import SKCommon

class KeyboardInfoService: BaseJSService {
    enum Trigger: Int {
        case permission

        var stringValue: String? {
            switch self {
            case .permission:
                return "permission"
            }
        }
    }

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension KeyboardInfoService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.setKeyboardInfo]
    }

    public func handle(params: [String: Any], serviceName: String) {
        if let triggerRawValue = params["trigger"] as? Int, let trigger = KeyboardInfoService.Trigger(rawValue: triggerRawValue)?.stringValue {
            ui?.uiResponder.setTrigger(trigger: trigger)
        }
    }
}
