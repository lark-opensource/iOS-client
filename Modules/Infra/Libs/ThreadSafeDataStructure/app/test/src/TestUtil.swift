//
//  TestUtil.swift
//  DSDemo
//
//  Created by PGB on 2019/8/29.
//

import Foundation
import ThreadSafeDataStructure

// swiftlint:disable all
/// 线程安全数据结构单元测试设计文档：
/// https://bytedance.feishu.cn/space/doc/doccnWLQeAb8iZQsDhNeKdy7Ehb#y6gQrJ
class TestUtil {
    static let shared: TestUtil = TestUtil()
    var workerCount = 0
    var durations: [TimeInterval] = []
    let synchronizations: [SynchronizationType] = [.readWriteLock, .concurrentQueue, .semaphore, .unfairLock, .recursiveLock]
    private init() {}

    func randomInt(min: Int = 0, max: Int = 1_000) -> Int {
        return Int.random(in: min..<max)
    }

    func generateRandomArray(size: Int, synchronization: SynchronizationType) -> SafeArray<Int> {
        var array: [Int] = []
        for _ in 0 ..< size {
            array.append(randomInt())
        }
        return array + synchronization
    }

    func generateRandomArrayOfReferenceType(size: Int, synchronization: SynchronizationType) -> SafeArray<Model> {
        var array: [Model] = []
        for _ in 0 ..< size {
            array.append(Model(value: randomInt()))
        }
        return array + synchronization
    }

    func generateRandomDictionary(size: Int, synchronization: SynchronizationType) -> SafeDictionary<Int, String> {
        var dict: [Int: String] = [:]
        for i in 0 ..< size {
            dict[i] = String(randomInt())
        }
        return dict + synchronization
    }

    func generateRandomDictionaryOfReferenceType(size: Int, synchronization: SynchronizationType) -> SafeDictionary<Int, Model> {
        var dict: [Int: Model] = [:]
        for i in 0 ..< size {
            dict[i] = Model(value: randomInt())
        }
        return dict + synchronization
    }

    func generateRandomSet(size: Int, synchronization: SynchronizationType) -> SafeSet<Int> {
        var set: Set<Int> = []
        for _ in 0 ..< size {
            set.insert(randomInt())
        }
        return SafeSet(set, synchronization: synchronization)
    }

    func generateRandomSetOfReferenceType(size: Int, synchronization: SynchronizationType) -> SafeSet<Model> {
        var set: Set<Model> = []
        for _ in 0 ..< size {
            set.insert(Model(value: randomInt()))
        }
        return SafeSet(set, synchronization: synchronization)
    }

    func generateRandomAtomic(synchronization: SynchronizationType) -> SafeAtomic<Int> {
        return randomInt() + synchronization
    }

    func generateRandomAtomicOfReferenceType(synchronization: SynchronizationType) -> SafeAtomic<Model> {
        return Model(value: randomInt()) + synchronization
    }

    func calculateDuration(block: () -> Void) -> TimeInterval {
        let start = Date().timeIntervalSince1970
        block()
        let end = Date().timeIntervalSince1970
        return end - start
    }

    func randomAccess(_ array: SafeArray<Int>, totalTimes: Int, writeRatio: Double) {
        for _ in 0 ..< totalTimes {
            let critical = Int(writeRatio * 100)
            let read = randomInt(min: 0, max: 100) > critical ? true : false
            let index = Int(arc4random()) % 100
            if read {
                _ = array[index]
            } else {
                array[index] = Int(arc4random())
            }
        }
    }

    func asyncTest(block: @escaping () -> Void) {
        let label = "Queue " + String(workerCount)
        workerCount += 1
        DispatchQueue(label: label).async {
            let duration = self.calculateDuration {
                block()
            }
            print(label, "finished working in", duration, "s")
        }
    }

    func asyncTestWithGroup(group: DispatchGroup, block: @escaping () -> Void) {
        let label = "Queue " + String(workerCount)
        workerCount += 1
        DispatchQueue(label: label).async(group: group) {
            let duration = self.calculateDuration {
                block()
            }
            print(label, "finished working in", duration, "s")
        }
    }

    func asyncTestWithGroup(blocks: [() -> Void]) -> Double {
        let group = DispatchGroup()
        var timeSum = 0.0
        for block in blocks {
            let label = "Queue " + String(workerCount)
            workerCount += 1
            DispatchQueue(label: label).async(group: group) {
                let duration = self.calculateDuration {
                    block()
                }
                timeSum += duration
            }
        }
        group.wait()
        return timeSum / Double(blocks.count) * 1000
    }

    func runCorrectnessCheck(for structType: UnitTest.StructType,
                             elementType: UnitTest.ElementType,
                             totalCount: Int = 1,
                             testCaseNum: Int) {
        let synchronizations: [SynchronizationType] = [.readWriteLock, .concurrentQueue, .semaphore, .unfairLock, .recursiveLock]
        for synchronization in synchronizations {
            let unitTest = UnitTest()
            for _ in 0 ..< totalCount {
                switch structType {
                case .array:
                    switch elementType {
                    case .value: unitTest.appendArrayTestCases(num: testCaseNum, synchronization: synchronization)
                    case .reference: unitTest.appendArrayTestCasesWithReferenceType(num: testCaseNum, synchronization: synchronization)
                    }
                case .dictionary:
                    switch elementType {
                    case .value: unitTest.appendDictionaryTestCases(num: testCaseNum, synchronization: synchronization)
                    case .reference: unitTest.appendDictionaryTestCasesWithReferenceType(num: testCaseNum, synchronization: synchronization)
                    }
                case .set:
                    switch elementType {
                    case .value: unitTest.appendSetTestCases(num: testCaseNum, synchronization: synchronization)
                    case .reference: unitTest.appendSetTestCasesWithReferenceType(num: testCaseNum, synchronization: synchronization)
                    }
                case .atomic:
                switch elementType {
                    case .value: unitTest.appendAtomicTestCases(num: testCaseNum, synchronization: synchronization)
                    case .reference: unitTest.appendAtomicTestCasesWithReferenceType(num: testCaseNum, synchronization: synchronization)
                    }
                }
            }
            unitTest.compareResultForAllTestCases(calculateTime: totalCount != 1)
            if totalCount != 1 {
                let threadSafeTime = unitTest.getTotalTime(of: .threadSafe, ratio: totalCount)
                let originalTime = unitTest.getTotalTime(of: .original, ratio: totalCount)
                let percentage = String(format: "%.2f", arguments: [(threadSafeTime / originalTime) * 100])
                print("\(threadSafeTime.fourDigit)(\(percentage)%) \(originalTime.fourDigit)")
            }
        }
    }

    func runMultiThreadTest(for structType: UnitTest.StructType,
                            elementType: UnitTest.ElementType,
                            threadCount: Int = 5,
                            testCaseCountPerThread: Int = 1000,
                            averageCountForTimeMeasuring: Int = 1) {
        let synchronizations: [SynchronizationType] = [.readWriteLock, .concurrentQueue, .semaphore, .unfairLock, .recursiveLock]
        let util = self

        var testCasesSequence: [(threadNum: Int, testCaseNum: Int)] = []
        for _ in 0 ..< testCaseCountPerThread {
            let threadNum = Int.random(in: 0 ..< threadCount)
            let testCaseNum = Int.random(in: 1...3)
            testCasesSequence.append((threadNum, testCaseNum))
        }

        for synchronization in synchronizations {
            var originalSum: Double = 0
            var threadSafeSum: Double = 0

            for _ in 0 ..< averageCountForTimeMeasuring {
                let threads = Array(repeating: UnitTest(), count: threadCount)

                switch structType {
                case .array:
                    switch elementType {
                    case .value:
                        let array = util.generateRandomArray(size: 100, synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendArrayTestCases(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeArray: array,
                                originalData: array.getImmutableCopy())
                        }
                    case .reference:
                        let array = util.generateRandomArrayOfReferenceType(size: 100, synchronization: synchronization)
                        for i in 0..<100 {
                            threads[testCasesSequence[i].threadNum].appendArrayTestCasesWithReferenceType(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeArray: array)
                        }
                    }
                case .dictionary:
                    switch elementType {
                    case .value:
                        let dict = util.generateRandomDictionary(size: 100, synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendDictionaryTestCases(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeDict: dict)
                        }
                    case .reference:
                        let dict = util.generateRandomDictionaryOfReferenceType(size: 100, synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendDictionaryTestCasesWithReferenceType(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeDict: dict)
                        }
                    }
                case .set:
                    switch elementType {
                    case .value:
                        let set = util.generateRandomSet(size: 100, synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendSetTestCases(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeSet: set)
                        }
                    case .reference:
                        let set = util.generateRandomSetOfReferenceType(size: 100, synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendSetTestCasesWithReferenceType(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeSet: set)
                        }
                    }
                case .atomic:
                    switch elementType {
                    case .value:
                        let atomic = util.generateRandomAtomic(synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendAtomicTestCases(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeAtomic: atomic)
                        }
                    case .reference:
                        let atomic = util.generateRandomAtomicOfReferenceType(synchronization: synchronization)
                        for i in 0..<testCaseCountPerThread {
                            threads[testCasesSequence[i].threadNum].appendAtomicTestCasesWithReferenceType(
                                num: testCasesSequence[i].testCaseNum,
                                synchronization: synchronization,
                                threadSafeAtomic: atomic)
                        }
                    }
                }

                threadSafeSum += util.asyncTestWithGroup(blocks: threads.map {
                    $0.runThreadSafeTestCases
                })

                guard averageCountForTimeMeasuring != 1 else { break }
                originalSum += util.asyncTestWithGroup(blocks: threads.map {
                    $0.runOriginalTestCases
                })
            }

            guard averageCountForTimeMeasuring != 1 else { continue }
            let threadSafeTime = threadSafeSum / Double(averageCountForTimeMeasuring)
            let originalTime = originalSum / Double(averageCountForTimeMeasuring)

            let percentage = String(format: "%.2f", arguments: [(threadSafeTime / originalTime) * 100])
            print("\(threadSafeTime.fourDigit)(\(percentage)%) \(originalTime.fourDigit)")
        }
    }
}
