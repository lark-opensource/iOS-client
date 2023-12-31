//
//  NativeAppAPIRequiredParam.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/13.
//

import Foundation

/// 通过propertyWrapper来实现参数注解
/// 参数模型里的必须参数，即最终生成的是一个T，外部直接使用T
@propertyWrapper
public class NativeAppAPIRequiredParam<T>: NSObject, NativeAppAPIParamPropertyProtocol {

    public var jsonKey: String

    /// 验证器，校验参数有效性，比如 0 <= X <= 8
    private let validChecker: NativeAppAPIValidChecker.Checker<T>?

    /// enum 构建器，当 T 的类型为 OpenAPIEnum 时使用，完整支持对框架的改动较大，暂时这么支持
    private let enumCreator: NativeAppAPIEnumParamCreator?

    /// 默认值
    private let defaultValue: T?

    private let requiredInConfigDict: Bool

    /// 若声明时外部参数必须包含该字段，则使用外部传入的参数dic里对应的值作为value
    /// 否则，若外部传入的参数dic有值，则使用该值作为value，否则使用默认值作为value
    private var value: T?

    public private(set) var checkResult: [String : String] = [:]

    public var wrappedValue: T {
        set { value = newValue }
        get {
            assert(value != nil, "value should be nil")
            return value!
        }
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        validChecker: NativeAppAPIValidChecker.Checker<T>? = nil
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            validChecker: validChecker,
            enumCreator: nil
        )
    }

    public convenience init(
        userRequiredWithJsonKey: String,
        validChecker: NativeAppAPIValidChecker.Checker<T>? = nil
    ) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            validChecker: validChecker,
            enumCreator: nil
        )
    }

    private init(
        with jsonKey: String,
        requiredInConfigDict: Bool,
        defaultValue: T?,
        validChecker: NativeAppAPIValidChecker.Checker<T>?,
        enumCreator: NativeAppAPIEnumParamCreator?
    ) {
        self.jsonKey = jsonKey
        self.validChecker = validChecker
        self.defaultValue = defaultValue
        self.requiredInConfigDict = requiredInConfigDict
        self.value = defaultValue
        self.enumCreator = enumCreator
    }

    /// 必须参数检查逻辑：
    /// 1. 外部参数必须包含该字段，若未包含，报错
    /// 2. 外部参数必须包含该字段，若该字段对应类型不对，报错
    /// 3. validChecker失败，报错
    public func configAndCheck(with sourceDic: [AnyHashable: Any]) throws {
        var sourceValue = sourceDic[jsonKey]
        var typeValue: T

        // 支持解析嵌套Params类型（与代码生成对应）
        if T.self is NativeAppAPIBaseParams.Type,
           let source = sourceValue as? [AnyHashable: Any] {
           sourceValue = try? (T.self as! NativeAppAPIBaseParams.Type).init(with: source)
        }
        if T.self is NativeAppAPIBaseParamsArrayType.Type,
           let source = sourceValue as? [[AnyHashable: Any]] {
            sourceValue = try? source.map({
                try ((T.self as! NativeAppAPIBaseParamsArrayType.Type).elementType as! NativeAppAPIBaseParams.Type).init(with: $0)
            })
        }

        /// 生成枚举类型
        if let enumCreator = enumCreator {
            let enumValue = try enumCreator.create(with: sourceValue)
            sourceValue = enumValue
        }

        if requiredInConfigDict {
            guard sourceValue != nil else {
                throw InvokeNativeAppAPIError(errorMsg: "missing parameter: \(jsonKey) ")
            }
            guard sourceValue is T else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid: \(jsonKey)")
            }
            typeValue = sourceValue as! T
        } else {
            guard let propertyValue = sourceValue as? T ?? getDefaultValue() else {
                throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid: \(jsonKey)")
            }
            typeValue = propertyValue
        }

        // 用户传了参数, 但类型传错了
        let sourceValueTypeInvalid = (sourceValue != nil) && !(sourceValue is NSNull) && (sourceValue as? T == nil)

        // 用户传了, 但类型传错, 报错, 与新版安卓对齐（老版没有做type检查）
        if sourceValueTypeInvalid {
            throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid: \(jsonKey)")
        }
        

        /// 参数值合法性校验
        guard checkValue(typeValue) else {
            throw InvokeNativeAppAPIError(errorMsg: "parameter type invalid: \(jsonKey)")
        }
        value = typeValue
    }
    
    // 获取默认值
    private func getDefaultValue() -> T? {
        return defaultValue
    }

    private func checkValue(_ value: T) -> Bool {
        self.checkResult["param_key"] = jsonKey
        let result = validChecker?(value)
        return result ?? true
    }
}

/// String 枚举类型参数
extension NativeAppAPIRequiredParam where T: NativeAppAPIEnum, T.RawValue == String {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T>.single
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T>.single
        )
    }
}

/// Number 枚举类型参数
extension NativeAppAPIRequiredParam where T: NativeAppAPIEnum, T.RawValue == Int {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T>.single
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T>.single
        )
    }
}

/// [String] 枚举类型参数
///
/// 任意一个元素不满足则参数整体创建失败，比如枚举类型为：["one", "two"]
/// ["one", "two"]          -> 校验成功
/// ["one"]                 -> 校验成功
/// []                      -> 校验成功/失败，取决于 OpenAPIEnum 枚举定义的 allowArrayParamEmpty
/// ["one", "one"]          -> 校验成功
/// ["one", "three"]        -> 校验失败
/// ["three"]               -> 校验失败
extension NativeAppAPIRequiredParam where T: Sequence, T.Element: NativeAppAPIEnum, T.Element.RawValue == String {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T.Element>.array
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T.Element>.array
        )
    }
}

/// [Number] 枚举类型参数
///
/// 任意一个元素不满足则参数整体创建失败，比如枚举类型为：[1, 2]
/// [1, 2]         -> 校验成功
/// [1]            -> 校验成功
/// []             -> 校验成功/失败，取决于 OpenAPIEnum 枚举定义的 allowArrayParamEmpty
/// [1, 1]         -> 校验成功
/// [1, 3]         -> 校验失败
/// [3]            -> 校验失败
extension NativeAppAPIRequiredParam where T: Sequence, T.Element: NativeAppAPIEnum, T.Element.RawValue == Int {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T.Element>.array
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            validChecker: nil,
            enumCreator: NativeAppAPIEnumCreator<T.Element>.array
        )
    }
}
