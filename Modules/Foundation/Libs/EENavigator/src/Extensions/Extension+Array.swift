//
//  Extension+Array.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/12/29.
//

import Foundation

extension Array {
    func insertionIndex(of element: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var low = 0
        var high = self.count - 1
        while low <= high {
            let mid = (low + high) / 2
            if isOrderedBefore(self[mid], element) {
                low = mid + 1
            } else if isOrderedBefore(element, self[mid]) {
                high = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return low // not found, would be inserted at position lo
    }
}
