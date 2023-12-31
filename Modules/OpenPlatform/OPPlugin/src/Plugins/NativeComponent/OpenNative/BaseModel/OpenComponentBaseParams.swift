//
//  OpenComponentBaseParams.swift
//  LarkWebviewNativeComponent
//
//  Created by baojianjun on 2022/7/28.
//

import Foundation
import LKCommonsLogging

protocol OpenComponentBaseParamsArrayType {
    static var elementType: Any.Type { get }
}

extension Array: OpenComponentBaseParamsArrayType where Element: OpenComponentParamPropertyProtocol {
    static var elementType: Any.Type {
        return Element.self
    }
}

/// 参数协议
protocol OpenComponentParamPropertyProtocol {

    /// 对应params dic里的key，可在注解中自定义来做映射
    var jsonKey: String { get set }

    /// 配置并检查参数合法性，会在OpenComponentBaseParams init里内部调用，参数不合法会导致init失败
    /// - Parameter sourceDic: 外部调用者传入的参数字典，比如js传入的参数
    func configAndCheck(with sourceDic: [AnyHashable: Any])

}

/// OpenComponentBaseParams基类，内部会寻找和check 组件参数的有效性；外部参数模型需要继承自此类
class OpenComponentBaseParams: NSObject {

    static let logger = Logger.log(OpenComponentBaseParams.self, category: "OpenComponent")

    /// 将默认初始化方法设为private ，需要子类均通过init(with param)来初始化
    private override init() {
        super.init()
    }

    required init(with params: [AnyHashable: Any]) {
        super.init()
        self.autoCheckProperties.forEach({
            $0.configAndCheck(with: params)
        })
    }
    
    var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return []
    }
}
