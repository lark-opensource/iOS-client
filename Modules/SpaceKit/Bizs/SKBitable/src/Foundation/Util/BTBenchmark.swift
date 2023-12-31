//
//  BTBenchmark.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/10/14.
//  


import Foundation
import UIKit

struct BTBenchmark {
    
    static func timeCost<T>(of task: () -> T?, taskDescription: String) -> T? {
        #if DEBUG
        let start = CACurrentMediaTime()
        let result = task()
        let end = CACurrentMediaTime()
        let cost = end - start
        debugPrint("BTBenchmark task \(taskDescription) time cost: \(cost) s")
        return result
        #else
        return task()
        #endif
    }
    
    static func reloadTimeCost(of reloadTask: () -> Void, taskDescription: String) {
        #if DEBUG
        let start = CACurrentMediaTime()
        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setCompletionBlock {
                let end = CACurrentMediaTime()
                let cost = end - start
                debugPrint("BTBenchmark reloadTask \(taskDescription) time cost: \(cost)")
            }
            reloadTask()
            CATransaction.commit()
        }
        #else
        reloadTask()
        #endif
    }
}
