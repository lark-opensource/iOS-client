//
//  OpenAPIOptionalParam.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import ECOInfra
import ECOProbe
import ECOProbeMeta

/// 通过propertyWrapper来实现参数注解
/// 参数模型里的可选参数，即最终生成的是一个T?，外部可能需要 if let t = T {}
@propertyWrapper
public final class OpenAPIOptionalParam<T>: NSObject, OpenAPIParamPropertyProtocol {

    public var jsonKey: String

    /// 校验参数有效性，比如 0 <= X <= 8
    private let validChecker: OpenAPIValidChecker.Checker<T>?

    /// 灰度验证器
    private let grayChecker: OpenAPIGrayChecker<T>?

    /// 若外部传入的参数dic对应key有值，则使用该值作为value，否则使用默认值作为value
    private var value: T?

    public var wrappedValue: T? {
        set { value = newValue }
        get { return value }
    }

    /// enum 构建器，当 T 的类型为 OpenAPIEnum 时使用，完整支持对框架的改动较大，暂时这么支持
    private let enumCreator: OpenAPIEnumParamCreator?

    public private(set) var checkResult: [String : String] = [:]
        
    public convenience init(
        jsonKey: String,
        validChecker: OpenAPIValidChecker.Checker<T>? = nil,
        grayChecker: OpenAPIGrayChecker<T>? = nil
    ) {
        self.init(
            jsonKey: jsonKey,
            validChecker: validChecker,
            grayChecker: grayChecker,
            enumCreator: nil
        )
    }

    private init(
        jsonKey: String,
        validChecker: OpenAPIValidChecker.Checker<T>?,
        grayChecker: OpenAPIGrayChecker<T>?,
        enumCreator: OpenAPIEnumParamCreator?
    ) {
        self.jsonKey = jsonKey
        self.validChecker = validChecker
        self.grayChecker = grayChecker
        self.enumCreator = enumCreator
    }

    public func configAndCheck(with sourceDic: [AnyHashable: Any]) throws {
        if OpenAPIUtils.useNewParamsValidation {
            try validateNew(with: sourceDic)
        } else {
            try validateOld(with: sourceDic)
        }
    }
    
    /// 可选参数检查逻辑：只需要看validChecker是否通过
    private func validateOld(with sourceDic: [AnyHashable: Any]) throws {
        var propertyValue = sourceDic[jsonKey]

        /// 如果没有传值或传了 NSNull，在 Optional 上认为是合法的，不需要再走 ValidChecker 校验了
        if propertyValue == nil || propertyValue is NSNull {
            wrappedValue = nil
            return
        }

        // 支持解析嵌套Params类型（与代码生成对应）
        if T.self is OpenAPIBaseParams.Type,
           let source = propertyValue as? [AnyHashable: Any] {
            propertyValue = try? (T.self as! OpenAPIBaseParams.Type).init(with: source)
        }
        if T.self is OpenAPIBaseParamsArrayType.Type,
           let source = propertyValue as? [[AnyHashable: Any]] {
            propertyValue = try? source.map({
                try ((T.self as! OpenAPIBaseParamsArrayType.Type).elementType as! OpenAPIBaseParams.Type).init(with: $0)
            })
        }

        /// 生成枚举类型
        if let enumCreator = enumCreator {
            let enumValue = try enumCreator.create(with: propertyValue)
            propertyValue = enumValue
        }

        // 用户传了，但类型传错了，报错
        if propertyValue != nil, !(propertyValue is NSNull), propertyValue as? T == nil {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
            .setOuterMessage("parameter type invalid: \(jsonKey)")
        }

        /// 此时应当有值且类型正确，等上面的类型检查逻辑全量了，考虑合并到一起
        guard let sourceValue = propertyValue as? T else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: jsonKey)))
                .setOuterMessage("parameter type invalid: \(jsonKey)")
        }

        guard checkValue(sourceValue) else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: jsonKey)))
                .setOuterMessage("parameter value invalid: \(jsonKey)")
        }
        hasChecked = true
        wrappedValue = sourceValue
    }
    
    public func validateNew(with dict: [AnyHashable: Any]) throws {
        var rawVal = dict[jsonKey]
        var result: T
        
        if rawVal == nil || rawVal is NSNull {
            wrappedValue = nil
            return
        }
        
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
        
        // 类型校验
        if rawVal is T, !(T.self is Bool.Type), !OpenAPIUtils.isBoolNSNumberType(rawVal as? NSNumber)  {
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
        wrappedValue = result
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
            "value": wrappedValue,
        ].description
        return """
        \(result);
        \(addition)
        """
    }
}

/// String 枚举类型参数
extension OpenAPIOptionalParam where T: OpenAPIEnum, T.RawValue == String {
    public convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: jsonKey)
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
extension OpenAPIOptionalParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == String {
    public convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: jsonKey)
        )
    }
}

/// Number 枚举类型参数
extension OpenAPIOptionalParam where T: OpenAPIEnum, T.RawValue == Int {
    public convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T>.single(key: jsonKey)
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
extension OpenAPIOptionalParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == Int {
    public convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            validChecker: nil,
            grayChecker: nil,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: jsonKey)
        )
    }
}
