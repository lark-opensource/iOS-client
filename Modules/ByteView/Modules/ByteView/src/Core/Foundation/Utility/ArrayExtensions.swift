//
//  ArrayExtensions.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/8/15.
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

    func slice(_ fromIndex: Int, _ toIndex: Int) -> [Element] {
        let from = Swift.max(Swift.min(fromIndex, self.count), 0)
        let toValue = Swift.min(toIndex, self.count)
        if from >= toValue {
            return []
        }
        return Array(self[from..<toValue])
    }
}

extension Array where Element: Hashable {

    func uniqued() -> [Element] {
        return uniqued { $0 }
    }

}

extension Sequence {
    func groupBy<Key: Hashable>(keySelector: (Element) -> Key) -> [(Key, [Element])] {
        let dict = Dictionary(grouping: self, by: keySelector)
        var set = Set<Key>()
        var results = [(Key, [Element])]()
        forEach {
            let key = keySelector($0)
            if set.insert(key).inserted, let values = dict[key] {
                results.append((key, values))
            }
        }
        return results
    }
}
