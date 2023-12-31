//
//  TimeConsumingTest.swift
//  ThreadSafeDataStructureDev
//
//  Created by PGB on 2019/11/12.
//

import Foundation
import ThreadSafeDataStructure

// swiftlint:disable all
class TimeConsumingTest {
    let shared = TimeConsumingTest()
    private init() {}

    func generateCreateTimeData() {
        print(
            averageCreateTime(size: 1000, using: .readWriteLock),
            averageCreateTime(size: 1000, using: .concurrentQueue),
            averageCreateTime(size: 1000, using: .semaphore),
            averageCreateTime(size: 1000, using: .unfairLock)
        )
    }

    func averageAccessTimeDataForThreads() {
        let util = TestUtil.shared

        let arrays = [
            util.generateRandomArray(size: 100, synchronization: .readWriteLock),
            util.generateRandomArray(size: 100, synchronization: .concurrentQueue),
            util.generateRandomArray(size: 100, synchronization: .semaphore),
            util.generateRandomArray(size: 100, synchronization: .unfairLock)
        ]

        var n = 0
        for array in arrays {
            sleep(5)
            print("num_list\(n) = ", terminator: "[")
            for i in 0..<10 {
                let terminator = i == 9 ? "" : ","
                print(averageAccessTime(array: array, concurrentThreads: i+1, writeRatio: 0.1), terminator: terminator)
            }
            print("]")
            n += 1
        }
    }

    func averageAccessTimeDataForWrites() {
        let util = TestUtil.shared

        let arrays = [
            util.generateRandomArray(size: 100, synchronization: .readWriteLock),
            util.generateRandomArray(size: 100, synchronization: .concurrentQueue),
            util.generateRandomArray(size: 100, synchronization: .semaphore),
            util.generateRandomArray(size: 100, synchronization: .unfairLock)
        ]

        var n = 0
        for array in arrays {
            sleep(5)
            print("num_list\(n) = ", terminator: "[")
            for i in 0...10 {
                let ratio = Double(i) / 10.0
                let terminator = i == 10 ? "" : ","
                print(averageAccessTime(array: array, concurrentThreads: 4, writeRatio: ratio), terminator: terminator)
            }
            print("]")
            n += 1
        }
    }

    func averageAccessTime(array: SafeArray<Int>, concurrentThreads: Int, writeRatio: Double) -> Double {
        let util = TestUtil.shared
        var sum = 0.0

        let round = 1000
        for _ in 0..<round {

            let workingGroup = DispatchGroup()
            var roundTime = 0.0

            for _ in 0..<concurrentThreads {
                DispatchQueue.global().async(group: workingGroup) {
                    let duration = util.calculateDuration {
                        util.randomAccess(array, totalTimes: 10, writeRatio: writeRatio)
                    }
                    roundTime += duration
                }
            }

            workingGroup.wait()
            sum += roundTime / Double(concurrentThreads)
        }
        return sum / Double(round)
    }

    func averageCreateTime(size: Int, using delegate: SynchronizationType) -> Double {
        let util = TestUtil.shared
        var sum = 0.0
        var array = [Int]()
        for _ in 0 ..< size {
            array.append(Int.random(in: 0 ..< 1000))
        }
        let round = 100
        for _ in 0..<round {
            let creatingTime = util.calculateDuration {
                _ = SafeArray(array, synchronization: delegate)
            }
            sum += creatingTime
        }
        return sum / Double(round)
    }

    func averageAccessTimeTest(array: SafeArray<Int>, totalTimes: Int, writeRatio: Double) {
        let util = TestUtil.shared
        util.asyncTest {
            Thread.current.name = "1"
            util.randomAccess(array, totalTimes: totalTimes, writeRatio: writeRatio)
        }

        util.asyncTest {
            Thread.current.name = "2"
            util.randomAccess(array, totalTimes: totalTimes, writeRatio: writeRatio)
        }

        util.asyncTest {
            Thread.current.name = "3"
            util.randomAccess(array, totalTimes: totalTimes, writeRatio: writeRatio)
        }

        util.asyncTest {
            Thread.current.name = "4"
            util.randomAccess(array, totalTimes: totalTimes, writeRatio: writeRatio)
        }
    }

}
// swiftlint:enable all
