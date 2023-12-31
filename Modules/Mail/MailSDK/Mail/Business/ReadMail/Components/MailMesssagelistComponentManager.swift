//
//  MailMesssagelistComponentManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/12/4.
//

import Foundation
import WebKit

enum MailMesssagelistState {
    case none
    case getSection
    case replaceTemplate
    case beforeLoadTemplate
    case didRenderTemplate
}

private struct Param<Value> {
    private var _value: Value?
    var value: Value {
        return _value!
    }

    init(from: Any?) {
        if let temp = from as? Value {
            _value = temp
        } else {
            assert(false, "no param find!")
        }
    }
}

class MailMessageReplaceComponentManager {
    private(set) var replaceComponents: [MailMessageReplaceComponent] = []
    private(set) var state = MailMesssagelistState.none

    init() { }
}

/// func
extension MailMessageReplaceComponentManager {
    func addComponet(_ component: MailMessageReplaceComponent) {
        replaceComponents.append(component)
    }

    @discardableResult
    func setCurrentState(_ state: MailMesssagelistState, params: Any? = nil) -> Any? {
        self.state = state
        var res: Any? = nil
        for comp in replaceComponents {
            switch state {
            case .getSection:
                comp.getSection(template: Param<MailMessageListTemplate>(from: params).value)
            case .replaceTemplate:
                let param = Param<(String, MailItem?, MailMessageItem)>.init(from: params)
                if var _ = res as? String {
                    assert(false, "has same keyword handler")
                }
                res = comp.replaceTemplate(keyword: param.value.0, mailItem: param.value.1, messageItem: param.value.2)
            case .none:
                break
            case .beforeLoadTemplate:
                break
            case .didRenderTemplate:
                break
            }
        }
        return res
    }
}
