//
//  UnitTest + SafeArray.swift
//  ThreadSafeDataStructureDev
//
//  Created by PGB on 2019/11/12.
//

import Foundation
import ThreadSafeDataStructure

// swiftlint:disable function_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length
extension UnitTest {
    func appendArrayTestCases(num: Int, synchronization: SynchronizationType,
                              threadSafeArray: SafeArray<Int>? = nil, originalData: [Int]? = nil) {
        let util = TestUtil.shared
        let array = threadSafeArray ?? util.generateRandomArray(size: 100, synchronization: synchronization)
        var data = originalData ?? array.getImmutableCopy()

        if num == 1 {
            for _ in 0 ..< 10 {
                let randomIndex = util.randomInt(min: 0, max: 100)
                let randomIndex2 = util.randomInt(min: 0, max: 100)
                appendTestCase(threadSafeOperation: {
                    array[randomIndex] = array[randomIndex2]
                    return array
                }, originalOperation: {
                    data[randomIndex] = data[randomIndex2]
                    return data
                }, errorMessage: "subscript(index: Int) -> Element { get set }")
            }

            for i in 0 ..< 100 {
                var value: Int = 0
                appendTestCase(threadSafeOperation: {
                    array.safeRead(at: i) { element in
                        value = element
                    }
                    return value
                }, originalOperation: {
                    value = data[i]
                    return value
                }, errorMessage: "func safeRead(at index: Int, action: ((Int) -> Void))")

                value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    array.safeWrite(at: i) { element in
                        element = value
                    }
                    return array
                }, originalOperation: {
                    data[i] = value
                    return data
                }, errorMessage: "func safeWrite(at index: Int, action: ((inout Int) -> Void))")
            }

            let index = Int.random(in: 0 ..< array.count)
            appendTestCase(threadSafeOperation: {
                return array.remove(at: index)
            }, originalOperation: {
                return data.remove(at: index)
            }, errorMessage: "func remove(at index: Int) -> Int")

            for _ in 0 ..< 10 {
                let index = util.randomInt(min: 0, max: array.count)
                let newElement = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    return array.insert(newElement, at: index)
                }, originalOperation: {
                    return data.insert(newElement, at: index)
                }, errorMessage: "func insert(_ newElement: Int, at i: Int)")
            }

            for _ in 0 ..< 100 {
                let value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    array.append(value)
                    return array
                }, originalOperation: {
                    data.append(value)
                    return data
                }, errorMessage: "func append(_ newElement: Int)")
                appendTestCase(threadSafeOperation: {
                    return array.min()
                }, originalOperation: {
                    return data.min()
                }, errorMessage: "func min() -> Int?")
                appendTestCase(threadSafeOperation: {
                    return array.max()
                }, originalOperation: {
                    return data.max()
                }, errorMessage: "func max() -> Int?")
            }

            appendTestCase(threadSafeOperation: {
                return array
            }, originalOperation: {
                return data
            }, errorMessage: "after append")

            appendTestCase(threadSafeOperation: {
                return array.removeAll()
            }, originalOperation: {
                return data.removeAll()
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return array.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomArray(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return array.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by array: [Int])")
        }

        if num == 2 {
            for _ in 0 ..< 50 {
                let dataToAppend = util.generateRandomArray(size: 5, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    array.append(contentsOf: dataToAppend)
                    return array
                }, originalOperation: {
                    data.append(contentsOf: dataToAppend)
                    return data
                }, errorMessage: "func append<S>(contentsOf newElements: S) where Element == S.Element, S : Sequence")
                appendTestCase(threadSafeOperation: {
                    return array.min { $0 < $1 }
                }, originalOperation: {
                    return data.min { $0 < $1 }
                }, errorMessage: "func min(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> Int?")
                appendTestCase(threadSafeOperation: {
                    return array.max { $0 < $1 }
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
                    return array.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: (Int) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                array.sort { $0 > $1 }
                return array
            }, originalOperation: {
                data.sort { $0 > $1 }
                return data
            }, errorMessage: "func sort(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows")

            appendTestCase(threadSafeOperation: {
                return array.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows -> [Int]")
        }

        if num == 3 {
            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return array.map { $0 + random }
            }, originalOperation: {
                return data.map { $0 + random }
            }, errorMessage: "func map<T>(_ transform: (Int) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return array.compactMap { $0 + random }
            }, originalOperation: {
                return data.compactMap { $0 + random }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: (Int) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            var flatMapTestData: [[Int]] = []
            for i in 0 ..< util.randomInt(min: 0, max: 5) {
                flatMapTestData.append([])
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    flatMapTestData[i].append(util.randomInt())
                }
            }
            let flatMapTestArray = SafeArray(flatMapTestData, synchronization: synchronization)
            appendTestCase(threadSafeOperation: {
                return flatMapTestArray.flatMap { $0 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0 }
            }, errorMessage: "func flatMap<ElementOfResult>(_ transform: (Int) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            appendTestCase(threadSafeOperation: {
                return array.filter { $0 > random }.count
            }, originalOperation: {
                return data.filter { $0 > random }.count
            }, errorMessage: "func filter(_ isIncluded: (Int) throws -> Bool) rethrows -> [Int]")

            appendTestCase(threadSafeOperation: {
                return array.last { $0 > random }
            }, originalOperation: {
                return data.last { $0 > random }
            }, errorMessage: "func last(where predicate: (Int) throws -> Bool) rethrows -> Int?")

            appendTestCase(threadSafeOperation: {
                return array.sorted().first { $0 > random }
            }, originalOperation: {
                return data.sorted().first { $0 > random }
            }, errorMessage: "func first(where predicate: (Int) throws -> Bool) rethrows -> Int?")

            appendTestCase(threadSafeOperation: {
                return array.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: Int? { get }")

            appendTestCase(threadSafeOperation: {
                array.sort()
                return array.last
            }, originalOperation: {
                data.sort()
                return data.last
            }, errorMessage: "var last: Int? { get }")
        }

        if num == 4 {
            appendTestCase(threadSafeOperation: {
                array.reduce(0) { result, element in
                    return result + element
                }
            }, originalOperation: {
                data.reduce(0) { result, element in
                    return result + element
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Int) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                array.reduce(into: 1) { result, element in
                    result += element
                }
            }, originalOperation: {
                data.reduce(into: 1) { result, element in
                    result += element
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Int) throws -> ()) rethrows -> Result")

            var arrayResult: [Int] = []
            var dataResult: [Int] = []
            appendTestCase(threadSafeOperation: {
                array.forEach { element in
                    arrayResult.append(element)
                }
                return arrayResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element)
                }
                return dataResult
            }, errorMessage: "func forEach(_ body: (Int) throws -> Void) rethrows")

            var arrayEnumerateResult: [(Int, Int)] = []
            var dataEnumerateResult: [(Int, Int)] = []
            appendTestCase(threadSafeOperation: {
                array.safeRead { data in
                    for (index, element) in data.enumerated() {
                        arrayEnumerateResult.append((index, element))
                    }
                }
                return arrayEnumerateResult
            }, originalOperation: {
                for (index, element) in data.enumerated() {
                    dataEnumerateResult.append((index, element))
                }
                return dataEnumerateResult
            }, errorMessage: "func safeRead(all action: (([Int]) -> Void))")

            appendTestCase(threadSafeOperation: {
                array.safeWrite { data in
                    for (index, element) in data.enumerated() {
                        data.append(index)
                        data.append(element)
                    }
                }
                return array
            }, originalOperation: {
                for (index, element) in data.enumerated() {
                    data.append(index)
                    data.append(element)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout [Int]) -> Void))")

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return array.firstIndex { $0 > random }
            }, originalOperation: {
                return data.firstIndex { $0 > random }
            }, errorMessage: "func firstIndex(where predicate: (Int) throws -> Bool) rethrows -> Int?")

            appendTestCase(threadSafeOperation: {
                return array.lastIndex { $0 > random }
            }, originalOperation: {
                return data.lastIndex { $0 > random }
            }, errorMessage: "func lastIndex(where predicate: (Int) throws -> Bool) rethrows -> Int?")

            let randomCount = Int.random(in: 0 ..< 10)
            appendTestCase(threadSafeOperation: {
                return array.prefix(randomCount)
            }, originalOperation: {
                return data.prefix(randomCount)
            }, errorMessage: "func prefix(_ maxLength: Int) -> [Int]")

            let stringData = data.map { String($0) }
            let stringArray = stringData + synchronization
            appendTestCase(threadSafeOperation: {
                return stringArray.contains(String(random))
            }, originalOperation: {
                return stringData.contains(String(random))
            }, errorMessage: "func contains(_ element: Int) -> Bool")
        }
    }

    func appendArrayTestCasesWithReferenceType(num: Int, synchronization: SynchronizationType,
                                               threadSafeArray: SafeArray<Model>? = nil) {
        let util = TestUtil.shared
        let array = threadSafeArray ?? util.generateRandomArrayOfReferenceType(size: 100, synchronization: synchronization)

        var data = array.getImmutableCopy()
        if num == 1 {
            for _ in 0 ..< 10 {
                let randomIndex = util.randomInt(min: 0, max: 100)
                let randomIndex2 = util.randomInt(min: 0, max: 100)
                appendTestCase(threadSafeOperation: {
                    array[randomIndex] = array[randomIndex2]
                    return array
                }, originalOperation: {
                    data[randomIndex] = data[randomIndex2]
                    return data
                }, errorMessage: "subscript(index: Int) -> Element { get set }")
            }

            for i in 0 ..< 100 {
                var value: Int = 0
                appendTestCase(threadSafeOperation: {
                    array.safeRead(at: i) { element in
                        value = element.value
                    }
                    return value
                }, originalOperation: {
                    value = data[i].value
                    return value
                }, errorMessage: "func safeRead(at index: Int, action: ((Model) -> Void))")

                value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    array.safeWrite(at: i) { element in
                        element.value = value
                    }
                    return array
                }, originalOperation: {
                    data[i].value = value
                    return data
                }, errorMessage: "func safeWrite(at index: Int, action: ((inout Model) -> Void))")
            }

            let index = Int.random(in: 0 ..< array.count)
            appendTestCase(threadSafeOperation: {
                return array.remove(at: index)
            }, originalOperation: {
                return data.remove(at: index)
            }, errorMessage: "func remove(at index: Int) -> Model")

            for _ in 0 ..< 10 {
                let index = Int.random(in: 0 ..< array.count)
                let newElement = Model(value: util.randomInt())
                appendTestCase(threadSafeOperation: {
                    return array.insert(newElement, at: index)
                }, originalOperation: {
                    return data.insert(newElement, at: index)
                }, errorMessage: "func insert(_ newElement: Model, at i: Int)")
            }

            for _ in 0 ..< 100 {
                let value = Model(value: util.randomInt())
                appendTestCase(threadSafeOperation: {
                    array.append(value)
                    return array
                }, originalOperation: {
                    data.append(value)
                    return data
                }, errorMessage: "func append(_ newElement: Model)")
                appendTestCase(threadSafeOperation: {
                    return array.min()
                }, originalOperation: {
                    return data.min()
                }, errorMessage: "func min() -> Model?")
                appendTestCase(threadSafeOperation: {
                    return array.max()
                }, originalOperation: {
                    return data.max()
                }, errorMessage: "func max() -> Model?")
            }

            appendTestCase(threadSafeOperation: {
                return array
            }, originalOperation: {
                return data
            }, errorMessage: "after append")

            appendTestCase(threadSafeOperation: {
                return array.removeAll()
            }, originalOperation: {
                return data.removeAll()
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return array.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomArrayOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return array.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by array: [Model])")
        }

        if num == 2 {
            for _ in 0 ..< 50 {
                let dataToAppend = util.generateRandomArrayOfReferenceType(size: 5, synchronization: synchronization).getImmutableCopy()

                appendTestCase(threadSafeOperation: {
                    array.append(contentsOf: dataToAppend)
                    return array
                }, originalOperation: {
                    data.append(contentsOf: dataToAppend)
                    return data
                }, errorMessage: "func append<S>(contentsOf newElements: S) where Element == S.Element, S : Sequence")
                appendTestCase(threadSafeOperation: {
                    return array.min { $0.value < $1.value }
                }, originalOperation: {
                    return data.min { $0.value < $1.value }
                }, errorMessage: "func min(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> Model?")
                appendTestCase(threadSafeOperation: {
                    return array.max { $0.value < $1.value }
                }, originalOperation: {
                    return data.max { $0.value < $1.value }
                }, errorMessage: "func max(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> Model?")
            }
            for _ in 0 ..< 100 {
                let value = util.randomInt()
                let containsCloure = { (element: Model) -> Bool in
                    return element.value > value
                }
                appendTestCase(threadSafeOperation: {
                    return array.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: (Model) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                array.sort { $0.value > $1.value }
                return array
            }, originalOperation: {
                data.sort { $0.value > $1.value }
                return data
            }, errorMessage: "func sort(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows")

            appendTestCase(threadSafeOperation: {
                return array.sorted { $0.value > $1.value }
            }, originalOperation: {
                return data.sorted { $0.value > $1.value }
            }, errorMessage: "func sorted(by areInIncreasingOrder: (Model, Model) throws -> Bool) rethrows -> SafeArray<Model>")
        }

        if num == 3 {
            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return array.map { $0.value + random }
            }, originalOperation: {
                return data.map { $0.value + random }
            }, errorMessage: "func map<T>(_ transform: (Model) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return array.compactMap { $0.value + random }
            }, originalOperation: {
                return data.compactMap { $0.value + random }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: (Model) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            var flatMapTestData: [[Model]] = []
            for i in 0 ..< util.randomInt(min: 0, max: 5) {
                flatMapTestData.append([])
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    flatMapTestData[i].append(Model(value: util.randomInt()))
                }
            }
            let flatMapTestArray = SafeArray(flatMapTestData, synchronization: synchronization)

            appendTestCase(threadSafeOperation: {
                return flatMapTestArray.flatMap { $0 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0 }
            }, errorMessage: "func flatMap<ElementOfResult>(_ transform: (Model) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            appendTestCase(threadSafeOperation: {
                return array.filter { $0.value > random }.count
            }, originalOperation: {
                return data.filter { $0.value > random }.count
            }, errorMessage: "func filter(_ isIncluded: (Model) throws -> Bool) rethrows -> SafeArray<Model>")

            appendTestCase(threadSafeOperation: {
                return array.last { $0.value > random }
            }, originalOperation: {
                return data.last { $0.value > random }
            }, errorMessage: "func last(where predicate: (Model) throws -> Bool) rethrows -> Model?")

            appendTestCase(threadSafeOperation: {
                return array.sorted().first { $0.value > random }
            }, originalOperation: {
                return data.sorted().first { $0.value > random }
            }, errorMessage: "func first(where predicate: (Model) throws -> Bool) rethrows -> Model?")

            appendTestCase(threadSafeOperation: {
                return array.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: Model? { get }")

            appendTestCase(threadSafeOperation: {
                array.sort()
                return array.last
            }, originalOperation: {
                data.sort()
                return data.last
            }, errorMessage: "var last: Model? { get }")
        }

        if num == 4 {
            appendTestCase(threadSafeOperation: {
                array.reduce(0) { result, element in
                    return result + element.value
                }
            }, originalOperation: {
                data.reduce(0) { result, element in
                    return result + element.value
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Model) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                array.reduce(into: 1) { result, element in
                    result += element.value
                }
            }, originalOperation: {
                data.reduce(into: 1) { result, element in
                    result += element.value
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Model) throws -> ()) rethrows -> Result")

            var arrayResult: [Int] = []
            var dataResult: [Int] = []
            appendTestCase(threadSafeOperation: {
                array.forEach { element in
                    arrayResult.append(element.value)
                }
                return arrayResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element.value)
                }
                return dataResult
            }, errorMessage: "func forEach(_ body: (Model) throws -> Void) rethrows")

            var arrayEnumerateResult: [(Int, Model)] = []
            var dataEnumerateResult: [(Int, Model)] = []
            appendTestCase(threadSafeOperation: {
                array.safeRead { data in
                    for (index, element) in data.enumerated() {
                        arrayEnumerateResult.append((index, element))
                    }
                }
                return arrayEnumerateResult
            }, originalOperation: {
                for (index, element) in data.enumerated() {
                    dataEnumerateResult.append((index, element))
                }
                return dataEnumerateResult
            }, errorMessage: "func safeRead(all action: (([Model]) -> Void))")

            appendTestCase(threadSafeOperation: {
                array.safeWrite { data in
                    for (index, element) in data.enumerated() {
                        data.append(Model(value: index))
                        data.append(element)
                    }
                }
                return array
            }, originalOperation: {
                for (index, element) in data.enumerated() {
                    data.append(Model(value: index))
                    data.append(element)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout [Model]) -> Void))")

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return array.firstIndex { $0.value > random }
            }, originalOperation: {
                return data.firstIndex { $0.value > random }
            }, errorMessage: "func firstIndex(where predicate: (Model) throws -> Bool) rethrows -> Int?")

            appendTestCase(threadSafeOperation: {
                return array.lastIndex { $0.value > random }
            }, originalOperation: {
                return data.lastIndex { $0.value > random }
            }, errorMessage: "func lastIndex(where predicate: (Model) throws -> Bool) rethrows -> Int?")

            let randomCount = Int.random(in: 0 ..< 10)
            appendTestCase(threadSafeOperation: {
                return array.prefix(randomCount)
            }, originalOperation: {
                return data.prefix(randomCount)
            }, errorMessage: "func prefix(_ maxLength: Int) -> SafeArray<Model>")

            let randomModel = Model(value: random)
            appendTestCase(threadSafeOperation: {
                return array.contains(randomModel)
            }, originalOperation: {
                return data.contains(randomModel)
            }, errorMessage: "func contains(_ element: Int) -> Bool")
        }
    }
}
