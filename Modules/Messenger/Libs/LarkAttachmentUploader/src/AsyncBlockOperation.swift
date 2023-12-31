//
//  AsyncBlockOperation.swift
//  Lark
//
//  Created by lichen on 2017/8/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias AsyncOperationBlock = (_ completionHandler: @escaping () -> Void) -> Void

public final class AsyncBlockOperation: Operation {
    public var asyncBlock: AsyncOperationBlock

    public init(_ asyncBlock: @escaping AsyncOperationBlock) {
        self.asyncBlock = asyncBlock
        super.init()
    }

    public override func start() {
        if !self.isCancelled {
            self.isExecuting = true
            self.isFinished = false

            self.asyncBlock { [weak self] in
                self?.isExecuting = false
                self?.isFinished = true
            }

        } else {
            self.isFinished = true
        }
    }

    fileprivate var _executing: Bool = false
    public override var isExecuting: Bool {
        get { return _executing }
        set {
            if newValue != _executing {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    fileprivate var _finished: Bool = false
    public override var isFinished: Bool {
        get { return _finished }
        set {
            if newValue != _finished {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    public override var isAsynchronous: Bool {
        return true
    }

}

extension OperationQueue {
    @discardableResult
    public func add(asyncBlock: @escaping AsyncOperationBlock) -> AsyncBlockOperation {
        let asyncOperation = AsyncBlockOperation(asyncBlock)
        self.addOperation(asyncOperation)
        return asyncOperation
    }
}
