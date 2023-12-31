//
//  NativeAppApiInfo.swift
//  LarkOpenPluginManager
//
//  Created by bytedance on 2022/6/9.
//

import Foundation

public final class NativeAppApiInfo {

    let apiName: String
    /// 该API的参数模型类
    let pluginClass: String
    /// 实现该API的handler所在的类
    let paramsClass: String
    /// 该API是否强制需要在主线程执行
    public let excuteOnMainThread: Bool
    /// 是否是同步API
    public let isSync: Bool

    public init(apiName: String,
                pluginClass: String,
                paramsClass: String,
                excuteOnMainThread: Bool,
                isSync: Bool) {
        self.apiName = apiName
        self.pluginClass = pluginClass
        self.paramsClass = paramsClass
        self.excuteOnMainThread = excuteOnMainThread
        self.isSync = isSync
    }
}
