//
//  UnitTest + SafeSet.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by PGB on 2019/11/19.
//

import Foundation
import ThreadSafeDataStructure

// swiftlint:disable function_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length
extension UnitTest {
    func appendSetTestCases(num: Int,
                            synchronization: SynchronizationType,
                            threadSafeSet: SafeSet<Int>? = nil) {
        let util = TestUtil.shared
        let set = threadSafeSet ?? util.generateRandomSet(size: 100, synchronization: synchronization)

        if num == 1 {
            var data = set.getImmutableCopy()

            for _ in 0 ..< 100 {
                let value: Int = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    set.insert(value)
                    return set
                }, originalOperation: {
                    data.insert(value)
                    return data
                }, errorMessage: "func insert(_ newMember: Int) -> (inserted: Bool, memberAfterInsert: Int)")

                appendTestCase(threadSafeOperation: {
                    return set.remove(value)
                }, originalOperation: {
                    return data.remove(value)
                }, errorMessage: "func remove(_ member: Int) -> Int?")

                appendTestCase(threadSafeOperation: {
                    return set.update(with: value)
                }, originalOperation: {
                    return data.update(with: value)
                }, errorMessage: "func update(with newMember: Int) -> Int?")

                appendTestCase(threadSafeOperation: {
                    return set.sorted()
                }, originalOperation: {
                    return set.sorted()
                }, errorMessage: "func sorted() -> [Int]")
            }

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return set.contains(random)
            }, originalOperation: {
                return data.contains(random)
            }, errorMessage: "func contains(_ member: Int) -> Bool")

            appendTestCase(threadSafeOperation: {
                set.removeAll()
                return set
            }, originalOperation: {
                data.removeAll()
                return data
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return set.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomSet(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return set.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by set: Set<Int>)")
        }

        if num == 2 {
            let data = set.getImmutableCopy()

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSet(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSet(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.subtract(otherSet)
                }, originalOperation: {
                    return randomData.subtract(otherSet)
                }, errorMessage: "func subtract(_ other: Set<Int>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSet(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSet(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formUnion(otherSet)
                }, originalOperation: {
                    return randomData.formUnion(otherSet)
                }, errorMessage: "func formUnion(_ other: Set<Int>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSet(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSet(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formIntersection(otherSet)
                }, originalOperation: {
                    return randomData.formIntersection(otherSet)
                }, errorMessage: "func formIntersection(_ other: Set<Int>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSet(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSet(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formSymmetricDifference(otherSet)
                }, originalOperation: {
                    return randomData.formSymmetricDifference(otherSet)
                }, errorMessage: "func formSymmetricDifference(_ other: Set<Int>)")
            }

            for _ in 0 ..< 100 {
                let randomSet = util.generateRandomSet(size: data.count / 10, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return set.intersection(randomSet)
                }, originalOperation: {
                    return data.intersection(randomSet)
                }, errorMessage: "func intersection(_ other: Set<Int>) -> Set<Int>")

                appendTestCase(threadSafeOperation: {
                    return set.subtracting(randomSet)
                }, originalOperation: {
                    return data.subtracting(randomSet)
                }, errorMessage: "func subtracting(_ other: Set<Int>) -> Set<Int>")

                appendTestCase(threadSafeOperation: {
                    return set.union(randomSet)
                }, originalOperation: {
                    return data.union(randomSet)
                }, errorMessage: "func union<S>(_ other: S) -> Set<Int> where Element == S.Element, S : Sequence")

                appendTestCase(threadSafeOperation: {
                    return set.symmetricDifference(randomSet)
                }, originalOperation: {
                    return data.symmetricDifference(randomSet)
                }, errorMessage: "func symmetricDifference(_ other: Set<Int>) -> Set<Int>")

                appendTestCase(threadSafeOperation: {
                    return set.isSubset(of: randomSet)
                }, originalOperation: {
                    return data.isSubset(of: randomSet)
                }, errorMessage: "func isSubset(of other: Set<Int>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isSuperset(of: randomSet)
                }, originalOperation: {
                    return data.isSuperset(of: randomSet)
                }, errorMessage: "func isSuperset(of other: Set<Int>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isDisjoint(with: randomSet)
                }, originalOperation: {
                    return data.isDisjoint(with: randomSet)
                }, errorMessage: "func isSubset(of other: Set<Int>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isStrictSubset(of: randomSet)
                }, originalOperation: {
                    return data.isStrictSubset(of: randomSet)
                }, errorMessage: "func isStrictSubset(of other: Set<Int>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isStrictSuperset(of: randomSet)
                }, originalOperation: {
                    return data.isStrictSuperset(of: randomSet)
                }, errorMessage: "func isStrictSuperset(of other: Set<Int>) -> Bool")
            }

            for _ in 0 ..< 50 {
                appendTestCase(threadSafeOperation: {
                    return set.min { $0 < $1 }
                }, originalOperation: {
                    return data.min { $0 < $1 }
                }, errorMessage: "func min(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> Int?")
                appendTestCase(threadSafeOperation: {
                    return set.max { $0 < $1 }
                }, originalOperation: {
                    return data.max { $0 < $1 }
                }, errorMessage: "func max(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> Int?")
            }
            for _ in 0 ..< 100 {
                let value = util.randomInt()
                let containsCloure = { (element: Int) -> Bool in
                    return element > value
                }
                appendTestCase(threadSafeOperation: {
                    return set.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: (Int) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                return set.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> [Int]")

        }

        if num == 3 {
            let data = set.getImmutableCopy()

            var flatMapTestData: Set<[Int]> = []
            for _ in 0 ..< util.randomInt(min: 0, max: 5) {
                var element: [Int] = []
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    element.append(util.randomInt())
                }
                flatMapTestData.insert(element)
            }
            let flatMapTestSet = SafeSet(flatMapTestData, synchronization: synchronization)
            appendTestCase(threadSafeOperation: {
                return flatMapTestSet.flatMap { $0 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0 }
            }, errorMessage: "func flatMap<SegmentOfResult>(_ transform: ([Int]) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence")

            appendTestCase(threadSafeOperation: {
                return set.map { $0 + 3 }
            }, originalOperation: {
                return data.map { $0 + 3 }
            }, errorMessage: "func map<T>(_ transform: (Int) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return set.compactMap { $0 + 2 }
            }, originalOperation: {
                return data.compactMap { $0 + 2 }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: (Int) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return set.filter { $0 > random }
            }, originalOperation: {
                return data.filter { $0 > random }
            }, errorMessage: "func filter(_ isIncluded: (Int) throws -> Bool) rethrows -> [Int]")

            appendTestCase(threadSafeOperation: {
                return set.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> [Int]")

            appendTestCase(threadSafeOperation: {
                return set.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: Int? { get }")

            appendTestCase(threadSafeOperation: {
                return set.min()
            }, originalOperation: {
                return data.min()
            }, errorMessage: "func min() -> Int?")

            appendTestCase(threadSafeOperation: {
                return set.max()
            }, originalOperation: {
                return data.max()
            }, errorMessage: "func max() -> Int?")

            appendTestCase(threadSafeOperation: {
                return set.count
            }, originalOperation: {
                return data.count
            }, errorMessage: "var count: Int { get }")
        }

        if num == 4 {
            var data = set.getImmutableCopy()

            appendTestCase(threadSafeOperation: {
                return set.reduce(0) { result, element in
                    return result + element
                }
            }, originalOperation: {
                return data.reduce(0) { result, element in
                    return result + element
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Int) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                return set.reduce(into: 1) { result, element in
                    result += element
                }
            }, originalOperation: {
                return data.reduce(into: 1) { result, element in
                    result += element
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Int) throws -> ()) rethrows -> Result")

            var setResult: [Int] = []
            var dataResult: [Int] = []
            appendTestCase(threadSafeOperation: {
                set.forEach { element in
                    setResult.append(element)
                }
                return setResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element)
                }
                return dataResult
            }, errorMessage: "public func forEach(_ body: (Element) throws -> Void) rethrows")

            var setEnumeratedArray: [Int] = []
            var dataEnumeratedArray: [Int] = []
            appendTestCase(threadSafeOperation: {
                set.safeRead { data in
                    for (i, element) in data.enumerated() {
                        setEnumeratedArray.append(i)
                        setEnumeratedArray.append(element)
                    }
                }
                return setEnumeratedArray
            }, originalOperation: {
                for (i, element) in data.enumerated() {
                    dataEnumeratedArray.append(i)
                    dataEnumeratedArray.append(element)
                }
                return dataEnumeratedArray
            }, errorMessage: "func safeRead(all action: ((Set<Int>) -> Void))")

            appendTestCase(threadSafeOperation: {
                set.safeWrite { data in
                    for (i, element) in data.enumerated() {
                        data.insert(i)
                        data.insert(element)
                    }
                }
                return set
            }, originalOperation: {
                for (i, element) in data.enumerated() {
                    data.insert(i)
                    data.insert(element)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout Set<Int>) -> Void))")
        }
    }

    func appendSetTestCasesWithReferenceType(num: Int, synchronization: SynchronizationType, threadSafeSet: SafeSet<Model>? = nil) {
        let util = TestUtil.shared
        let set = threadSafeSet ?? util.generateRandomSetOfReferenceType(size: 100, synchronization: synchronization)

        if num == 1 {
            var data = set.getImmutableCopy()

            for _ in 0 ..< 100 {
                let value = Model(value: util.randomInt())
                appendTestCase(threadSafeOperation: {
                    set.insert(value)
                    return set
                }, originalOperation: {
                    data.insert(value)
                    return data
                }, errorMessage: "func insert(_ newMember: Model) -> (inserted: Bool, memberAfterInsert: Int)")

                appendTestCase(threadSafeOperation: {
                    return set.remove(value)
                }, originalOperation: {
                    return data.remove(value)
                }, errorMessage: "func remove(_ member: Model) -> Model?")

                appendTestCase(threadSafeOperation: {
                    return set.update(with: value)
                }, originalOperation: {
                    return data.update(with: value)
                }, errorMessage: "func update(with newMember: Model) -> Model?")

                appendTestCase(threadSafeOperation: {
                    return set.sorted()
                }, originalOperation: {
                    return set.sorted()
                }, errorMessage: "func sorted() -> [Model]")
            }

            let random = Model(value: util.randomInt())
            appendTestCase(threadSafeOperation: {
                return set.contains(random)
            }, originalOperation: {
                return data.contains(random)
            }, errorMessage: "func contains(_ member: Model) -> Bool")

            appendTestCase(threadSafeOperation: {
                set.removeAll()
                return set
            }, originalOperation: {
                data.removeAll()
                return data
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return set.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return set.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by set: Set<Model>)")
        }

        if num == 2 {
            let data = set.getImmutableCopy()

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.subtract(otherSet)
                }, originalOperation: {
                    return randomData.subtract(otherSet)
                }, errorMessage: "func subtract(_ other: Set<Model>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formUnion(otherSet)
                }, originalOperation: {
                    return randomData.formUnion(otherSet)
                }, errorMessage: "func formUnion(_ other: Set<Model>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formIntersection(otherSet)
                }, originalOperation: {
                    return randomData.formIntersection(otherSet)
                }, errorMessage: "func formIntersection(_ other: Set<Model>)")
            }

            for _ in 0 ..< 10 {
                let randomSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization)
                var randomData = randomSet.getImmutableCopy()

                let otherSet = util.generateRandomSetOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return randomSet.formSymmetricDifference(otherSet)
                }, originalOperation: {
                    return randomData.formSymmetricDifference(otherSet)
                }, errorMessage: "func formSymmetricDifference(_ other: Set<Model>)")
            }

            for _ in 0 ..< 100 {
                let randomSet = util.generateRandomSetOfReferenceType(size: data.count / 10, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    return set.intersection(randomSet)
                }, originalOperation: {
                    return data.intersection(randomSet)
                }, errorMessage: "func intersection(_ other: Set<Model>) -> Set<Model>")

                appendTestCase(threadSafeOperation: {
                    return set.subtracting(randomSet)
                }, originalOperation: {
                    return data.subtracting(randomSet)
                }, errorMessage: "func subtracting(_ other: Set<Model>) -> Set<Model>")

                appendTestCase(threadSafeOperation: {
                    return set.union(randomSet)
                }, originalOperation: {
                    return data.union(randomSet)
                }, errorMessage: "func union<S>(_ other: S) -> Set<Model> where Element == S.Element, S : Sequence")

                appendTestCase(threadSafeOperation: {
                    return set.symmetricDifference(randomSet)
                }, originalOperation: {
                    return data.symmetricDifference(randomSet)
                }, errorMessage: "func symmetricDifference(_ other: Set<Model>) -> Set<Model>")

                appendTestCase(threadSafeOperation: {
                    return set.isSubset(of: randomSet)
                }, originalOperation: {
                    return data.isSubset(of: randomSet)
                }, errorMessage: "func isSubset(of other: Set<Model>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isSuperset(of: randomSet)
                }, originalOperation: {
                    return data.isSuperset(of: randomSet)
                }, errorMessage: "func isSuperset(of other: Set<Model>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isDisjoint(with: randomSet)
                }, originalOperation: {
                    return data.isDisjoint(with: randomSet)
                }, errorMessage: "func isSubset(of other: Set<Model>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isStrictSubset(of: randomSet)
                }, originalOperation: {
                    return data.isStrictSubset(of: randomSet)
                }, errorMessage: "func isStrictSubset(of other: Set<Model>) -> Bool")

                appendTestCase(threadSafeOperation: {
                    return set.isStrictSuperset(of: randomSet)
                }, originalOperation: {
                    return data.isStrictSuperset(of: randomSet)
                }, errorMessage: "func isStrictSuperset(of other: Set<Model>) -> Bool")
            }

            for _ in 0 ..< 50 {
                appendTestCase(threadSafeOperation: {
                    return set.min { $0 < $1 }
                }, originalOperation: {
                    return data.min { $0 < $1 }
                }, errorMessage: "func min(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> Int?")
                appendTestCase(threadSafeOperation: {
                    return set.max { $0 < $1 }
                }, originalOperation: {
                    return data.max { $0 < $1 }
                }, errorMessage: "func max(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> Int?")
            }
            for _ in 0 ..< 100 {
                let value = util.randomInt()
                let containsCloure = { (element: Model) -> Bool in
                    return element.value > value
                }
                appendTestCase(threadSafeOperation: {
                    return set.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: (Model) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                return set.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> [Model]")

        }

        if num == 3 {
            let data = set.getImmutableCopy()

            var flatMapTestData: Set<[Int]> = []
            for _ in 0 ..< util.randomInt(min: 0, max: 5) {
                var element: [Int] = []
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    element.append(util.randomInt())
                }
                flatMapTestData.insert(element)
            }
            let flatMapTestSet = SafeSet(flatMapTestData, synchronization: synchronization)
            appendTestCase(threadSafeOperation: {
                return flatMapTestSet.flatMap { $0 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0 }
            }, errorMessage: "func flatMap<SegmentOfResult>(_ transform: ([Model]) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence")

            appendTestCase(threadSafeOperation: {
                return set.map { $0.value + 3 }
            }, originalOperation: {
                return data.map { $0.value + 3 }
            }, errorMessage: "func map<T>(_ transform: (Model) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return set.compactMap { $0.value + 2 }
            }, originalOperation: {
                return data.compactMap { $0.value + 2 }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: (Model) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return set.filter { $0.value > random }
            }, originalOperation: {
                return data.filter { $0.value > random }
            }, errorMessage: "func filter(_ isIncluded: (Model) throws -> Bool) rethrows -> [Model]")

            appendTestCase(threadSafeOperation: {
                return set.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> [Model]")

            appendTestCase(threadSafeOperation: {
                return set.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: Model? { get }")

            appendTestCase(threadSafeOperation: {
                return set.min()
            }, originalOperation: {
                return data.min()
            }, errorMessage: "func min() -> Model?")

            appendTestCase(threadSafeOperation: {
                return set.max()
            }, originalOperation: {
                return data.max()
            }, errorMessage: "func max() -> Model?")

            appendTestCase(threadSafeOperation: {
                return set.count
            }, originalOperation: {
                return data.count
            }, errorMessage: "var count: Int { get }")
        }

        if num == 4 {
            var data = set.getImmutableCopy()

            appendTestCase(threadSafeOperation: {
                return set.reduce(0) { result, element in
                    return result + element.value
                }
            }, originalOperation: {
                return data.reduce(0) { result, element in
                    return result + element.value
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Model) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                return set.reduce(into: 1) { result, element in
                    result += element.value
                }
            }, originalOperation: {
                return data.reduce(into: 1) { result, element in
                    result += element.value
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Model) throws -> ()) rethrows -> Result")

            var setResult: [Model] = []
            var dataResult: [Model] = []
            appendTestCase(threadSafeOperation: {
                set.forEach { element in
                    setResult.append(element)
                }
                return setResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element)
                }
                return dataResult
            }, errorMessage: "public func forEach(_ body: (Element) throws -> Void) rethrows")

            var setEnumeratedArray: [Model] = []
            var dataEnumeratedArray: [Model] = []
            appendTestCase(threadSafeOperation: {
                set.safeRead { data in
                    for (i, element) in data.enumerated() {
                        setEnumeratedArray.append(Model(value: i))
                        setEnumeratedArray.append(element)
                    }
                }
                return setEnumeratedArray
            }, originalOperation: {
                for (i, element) in data.enumerated() {
                    dataEnumeratedArray.append(Model(value: i))
                    dataEnumeratedArray.append(element)
                }
                return dataEnumeratedArray
            }, errorMessage: "func safeRead(all action: ((Set<Model>) -> Void))")

            appendTestCase(threadSafeOperation: {
                set.safeWrite { data in
                    for (i, element) in data.enumerated() {
                        data.insert(Model(value: i))
                        data.insert(element)
                    }
                }
                return set
            }, originalOperation: {
                for (i, element) in data.enumerated() {
                    data.insert(Model(value: i))
                    data.insert(element)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout Set<Model>) -> Void))")
        }
    }
}
