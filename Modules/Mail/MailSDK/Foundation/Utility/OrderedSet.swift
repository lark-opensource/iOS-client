//
//  OrderedSet.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/10/9.
//

import Foundation

struct OrderSet<Element> where Element: Hashable {
    private(set) var elements = [Element]()

    var count: Int {
        return elements.count
    }

    init() { }

    init(_ array: [Element]) {
        for ele in array where !elements.contains(ele) {
            elements.append(ele)
        }
    }

    mutating func insert(_ newElement: Element) {
        if !elements.contains(newElement) {
            elements.append(newElement)
        }
    }

    func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> OrderSet<Element> {
        let newElements = try elements.filter(isIncluded)
        return OrderSet(newElements)
    }

    func map<T>(_ transform: (Element) throws -> T) rethrows -> OrderSet<T> {
        var newElements = [T]()
        for ele in elements {
            let newEle = try transform(ele)
            if !newElements.contains(newEle) {
                newElements.append(newEle)
            }
        }
        return OrderSet<T>(newElements)
    }

    func contains(_ member: Element) -> Bool {
        return elements.contains(member)
    }

    func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try elements.contains(where: predicate)
    }

    static func + (lhs: OrderSet<Element>, rhs: OrderSet<Element>) -> OrderSet<Element> {
        let newElements = lhs.elements + rhs.elements
        return OrderSet<Element>(newElements)
    }
}
