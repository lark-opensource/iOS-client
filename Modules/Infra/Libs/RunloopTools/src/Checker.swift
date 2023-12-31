//
//  Checker.swift
//  RunloopTools
//
//  Created by KT on 2020/2/11.
//

import Foundation
import ThreadSafeDataStructure

public protocol DispatcherChecker {
    func enable(task: Task) -> Bool
}

final class Checker {
    func append(_ checker: DispatcherChecker) {
        self.checkers.append(checker)
    }

    func pass(_ task: Task) -> Bool {
        // 有拦截项 不通过
        return self.checkers.filter { !$0.enable(task: task) }.isEmpty
    }

    private var checkers: SafeArray<DispatcherChecker> = [] + .readWriteLock
}
