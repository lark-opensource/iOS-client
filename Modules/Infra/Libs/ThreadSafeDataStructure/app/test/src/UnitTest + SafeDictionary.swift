//
//  UnitTest + SafeDictionary.swift
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
    func appendDictionaryTestCases(num: Int,
                                   synchronization: SynchronizationType,
                                   threadSafeDict: SafeDictionary<Int, String>? = nil) {
        let util = TestUtil.shared
        let dict = threadSafeDict ?? util.generateRandomDictionary(size: 100, synchronization: synchronization)

        if num == 1 {
            var data = dict.getImmutableCopy()

            let randomIndex = util.randomInt(min: 0, max: 100)
            let randomIndex2 = util.randomInt(min: 0, max: 100)
            appendTestCase(threadSafeOperation: { () -> Any? in
                dict[randomIndex] = dict[randomIndex2]
                return dict
            }, originalOperation: { () -> Any? in
                data[randomIndex] = data[randomIndex2]
                return data
            }, errorMessage: "subscript(key: Key) -> Value? { get set }")

            let validIndex = util.randomInt(min: 0, max: 100)
            let invalidIndex = util.randomInt(min: 101, max: 999)
            let randomDefault = String(util.randomInt())
            let random = String(util.randomInt())
            appendTestCase(threadSafeOperation: { () -> Any? in
                dict[validIndex, default: random] = dict[invalidIndex, default: randomDefault]
                return dict
            }, originalOperation: { () -> Any? in
                data[validIndex, default: random] = data[invalidIndex, default: randomDefault]
                return data
            }, errorMessage: "subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value { get set }")

            appendTestCase(threadSafeOperation: { () -> Any? in
                return dict.keys
            }, originalOperation: { () -> Any? in
                return data.keys
            }, errorMessage: "var keys: SafeArray<Int> { get }")

            appendTestCase(threadSafeOperation: { () -> Any? in
                return dict.values
            }, originalOperation: { () -> Any? in
                return data.values
            }, errorMessage: "var values: SafeArray<String> { get }")

            for _ in 0 ..< 100 {
                var value: String?
                let i = util.randomInt(min: 0, max: 200)

                appendTestCase(threadSafeOperation: {
                    dict.safeRead(for: i) { v in
                        value = v
                    }
                    return dict
                }, originalOperation: {
                    value = data[i]
                    return data
                }, errorMessage: "func safeRead(for key: Int, default defaultValue: ((() -> String))? = nil, action: ((String?) -> Void))")

                appendTestCase(threadSafeOperation: {
                    dict.safeRead(for: i, default: "0") { v in
                        value = v
                    }
                    return dict
                }, originalOperation: {
                    value = data[i, default: "0"]
                    return data
                }, errorMessage: "func safeRead(for key: Int, default defaultValue: ((() -> String))? = nil, action: ((String?) -> Void))")

                appendTestCase(threadSafeOperation: {
                    dict.safeWrite(for: i) { v in
                        v = value
                    }
                    return dict
                }, originalOperation: {
                    data[i] = value
                    return data
                }, errorMessage: "func safeWrite(for key: Int, action: ((inout String?) -> Void))")
            }

            for i in 0 ..< 100 {
                guard Bool.random() else { continue }
                appendTestCase(threadSafeOperation: {
                    return dict.removeValue(forKey: i)
                }, originalOperation: {
                    return data.removeValue(forKey: i)
                }, errorMessage: "func removeValue(forKey key: Int) -> String?")
            }

            appendTestCase(threadSafeOperation: {
                return dict
            }, originalOperation: {
                return data
            }, errorMessage: "after removeValue")

            appendTestCase(threadSafeOperation: {
                return dict.removeAll()
            }, originalOperation: {
                return data.removeAll()
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return dict.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomDictionary(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return dict.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by dictionary: [Int : String])")
        }

        if num == 2 {
            var data = dict.getImmutableCopy()
            for i in 0 ..< 100 {
                let value = util.randomInt()
                appendTestCase(threadSafeOperation: {
                    dict.updateValue(String(value), forKey: i)
                    return dict
                }, originalOperation: {
                    data.updateValue(String(value), forKey: i)
                    return data
                }, errorMessage: "func updateValue(_ value: String, forKey key: Int) -> String?")
                appendTestCase(threadSafeOperation: {
                    return dict.min(by: { $0.value < $1.value })
                }, originalOperation: {
                    return data.min(by: { $0.value < $1.value })
                }, errorMessage: "func min(by areInIncreasingOrder: ((key: Int, value: String), (key: Int, value: String)) throws -> Bool) rethrows -> (key: Int, value: String)?")
                appendTestCase(threadSafeOperation: {
                    return dict.max(by: { $0.value < $1.value })
                }, originalOperation: {
                    return data.max(by: { $0.value < $1.value })
                }, errorMessage: "func max(by areInIncreasingOrder: ((key: Int, value: String), (key: Int, value: String)) throws -> Bool) rethrows -> (key: Int, value: String)?")
            }
            for _ in 0 ..< 100 {
                let value = Int.random(in: 0 ..< 100)
                let containsCloure = { (k: Int, v: String) -> Bool in
                    return v > String(value)
                }
                appendTestCase(threadSafeOperation: {
                    return dict.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: ((key: Int, value: String)) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                return dict.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: ((key: Int, value: String), (key: Int, value: String)) throws -> Bool) rethrows -> [(key: Int, value: String)]")
        }

        if num == 3 {
            let data = dict.getImmutableCopy()

            var flatMapTestData: [Int: [String]] = [:]
            for i in 0 ..< util.randomInt(min: 0, max: 5) {
                flatMapTestData[i] = []
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    flatMapTestData[i]?.append(String(util.randomInt()))
                }
            }
            let flatMapTestDict = SafeDictionary(flatMapTestData, synchronization: synchronization)
            appendTestCase(threadSafeOperation: {
                return flatMapTestDict.flatMap { $0.1 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0.1 }
            }, errorMessage: "func flatMap<ElementOfResult>(_ transform: ((key: Int, value: [String])) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            let randomChar = String("qwertyuiopasdfghjklzxcvbnm".randomElement() ?? Character(""))
            appendTestCase(threadSafeOperation: {
                return dict.map { $0.value + randomChar }
            }, originalOperation: {
                return data.map { $0.value + randomChar }
            }, errorMessage: "func map<T>(_ transform: ((key: Int, value: String)) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return dict.compactMap { $0.value + randomChar }
            }, originalOperation: {
                return data.compactMap { $0.value + randomChar }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: ((key: Int, value: String)) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            appendTestCase(threadSafeOperation: {
                return dict.mapValues { $0 + randomChar }
            }, originalOperation: {
                return data.mapValues { $0 + randomChar }
            }, errorMessage: "func mapValues<T>(_ transform: (String) throws -> T) rethrows -> [Int : T]")

            appendTestCase(threadSafeOperation: {
                return dict.compactMapValues { $0 + randomChar }
            }, originalOperation: {
                return data.compactMapValues { $0 + randomChar }
            }, errorMessage: "func compactMapValues<T>(_ transform: (String) throws -> T?) rethrows -> [Int : T]")

            let random = String(util.randomInt())
            appendTestCase(threadSafeOperation: {
                return dict.filter { $0.value > random }
            }, originalOperation: {
                return data.filter { $0.value > random }
            }, errorMessage: "func filter(_ isIncluded: ((key: Int, value: String)) throws -> Bool) rethrows -> Dictionary<Int, String>")

            appendTestCase(threadSafeOperation: {
                return dict.first { $0.value > random }
            }, originalOperation: {
                return data.first { $0.value > random }
            }, errorMessage: "func first(where predicate: ((key: Int, value: String)) throws -> Bool) rethrows -> (key: Int, value: String)?")

            appendTestCase(threadSafeOperation: {
                return dict.sorted { $0 > $1 }
            }, originalOperation: {
                return data.sorted { $0 > $1 }
            }, errorMessage: "func sorted(by areInIncreasingOrder: ((key: Int, value: String), (key: Int, value: String)) throws -> Bool) rethrows -> [(key: Int, value: String)]")

            appendTestCase(threadSafeOperation: {
                return dict.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: (key: Int, value: String)? { get }")

            appendTestCase(threadSafeOperation: {
                return dict.count
            }, originalOperation: {
                return data.count
            }, errorMessage: "var count: Int { get }")
        }

        if num == 4 {
            var data = dict.getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return dict.reduce(0) { result, pair in
                    return result + (Int(pair.value) ?? 0)
                }
            }, originalOperation: {
                return data.reduce(0) { result, pair in
                    return result + (Int(pair.value) ?? 0)
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, (key: Int, value: String)) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                return dict.reduce(into: 1) { result, pair in
                    result += Int(pair.value) ?? 0
                }
            }, originalOperation: {
                return data.reduce(into: 1) { result, pair in
                    result += Int(pair.value) ?? 0
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, (key: Int, value: String)) throws -> ()) rethrows -> Result")

            var dictResult: [(Int, String)] = []
            var dataResult: [(Int, String)] = []
            appendTestCase(threadSafeOperation: {
                dict.forEach { element in
                    dictResult.append(element)
                }
                return dictResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element)
                }
                return dataResult
            }, errorMessage: "func forEach(_ body: ((key: Int, value: String)) throws -> Void) rethrows")

            var dictEnumeratedArray: [(Int, String)] = []
            var dataEnumeratedArray: [(Int, String)] = []
            appendTestCase(threadSafeOperation: {
                dict.safeRead { data in
                    for (i, pair) in data.enumerated() {
                        dictEnumeratedArray.insert(pair, at: i)
                    }
                }
                return dictEnumeratedArray
            }, originalOperation: {
                for (i, pair) in data.enumerated() {
                    dataEnumeratedArray.insert(pair, at: i)
                }
                return dataEnumeratedArray
            }, errorMessage: "func safeRead(all action: (([Int : String]) -> Void))")

            appendTestCase(threadSafeOperation: {
                dict.safeWrite { data in
                    for (i, pair) in data.enumerated() {
                        data[pair.key] = String(i)
                    }
                }
                return dict
            }, originalOperation: {
                for (i, pair) in data.enumerated() {
                    data[pair.key] = String(i)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout [Int : String]) -> Void))")
        }
    }

    func appendDictionaryTestCasesWithReferenceType(num: Int, synchronization: SynchronizationType, threadSafeDict: SafeDictionary<Int, Model>? = nil) {
        let util = TestUtil.shared
        let dict = threadSafeDict ?? util.generateRandomDictionaryOfReferenceType(size: 100, synchronization: synchronization)

        if num == 1 {
            var data = dict.getImmutableCopy()

            let randomIndex = util.randomInt(min: 0, max: 100)
            let randomIndex2 = util.randomInt(min: 0, max: 100)
            appendTestCase(threadSafeOperation: { () -> Any? in
                dict[randomIndex] = dict[randomIndex2]
                return dict
            }, originalOperation: { () -> Any? in
                data[randomIndex] = data[randomIndex2]
                return data
            }, errorMessage: "subscript(key: Key) -> Value? { get set }")

            let validIndex = util.randomInt(min: 0, max: 100)
            let invalidIndex = util.randomInt(min: 101, max: 999)
            let randomDefault = Model(value: util.randomInt())
            let random = Model(value: util.randomInt())
            appendTestCase(threadSafeOperation: { () -> Any? in
                dict[validIndex, default: random] = dict[invalidIndex, default: randomDefault]
                return dict
            }, originalOperation: { () -> Any? in
                data[validIndex, default: random] = data[invalidIndex, default: randomDefault]
                return data
            }, errorMessage: "subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value { get set }")

            appendTestCase(threadSafeOperation: { () -> Any? in
                return dict.keys.max()
            }, originalOperation: { () -> Any? in
                return data.keys.max()
            }, errorMessage: "var keys: SafeArray<Model> { get }")

            appendTestCase(threadSafeOperation: { () -> Any? in
                return dict.values
            }, originalOperation: { () -> Any? in
                return data.values
            }, errorMessage: "var values: SafeArray<Model> { get }")

            for _ in 0 ..< 100 {
                var value: Int?
                let i = util.randomInt(min: 0, max: 200)
                appendTestCase(threadSafeOperation: {
                    dict.safeRead(for: i, default: Model(value: 0)) { v in
                        value = v?.value
                    }
                    return dict
                }, originalOperation: {
                    value = data[i, default: Model(value: 0)].value
                    return data
                }, errorMessage: "func safeRead(for key: Int, default defaultValue: Model? = nil, action: ((Model?) -> Void))")

                appendTestCase(threadSafeOperation: {
                    dict.safeRead(for: i) { v in
                        value = v?.value
                    }
                    return dict
                }, originalOperation: {
                    value = data[i]?.value
                    return data
                }, errorMessage: "func safeRead(for key: Int, default defaultValue: Model? = nil, action: ((Model?) -> Void))")

                appendTestCase(threadSafeOperation: {
                    dict.safeWrite(for: i) { v in
                        v?.value = value ?? 0
                    }
                    return dict
                }, originalOperation: {
                    data[i]?.value = value ?? 0
                    return data
                }, errorMessage: "func safeWrite(for key: Int, action: ((inout Model?) -> Void))")
            }

            for i in 0 ..< 100 {
                guard Bool.random() else { continue }
                appendTestCase(threadSafeOperation: {
                    return dict.removeValue(forKey: i)
                }, originalOperation: {
                    return data.removeValue(forKey: i)
                }, errorMessage: "func removeValue(forKey key: Int) -> Model?")
            }

            appendTestCase(threadSafeOperation: {
                return dict
            }, originalOperation: {
                return data
            }, errorMessage: "after removeValue")

            appendTestCase(threadSafeOperation: {
                return dict.removeAll()
            }, originalOperation: {
                return data.removeAll()
            }, errorMessage: "func removeAll(keepingCapacity keepCapacity: Bool = false)")

            appendTestCase(threadSafeOperation: {
                return dict.isEmpty
            }, originalOperation: {
                return data.isEmpty
            }, errorMessage: "var isEmpty: Bool { get }")

            let temp = util.generateRandomDictionaryOfReferenceType(size: 50, synchronization: synchronization).getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return dict.replaceInnerData(by: temp)
            }, originalOperation: {
                return data = temp
            }, errorMessage: "func replaceInnerData(by dictionary: [Int : Model])")
        }

        if num == 2 {
            var data = dict.getImmutableCopy()
            for i in 0 ..< 100 {
                let value = util.randomInt()
                let model = Model(value: value)
                appendTestCase(threadSafeOperation: {
                    dict.updateValue(model, forKey: i)
                    return dict
                }, originalOperation: {
                    data.updateValue(model, forKey: i)
                    return data
                }, errorMessage: "func updateValue(_ value: Model, forKey key: Int) -> Model?")
                appendTestCase(threadSafeOperation: {
                    return dict.min(by: { $0.value.value < $1.value.value })?.value
                }, originalOperation: {
                    return data.min(by: { $0.value.value < $1.value.value })?.value
                }, errorMessage: "func min(by areInIncreasingOrder: ((key: Int, value: Model), (key: Int, value: Model)) throws -> Bool) rethrows -> (key: Int, value: Model)?")
                appendTestCase(threadSafeOperation: {
                    return dict.max(by: { $0.value.value < $1.value.value })?.value
                }, originalOperation: {
                    return data.max(by: { $0.value.value < $1.value.value })?.value
                }, errorMessage: "func max(by areInIncreasingOrder: ((key: Int, value: Model), (key: Int, value: Model)) throws -> Bool) rethrows -> (key: Int, value: Model)?")
            }
            for _ in 0 ..< 100 {
                let value = Int.random(in: 0 ..< 100)
                let containsCloure = { (k: Int, v: Model) -> Bool in
                    return v.value > value
                }
                appendTestCase(threadSafeOperation: {
                    return dict.contains(where: containsCloure)
                }, originalOperation: {
                    return data.contains(where: containsCloure)
                }, errorMessage: "func contains(where predicate: ((key: Int, value: Model)) throws -> Bool) rethrows -> Bool")
            }

            appendTestCase(threadSafeOperation: {
                return dict.sorted { $0.value.value > $1.value.value }
            }, originalOperation: {
                return data.sorted { $0.value.value > $1.value.value }
            }, errorMessage: "func sorted(by areInIncreasingOrder: ((key: Int, value: Model), (key: Int, value: Model)) throws -> Bool) rethrows -> SafeArray<(Int, Model)>")
        }

        if num == 3 {
            let data = dict.getImmutableCopy()

            var flatMapTestData: [Int: [Model]] = [:]
            for i in 0 ..< util.randomInt(min: 0, max: 5) {
                flatMapTestData[i] = []
                for _ in 0 ..< util.randomInt(min: 0, max: 10) {
                    flatMapTestData[i]?.append(Model(value: util.randomInt()))
                }
            }
            let flatMapTestDict = SafeDictionary(flatMapTestData, synchronization: synchronization)
            appendTestCase(threadSafeOperation: {
                return flatMapTestDict.flatMap { $0.1 }
            }, originalOperation: {
                return flatMapTestData.flatMap { $0.1 }
            }, errorMessage: "func flatMap<ElementOfResult>(_ transform: ((key: Int, value: [Model])) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            appendTestCase(threadSafeOperation: {
                return dict.map { $0.value.value += 3 }
            }, originalOperation: {
                return data.map { $0.value.value += 3 }
            }, errorMessage: "func map<T>(_ transform: ((key: Int, value: Model)) throws -> T) rethrows -> [T]")
            appendTestCase(threadSafeOperation: {
                return dict.compactMap { $0.value.value += 2 }
            }, originalOperation: {
                return data.compactMap { $0.value.value += 2 }
            }, errorMessage: "func compactMap<ElementOfResult>(_ transform: ((key: Int, value: Model)) throws -> ElementOfResult?) rethrows -> [ElementOfResult]")

            appendTestCase(threadSafeOperation: {
                return dict.mapValues { $0.value - 1 }
            }, originalOperation: {
                return data.mapValues { $0.value - 1 }
            }, errorMessage: "func mapValues<T>(_ transform: (Model) throws -> T) rethrows -> [Int : T]")

            appendTestCase(threadSafeOperation: {
                return dict.compactMapValues { $0.value - 2 }
            }, originalOperation: {
                return data.compactMapValues { $0.value - 2 }
            }, errorMessage: "func compactMapValues<T>(_ transform: (Model) throws -> T?) rethrows -> [Int : T]")

            let random = util.randomInt()
            appendTestCase(threadSafeOperation: {
                return dict.filter { $0.value.value > random }
            }, originalOperation: {
                return data.filter { $0.value.value > random }
            }, errorMessage: "func filter(_ isIncluded: ((key: Int, value: Model)) throws -> Bool) rethrows -> SafeDictionary<Int, Model>")

            appendTestCase(threadSafeOperation: {
                return dict.first { $0.value.value > random }
            }, originalOperation: {
                return data.first { $0.value.value > random }
            }, errorMessage: "func first(where predicate: ((key: Int, value: Model)) throws -> Bool) rethrows -> (key: Int, value: Model)?")

            appendTestCase(threadSafeOperation: {
                return dict.sorted { $0.value.value > $1.value.value }
            }, originalOperation: {
                return data.sorted { $0.value.value > $1.value.value }
            }, errorMessage: "func sorted(by areInIncreasingOrder: ((key: Int, value: Model), (key: Int, value: Model)) throws -> Bool) rethrows -> SafeArray<(Int, Model)>")

            appendTestCase(threadSafeOperation: {
                return dict.first
            }, originalOperation: {
                return data.first
            }, errorMessage: "var first: (key: Int, value: Model)? { get }")

            appendTestCase(threadSafeOperation: {
                return dict.count
            }, originalOperation: {
                return data.count
            }, errorMessage: "var count: Int { get }")
        }

        if num == 4 {
            var data = dict.getImmutableCopy()
            appendTestCase(threadSafeOperation: {
                return dict.reduce(0) { result, pair in
                    return result + pair.value.value
                }
            }, originalOperation: {
                return data.reduce(0) { result, pair in
                    return result + pair.value.value
                }
            }, errorMessage: "func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, (key: Int, value: Model)) throws -> Result) rethrows -> Result")

            appendTestCase(threadSafeOperation: {
                return dict.reduce(into: 1) { result, pair in
                    result += pair.value.value
                }
            }, originalOperation: {
                return data.reduce(into: 1) { result, pair in
                    result += pair.value.value
                }
            }, errorMessage: "func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, (key: Int, value: Model)) throws -> ()) rethrows -> Result")

            var dictResult: [(Int, Model)] = []
            var dataResult: [(Int, Model)] = []
            appendTestCase(threadSafeOperation: {
                dict.forEach { element in
                    dictResult.append(element)
                }
                return dictResult
            }, originalOperation: {
                data.forEach { element in
                    dataResult.append(element)
                }
                return dataResult
            }, errorMessage: "func forEach(_ body: ((key: Int, value: String)) throws -> Void) rethrows")

            var dictEnumeratedArray: [(Int, Model)] = []
            var dataEnumeratedArray: [(Int, Model)] = []
            appendTestCase(threadSafeOperation: {
                dict.safeRead { data in
                    for (i, pair) in data.enumerated() {
                        dictEnumeratedArray.insert(pair, at: i)
                    }
                }
                return dictEnumeratedArray
            }, originalOperation: {
                for (i, pair) in data.enumerated() {
                    dataEnumeratedArray.insert(pair, at: i)
                }
                return dataEnumeratedArray
            }, errorMessage: "func safeRead(all action: (([Int : Model]) -> Void))")

            appendTestCase(threadSafeOperation: {
                dict.safeWrite { data in
                    for (i, pair) in data.enumerated() {
                        data[pair.key] = Model(value: i)
                    }
                }
                return dict
            }, originalOperation: {
                for (i, pair) in data.enumerated() {
                    data[pair.key] = Model(value: i)
                }
                return data
            }, errorMessage: "func safeWrite(all action: ((inout [Int : Model]) -> Void))")
        }
    }
}
