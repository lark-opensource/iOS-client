//
//  Queue+ext.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/8.
//

import Foundation

public func docExpectOnQueue(_ queue: DispatchQueue) {
    #if DEBUG
    dispatchPrecondition(condition: .onQueue(queue))
    #endif
}

extension DispatchQueue {
    public func docAsyncAfter(_ delaySeconds: Double, block: @escaping () -> Void) {
        self.asyncAfter(deadline: DispatchTime.now() + delaySeconds, execute: block)
    }
    
    public class func safetyAsyncMain(execute work: @escaping (() -> Void)) {
        if Thread.isMainThread {
            work()
        } else {
            main.async(execute: work)
        }
    }

}
