//
//  UnitTest.swift
//  ThreadSafeDataStructureDev
//
//  Created by PGB on 2019/11/12.
//

import Foundation
import ThreadSafeDataStructure
import XCTest

// swiftlint:disable all
class UnitTest {
    var testCases: [(threadSafeOperation: () -> Any?, originalOperation: () -> Any?, errorMessage: String)] = []

    var timerForThreadSafe = TimeAccumulator()
    var timerForOriginal = TimeAccumulator()

    func appendTestCase (threadSafeOperation: @escaping () -> Any?,
                         originalOperation: @escaping () -> Any?,
                         errorMessage: String = "") {
        testCases.append((threadSafeOperation, originalOperation, errorMessage))
    }

    func compareResultForAllTestCases(calculateTime: Bool = true, printDetail: Bool = false) {
        for testCase in testCases {
            let threadSafeResult = calculateTime ?
                timerForThreadSafe.accumulateDuration {
                    testCase.threadSafeOperation()
                }:
                testCase.threadSafeOperation()
            let originalResult = calculateTime ?
                timerForOriginal.accumulateDuration {
                    testCase.originalOperation()
                }:
                testCase.originalOperation()
            let sameResult = compare(threadSafeResult, originalResult)
            XCTAssert(sameResult, testCase.errorMessage)
            if !printDetail && !sameResult {
                print(threadSafeResult, originalResult)
            }
            if printDetail {
                print("===============================")
                print("running test case: \(testCase.errorMessage) ----- \(sameResult)")
                print(threadSafeResult, originalResult)
            }
        }
        testCases = []
    }

    func runThreadSafeTestCases() {
        for testCase in testCases {
            _ = testCase.threadSafeOperation()
        }
    }

    func runOriginalTestCases() {
        for testCase in testCases {
            _ = testCase.originalOperation()
        }
    }

    func compare(_ a: Any?, _ b: Any?) -> Bool {
        guard let anyA = a, let anyB = b else {
            return a == nil && b == nil
        }

        if String(describing: a) == String(describing: b) {
            return true
        }

        if let stringA = anyA as? String, let stringB = anyB as? String {
            return stringA == stringB
        }

        if let dictA = anyA as? SafeDictionary<Int, Model>, let dataB = anyB as? [Int: Model] {
            return dictA.getImmutableCopy() == dataB
        }

        if let arrayA = anyA as? SafeArray<Int>, let arraySliceB = anyB as? ArraySlice<Int> {
            return arrayA.getImmutableCopy() == Array(arraySliceB)
        }

        if let arrayA = anyA as? [Int], let arraySliceB = anyB as? ArraySlice<Int> {
            return arrayA == Array(arraySliceB)
        }

        if let arrayA = anyA as? SafeArray<Model>, let arraySliceB = anyB as? ArraySlice<Model> {
            return arrayA.getImmutableCopy() == Array(arraySliceB)
        }

        if let arrayA = anyA as? [Model], let arraySliceB = anyB as? ArraySlice<Model> {
            return arrayA == Array(arraySliceB)
        }

        if let dictA = anyA as? SafeDictionary<Int, String>, let dictB = anyB as? [Int: String] {
            return dictA.getImmutableCopy() == dictB
        }

        if let dictA = anyA as? [Int: String], let dictB = anyB as? [Int: String] {
            return dictA == dictB
        }

        if let arrayA = anyA as? SafeArray<Int>, let keysB = anyB as? Dictionary<Int, String>.Keys {
            return arrayA.getImmutableCopy() == keysB.map { $0 }
        }

        if let arrayA = anyA as? SafeArray<String>, let keysB = anyB as? Dictionary<Int, String>.Values {
            return arrayA.getImmutableCopy() == keysB.map { $0 }
        }

        if let arrayA = anyA as? SafeArray<Int>, let keysB = anyB as? Dictionary<Int, Model>.Keys {
            return arrayA.getImmutableCopy() == keysB.map { $0 }
        }

        if let arrayA = anyA as? SafeArray<Model>, let keysB = anyB as? Dictionary<Int, Model>.Values {
            return arrayA.getImmutableCopy() == keysB.map { $0 }
        }

        if let arrayA = anyA as? SafeArray<(Int, String)>, let arrayB = anyB as? [(Int, String)] {
            let arrayA = arrayA.getImmutableCopy()
            for i in 0 ..< arrayA.count where arrayA[i] != arrayB[i] {
                return false
            }
            return true
        }

        if let arrayA = anyA as? SafeArray<(Int, Model)>, let arrayB = anyB as? [(Int, Model)] {
            let arrayA = arrayA.getImmutableCopy()
            for i in 0 ..< arrayA.count where arrayA[i].1.value != arrayB[i].1.value {
                return false
            }
            return true
        }

        if let setA = anyA as? SafeSet<Int>, let setB = anyB as? Set<Int> {
            return setA.getImmutableCopy() == setB
        }

        if let setA = anyA as? Set<Int>, let setB = anyB as? Set<Int> {
            return setA == setB
        }

        if let setA = anyA as? SafeSet<Model>, let setB = anyB as? Set<Model> {
            return setA.getImmutableCopy() == setB
        }

        if let setA = anyA as? Set<Model>, let setB = anyB as? Set<Model> {
            return setA == setB
        }

        if let dictA = anyA as? [Int: Int], let dictB = anyB as? [Int: Int] {
            return dictA == dictB
        }

        if let atomicA = anyA as? SafeAtomic<Int>, let intB = anyB as? Int {
            return atomicA.value == intB
        }

        if let atomicA = anyA as? SafeAtomic<Model>, let modelB = anyB as? Model {
            return atomicA.value == modelB
        }

        return false
    }

    func getTotalTime(of timer: TimerType, ratio: Int = 1) -> Double {
        switch timer {
        case .threadSafe: return 1000.0 * timerForThreadSafe.total / Double(ratio)
        case .original: return 1000.0 * timerForOriginal.total / Double(ratio)
        }
    }

    class TimeAccumulator {
        var total: Double = 0
        func accumulateDuration<T>(block: () -> T) -> T {
            let start = Date().timeIntervalSince1970
            let result = block()
            let end = Date().timeIntervalSince1970
            total += end - start
            return result
        }
    }

    enum TimerType {
        case threadSafe
        case original
    }

    enum StructType {
        case array
        case dictionary
        case set
        case atomic
    }

    enum ElementType {
        case value
        case reference
    }
}

public class Model: CustomStringConvertible, Equatable, Hashable, Comparable {
    var value = 0
    init(value: Int) {
        self.value = value
    }

    func changeValue() {
        value = Int.random(in: 0 ..< 1_000)
    }

    public var description: String {
        return String(value)
    }

    public static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.value == rhs.value
    }

    public var hashValue: Int {
        return value
    }

    public static func < (lhs: Model, rhs: Model) -> Bool {
        return lhs.value < rhs.value
    }
}

extension Double {
    var fourDigit: String {
        return String(format: "%.4f", arguments: [self])
    }
}
// swiftlint:enable all
