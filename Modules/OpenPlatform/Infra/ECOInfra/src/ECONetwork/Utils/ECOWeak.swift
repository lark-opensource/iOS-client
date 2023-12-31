//
//  ECOWeak.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

public struct WeakArray<Element: AnyObject> {
    private var items: [WeakReference<Element>] = []

    public init(_ elements: [Element]) {
        items = elements.map { WeakReference(value: $0) }
    }
    
    public mutating func append(_ newElement: Element) {
        items.append(WeakReference(value: newElement))
    }
    
    public mutating func remove(at position: Int) -> WeakReference<Element> {
        items.remove(at: position)
    }
    
    public mutating func remove(
        where isExcluded: (Element) -> Bool
    ) -> WeakArray<WeakReference<Element>> {
        var removed = WeakArray<WeakReference<Element>>([])
        for (index, element) in enumerated().reversed() {
            if element != nil && isExcluded(element!) {
                removed.append(remove(at: index))
            }
        }
        return removed
    }
}

extension WeakArray: Collection {
    public var startIndex: Int { return items.startIndex }
    public var endIndex: Int { return items.endIndex }

    public subscript(_ index: Int) -> Element? {
        return items[index].value
    }

    public func index(after idx: Int) -> Int {
        return items.index(after: idx)
    }
}
