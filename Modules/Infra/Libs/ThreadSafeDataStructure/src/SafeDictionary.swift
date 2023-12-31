//
//  SafeDictionary.swift
//  ThreadSafeDataStructure
//
//  Created by PGB on 2019/11/5.
//

import Foundation

/// special API different from system
public extension SafeDictionary {
    /// Set new elements to the data inside
    /// - Parameter dictionary: New elements to replace current elements
    func replaceInnerData(by dictionary: [Key: Value]) {
        synchronizationDelegate.writeOperation {
            data = dictionary
        }
    }

    /// return a copy of the data inside of type 'Dictionary'.
    func getImmutableCopy() -> [Key: Value] {
        return synchronizationDelegate.readOperation {
            return self.data
        }
    }

    /// Accesses the value associated with the given key for reading.
    /// - Parameter key: The key the look up in the dictionary.
    /// - Parameter defaultValue: defaultValue: The default value to use if `key` doesn't exist in the dictionary.
    /// - Parameter action: The action on the value.
    func safeRead(for key: Key, default defaultValue: Value? = nil, action: ((Value?) -> Void)) {
        synchronizationDelegate.readOperation {
            if let defaultValue = defaultValue {
                action(data[key, default: defaultValue])
            } else {
                action(data[key])
            }
        }
    }

    /// Accesses the value associated with the given key for writing.
    /// - Parameter key: The key the look up in the dictionary.
    /// - Parameter action: The action on the value.
    func safeWrite(for key: Key, action: ((inout Value?) -> Void)) {
        synchronizationDelegate.writeOperation {
            action(&data[key])
        }
    }

    /// Accesses the dictionary for reading.
    /// - Parameter action: The action on the struct.
    func safeRead(all action: (([Key: Value]) -> Void)) {
        synchronizationDelegate.readOperation {
            action(data)
        }
    }

    /// Accesses the dictionary for writing.
    /// - Parameter action: The action on the struct.
    func safeWrite(all action: ((inout [Key: Value]) -> Void)) {
        synchronizationDelegate.writeOperation {
            action(&data)
        }
    }
}

/// Init a 'SafeDictionary' by using an dictionary literal and a designated synchronization primtive
/// - Parameter elements: Inner data of the safeDictionary
/// - Parameter synchronization: The synchronization primtive type used in this safeDictionary
public func +<Key, Value>(data: [Key: Value],
                          synchronization: SynchronizationType) -> SafeDictionary<Key, Value> where Key: Hashable {
    return SafeDictionary(data, synchronization: synchronization)
}

/// A thread-safe collection whose elements are key-value pairs implemented as a **class**.
///
/// Checkout the [guidebook](https://bytedance.feishu.cn/space/doc/doccnNb7YCSPctnUGmWNEUs3Ywh) to get started with more information
/// - Important: The ThreadSafeDataStructure only ensure of the safety itself.
/// The strategy for the safety of elements inside is still under consideration
public final class SafeDictionary<Key, Value> where Key: Hashable {
    public typealias Element = (key: Key, value: Value)

    let synchronizationDelegate: SynchronizationDelegate
    var data: [Key: Value]
    let elementIsValueType: Bool

    /// Accesses the value associated with the given key for reading and writing.
    public subscript(key: Key) -> Value? {
        get {
            return synchronizationDelegate.readOperation {
                return data[key]
            }
        }
        set {
            synchronizationDelegate.writeOperation {
                data[key] = newValue
            }
        }
    }

    /// Accesses the value with the given key. If the dictionary doesn’t contain the given key,
    /// accesses the provided default value as if the key and default value existed in the dictionary.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            return synchronizationDelegate.readOperation {
                return data[key, default: defaultValue()]
            }
        }
        set {
            synchronizationDelegate.writeOperation {
                data[key] = newValue
            }
        }
    }

    /// A collection containing just the keys of the dictionary.
    public var keys: SafeArray<Key> {
        return synchronizationDelegate.readOperation {
            return SafeArray(data.keys.map { $0 }, synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    /// A collection containing just the values of the dictionary.
    public var values: SafeArray<Value> {
        return synchronizationDelegate.readOperation {
            return SafeArray(data.values.map { $0 }, synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    /// Creates a thread-safe dictionary by given Dictionary and SynchronizationType
    public convenience init(_ data: [Key: Value] = [:], synchronization: SynchronizationType = .readWriteLock) {
        let synchronizationDelegate = synchronization.generateSynchronizationDelegate()
        self.init(data, synchronizationDelegate: synchronizationDelegate)
    }

    /// Returns a new dictionary containing the key-value pairs of the dictionary that satisfy the given predicate.
    public func filter(_ isIncluded: (SafeDictionary.Element) throws -> Bool) rethrows -> SafeDictionary<Key, Value> {
        return try synchronizationDelegate.readOperation {
            return SafeDictionary(try data.filter(isIncluded),
                                  synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    /// Returns the first element of the sequence that satisfies the given predicate.
    public func first(where predicate: (SafeDictionary.Element) throws -> Bool) rethrows -> SafeDictionary.Element? {
        return try synchronizationDelegate.readOperation {
            return try data.first(where: predicate)
        }
    }

    /// Returns a new dictionary containing the keys of this dictionary
    /// with the values transformed by the given closure.
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        return try synchronizationDelegate.readOperation {
            return try data.mapValues(transform)
        }
    }

    /// Returns a new dictionary containing only the key-value pairs that
    /// have non-nil values as the result of transformation by the given closure.
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
         return try synchronizationDelegate.readOperation {
            return try data.compactMapValues(transform)
         }
    }

    /// Updates the value stored in the dictionary for the given key,
    /// or adds a new key-value pair if the key does not exist.
    @discardableResult
    public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        return synchronizationDelegate.writeOperation {
            return data.updateValue(value, forKey: key)
        }
    }

    /// Removes the given key and its associated value from the dictionary.
    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        return synchronizationDelegate.writeOperation {
            return data.removeValue(forKey: key)
        }
    }

    /// Removes all key-value pairs from the dictionary.
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        return synchronizationDelegate.writeOperation {
            return data.removeAll(keepingCapacity: keepCapacity)
        }
    }

    /// Returns an array containing the results of mapping the given closure over the sequence’s elements.
    public func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        return try synchronizationDelegate.writeOperation {
            return try data.map(transform)
        }
    }

    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    public func forEach(_ body: ((key: Key, value: Value)) throws -> Void) rethrows {
        return try synchronizationDelegate.readOperation {
            return try data.forEach(body)
        }
    }

    public func merging(_ other: SafeDictionary<Key, Value>, uniquingKeysWith: (Value, Value) throws -> Value) rethrows -> SafeDictionary<Key, Value> {
        return try synchronizationDelegate.readOperation {
            try other.synchronizationDelegate.readOperation {
                return try data.merging(other.data, uniquingKeysWith: uniquingKeysWith) + .readWriteLock
            }
        }
    }

    /// Returns the minimum element in the sequence, using the given predicate as the comparison between elements.
    @warn_unqualified_access
    public func min(by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value))
        throws -> Bool) rethrows -> (key: Key, value: Value)? {
        return try synchronizationDelegate.readOperation {
            return try data.min(by: areInIncreasingOrder)
        }
    }

    /// Returns the maximum element in the sequence, using the given predicate as the comparison between elements.
    @warn_unqualified_access
    public func max(by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value))
        throws -> Bool) rethrows -> (key: Key, value: Value)? {
        return try synchronizationDelegate.readOperation {
            return try data.max(by: areInIncreasingOrder)
        }
    }

    /// Returns a Boolean value indicating whether the sequence contains an element that satisfies the given predicate.
    public func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        return try synchronizationDelegate.readOperation {
            return try data.contains(where: predicate)
        }
    }

    /// Returns the result of combining the elements of the sequence using the given closure.
    public func reduce<Result>(_ initialResult: Result,
                               _ nextPartialResult: (Result, (key: Key, value: Value))
        throws -> Result) rethrows -> Result {
        return try synchronizationDelegate.readOperation {
            return try data.reduce(initialResult, nextPartialResult)
        }
    }

    /// Returns the result of combining the elements of the sequence using the given closure.
    public func reduce<Result>(into initialResult: Result,
                               _ updateAccumulatingResult: (inout Result, (key: Key, value: Value))
        throws -> Void) rethrows -> Result {
        return try synchronizationDelegate.readOperation {
            return try data.reduce(into: initialResult, updateAccumulatingResult)
        }
    }

    /// Returns an array containing the concatenated results of calling
    /// the given transformation with each element of this sequence.
    public func flatMap<SegmentOfResult>(_ transform: ((key: Key, value: Value))
        throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult: Sequence {
        return try synchronizationDelegate.readOperation {
            return try data.flatMap(transform)
        }
    }

    /// Returns an array containing the non-nil results of calling
    /// the given transformation with each element of this sequence.
    public func compactMap<ElementOfResult>(_ transform: ((key: Key, value: Value))
        throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        return try synchronizationDelegate.readOperation {
            return try data.compactMap(transform)
        }
    }

    /// Returns the elements of the sequence, sorted using the given predicate as the comparison between elements.
    public func sorted(by areInIncreasingOrder:((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool)
        rethrows -> SafeArray<(Key, Value)> {
        return try synchronizationDelegate.readOperation {
            return SafeArray(try data.sorted(by: areInIncreasingOrder),
                             synchronizationDelegate: generateSynchronizationDelegate())
        }
    }

    // MARK: - internal & private functions implementations from here
    private init(_ data: [Key: Value], synchronizationDelegate: SynchronizationDelegate) {
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

extension SafeDictionary {
    /// A Boolean value that indicates whether the dictionary is empty.
    public var isEmpty: Bool {
        return synchronizationDelegate.readOperation {
            return data.isEmpty
        }
    }

    /// The first element of the collection.
    public var first: (key: Key, value: Value)? {
        return synchronizationDelegate.readOperation {
            return data.first
        }
    }

    /// The number of key-value pairs in the dictionary.
    public var count: Int {
        return synchronizationDelegate.readOperation {
            return data.count
        }
    }
}

extension SafeDictionary: CustomStringConvertible {
    public var description: String {
        return synchronizationDelegate.readOperation {
            return String(describing: data)
        }
    }
}
