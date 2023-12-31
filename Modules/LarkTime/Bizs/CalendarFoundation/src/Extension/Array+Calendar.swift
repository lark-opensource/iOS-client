//
//  Array+Calendar.swift
//  Calendar
//
//  Created by harry zou on 2019/3/21.
//

import Foundation

extension Array {
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
//            assertionFailureLog()
            return nil
        }
        return self[index]
    }
}

extension Array where Element: Hashable {
    public var unique: [Element] {
        var uniq = Set<Element>()
        uniq.reserveCapacity(self.count)
        return self.filter {
            return uniq.insert($0).inserted
        }
    }
}
