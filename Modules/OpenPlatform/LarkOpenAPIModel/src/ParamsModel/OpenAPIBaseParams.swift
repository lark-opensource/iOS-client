//
//  OpenAPIBaseParams.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import LKCommonsLogging

protocol OpenAPIBaseParamsArrayType {
    static var elementType: Any.Type { get }
}

extension Array: OpenAPIBaseParamsArrayType where Element: OpenAPIBaseParams {
    static var elementType: Any.Type {
        return Element.self
    }
}

/// API参数协议
public protocol OpenAPIParamPropertyProtocol: AnyObject {

    /// 对应params dic里的key，可在注解中自定义来做映射
    var jsonKey: String { get set }

    /// 临时使用，改造完成需要移除
    var checkResult: [String: String] { get }

    /// 配置并检查参数合法性，会在OPAPIHandlerBaseParams init里内部调用，参数不合法会导致init失败
    /// - Parameter sourceDic: 外部调用者传入的参数字典，比如js传入的参数
    func configAndCheck(with sourceDic: [AnyHashable: Any]) throws

}

/// APIParams基类，内部会寻找和check api参数的有效性；外部参数模型需要继承自此类
open class OpenAPIBaseParams: NSObject {
    
    public static let logger = Logger.log(OpenAPIBaseParams.self, category: "OpenAPI")

    public private(set) var checkResults: [[String: String]] = []

    /// 将默认初始化方法设为private ，需要子类均通过init(with param)来初始化
    private override init() {
        super.init()
    }

    public required init(with params: [AnyHashable: Any]) throws {
        super.init()
        try self.autoCheckProperties.forEach({
            try $0.configAndCheck(with: params)
            checkResults.append($0.checkResult)
        })
    }

    // 加入该数组的属性，会自动在初始化时进行参数解析和有效性check，所有使用@OpenAPIOptionalParam和@OpenAPIRequiredParam注解声明的属性均需要加入此数组
    open var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return []
    }

}
