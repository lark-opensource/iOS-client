//
//  LarkLynxContainerProtocol.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/4.
//

import Foundation
import Lynx

///abstract [简述]Lynx通用容器为业务方暴露的能力
///Discussion：建议业务方不要用LynxView做lynx相关的逻辑，所有LynxView需要的能力都由Lynx通用容器暴露
public protocol LarkLynxContainerProtocol {
    
    /**
     获得LynxView
     */
    func getLynxView() -> UIView

    /**
     获得内容大小
     */
    func getContentSize() -> CGSize
    
    /**
     渲染LynxView
     */
    func render()

    func processLayout(template: Data, withURL: String, initData: [AnyHashable: Any])

    func processRender()


    /**
     渲染LynxView

     - Parameters:
       - templateUrl: 要加载的模版产物的Url
       - initData: DSL数据
     */
    func render(templateUrl: String, initData: String)
    
    /**
     渲染LynxView

     - Parameters:
       - templateUrl: 要加载的模版产物的Url
       - initData: DSL数据
     */
    func render(templateUrl: String, initData: [AnyHashable: Any])
    
    /**
     渲染LynxView

     - Parameters:
       - template: 要加载的模版产物
       - initData: DSL数据
     */
    func render(template: Data, initData: String)
    
    /**
     渲染LynxView

     - Parameters:
       - template: 要加载的模版产物
       - initData: DSL数据
     */
    func render(template: Data, initData: [AnyHashable: Any])

    /**
     渲染LynxView

     - Parameters:
       - templatePathUsingResourceLoader: 要通过 ResourceLoader 加载的模版产物资源相对路径，形式为 xxx/xxx/template.js，路径起点由业务的 ResourceLoader 控制，通常为各业务的 Lynx 资源目录
       - initData: DSL数据
     */
    func render(templatePathUsingResourceLoader templatePath: String,
                       initData: String)

    /**
     渲染LynxView

     - Parameters:
       - templatePathUsingResourceLoader: 要通过 ResourceLoader 加载的模版产物资源相对路径，形式为 xxx/xxx/template.js，路径起点由业务的 ResourceLoader 控制，通常为各业务的 Lynx 资源目录
       - initData: DSL数据
     */
    func render(templatePathUsingResourceLoader templatePath: String,
                       initData: [AnyHashable: Any])
    
    /**
     渲染LynxView

     - Parameters:
       - bundle: 要加载的模版产物
       - initData: DSL数据
     */
    func render(bundle: LynxTemplateBundle, initData: [AnyHashable: Any])

    /**
     更新 LynxView 数据

     - Parameters:
       - data: lynx view 输入数据
     */
    func update(data: String)
    
    
    /**
     更新 LynxView Layout

     - Parameters:
       - data: lynxView layout
     */
    func updateLayoutIfNeeded(sizeConfig: LynxViewSizeConfig)
    
    /**
     更新 LynxView Mode

     - Parameters:
       - data: lynxView layout
     */
    func updateModeIfNeeded(sizeConfig: LynxViewSizeConfig)
    
    /**
     更新 LynxView 数据

     - Parameters:
     - data: lynx view 输入数据
     */
    func update(data: [AnyHashable: Any])
    
    
    /**
     更新 LynxView 全局共享数据

     - Parameters:
     - data: lynxview 全局共享数据
     */
    func updateGlobalData(data: [String: Any])
    
    
    /**
     更新 LynxView 全局共享数据
     - Parameters:
     - data: lynxview 全局共享数据
     */
    func updateGlobalData(data: String)
    
    /**
     Native发送全局事件到Lynx

     - Parameters:
       - event: 事件名
       - dataArray: 相关的数据
     */
    func sendGlobalEventToJS(event: String, dataArray: [Any])
    
    
    /**
     Native通过JSModule的方式发送数据
     
     - Parameters:
       - dataArray: 相关的数据
     */
    func sendDataToJSByModule(dataArray: [Any])
    
    /**
     展示LynxView
     */
    func show()
    
    /**
     隐藏LynxView
     */
    func hide()
    
    /**
     设置extra时间戳，用于性能分析
     
     - Parameters:
       - extraTimingDic: 时间戳字典
     */
    func setExtraTiming(extraTimingDic: [AnyHashable: Any])

    /**
    标识是否已经渲染过
     */
    func hasRendered() -> Bool

    /**
    标识是否已经布局过
     */
    func hasLayout() -> Bool
}
