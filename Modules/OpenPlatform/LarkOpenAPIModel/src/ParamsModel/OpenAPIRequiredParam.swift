//
//  OpenAPIRequiredParam.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import ECOProbe
import ECOProbeMeta
import ECOInfra

/// 通过propertyWrapper来实现参数注解
/// 参数模型里的必须参数，即最终生成的是一个T，外部直接使用T
@propertyWrapper
public final class OpenAPIRequiredParam<T>: NSObject, OpenAPIParamPropertyProtocol {

    public var jsonKey: String

    /// 验证器，校验参数有效性，比如 0 <= X <= 8
    private let validChecker: OpenAPIValidChecker.Checker<T>?

    /// 灰度验证器
    private let grayChecker: OpenAPIGrayChecker<T>?

    /// enum 构建器，当 T 的类型为 OpenAPIEnum 时使用，完整支持对框架的改动较大，暂时这么支持
    private let enumCreator: OpenAPIEnumParamCreator?

    /// 默认值
    private let defaultValue: T?
    
    /// 灰度默认值
    private let grayDefaultValue: OpenAPIGrayDefaultValue<T>?

    private let requiredInConfigDict: Bool

    /// 若声明时外部参数必须包含该字段，则使用外部传入的参数dic里对应的值作为value
    /// 否则，若外部传入的参数dic有值，则使用该值作为value，否则使用默认值作为value
    private var value: T?

    public private(set) var checkResult: [String : String] = [:]
    
    public var wrappedValue: T {
        set { value = newValue }
        get {
            assert(value != nil, "value should not be nil")
            return value!
        }
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>? = nil,
        validChecker: OpenAPIValidChecker.Checker<T>? = nil,
        grayChecker: OpenAPIGrayChecker<T>? = nil
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            grayDefaultValue: grayDefaultValue,
            validChecker: validChecker,
            grayChecker: grayChecker,
            enumCreator: nil
        )
    }

    public convenience init(
        userRequiredWithJsonKey: String,
        validChecker: OpenAPIValidChecker.Checker<T>? = nil,
        grayChecker: OpenAPIGrayChecker<T>? = nil
    ) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            grayDefaultValue: nil,
            validChecker: validChecker,
            grayChecker: grayChecker,
            enumCreator: nil
        )
    }

    private init(
        with jsonKey: String,
        requiredInConfigDict: Bool,
        defaultValue: T?,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>?,
        validChecker: OpenAPIValidChecker.Checker<T>?,
        grayChecker: OpenAPIGrayChecker<T>?,
        enumCreator: OpenAPIEnumParamCreator?
    ) {
        self.jsonKey = jsonKey
        self.validChecker = validChecker
        self.grayChecker = grayChecker
        self.defaultValue = defaultValue
        self.grayDefaultValue = grayDefaultValue
        self.requiredInConfigDict = requiredInConfigDict
        self.value = defaultValue
        self.enumCreator = enumCreator
    }

    public func configAndCheck(with sourceDic: [AnyHashable: Any]) throws {
        if OpenAPIUtils.useNewParamsValidation {
            try validateNew(with: sourceDic)
        } else {
            try validateOld(with: sourceDic)
        }
    }
    
    /// 必须参数检查逻辑：
    /// 1. 外部参数必须包含该字段，若未包含，报错
    /// 2. 外部参数必须包含该字段，若该字段对应类型不对，报错
    /// 3. validChecker失败，报错
    private func validateOld(with sourceDic: [AnyHashable: Any]) throws {
        var sourceValue = sourceDic[jsonKey]
        var typeValue: T

        // 支持解析嵌套Params类型（与代码生成对应）
        if T.self is OpenAPIBaseParams.Type,
           let source = sourceValue as? [AnyHashable: Any] {
           sourceValue = try? (T.self as! OpenAPIBaseParams.Type).init(with: source)
        }
        if T.self is OpenAPIBaseParamsArrayType.Type,
           let source = sourceValue as? [[AnyHashable: Any]] {
            sourceValue = try? source.map({
                try ((T.self as! OpenAPIBaseParamsArrayType.Type).elementType as! OpenAPIBaseParams.Type).init(with: $0)
            })
        }

        /// 生成枚举类型
        if let enumCreator = enumCreator {
            let enumValue = try enumCreator.create(with: sourceValue)
            sourceValue = enumValue
        }

        if requiredInConfigDict {
            guard sourceValue != nil else {
                OpenAPIBaseParams.logger.error("required \(jsonKey) missed in srouceDic with keys \(sourceDic.keys)")
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: jsonKey)))
                .setOuterMessage("missing parameter: \(jsonKey) ")
            }
            guard sourceValue is T else {
                OpenAPIBaseParams.logger.error("required \(jsonKey) type invalid \(type(of: sourceValue))")
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                .setOuterMessage("parameter type invalid: \(jsonKey)")
            }
            typeValue = sourceValue as! T
        } else {
            guard let propertyValue = sourceValue as? T ?? getDefaultValue() else {
                OpenAPIBaseParams.logger.error("required \(jsonKey) value invalid \(type(of: sourceValue))")
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                .setOuterMessage("parameter type invalid: \(jsonKey)")
            }
            typeValue = propertyValue
        }

        // 用户传了参数, 但类型传错了
        let sourceValueTypeInvalid = (sourceValue != nil) && !(sourceValue is NSNull) && (sourceValue as? T == nil)

        // 埋点上报, 根据埋点数据放量
        if sourceValueTypeInvalid {
            OpenAPIBaseParams.logger.warn("required \(jsonKey) type invalid")
            OPMonitor(name: "op_api_invoke", code: EPMClientOpenPlatformApiCommonCode.plugin_paramtype_checker)
                .addCategoryValue("key", jsonKey)
                .flush()
        }
        
        /// 参数值合法性校验
        guard checkValue(typeValue) else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: jsonKey)))
                .setOuterMessage("parameter value invalid: \(jsonKey)")
        }
        hasChecked = true
        value = typeValue
    }
    
    private func validateNew(with dict: [AnyHashable: Any]) throws {
        var rawVal = dict[jsonKey]
        var result: T
        
        if T.self is OpenAPIBaseParams.Type {
            if let value = rawVal as? [AnyHashable: Any] {
                rawVal = try (T.self as! OpenAPIBaseParams.Type).init(with: value)
            } else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                    .setOuterMessage("parameter type invalid: \(jsonKey)")
            }
        } else if T.self is OpenAPIBaseParamsArrayType.Type {
            if let value = rawVal as? [[AnyHashable: Any]] {
                rawVal = try value.map({
                    try ((T.self as! OpenAPIBaseParamsArrayType.Type).elementType as! OpenAPIBaseParams.Type).init(with: $0)
                })
            } else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                    .setOuterMessage("parameter type invalid: \(jsonKey)")
            }
        }
        if let enumCreator = enumCreator {
            rawVal = try enumCreator.create(with: rawVal)
        }
        
        // 空值校验
        if requiredInConfigDict {
            guard rawVal != nil, !(rawVal is NSNull) else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: jsonKey)))
                .setOuterMessage("missing parameter: \(jsonKey) ")
            }
        } else if rawVal == nil || (rawVal is NSNull) {
            rawVal = getDefaultValue()
        }
        
        // 类型校验
        if rawVal is T, !(T.self is Bool.Type), !OpenAPIUtils.isBoolNSNumberType(rawVal as? NSNumber) {
            result = rawVal as! T
        } else if let weakTypeConvertVal = OpenAPIUtils.convertAPIParamsWeakTypeValue(val: rawVal, type: T.self) {
            result = weakTypeConvertVal
        } else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                .setOuterMessage("parameter type invalid: \(jsonKey)")
        }

        /// value checker校验
        guard checkValue(result) else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: jsonKey)))
                .setOuterMessage("parameter value invalid: \(jsonKey)")
        }
        hasChecked = true
        value = result
    }
    
    // 获取默认值
    private func getDefaultValue() -> T? {
        if let grayDefaultValue = grayDefaultValue,
            OpenAPIUtils.isEnable(feature: grayDefaultValue.featureKey) {
            return grayDefaultValue.defaultValue
        } else {
            return defaultValue
        }
    }

    private func checkValue(_ value: T) -> Bool {
        self.checkResult["param_key"] = jsonKey
        let result = validChecker?(value)
        let grayResult = grayChecker?.checker(value)

        if let grayChecker = grayChecker,
           let grayResult = grayResult,
           OpenAPIUtils.isEnable(feature: grayChecker.featureKey) {
            /// 有 gray checker 情况下再埋点，减少数据上报量
            self.checkResult["valid_checker_result"] = "\(result)"
            self.checkResult["gray_valid_checker_result"] = "\(grayResult)"
            self.checkResult["gray_feature_key"] = grayChecker.featureKey
            return grayResult
        } else {
            return result ?? true
        }
    }
    
    private var hasChecked = false
    public override var description: String {
        let result = super.description
        guard hasChecked else {
            return result
        }
        let addition = [
            "jsonKey": jsonKey,
            "value": value,
            "defaultValue": defaultValue,
        ].description
        return """
        \(result);
        \(addition)
        """
    }
}

/// String 枚举类型参数
extension OpenAPIRequiredParam where T: OpenAPIEnum, T.RawValue == String {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            grayDefaultValue: nil,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: userRequiredWithJsonKey)
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>? = nil
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            grayDefaultValue: grayDefaultValue,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: userOptionWithJsonKey)
        )
    }
}

/// Number 枚举类型参数
extension OpenAPIRequiredParam where T: OpenAPIEnum, T.RawValue == Int {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            grayDefaultValue: nil,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: userRequiredWithJsonKey)
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>? = nil
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            grayDefaultValue: grayDefaultValue,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: userOptionWithJsonKey)
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
extension OpenAPIRequiredParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == String {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            grayDefaultValue: nil,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: userRequiredWithJsonKey)
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>? = nil
    ) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            grayDefaultValue: grayDefaultValue,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: userOptionWithJsonKey)
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
extension OpenAPIRequiredParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == Int {
    public convenience init(userRequiredWithJsonKey: String) {
        self.init(
            with: userRequiredWithJsonKey,
            requiredInConfigDict: true,
            defaultValue: nil,
            grayDefaultValue: nil,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: userRequiredWithJsonKey)
        )
    }

    public convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T,
        grayDefaultValue: OpenAPIGrayDefaultValue<T>? = nil
) {
        self.init(
            with: userOptionWithJsonKey,
            requiredInConfigDict: false,
            defaultValue: defaultValue,
            grayDefaultValue: grayDefaultValue,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: userOptionWithJsonKey)
        )
    }
}
