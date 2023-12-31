//
//  Array+TranslateSupport.swift
//  LarkCore
//
//  Created by shizhengyu on 2020/3/26.
//

/// 「特性」：替换值不会触发kvo，增减值会触发kvo
/// 另外，KVO 需要支持 oc dynamic，性能上会有影响，且使用上不太优雅，故使用以下结构变相实现相同效果
import Foundation
public struct ObservableArray<E> {
    public private(set) var internalArray: [E] = []
    private let filterCondition: ((E) -> Bool)?
    /// (当前diff, 当前数组)
    private let observeBlock: ([E], [E]) -> Void
    public var count: Int {
        return internalArray.count
    }

    private var defaultSubscriptValue: E
    public init(array: [E],
                filterCondition: ((E) -> Bool)? = nil,
                observeBlock: @escaping ([E], [E]) -> Void,
                defaultSubscriptValue: E) {
        self.internalArray = array
        self.filterCondition = filterCondition
        self.observeBlock = observeBlock
        /// 初始化值时，也应该触发一次
        if !array.isEmpty {
            self.observeBlock(array, array)
        }
        self.defaultSubscriptValue = defaultSubscriptValue
    }

    subscript(_ index: Int) -> E {
        get {
            guard index >= 0, index < internalArray.count else {
                return defaultSubscriptValue
            }
            return internalArray[index]
        }
        set(newValue) {
            if index >= internalArray.count {
                assertionFailure("不支持使用subscript扩展obserableArray数组")
                return
            }
            /// 这里直接替换，无须触发kvo
            internalArray[index] = newValue
        }
    }

    public func filter(isIncluded: (E) -> Bool) -> [E] {
        return internalArray.filter(isIncluded)
    }

    public func map<T>(transform: (E) -> T) -> [T] {
        return internalArray.map(transform)
    }

    public mutating func insert(newElement: E, at index: Int) {
        internalArray.insert(newElement, at: index)
        fireObserveHandlerIfNeeded(diffElements: [newElement])
    }

    public mutating func insert(newElements: [E], at index: Int) {
        internalArray.insert(contentsOf: newElements, at: index)
        fireObserveHandlerIfNeeded(diffElements: newElements)
    }

    public mutating func append(newElement: E) {
        internalArray.append(newElement)
        fireObserveHandlerIfNeeded(diffElements: [newElement])
    }

    public mutating func append(newElements: [E]) {
        internalArray.append(contentsOf: newElements)
        fireObserveHandlerIfNeeded(diffElements: newElements)
    }

    public mutating func remove(at index: Int) {
        if index < internalArray.count {
            let e = internalArray.remove(at: index)
            fireObserveHandlerIfNeeded(diffElements: [e])
        }
    }

    private func fireObserveHandlerIfNeeded(diffElements: [E]) {
        guard let condition = filterCondition else {
            if diffElements.isEmpty { return }
            observeBlock(diffElements, internalArray)
            return
        }
        let finalDiffs = diffElements.filter(condition)
        if finalDiffs.isEmpty { return }

        observeBlock(finalDiffs, internalArray)
    }
}
