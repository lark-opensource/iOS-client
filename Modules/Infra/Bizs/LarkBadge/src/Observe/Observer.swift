//
//  ObserveInfo.swift
//  LarkBadge
//
//  Created by KT on 2019/4/17.
//

import Foundation
import UIKit

/// 存放Observer对象
public struct Observer {
    let path: [NodeName]
    weak var controller: BadgeController? // 被观察者，弱持有
    let callback: OnChanged<ObserverNode, BadgeNode>?
    let primiry: Bool

    init(
        _ path: [NodeName],
        controller: BadgeController,
        primiry: Bool = false,
        callback: OnChanged<ObserverNode, BadgeNode>? = nil) {
        self.path = path
        self.primiry = primiry
        self.controller = controller
        self.callback = callback
    }
}

extension Observer: Equatable {
    public static func == (lhs: Observer, rhs: Observer) -> Bool {
        return lhs.path == rhs.path && lhs.controller == rhs.controller
    }
}
