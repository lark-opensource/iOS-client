//
//  LKRichViewEventCore.swift
//  LKRichView
//
//  Created by qihongye on 2021/10/6.
//

import Foundation

final class LKRichViewEventCore {
    private(set) var propagationListeners: [CSSSelectorList] = []
    private(set) var catchListeners: [CSSSelectorList] = []

    var hasPropagationListeners: Bool {
        return !propagationListeners.isEmpty
    }
    var hasCatchListeners: Bool {
        return !catchListeners.isEmpty
    }

    func matchPropagationListener(target: Node) -> Bool {
        return propagationListeners.contains(where: { $0.match(target) })
    }

    func matchCatchListener(target: Node) -> Bool {
        return catchListeners.contains(where: { $0.match(target) })
    }

    /// bindEvent
    /// - Parameters:
    ///   - selector: CSSSelectorList, the element you want to match.
    ///   - isPropagation: If set true, the event will matched in event-propagation mode. If set false, the event will matched in event-catch mode.
    func bindEvent(selector: CSSSelectorList, isPropagation: Bool) {
        if isPropagation {
            if !propagationListeners.contains(selector) {
                propagationListeners.append(selector)
            }
            return
        }
        if !catchListeners.contains(selector) {
            catchListeners.append(selector)
        }
    }

    func unbindEvent(selector: CSSSelectorList, isPropagation: Bool) {
        if isPropagation {
            if let idx = propagationListeners.firstIndex(of: selector) {
                propagationListeners.remove(at: idx)
            }
            return
        }
        if let idx = catchListeners.firstIndex(of: selector) {
            catchListeners.remove(at: idx)
        }
    }

    func unbindAllEvent(isPropagation: Bool) {
        if isPropagation {
            propagationListeners.removeAll()
            return
        }
        catchListeners.removeAll()
    }
}
