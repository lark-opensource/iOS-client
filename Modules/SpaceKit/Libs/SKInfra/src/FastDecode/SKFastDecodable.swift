//
//  SKFastDecodable.swift
//  SKCommon
//
//  Created by X-MAN on 2023/3/13.
//

import Foundation

enum SKFastDecodableError: String, Error, CustomStringConvertible {
    case invalidData
    case invalidJson
    
    var description: String { "SKFastDecodableError.\(rawValue)" }
}

/// https://bytedance.feishu.cn/docx/UAJVdcUmKojxu5xwVofcg8tmnsh 配合工具使用
public protocol SKFastDecodable {
    /// 打开卡片性能敏感，所有实现了该协议的都需要在这个方法里设置所有属性，不要自己调用这个方法
    static func deserialized(with dictionary: [String: Any]) -> Self
    // 解析完毕的回调
    mutating func didFinishDeserialize()
}

public extension SKFastDecodable {
    /// 从 data 解析
    static func deserialized(with data: Data) throws -> Self {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
                throw SKFastDecodableError.invalidJson
            }
            return Self.deserialized(with: json)
        } catch {
            throw error
        }
    }
    
    /// 从 jsonStr 解析
    static func deserialized(with jsonStr: String) throws -> Self {
        do {
            guard let data = jsonStr.data(using: .utf8) else {
                throw SKFastDecodableError.invalidData
            }
            return try Self.deserialized(with: data)
        } catch {
            throw error
        }
    }
}

public protocol SKBasicFastConvertable {
    static func _convert(from object: Any?) -> Self?
}

fileprivate class Serializer<T> where T: SKFastDecodable {
    static func desrialized(from dictionray: [String: Any]) -> T {
        var model = T.deserialized(with: dictionray)
        model.didFinishDeserialize()
        return model
    }
}

public extension SKFastDecodable {
    mutating func didFinishDeserialize() {}
    /// 解析转模型请调用这个方法
    static func convert(from dictionary: [String: Any]) -> Self {
        return Serializer<Self>.desrialized(from: dictionary)
    }
}

public protocol SKFastDecodableArray {
    static func deserialized(with data: [[String: Any]]) -> Self
}

public protocol SKFastDecodableDictionary {
    static func deserialized(with data: [String : [String: Any]]) -> Self
}

public protocol SKFastConvertableArray {
    static func deserialized(with data: [Any]) -> Self
}

public protocol SKFastConvertableDictionary {
    static func deserialized(with data: [String : Any]) -> Self
}

public protocol SKFastDecodableEnumArray {
    static func deserialized(with data: [Any]) -> Self
}

public protocol SKFastDecodableEnumDictionary {
    static func deserialized(with data: [String : Any]) -> Self
}

//public protocol SKFastDecodableMutilArray {
//    static func _convert(_ array: [Any]) -> Self
//}
//
//public protocol SKFastDecodableMutilDictionary {
//    static func _convert(_ array: [String: Any]) -> Self
//}

extension Int: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Int? {
        return object as? Int
    }
}

extension Int8: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Int8? {
        return object as? Int8
    }
}

extension Int16: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Int16? {
        return object as? Int16
    }
}

extension Int32: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Int32? {
        return object as? Int32
    }
}

extension Int64: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Int64? {
        return object as? Int64
    }
}

extension UInt: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> UInt? {
        return object as? UInt
    }
}

extension UInt8: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> UInt8? {
        return object as? UInt8
    }
}

extension UInt16: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> UInt16? {
        return object as? UInt16
    }
}

extension UInt32: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> UInt32? {
        return object as? UInt32
    }
}

extension UInt64: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> UInt64? {
        return object as? UInt64
    }
}

extension String: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> String? {
        return object as? String
    }
}

extension Float: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Float? {
        return object as? Float
    }
}

extension Double: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Double? {
        return object as? Double
    }
}

extension CGFloat: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> CGFloat? {
        return object as? CGFloat
    }
}

extension Bool: SKBasicFastConvertable {
    public static func _convert(from object: Any?) -> Bool? {
        return object as? Bool
    }
}

public protocol SKFastDecodableEnum {
    static func _rawValue() -> Any?
    static func _transfrom(from object: Any?) -> Self?
}

extension Array: SKFastConvertableArray where Element: SKBasicFastConvertable {
    public static func deserialized(with data: [Any]) -> Array<Element> {
        return data.compactMap({ Element._convert(from: $0) })
    }
}

extension Dictionary: SKFastConvertableDictionary where Value: SKBasicFastConvertable, Key == String {
    public static func deserialized(with data: [String : Any]) -> Dictionary<String, Value> {
        return data.compactMapValues({ Value._convert(from: $0) })
    }
}

extension Array: SKFastDecodableArray where Element: SKFastDecodable {
    public static func deserialized(with data: [[String : Any]]) -> Array<Element> {
        return data.compactMap({ Element.convert(from: $0) })
    }
}

extension Dictionary: SKFastDecodableDictionary where Value: SKFastDecodable, Key == String {
    public static func deserialized(with data: [String : [String : Any]]) -> Dictionary<String, Value> {
        return data.compactMapValues({ Value.convert(from: $0) })
    }
}

extension Array: SKFastDecodableEnumArray where Element: SKFastDecodableEnum {
    public static func deserialized(with data: [Any]) -> Array<Element> {
        return data.compactMap({ Element._transfrom(from: $0) })
    }
}

extension Dictionary: SKFastDecodableEnumDictionary where Value: SKFastDecodableEnum, Key == String {
    public static func deserialized(with data: [String : Any]) -> Dictionary<String, Value> {
        return data.compactMapValues({ Value._transfrom(from: $0) })
    }
}

//extension Array: SKFastDecodableMutilArray {
//    public static func _convert(_ array: [Any]) -> Array<Element> {
//        let result = array.map {
//            if let cls = Element.self as? SKBasicFastConvertable.Type {
//                return cls._convert(from: $0) as? Element
//            } else if let cls = Element.self as? SKFastDecodableEnum.Type {
//                return cls._transfrom(from: $0) as? Element
//            } else if let cls = Element.self as? SKFastDecodable.Type,
//                      let data = $0 as? [String: Any] {
//                return cls.convert(from: data) as? Element
//            } else if let cls = Element.self as? SKFastDecodableMutilArray.Type {
//                if let data = $0 as? [Any] {
//                    return cls._convert(data) as? Element
//                }
//                return $0 as? Element
//            } else if let cls = Element.self as? SKFastDecodableMutilDictionary.Type {
//                if let data = $0 as? [String: Any] {
//                    return cls._convert(data) as? Element
//                }
//                return $0 as? Element
//            } else {
//                return $0 as? Element
//            }
//        }
//        return result.compactMap { $0 }
//    }
//}
//
//extension Dictionary: SKFastDecodableMutilDictionary where Key == String {
//    public static func _convert(_ array: [String: Any]) -> Dictionary<Key, Value> {
//        let result = array.mapValues {
//            if let cls = Value.self as? SKBasicFastConvertable.Type {
//                return cls._convert(from: $0) as? Value
//            } else if let cls = Value.self as? SKFastDecodableEnum.Type {
//                return cls._transfrom(from: $0) as? Value
//            } else if let cls = Value.self as? SKFastDecodable.Type,
//                      let data = $0 as? [String: Any] {
//                return cls.convert(from: data) as? Value
//            } else if let cls = Value.self as? SKFastDecodableMutilArray.Type {
//                if let data = $0 as? [Any] {
//                    return cls._convert(data) as? Value
//                }
//                return $0 as? Value
//            } else if let cls = Value.self as? SKFastDecodableMutilDictionary.Type {
//                if let data = $0 as? [String: Any] {
//                    return cls._convert(data) as? Value
//                }
//                return $0 as? Value
//            } else {
//                return $0 as? Value
//            }
//        }
//        return result.compactMapValues { $0 }
//    }
//}

extension RawRepresentable where Self: SKFastDecodableEnum {
    public static func _transfrom(from object: Any?) -> Self? {
        if let value = object as? RawValue {
            return Self(rawValue: value)
        }
        return nil
    }
    
    public static func _rawValue() -> Any? {
        return self.RawValue
    }
}

precedencegroup SKFastDecodablePrecedence {
    associativity: left
    assignment: true
}

infix operator <~: SKFastDecodablePrecedence
/// 非定义的类型走这里
@available(*, message: "Please use a specific type that confirms to SKFastDecodable for this property")
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) {
    guard let value = rhs.0[rhs.1] as? T else { return }
    lhs = value
}
/// 非定义的类型走这里
@available(*, message: "Please use a specific type that confirms to SKFastDecodable for this property")
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) {
    guard let value = rhs.0[rhs.1] as? T else { return }
    lhs = value
}
/// 处理 Value -> 基础类型，Int等
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKBasicFastConvertable {
    guard let value = rhs.0[rhs.1], let result = T._convert(from: value) else { return }
    lhs = result
}
/// 处理 Value -> 基础类型，Int等
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKBasicFastConvertable {
    guard let value = rhs.0[rhs.1], let result = T._convert(from: value) else { return }
    lhs = result
}
/// 处理 Value -> Enum
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableEnum {
    guard let value = rhs.0[rhs.1], let result = T._transfrom(from: value) else { return }
    lhs = result
}
/// 处理 Value -> Enum
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableEnum {
    guard let value = rhs.0[rhs.1], let result = T._transfrom(from: value) else { return }
    lhs = result
}
/// 处理 [String: Any] -> Model
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodable {
    guard let value = rhs.0[rhs.1] as? [String: Any] else { return }
    lhs =  T.convert(from: value)
}
/// 处理 [String: Any] -> Model
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodable {
    guard let value = rhs.0[rhs.1] as? [String: Any] else { return }
    lhs = T.convert(from: value)
}
/// 处理 [Model] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableArray {
    guard let dataList = rhs.0[rhs.1] as? [[String: Any]], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [Model] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableArray {
    guard let dataList = rhs.0[rhs.1] as? [[String: Any]], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [Int] 基础类型 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastConvertableArray {
    guard let dataList = rhs.0[rhs.1] as? [Any], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [Int] 基础类型 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastConvertableArray {
    guard let dataList = rhs.0[rhs.1] as? [Any], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [Enum] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableEnumArray {
    guard let dataList = rhs.0[rhs.1] as? [Any], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [Enum] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableEnumArray {
    guard let dataList = rhs.0[rhs.1] as? [Any], !dataList.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataList)
    lhs = result
}
/// 处理 [String: Model] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: [String: Any]], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}
/// 处理 [String: Model] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: [String: Any]], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}
/// 处理 [String: Int] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastConvertableDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: Any], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}
/// 处理 [String: Int] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastConvertableDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: Any], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}
/// 处理 [String: Enum] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableEnumDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: Any], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}
/// 处理 [String: Enum] 复杂容器灰度后删掉
public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableEnumDictionary {
    guard let dataMap = rhs.0[rhs.1] as? [String: Any], !dataMap.isEmpty else {
        return
    }
    let result = T.deserialized(with: dataMap)
    lhs = result
}

///// 处理复杂容器 [[Model]]
//public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableMutilArray {
//    guard let value = rhs.0[rhs.1] as? [Any] else { return }
//    lhs = T._convert(value)
//}
///// 处理复杂容器 [[Model]]
//public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableMutilArray {
//    guard let value = rhs.0[rhs.1] as? [Any] else { return }
//    lhs = T._convert(value)
//}
//
///// 处理复杂容器 [String: [String: Model]]
//public func <~<T>(lhs: inout T?, rhs: ([String: Any], String)) where T: SKFastDecodableMutilDictionary {
//    guard let value = rhs.0[rhs.1] as? [String: Any] else { return }
//    lhs = T._convert(value)
//}
///// 处理复杂容器 [String: [String: Model]]
//public func <~<T>(lhs: inout T, rhs: ([String: Any], String)) where T: SKFastDecodableMutilDictionary {
//    guard let value = rhs.0[rhs.1] as? [String: Any] else {
//        return
//    }
//    lhs = T._convert(value)
//}
