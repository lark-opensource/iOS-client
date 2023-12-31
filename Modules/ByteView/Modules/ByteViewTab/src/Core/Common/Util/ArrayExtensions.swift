//
//  ArrayExtensions.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/18.
//

import Foundation

extension Array {
    enum UniqueByOption {
        case keepFirst
        case keepLast
        case replaceFirst
    }

    func uniqued<E: Hashable>(by block: ((Element) -> E), option: UniqueByOption = .keepFirst) -> [Element] {
        switch option {
        case .keepFirst:
            return uniquedFirst(by: block)
        case .keepLast:
            return uniquedLast(by: block)
        case .replaceFirst:
            return uniquedReplace(by: block)
        }
    }

    private func uniquedFirst<E: Hashable>(by block: ((Element) -> E)) -> [Element] {
        var set = Set<E>()
        var values = [Element]()
        forEach {
            let key = block($0)
            if set.insert(key).inserted {
                values.append($0)
            }
        }
        return values
    }

    private func uniquedLast<E: Hashable>(by block: ((Element) -> E)) -> [Element] {
        var set = Set<E>()
        var values = [Element]()
        reversed().forEach {
            let key = block($0)
            if set.insert(key).inserted {
                values.append($0)
            }
        }
        return values.reversed()
    }

    private func uniquedReplace<E: Hashable>(by block: ((Element) -> E)) -> [Element] {
        var values: [Element] = []
        var map: [E: Int] = [:]
        for i in 0..<count {
            let elem = self[i]
            let key = block(elem)
            if let index = map[key] {
                map[key] = index
                values[index] = elem
            } else {
                map[key] = values.count
                values.append(elem)
            }
        }
        return values
    }
}

extension Array where Element: Hashable {

    func uniqued() -> [Element] {
        return uniqued { $0 }
    }
}
