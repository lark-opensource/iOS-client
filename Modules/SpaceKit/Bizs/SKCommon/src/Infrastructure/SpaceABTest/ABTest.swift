//
//  ABTest.swift
//  SKCommon
//
//  Created by litao_dev on 2020/12/20.
//  
/*
import Foundation
import BDABTestSDK
import SKFoundation

@propertyWrapper
public struct ABTest<T> {
    let defaultValue: T
    let abKey: String
    let isExposure: Bool

    private let parser: (Any) -> T

    public init(wrappedValue: T,
                abKey: String,
                owner: String,
                description: String,
                isExposure: Bool) {
        self.defaultValue = wrappedValue
        self.abKey = abKey
        self.isExposure = isExposure

        self.parser = { value in
            let result = value as? T ?? wrappedValue
            DocsLogger.info("getABTestValue for abKey: \(abKey), value: \(String(describing: value))")
            return result
        }

        let valueType: BDABTestValueType
        switch wrappedValue.self {
        case is String:
            valueType = .string
        case is NSDictionary:
            valueType = .dictionary
        case is NSNumber:
            valueType = .number
        case is NSArray:
            valueType = .array
        default:
            spaceAssertionFailure("no define BDABTestValueType")
            valueType = .string
        }
        let exp = BDABTestBaseExperiment(key: abKey,
                                         owner: owner,
                                         description: description,
                                         defaultValue: wrappedValue,
                                         valueType: valueType,
                                         isSticky: true)
        BDABTestManager.register(exp)
        DocsLogger.info("ABTest: \(abKey) register success")
    }

    public var wrappedValue: T {
        guard let rawValue = HostAppBridge.shared.call(GetABTestService(key: abKey, shouldExposure: isExposure)) else {
            DocsLogger.error("Failed to get AB value from host app bridge, key: \(abKey)")
            return defaultValue
        }
        return parser(rawValue)
    }
}

// 主要为 string 类型的 enum 提供便捷方法
public extension ABTest where T: RawRepresentable, T.RawValue == String {

    public init(wrappedValue: T,
                abKey: String,
                owner: String,
                description: String,
                isExposure: Bool) {
        self.defaultValue = wrappedValue
        self.abKey = abKey
        self.isExposure = isExposure

        parser = { value in
            guard let rawValue = value as? String else {
                assertionFailure("ABTest: value type is not string")
                return wrappedValue
            }
            guard let result = T(rawValue: rawValue) else {
                assertionFailure("ABTest: unknown experiment value found for key: \(abKey), value: \(rawValue)")
                return wrappedValue
            }
            return result
        }

        let exp = BDABTestBaseExperiment(key: abKey,
                                         owner: owner,
                                         description: description,
                                         defaultValue: wrappedValue.rawValue,
                                         valueType: .string,
                                         isSticky: true)
        BDABTestManager.register(exp)
        DocsLogger.info("ABTest: \(abKey) register success")
    }
}
*/
