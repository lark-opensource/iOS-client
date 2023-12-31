//
//  DocIdlePreloadTask.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/1/14.
//

import SKFoundation

/*
//闲时预加载任务
class DocIdlePreloadTask<Task: PreloadTask>: Operation {
    
    private var identifier: String
    private var preloader: SequeuePreloader<Task>
    
    init(identifier: String, preloader: SequeuePreloader<Task>) {
        self.identifier = identifier
        self.preloader = preloader
    }

    override func start() {
        DocsLogger.debug("start \(identifier) DocIdlePreloadTask")
        if !isCancelled {
            isExecuting = true
            isFinished = false
            preloader.startWholeTask(complete: { [weak self] in
                guard let self = self else { return }
                self.completeWholeTask()
            })
        } else {
            isFinished = true
        }
    }

    override func cancel() {
        super.cancel()
        preloader.clear()
        isExecuting = false
        isFinished = true
    }

    private func completeWholeTask() {
        DocsLogger.debug("complete \(identifier) DocIdlePreloadTask")
        isExecuting = false
        isFinished = true
    }
    
    //通过KVO设置或者获取Operation状态
    override var isAsynchronous: Bool {
        return true
    }

    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
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
    override var isFinished: Bool {
        get { return _finished }
        set {
            if newValue != _finished {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
}
*/
