//
//  UnitTest + SafeAtomic.swift
//  ThreadSafeDataStructureDev
//
//  Created by PGB on 2019/11/29.
//

import Foundation
import ThreadSafeDataStructure

extension UnitTest {
    func appendAtomicTestCases(num: Int, synchronization: SynchronizationType,
                               threadSafeAtomic: SafeAtomic<Int>? = nil, originalData: Int? = nil) {
        let util = TestUtil.shared
        let atomic = threadSafeAtomic ?? util.generateRandomAtomic(synchronization: synchronization)
        var data = originalData ?? atomic.value

        if num == 1 {
            for _ in 0 ..< 100 {
                let value: Int = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    atomic.value = value
                    return atomic.value
                }, originalOperation: {
                    data = value
                    return data
                }, errorMessage: "var value: Int { get set }")
            }

            for _ in 0 ..< 100 {
                var value: Int = 0
                appendTestCase(threadSafeOperation: {
                    atomic.safeRead { data in
                        value = data
                    }
                    return value
                }, originalOperation: {
                    value = data
                    return value
                }, errorMessage: "func safeRead(action: ((Int) -> Void))")
            }

            for _ in 0 ..< 100 {
                let value: Int = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    atomic.safeWrite { data in
                        data = value
                    }
                    return atomic
                }, originalOperation: {
                    data = value
                    return data
                }, errorMessage: "func safeWrite(action: ((Int) -> Void))")
            }
        }
    }

    func appendAtomicTestCasesWithReferenceType(num: Int, synchronization: SynchronizationType,
                                                threadSafeAtomic: SafeAtomic<Model>? = nil) {
        let util = TestUtil.shared
        let atomic = threadSafeAtomic ?? util.generateRandomAtomicOfReferenceType(synchronization: synchronization)
        var data = atomic.value

        if num == 1 {
            for _ in 0 ..< 100 {
                var value = Model(value: util.randomInt())
                appendTestCase(threadSafeOperation: {
                    atomic.value = value
                    return atomic.value
                }, originalOperation: {
                    data = value
                    return data
                }, errorMessage: "var value: Model { get set }")
            }

            for _ in 0 ..< 100 {
                var value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    atomic.safeRead { data in
                        value = data.value
                    }
                    return value
                }, originalOperation: {
                    value = data.value
                    return value
                }, errorMessage: "func safeRead(action: ((Model) -> Void))")
            }

            for _ in 0 ..< 100 {
                var value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    atomic.safeWrite { data in
                        data.value = value
                    }
                    return atomic
                }, originalOperation: {
                    data.value = value
                    return data
                }, errorMessage: "func safeWrite(action: ((Model) -> Void))")
            }
        }
    }
}
