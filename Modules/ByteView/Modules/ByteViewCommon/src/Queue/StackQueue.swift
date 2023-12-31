//
//  StackQueue.swift
//  ByteViewCommon
//
//  Created by fakegourmet on 2023/4/11.
//

import Foundation

public struct StackQueue<T>: QueueProtocol {

    private var leftStack: [T] = []
    private var rightStack: [T] = []
    public init() {}

    public var count: Int {
        leftStack.count + rightStack.count
    }

    public var isEmpty: Bool {
        leftStack.isEmpty && rightStack.isEmpty
    }

    public var peek: T? {
        leftStack.isEmpty ? rightStack.first : leftStack.last
    }

    public var tail: T? {
        leftStack.isEmpty ? rightStack.last : leftStack.first
    }

    @discardableResult
    mutating public func enqueue(_ element: T) -> Bool {
        rightStack.append(element)
        return true
    }

    @discardableResult
    mutating public func dequeue() -> T? {
        if leftStack.isEmpty {
            leftStack = rightStack.reversed()
            rightStack.removeAll()
        }
        return leftStack.popLast()
    }

    mutating public func clear() {
        leftStack.removeAll()
        rightStack.removeAll()
    }
}
