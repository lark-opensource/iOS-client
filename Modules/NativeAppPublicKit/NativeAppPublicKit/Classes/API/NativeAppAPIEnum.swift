//
//  NativeAppAPIEnum.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/13.
//

import Foundation

/// API Enum 参数类型约束
public protocol NativeAppAPIEnum: RawRepresentable, CaseIterable {
    /// 是否允许空数组类型的枚举, 默认为 true
    static var allowArrayParamEmpty: Bool { get }
}

extension NativeAppAPIEnum {
    public static var allowArrayParamEmpty: Bool {
        return true
    }
}

/// OpenAPIParam 的枚举参数构建器，用于构建 OpenAPIEnum/[OpenAPIEnum] 类型
protocol NativeAppAPIEnumParamCreator {
    func create(with sourceValue: Any?) throws -> Any?
}

/// OpenAPI Enum 构建器
enum NativeAppAPIEnumCreator<EnumType>: NativeAppAPIEnumParamCreator where EnumType: NativeAppAPIEnum {

    /// 单枚举构建
    case single

    /// 数组枚举构建
    case array

    func create(with sourceValue: Any?) throws -> Any? {
        /// js undefined 和 null 处理
        guard sourceValue != nil && !(sourceValue is NSNull) else {
            return nil
        }
        switch self {
        case .single:
            /// 原始数据类型不对则报错
            guard let singleSourceValue = sourceValue as? EnumType.RawValue else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid")
            }
            /// 原始数据类型不能初始化为 EnumType 则报错
            guard let result = EnumType(rawValue: singleSourceValue) else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid")
            }
            return result
        case .array:
            /// 原始数据类型不对则报错
            guard let arraySourceValue = sourceValue as? [EnumType.RawValue] else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid")
            }
            /// 如果配置了空数组校验，数组枚举原始数据为空数组则报错
            guard EnumType.allowArrayParamEmpty || (!EnumType.allowArrayParamEmpty && !arraySourceValue.isEmpty) else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid")
            }
            let result = arraySourceValue.compactMap({ EnumType(rawValue:$0) })
            /// 原始数据数组没有完整转换到枚举数组则报错
            guard result.count == arraySourceValue.count else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid")
            }
            return result
        }
    }
}
