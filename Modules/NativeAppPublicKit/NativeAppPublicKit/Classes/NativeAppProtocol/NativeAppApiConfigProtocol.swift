//
//  NativeAppApiConfigProtocol.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/9.
//

import Foundation

///为调用三方API做桥接，提供获得三方API相关配置的能力
@objc
public protocol NativeAppApiConfigProtocol: NSObjectProtocol {
    
    /**
     获取三方API配置的plist文件
     */
    @objc
    func getNativeAppAPIConfigs() -> Data
    
    
    /**
     获取某个三方API Plugin对象

     - Parameters:
       - pluginClassString: 从plist文件中读取到的API Plugin的配置名字.
     */
    @objc
    func getPlugin(pluginClassString: String) -> NativeAppBasePlugin
    
    
    /**
     获取某个三方API Params对象

     - Parameters:
       - paramsClassString: 从plist文件中读取到的API params的配置名字.
       - params: 从小程序/网页应用中调用API处取到的参数值
     */
    @objc
    func getParams(paramsClassString: String, params:[AnyHashable: Any]) -> NativeAppAPIBaseParams?
}
