//
//  NumberConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

extension Int: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<Int> { (result: MetaResource, _: OptionsInfoSet) throws -> Int in
        switch result.index.value {
        case .number(let number):
            return number.intValue
        case .boolean(let boolean):
            return boolean ? 1 : 0
        case .string(let str):
            if let value = Int(str) {
                return value
            }
        default:
            break
        }
        throw ResourceError.transformFailed
    }
}

extension Float: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<Float> { (result: MetaResource, _: OptionsInfoSet) throws -> Float in
        switch result.index.value {
        case .number(let number):
            return number.floatValue
        case .boolean(let boolean):
            return boolean ? 1 : 0
        case .string(let str):
            if let value = Float(str) {
                return value
            }
        default:
            break
        }
        throw ResourceError.transformFailed
    }
}

extension Double: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<Double> { (result: MetaResource, _: OptionsInfoSet) throws -> Double in
        switch result.index.value {
        case .number(let number):
            return number.doubleValue
        case .boolean(let boolean):
            return boolean ? 1 : 0
        case .string(let str):
            if let value = Double(str) {
                return value
            }
        default:
            break
        }
        throw ResourceError.transformFailed
    }
}
