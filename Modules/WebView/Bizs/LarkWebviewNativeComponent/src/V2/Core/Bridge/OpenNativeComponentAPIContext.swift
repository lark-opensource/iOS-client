//
//  OpenNativeComponentAPIContext.swift
//  LarkWebviewNativeComponent
//
//  Created by wangjin on 2022/10/20.
//

import Foundation
import LarkWebViewContainer
import ECOProbe
import LarkOpenAPIModel

final class APIContext: APIContextProtocol {
    /// 组件类型，标签名字(input)
    let type: String
    /// 组件实例id(0)
    let identify: String
    /// 识别WKChildScrollView的id
    var renderId: String
    /// 是否为同层渲染，同层：.native_component_sandwich；非同层：.native_component_overlay
    let renderType: OpenNativeComponentRenderType
    /// 组件原参数(未经过processComponentFrame处理)
    let data: [AnyHashable: Any]
    /// 调用链路的trace
    let trace: OPTrace
    /// 组件操作回调
    var completion: (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void
    
    weak var componentWrapper: OpenNativeComponentWrapper?
    
    weak var webView: LarkWebView?
    
    /// 代表已经存在的nativeView， 和componentWrapper的nativeView不是一个概念
    weak var existNativeView: UIView?
    
    init(type: String,
         identify: String,
         renderId: String,
         renderType: OpenNativeComponentRenderType,
         data: [AnyHashable: Any],
         trace: OPTrace,
         completion: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        self.type = type
        self.identify = identify
        self.renderId = renderId
        self.renderType = renderType
        self.data = data
        self.trace = trace
        self.completion = completion
    }
    
    func logComponentAdd(error: OpenAPIError?) {
        OpenNativeComponentInterceptor.classType(type, webView: webView)?.componentAdd(with: renderId, params: data, error: error)
    }
}
