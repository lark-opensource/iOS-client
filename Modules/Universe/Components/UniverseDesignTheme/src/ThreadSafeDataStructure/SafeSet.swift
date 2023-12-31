//
//  SafeSet.swift
//  ThreadSafeDataStructure
//
//  Created by PGB on 2019/11/12.
//

import Foundation

/// special API different from system
public extension SafeSet {
    /// Set new elements to the data inside
    /// - Parameter set: New elements to replace current elements
    func replaceInnerData(by set: Set<Element>) {
        synchronizationDelegate.writeOperation {
            data = set
        }
    }

    /// return a copy of the data inside of type 'Set'
    func getImmutableCopy() -> Set<Element> {
        return synchronizationDelegate.readOperation {
            return data
        }
    }

    /// Accesses the elements under shared lock.
    /// - Parameter action: The action to run on the struct.
    func safeRead(all action: ((Set<Element>) -> Void)) {
        synchronizationDelegate.readOperation {
            action(data)
        }
    }

    /// Accesses the elements under exclusive lock.
    /// - Parameter action: The action to run on the struct.
    func safeWrite(all action: ((inout Set<Element>) -> Void)) {
        synchronizationDelegate.writeOperation {
            action(&data)
        }
    }
}

/// A thread-safe, unordered collection of unique elements implemented as a **class**.
///
/// Checkout the [guidebook](https://bytedance.feishu.cn/space/doc/doccnNb7YCSPctnUGmWNEUs3Ywh) to get started with more information
/// - Important: The ThreadSafeDataStructure only ensure of the safety itself,
/// The strategy for the safety of elements inside is still under consideration
public final class SafeSet<Element> where Element: Hashable {
    let synchronizationDelegate: SynchronizationDelegate
    var data: Set<Element>
    let elementIsValueType: Bool

    /// Creates a thread-safe set by given Set and SynchronizationType
    public convenience init(_ data: Set<Element> = Set<Element>(),
                            synchronization: SynchronizationType = .readWriteLock) {
        let synchronizationDelegate = synchronization.generateSynchronizationDelegate()
        self.init(data, synchronizationDelegate: synchronizationDelegate)
    }

    /// Returns a new set containing the elements of the set that satisfy the given predicate.
    @available(swift 4.0)
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Set<Element> {
        return try synchronizationDelegate.readOperation {
            return try data.filter(isIncluded)
        }
    }

    /// Returns a new set with the elements of both this and the given set.
    public func union<S>(_ other: S) -> Set<Element> where Element == S.Element, S: Sequence {
        return synchronizationDelegate.readOperation {
            return data.union(other)
        }
    }

    /// Returns a new set with the elements that are common to both this set and the given set.
    public func intersection(_ other: Set<Element>) -> Set<Element> {
        return synchronizationDelegate.readOperation {
            return data.intersection(other)
        }
    }

    /// Returns a new set with the elements that are either in this set or in the given set, but not in both.
    public func symmetricDifference(_ other: Set<Element>) -> Set<Element> {
        return synchronizationDelegate.readOperation {
            return data.symmetricDifference(other)
        }
    }

    /// Returns a new set containing the elements of this set that do not occur in the given set.
    public func subtracting(_ other: Set<Element>) -> Set<Element> {
        return synchronizationDelegate.readOperation {
            return data.subtracting(other)
        }
    }

    /// Removes the elements of the set that are also in the given set and
    /// adds the members of the given set that are not already in the set.
    public func formSymmetricDifference(_ other: Set<Element>) {
        synchronizationDelegate.writeOperation {
            data.formSymmetricDifference(other)
        }
    }

    /// Adds the elements of the given set to the set.
    public func formUnion(_ other: Set<Element>) {
        synchronizationDelegate.writeOperation {
            data.formUnion(other)
        }
    }

    /// Removes the elements of this set that aren’t also in the given set.
    public func formIntersection(_ other: Set<Element>) {
        synchronizationDelegate.writeOperation {
            data.formIntersection(other)
        }
    }

    /// Removes the elements of the given set from this set.
    public func subtract(_ other: Set<Element>) {
        synchronizationDelegate.writeOperation {
            data.subtract(other)
        }
    }

    /// Returns a Boolean value that indicates whether the set is a subset of another set.
    public func isSubset(of other: Set<Element>) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.isSubset(of: other)
        }
    }

    /// Returns a Boolean value that indicates whether the set is a superset of the given set.
    public func isSuperset(of other: Set<Element>) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.isSuperset(of: other)
        }
    }

    /// Returns a Boolean value that indicates whether the set has no members in common with the given set.
    public func isDisjoint(with other: Set<Element>) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.isDisjoint(with: other)
        }
    }

    /// Returns a Boolean value that indicates whether the set is a strict superset of the given sequence.
    public func isStrictSuperset(of other: Set<Element>) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.isStrictSuperset(of: other)
        }
    }

    /// Returns a Boolean value that indicates whether the set is a strict subset of the given sequence.
    public func isStrictSubset(of other: Set<Element>) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.isStrictSubset(of: other)
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

    /// Returns a Boolean value that indicates whether the given element exists in the set.
    public func contains(_ member: Element) -> Bool {
        return synchronizationDelegate.readOperation {
            return data.contains(member)
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

    /// Returns an array containing the results of mapping the given closure over the sequence’s elements.
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        return try synchronizationDelegate.readOperation {
            return try data.map(transform)
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
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> [Element] {
        return try synchronizationDelegate.readOperation {
            return try data.sorted(by: areInIncreasingOrder)
        }
    }

    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try synchronizationDelegate.readOperation {
            try data.forEach(body)
        }
    }

    // MARK: - internal & private functions implementations from here
    private init(_ data: Set<Element>, synchronizationDelegate: SynchronizationDelegate) {
        self.data = data
        self.synchronizationDelegate = synchronizationDelegate
        self.elementIsValueType = !(Element.self is AnyClass)
    }
}

extension SafeSet {
    /// A Boolean value that indicates whether the set is empty.
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
    /// The number of elements in the set.
    public var count: Int {
        return synchronizationDelegate.readOperation {
            return data.count
        }
    }
}

extension SafeSet {
    /// Inserts the given element in the set if it is not already present.
    @discardableResult
    public func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        return synchronizationDelegate.writeOperation {
            return data.insert(newMember)
        }
    }

    /// Inserts the given element into the set unconditionally.
    public func update(with newMember: Element) -> Element? {
        return synchronizationDelegate.writeOperation {
            return data.update(with: newMember)
        }
    }

    /// Removes the given element and any elements subsumed by the given element.
    public func remove(_ member: Element) -> Element? {
        return synchronizationDelegate.writeOperation {
            return data.remove(member)
        }
    }

    /// Removes all members from the set.
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        return synchronizationDelegate.writeOperation {
            return data.removeAll(keepingCapacity: keepCapacity)
        }
    }
}

extension SafeSet: CustomStringConvertible {
    public var description: String {
        return synchronizationDelegate.readOperation {
            return data.description
        }
    }
}

public extension SafeSet where Element: Comparable {
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
    func sorted() -> [Element] {
        return synchronizationDelegate.readOperation {
            return data.sorted()
        }
    }
}
