//
//  JitterBuffer.swift
//  ByteViewCommon
//
//  Created by fakegourmet on 2023/4/11.
//

import Foundation

public protocol JitterBufferProtocol {
    var timestamp: UInt64 { get }
}

public struct JitterBuffer<T: JitterBufferProtocol>: QueueProtocol {

    @RwAtomic
    private var queue = StackQueue<T>()

    /// 当前保存的容量
    @RwAtomic
    private var currentDuration: Int = 0

    /// 最大容量
    @RwAtomic
    public private(set) var maxDuration: Int = 1

    /// 渲染间隔(ms)
    @RwAtomic
    private(set) var renderInterval: Int = 16

    private mutating func updateOutputInterval() -> Int {
        let maxDuration: Float = Float(maxDuration > 0 ? maxDuration : 1)
        let outputInterval = Int(((Float(currentDuration) / maxDuration) + 1) * Float(renderInterval))
        return outputInterval
    }

    public init(maxDuration: Int) {
        self.maxDuration = maxDuration
    }

    public var isEmpty: Bool {
        queue.isEmpty
    }

    public var peek: T? {
        queue.peek
    }

    public var tail: T? {
        queue.tail
    }

    public mutating func setRenderInterval(_ interval: Int) {
        self.renderInterval = interval
    }

    @discardableResult
    public mutating func setMaxDuration(_ duration: Int) -> Bool {
        self.maxDuration = duration
        return true
    }

    @discardableResult
    public mutating func enqueue(_ element: T) -> Bool {
        var duration: Int = 0
        if let head = peek {
            duration = Int(element.timestamp - head.timestamp)
        } else {
            duration = 0
        }
        currentDuration = duration
        _ = queue.enqueue(element)
        return true
    }

    @discardableResult
    public mutating func dequeue() -> T? {
        guard var result: T = queue.dequeue() else {
            return nil
        }
        if var last = peek {
            var interval = renderInterval
            let delta: Int = Int(truncatingIfNeeded: last.timestamp - result.timestamp)
            let outputInterval = updateOutputInterval()
            while interval + delta < outputInterval {
                interval += delta
                guard let new = queue.dequeue() else {
                    // 预期不会走到这里
                    return result
                }
                result = new
                if let peek = peek {
                    last = peek
                } else {
                    // 没有下一条数据，直接返回
                    return result
                }
            }
        }
        return result
    }

    public mutating func clear() {
        queue.clear()
        currentDuration = 0
    }
}
