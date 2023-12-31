//
//  DocComponentAPI.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/18.
//  


import Foundation
public typealias DocComponentInvokeCallBack = (([String: Any], Error?) -> Void)

public protocol DocComponentAPIDelegate: AnyObject {

    /// 传递文档的调用
    func docComponent(_ doc: DocComponentAPI,
                        onInvoke data: [String: Any]?,
                        callback: DocComponentInvokeCallBack?)

    /// 传递文档内的事件
    func docComponent(_ doc: DocComponentAPI, onEvent event: DocComponentEvent)
    
    /// 传递文档内的操作
    /// 返回值：true: 业务方如需要拦截处理   false: 业务方忽略，由文档处理
    func docComponent(_ doc: DocComponentAPI, onOperation operation: DocComponentOperation) -> Bool

}

public protocol DocComponentAPI: AnyObject {

    /// 文档组件的ViewController
    var docVC: UIViewController { get }
    
    /// 文档组件状态
    var status: DocComponentStatus { get }

    /// 设置纪要文档回调Delgate
    func setDelegate(_ delegate: DocComponentAPIDelegate)

    /// 通用调用方法
    /// - Parameters:
    ///   - command: 调用命令
    ///   - payload: 参数
    ///   - callback: 回调（暂未实现）
    func invoke(command: String,
                payload: [String: Any]?,
                callback: DocComponentInvokeCallBack?)
    
    
    /// 更新Setting配置
    func updateSettingConfig(_ settingConfig: [String: Any])
}
