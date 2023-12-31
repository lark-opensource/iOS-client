//
//  RingBuffer.swift
//  ByteViewCommon
//
//  Created by fakegourmet on 2023/2/14.
//

import Foundation
import EEAtomic

public struct RingBuffer<T>: QueueProtocol {

    /// 满队列策略
    public enum FullStrategy {
        case ignore /// 忽略新元素
        case overwrite /// 覆盖 head
    }

    /// 满阈值策略
    public enum ThresholdStrategy {
        case none /// 不做任何变化
        case double /// 一次有两个数据出队
    }

    @RwAtomic
    private var elements: [T?] = []

    private var head = AtomicUInt(0)
    private var tail = AtomicUInt(0)

    /// 最大容量
    private(set) var capacity: UInt = 0

    /// 阈值，超过阈值可调整入列策略
    /// 阈值应确保小于等于最大容量
    private(set) var threshold: UInt = 0

    private(set) var fullStrategy: FullStrategy = .overwrite
    private(set) var thresholdStrategy: ThresholdStrategy = .none

    public var count: Int {
        elements.compactMap { $0 }.count
    }

    public var isEmpty: Bool {
        elements.allSatisfy({ $0 == nil })
    }

    public var isFull: Bool {
        return count == capacity
    }

    public var isReachThreshold: Bool {
        return count >= threshold
    }

    public var peek: T? {
        return elements[head.index]
    }

    /// - Parameter capacity: 队列最大容量
    /// - Parameter threshold: 队列策略阈值，应小于capacity
    /// - Parameter FullStrategy: 队列为满时 enqueue 行为，默认覆盖操作
    /// - Parameter ThresholdStrategy: 达到阈值时 dequeue 行为，默认无操作
    public init(capacity: UInt, threshold: UInt = 0, fullStrategy: FullStrategy = .overwrite, thresholdStrategy: ThresholdStrategy = .none) {
        assert(threshold <= capacity, "error threshold is larger than capacity")
        self.elements = [T?](repeating: nil, count: Int(capacity))
        self.capacity = capacity
        self.threshold = threshold
        self.fullStrategy = fullStrategy
        self.thresholdStrategy = thresholdStrategy
    }

    public mutating func enqueue(_ element: T) -> Bool {
        if isFull {
            switch fullStrategy {
            case .ignore:
                return false
            case .overwrite: dequeue()
            }
        }

        elements[increment(tail).toInt()] = element
        return true
    }

    @discardableResult
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        }

        let isDouble: Bool = thresholdStrategy == .double && isReachThreshold

        defer {
            if isDouble {
                elements[increment(head).toInt()] = nil
            }
        }

        let index = increment(head).toInt()
        let element = elements[index]
        elements[index] = nil
        return element
    }

    public mutating func clear() {
        head.value = 0
        tail.value = 0
        for idx in 0..<elements.count {
            elements[idx] = nil
        }
    }

    private func increment(_ pointer: AtomicUInt) -> UInt {
        var next: UInt
        repeat {
            next = pointer.increment() + 1
            if next >= capacity && pointer.compare(expected: next, replace: 0) {
                return 0
            }
        } while(next >= capacity)
        return next
    }
}

extension RingBuffer: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        elements.description
    }

    public var debugDescription: String {
        elements.debugDescription
    }
}

fileprivate extension UInt {
    @inline(__always)
    func toInt() -> Int { Int(self) }
}

fileprivate extension AtomicUInt {
    var index: Int { value.toInt() }
}
