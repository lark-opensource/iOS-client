//
//  SafeArray.swift
//  ThreadSafeDataStructure
//
//  Created by PGB on 2019/8/28.
//

import Foundation

/// special API different from system
public extension SafeArray {
    /// Set new elements to the data inside
    /// - Parameter array: New elements to replace current elements
    func replaceInnerData(by array: [Element]) {
        synchronizationDelegate.writeOperation {
            data = array
        }
    }

    /// return a copy of the data inside of type 'Array'
    func getImmutableCopy() -> [Element] {
        return synchronizationDelegate.readOperation {
            return data
        }
    }

    /// Accesses the element at the specified position under shared lock.
    /// - Parameter index: The position of the element to access.
    /// - Parameter action: The action to run on the element
    func safeRead(at index: Int, action: ((Element) -> Void)) {
        synchronizationDelegate.readOperation {
            action(data[index])
        }
    }

    /// Accesses the element at the specified position under exclusive lock.
    /// - Parameter index: The position of the element to access.
    /// - Parameter action: The action to run on the element
    func safeWrite(at index: Int, action: ((inout Element) -> Void)) {
        synchronizationDelegate.writeOperation {
            action(&data[index])
        }
    }

    /// Accesses the inner data under shared lock.
    /// - Parameter action: The action to run on the struct
    func safeRead(all action: (([Element]) -> Void)) {
        synchronizationDelegate.readOperation {
            action(data)
        }
    }

    /// Accesses the inner data under exlusive lock.
    /// - Parameter action: The action to run on the struct
    func safeWrite(all action: ((inout [Element]) -> Void)) {
        synchronizationDelegate.writeOperation {
            action(&data)
        }
    }
}

/// Init a 'SafeArray' by using an array literal and a designated synchronization primtive
/// - Parameter elements: Inner data of the safeArray
/// - Parameter synchronization: The synchronization primtive type used in this safeArray
public func +<Element>(elements: [Element], synchronization: SynchronizationType) -> SafeArray<Element> {
    return SafeArray(elements, synchronization: synchronization)
}

/// A thread-safe, ordered, random-access collection implemented as a **class**.
///
/// Checkout the [guidebook](https://bytedance.feishu.cn/space/doc/doccnNb7YCSPctnUGmWNEUs3Ywh) to get started with more information
/// - Important: The ThreadSafeDataStructure only ensure of the safety itself,
/// The strategy for the safety of elements inside is still under consideration
public final class SafeArray<Element> {
    public typealias Element = Element

    let synchronizationDelegate: SynchronizationDelegate
    var data: [Element]
    private let elementIsValueType: Bool

    /// Accesses the element at the specified position.
    public subscript(index: Int) -> Element {
        get {
            synchronizationDelegate.readOperation {
                return data[index]
            }
        }

        set {
            synchronizationDelegate.writeOperation {
                data[index] = newValue
            }
        }
    }

    /// The number of elements in the array.
    public var count: Int {
        return synchronizationDelegate.readOperation {
            return data.count
        }
    }

    /// A Boolean value indicating whether the collection is empty.
    public var isEmpty: Bool {
        return synchronizationDelegate.readOperation {
            return data.isEmpty
        }
    }

    /// The first element of the collection.
    public var first: Element? {
        return synchronizationDelegate.readOperation {
            return data.first
        }
    }

    /// The last element of the collection.
    public var last: Element? {
        return synchronizationDelegate.readOperation {
            return data.last
        }
    }

    /// Creates a thread-safe array by given Array and SynchronizationType
    convenience public init(_ data: [Element] = [], synchronization: SynchronizationType = .readWriteLock) {
        let synchronizationDelegate = synchronization.generateSynchronizationDelegate()
        self.init(data, synchronizationDelegate: synchronizationDelegate)
    }

    /// Adds the elements of a sequence or collection to the end of this collection.
    public func append<S>(contentsOf newElements: S) where Element == S.Element, S: Sequence {
        synchronizationDelegate.writeOperation {
            data.append(contentsOf: newElements)
        }
    }

    /// Removes and returns the element at the specified position.
    @discardableResult
    public func remove(at index: Int) -> Element {
        return synchronizationDelegate.writeOperation {
            return data.remove(at: index)
        }
    }

    /// Inserts a new element into the collection at the specified position.
    public func insert(_ newElement: Element, at i: Int) {
        synchronizationDelegate.writeOperation {
            data.insert(newElement, at: i)
        }
    }

    /// Removes all elements from the collection.
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        synchronizationDelegate.writeOperation {
            data.removeAll(keepingCapacity: keepCapacity)
        }
    }

    /// Adds an element to the end of the collection.
    public func append(_ newElement: Element) {
        synchronizationDelegate.writeOperation {
            data.append(newElement)
        }
    }

    /// Returns an array containing the results of mapping the given closure over the sequence’s elements.
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        return try synchronizationDelegate.readOperation {
            return try data.map(transform)
        }
    }

    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try synchronizationDelegate.readOperation {
            try data.forEach(body)
        }
    }

    /// Returns the first element of the sequence that satisfies the given predicate.
    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try synchronizationDelegate.readOperation {
            return try data.first(where: predicate)
        }
    }

    /// Returns the last element of the sequence that satisfies the given predicate.
    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try synchronizationDelegate.readOperation {
            return try data.last(where: predicate)
        }
    }

    /// Returns the minimum element in the sequence, using the given predicate as the comparison between elements.
    @warn_unqualified_access
    public func min(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        return try synchronizationDelegate.readOperation {
            return try data.min(by: areInIncreasingOrder)
        }
    }

    /// Returns the maximum element in the sequence, using the given predicate as the comparison between elements.
    @warn_unqualified_access
    public func max(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        return try synchronizationDelegate.readOperation {
            return try data.max(by: areInIncreasingOrder)
        }
    }

    /// Returns a Boolean value indicating whether the sequence contains an element that satisfies the given predicate.
    public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try synchronizationDelegate.readOperation {
            return try data.contains(where: predicate)
        }
    }

    /// Returns the result of combining the elements of the sequence using the given closure.
    public func reduce<Result>(_ initialResult: Result,
                               _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        return try synchronizationDelegate.readOperation {
            return try data.reduce(initialResult, nextPartialResult)
        }
    }

    /// Returns the result of combining the elements of the sequence using the given closure.
    public func reduce<Result>(into initialResult: Result,
                               _ updateAccumulatingResult: (inout Result, Element) throws -> Void) rethrows -> Result {
        return try synchronizationDelegate.readOperation {
            return try data.reduce(into: initialResult, updateAccumulatingResult)
        }
    }

    /// Returns an array containing the concatenated results of calling
    /// the given transformation with each element of this sequence.
    public func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult)
        rethrows -> [SegmentOfResult.Element] where SegmentOfResult: Sequence {
        return try synchronizationDelegate.readOperation {
            return try data.flatMap(transform)
        }
    }

    /// Returns an array containing the non-nil results of calling
    /// the given transformation with each element of this sequence.
    public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?)
        rethrows -> [ElementOfResult] {
        return try synchronizationDelegate.readOperation {
            return try data.compactMap(transform)
        }
    }

    /// Returns the elements of the sequence, sorted using the given predicate as the comparison between elements.
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> SafeArray<Element> {
        return try synchronizationDelegate.readOperation {
            return SafeArray(try data.sorted(by: areInIncreasingOrder),
                             synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> SafeArray<Element> {
        return try synchronizationDelegate.readOperation {
            return SafeArray(try data.filter(isIncluded),
                             synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    /// Sorts the collection in place, using the given predicate as the comparison between elements.
    public func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        try synchronizationDelegate.writeOperation {
            try data.sort(by: areInIncreasingOrder)
        }
    }

    /// Returns the first index in which an element of the collection satisfies the given predicate.
    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        return try synchronizationDelegate.readOperation {
            return try data.firstIndex(where: predicate)
        }
    }

    /// Returns the index of the last element in the collection that matches the given predicate.
    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        return try synchronizationDelegate.readOperation {
            return try data.lastIndex(where: predicate)
        }
    }

    /// Returns a subsequence, up to the specified maximum length, containing the initial elements of the collection.
    public func prefix(_ maxLength: Int) -> SafeArray<Element> {
        return synchronizationDelegate.readOperation {
            return SafeArray(data.prefix(maxLength).map { $0 },
                             synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    // MARK: - internal & private functions implementations from here
    init(_ data: [Element], synchronizationDelegate: SynchronizationDelegate) {
        self.data = data
        self.synchronizationDelegate = synchronizationDelegate
        self.elementIsValueType = !(Element.self is AnyClass)
    }

    private func generateSynchronizationDelegate() -> SynchronizationDelegate {
        return elementIsValueType ?
            SynchronizationType(delegate: synchronizationDelegate).generateSynchronizationDelegate() :
            synchronizationDelegate
    }
}

public extension SafeArray where Element: Equatable {
    /// Returns a Boolean value indicating whether the sequence contains the given element.
    func contains(_ element: Element) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.contains(element)
        }
    }
}

public extension SafeArray where Element: Comparable {
    /// Returns the minimum element in the sequence.
    @warn_unqualified_access
    func min() -> Element? {
        return synchronizationDelegate.readOperation {
            return data.min()
        }
    }

    /// Returns the maximum element in the sequence.
    @warn_unqualified_access
    func max() -> Element? {
        return synchronizationDelegate.readOperation {
            return data.max()
        }
    }

    /// Returns the elements of the sequence, sorted.
    func sorted() -> SafeArray<Element> {
        return synchronizationDelegate.readOperation {
            return SafeArray(data.sorted(), synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    /// Sorts the collection in place.
    func sort() {
        synchronizationDelegate.writeOperation {
            data.sort()
        }
    }
}

extension SafeArray: CustomStringConvertible {
    public var description: String {
        return synchronizationDelegate.readOperation {
            return String(describing: data)
        }
    }
}
