//
//  File.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/5/14.
//  

import SKFoundation
import Foundation

public final class DebounceProcesser {

    var workItem: DispatchWorkItem?

    var isInProgressing: Bool {
        if let item = workItem, !item.isCancelled {
            return true
        }
        return false
    }

    public init() {}

    public func debounce(_ time: DispatchTimeInterval, action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            action()
            guard let self = self else { return }
            self.workItem?.cancel()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: workItem!)
    }

    public func endDebounce() {
        if let item = workItem, !item.isCancelled {
            DocsLogger.info("debounceProcesser endDebounce", component: LogComponents.comment)
            item.cancel()
        }
    }

    deinit {
        DocsLogger.info("debounceProcesser Deinit")
    }
}
