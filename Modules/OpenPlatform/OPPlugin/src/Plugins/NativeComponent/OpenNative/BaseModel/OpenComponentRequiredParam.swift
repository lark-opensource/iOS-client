//
//  OpenComponentRequiredParam.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import ECOProbe
import ECOProbeMeta
import ECOInfra
import LarkOpenAPIModel

/// 通过propertyWrapper来实现参数注解
/// 参数模型里的必须参数，即最终生成的是一个T，外部直接使用T
/// 仅限于组件属性使用，组件API和其他API对齐
@propertyWrapper
final class OpenComponentRequiredParam<T>: NSObject, OpenComponentParamPropertyProtocol {

    var jsonKey: String

    /// enum 构建器，当 T 的类型为 OpenAPIEnum 时使用，完整支持对框架的改动较大，暂时这么支持
    private let enumCreator: OpenAPIEnumParamCreator?

    /// 默认值，组件的RequiredParam必须要存在
    private let defaultValue: T

    /// 若声明时外部参数必须包含该字段，则使用外部传入的参数dic里对应的值作为value
    /// 否则，若外部传入的参数dic有值，则使用该值作为value，否则使用默认值作为value
    private var value: T
    
    var wrappedValue: T {
        set { value = newValue }
        get { return value }
    }

    convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            defaultValue: defaultValue,
            enumCreator: nil
        )
    }

    private init(
        with jsonKey: String,
        defaultValue: T,
        enumCreator: OpenAPIEnumParamCreator?
    ) {
        self.jsonKey = jsonKey
        self.value = defaultValue
        self.defaultValue = defaultValue
        self.enumCreator = enumCreator
    }

    /// 必须参数检查逻辑：
    /// 1. 外部参数必须包含该字段，若未包含，报错
    /// 2. 外部参数必须包含该字段，若该字段对应类型不对，报错
    /// 3. validChecker失败，报错
    func configAndCheck(with sourceDic: [AnyHashable: Any]) {
        var sourceValue = sourceDic[jsonKey]
        var typeValue: T

        // 支持解析嵌套Params类型（与代码生成对应）
        if T.self is OpenComponentBaseParams.Type,
           let source = sourceValue as? [AnyHashable: Any] {
           sourceValue = (T.self as! OpenComponentBaseParams.Type).init(with: source)
        }
        if T.self is OpenComponentBaseParamsArrayType.Type,
           let source = sourceValue as? [[AnyHashable: Any]] {
            sourceValue = source.map({
                ((T.self as! OpenComponentBaseParamsArrayType.Type).elementType as! OpenComponentBaseParams.Type).init(with: $0)
            })
        }

        /// 生成枚举类型
        if let enumCreator = enumCreator {
            do {
                let enumValue = try enumCreator.create(with: sourceValue)
                sourceValue = enumValue
            } catch {
                // enum 转换失败
            }
        }
        
        typeValue = sourceValue as? T ?? defaultValue

        // 用户传了参数, 但类型传错了
        let sourceValueTypeInvalid = (sourceValue != nil) && !(sourceValue is NSNull) && (sourceValue as? T == nil)

        // 埋点上报, 根据埋点数据放量
        if sourceValueTypeInvalid {
            OpenComponentBaseParams.logger.warn("required \(jsonKey) type invalid")
            OPMonitor(name: "op_api_invoke", code: EPMClientOpenPlatformApiCommonCode.plugin_paramtype_checker)
                .addCategoryValue("key", jsonKey)
                .flush()
        }
        value = typeValue
    }
}

/// String 枚举类型参数
extension OpenComponentRequiredParam where T: OpenAPIEnum, T.RawValue == String {

    convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            defaultValue: defaultValue,
            enumCreator: OpenAPIEnumCreator<T>.single(key: userOptionWithJsonKey)
        )
    }
}

/// Number 枚举类型参数
extension OpenComponentRequiredParam where T: OpenAPIEnum, T.RawValue == Int {

    convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            defaultValue: defaultValue,
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
extension OpenComponentRequiredParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == String {

    convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
    ) {
        self.init(
            with: userOptionWithJsonKey,
            defaultValue: defaultValue,
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
extension OpenComponentRequiredParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == Int {

    convenience init(
        userOptionWithJsonKey: String,
        defaultValue: T
) {
        self.init(
            with: userOptionWithJsonKey,
            defaultValue: defaultValue,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: userOptionWithJsonKey)
        )
    }
}
