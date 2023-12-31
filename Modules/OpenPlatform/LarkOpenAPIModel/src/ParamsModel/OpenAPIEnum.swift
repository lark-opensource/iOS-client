//
//  OpenAPIEnum.swift
//  LarkOpenAPIModel
//
//  Created by Meng on 2021/12/20.
//

import Foundation

/// API Enum 参数类型约束
public protocol OpenAPIEnum: RawRepresentable, CaseIterable {
    /// 是否允许空数组类型的枚举, 默认为 true
    static var allowArrayParamEmpty: Bool { get }
}

extension OpenAPIEnum {
    public static var allowArrayParamEmpty: Bool {
        return true
    }
}

/// OpenAPIParam 的枚举参数构建器，用于构建 OpenAPIEnum/[OpenAPIEnum] 类型
public protocol OpenAPIEnumParamCreator {
    func create(with sourceValue: Any?) throws -> Any?
}

/// OpenAPI Enum 构建器
public enum OpenAPIEnumCreator<EnumType>: OpenAPIEnumParamCreator where EnumType: OpenAPIEnum {

    /// 单枚举构建
    case single(key: String)

    /// 数组枚举构建
    case array(key: String)

    public func create(with sourceValue: Any?) throws -> Any? {
        /// js undefined 和 null 处理
        guard sourceValue != nil && !(sourceValue is NSNull) else {
            return nil
        }
        switch self {
        case .single(let key):
            /// 原始数据类型不对则报错
            guard let singleSourceValue = sourceValue as? EnumType.RawValue else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: key)))
                    .setOuterMessage("parameter type invalid")
            }
            /// 原始数据类型不能初始化为 EnumType 则报错
            guard let result = EnumType(rawValue: singleSourceValue) else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: key)))
                    .setOuterMessage("parameter value invalid")
            }
            return result
        case .array(let key):
            /// 原始数据类型不对则报错
            guard let arraySourceValue = sourceValue as? [EnumType.RawValue] else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: key)))
                    .setOuterMessage("parameter type invalid")
            }
            /// 如果配置了空数组校验，数组枚举原始数据为空数组则报错
            guard EnumType.allowArrayParamEmpty || (!EnumType.allowArrayParamEmpty && !arraySourceValue.isEmpty) else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: key)))
                    .setOuterMessage("parameter value invalid")
            }
            let result = arraySourceValue.compactMap({ EnumType(rawValue:$0) })
            /// 原始数据数组没有完整转换到枚举数组则报错
            guard result.count == arraySourceValue.count else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: key)))
                    .setOuterMessage("parameter value invalid")
            }
            return result
        }
    }
}
