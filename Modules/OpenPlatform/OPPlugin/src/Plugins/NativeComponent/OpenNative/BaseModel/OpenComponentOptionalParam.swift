//
//  OpenComponentOptionalParam.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import ECOInfra
import ECOProbe
import ECOProbeMeta
import LarkOpenAPIModel

/// 通过propertyWrapper来实现参数注解
/// 参数模型里的可选参数，即最终生成的是一个T?，外部可能需要 if let t = T {}
/// - warning ⚠️ 仅限于组件属性使用，组件API和其他API对齐
@propertyWrapper
final class OpenComponentOptionalParam<T>: NSObject, OpenComponentParamPropertyProtocol {

    var jsonKey: String

    /// 若外部传入的参数dic对应key有值，则使用该值作为value，否则使用默认值作为value
    private var value: T?

    var wrappedValue: T? {
        set { value = newValue }
        get { return value }
    }

    /// enum 构建器，当 T 的类型为 OpenAPIEnum 时使用，完整支持对框架的改动较大，暂时这么支持
    private let enumCreator: OpenAPIEnumParamCreator?

    private(set) var checkResult: [String : String] = [:]

    convenience init(
        jsonKey: String
    ) {
        self.init(
            jsonKey: jsonKey,
            enumCreator: nil
        )
    }

    private init(
        jsonKey: String,
        enumCreator: OpenAPIEnumParamCreator?
    ) {
        self.jsonKey = jsonKey
        self.enumCreator = enumCreator
    }

    /// 可选参数检查逻辑：只需要看validChecker是否通过
    func configAndCheck(with sourceDic: [AnyHashable: Any]) {
        var propertyValue = sourceDic[jsonKey]

        /// 如果没有传值或传了 NSNull，在 Optional 上认为是合法的，不需要再走 ValidChecker 校验了
        if propertyValue == nil || propertyValue is NSNull {
            wrappedValue = nil
            return
        }

        // 支持解析嵌套Params类型（与代码生成对应）
        if T.self is OpenComponentBaseParams.Type,
           let source = propertyValue as? [AnyHashable: Any] {
            propertyValue = (T.self as! OpenComponentBaseParams.Type).init(with: source)
        }
        if T.self is OpenComponentBaseParamsArrayType.Type,
           let source = propertyValue as? [[AnyHashable: Any]] {
            propertyValue = source.map({
                ((T.self as! OpenComponentBaseParamsArrayType.Type).elementType as! OpenComponentBaseParams.Type).init(with: $0)
            })
        }

        /// 生成枚举类型
        if let enumCreator = enumCreator {
            do {
                let enumValue = try enumCreator.create(with: propertyValue)
                propertyValue = enumValue
            } catch {
                
            }
        }
        
        wrappedValue = propertyValue as? T
    }
}

/// String 枚举类型参数
extension OpenComponentOptionalParam where T: OpenAPIEnum, T.RawValue == String {
    convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
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
extension OpenComponentOptionalParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == String {
    convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: jsonKey)
        )
    }
}

/// Number 枚举类型参数
extension OpenComponentOptionalParam where T: OpenAPIEnum, T.RawValue == Int {
    convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
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
extension OpenComponentOptionalParam where T: Sequence, T.Element: OpenAPIEnum, T.Element.RawValue == Int {
    convenience init(jsonKey: String) {
        self.init(
            jsonKey: jsonKey,
            enumCreator: OpenAPIEnumCreator<T.Element>.array(key: jsonKey)
        )
    }
}
