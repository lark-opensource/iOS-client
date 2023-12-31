//
//  Observer.swift
//  LarkBadge
//
//  Created by KT on 2019/4/16.
//

import Foundation

/// Observer Updatable
public struct ObserverUpdateInfo {
    var observers: [Observer] = []

    var primaryObserver: Observer? {
        return observers.first { $0.primiry }
    }
}

public struct ObserverNode: TrieValueble {
    typealias UpdateInfo = ObserverUpdateInfo

    // updatable
    var info: UpdateInfo = ObserverUpdateInfo()

    var linkedObserver: [[NodeName]] = []

    var name: NodeName
    var isElement: Bool = false
    init(_ name: NodeName) {
        self.name = name
    }
}

extension ObserverNode: Equatable {
    public static func == (lhs: ObserverNode, rhs: ObserverNode) -> Bool {
        return lhs.name == rhs.name
    }
}
