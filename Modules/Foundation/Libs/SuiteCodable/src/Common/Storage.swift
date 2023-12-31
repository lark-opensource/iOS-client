//
//  Storage.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

final class Storage {
    private(set) var containers: [Any] = []

    var count: Int {
        return containers.count
    }

    var last: Any? {
        return containers.last
    }

    func push(container: Any) {
        containers.append(container)
    }

    @discardableResult
    func popContainer() -> Any {
        precondition(!containers.isEmpty, "Empty container stack.")
        return containers.popLast() ?? [Int]()
    }
}
