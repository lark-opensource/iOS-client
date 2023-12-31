//
//  LarkCustomerServiceAPI.swift
//  Pods
//
//  Created by zhenning on 2019/6/6.
//

import UIKit
import Foundation
import RxSwift

public enum NewCustomerRequestError: String, Error {
    case noDomain
    case noSession
    case requestJsonError
}

public enum GetNewCustomerInfoResult {
    case chatId(String)
    case fallbackLink(URL)
    // desc: 可展示给用户的报错文案
    case fail(desc: String?)
}

public protocol LarkCustomerServiceAPI {

    /// 启动客服服务，获取相关配置
    func launchCustomerService()
    /// 跳转到客服
    ///  routerParams: 路由参数类
    ///  onSuccess: launch指定页面成功时的回调
    ///  onFailed: launch指定页面失败的回调
    func showCustomerServicePage(routerParams: RouterParams, onSuccess: (() -> Void)?, onFailed: (() -> Void)?)
    
    /// 获取新客服群相关信息https://bytedance.feishu.cn/docx/YfpddDLJFoQEivxGnMGceOp7n3f
    /// https://bytedance.feishu.cn/docx/BMJgdVXwGoM2jPxBUFycTHranCh
    func getNewCustomerInfo(botAppId: String, extInfo: String) -> Observable<GetNewCustomerInfoResult>
    
    /// 进信客服群后调用接口通知服务端 https://bytedance.feishu.cn/docx/YfpddDLJFoQEivxGnMGceOp7n3f
    /// https://bytedance.feishu.cn/docx/BMJgdVXwGoM2jPxBUFycTHranCh
    func enterNewCustomerChat(chatid: String) -> Observable<Void>
}

public enum SourceModuleType {
    case larkMine       // 侧边栏客服
    case docs           // Docs客服
    case videoChat      // 视屏
}

public enum ShowBehaviour {
    case push
    case present
}

public typealias PrepareHandler = (UIViewController) -> Void

public struct RouterParams {
    /// 是否需要先dissmiss当前页面, 对于presented的页面，需要先dissmiss
    var needDissmiss: Bool
    var sourceModuleType: SourceModuleType
    var showBehavior: ShowBehaviour
    var wrap: UINavigationController.Type?
    var from: UIViewController?
    var prepare: PrepareHandler?

    public init (sourceModuleType: SourceModuleType,
                 needDissmiss: Bool,
                 showBehavior: ShowBehaviour? = nil,
                 wrap: UINavigationController.Type? = nil,
                 from: UIViewController? = nil,
                 prepare: PrepareHandler? = nil) {
        self.sourceModuleType = sourceModuleType
        self.needDissmiss = needDissmiss
        self.showBehavior = showBehavior ?? .push
        self.wrap = wrap
        self.from = from
        self.prepare = prepare
    }
}
