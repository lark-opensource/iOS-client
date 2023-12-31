//
//  UniContext.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/2/24.
//

import Foundation
import LKTracing
import ThreadSafeDataStructure
import ECOProbe

//暂时写在这里 三期方案确定后再改地方
enum UniContextFrom: String {
    case unknown
    case invalidSession = "session_invalid"
    case sessionReauth = "session_reauth" // 风险 session 的验证
    case login = "login"
    case register = "register"
    case checkSecurityPassword
    case operationCenter = "operation_center"
    case operationCenterLogin = "operation_center_login"
    case switchUser = "switch_user"
    case authorization = "authorization"
    case logout = "logout"
    case logoutOffline = "logout_offline"
    case enterApp = "enter_app"
    case applink = "applink"
    case unregister = "unregister"
    case external = "external" //passport 模块以外的调用
    case jsbridge = "jsbridge"
    case continueSwitch = "continue_switch" //继续切换流程.只能切换 service 使用
    case httpRequest = "http_request"
    case ug = "ug" //ug 调用
    case switchRollback = "switch_rollback" //切换租户回滚失败发起的重新切换流程
    case appPermission = "app_permission"   // 一方应用无权限时切换用户
    case rustLongTimeNoLogin = "rust_long_time_no_login" // Rust Pipeline 14 天未登录
    case didUpgrade = "didUpgrade"
    case fidoCutout = "fido_cut_out"
    case eraseData = "erase_data" //数据擦除
    case fastLogin = "fast_login" //冷启动
}

/*
 监控埋点需求，需要串联所有上下文

 后续作为通用上下文存在
 - UI上下文 （处理多Scene）
 - Tracing上下文 （处理监控）
 - 容器上下 （处理 帐号模型改造）

 */

/// 上下文对象，子协议负责实现各类信息传递
protocol UniContextProtocol {
    var trace: UniContextTraceProtocol { get }
    var credential: UniContextCredentialProtocol { get }
    var from: UniContextFrom { get }
    var flowDomain: Request.Domain? { get }
    var params: SafeDictionary<String, Any> { get set }
}

/// Trace
protocol UniContextTraceProtocol: AnyObject {
    var traceId: String? { get set }

    /// App生命周期的trace id
    static var rootTraceId: String { get }

    /// 派生新流程的traceId标记子流程起点
    /// 使用场景: 输入手机号点击下一步、一键登录点击下一步等
    func newProcessSpan() -> UniContextTraceProtocol & UniContextProtocol
    /// 派生traceId
    /// 使用场景：调用Rust模块实现、调用外部依赖等
    func newSpan() -> UniContextTraceProtocol & UniContextProtocol
}

protocol UniContextCredentialProtocol: AnyObject {
    /// 登录凭证
    /// 手机号、邮箱
    var cp: String? { get set }
}

class UniContextCreator {
    /// 流程起点，生成新的Context
    
    static func create(_ from: UniContextFrom, flowDomain: Request.Domain? = nil) -> UniContextProtocol {
        let context = UniContext(from, flowDomain: flowDomain)
        context.traceId = UniContext.rootTraceId
        return context
    }
}

class UniContext: UniContextProtocol {
    lazy var params: SafeDictionary<String, Any> = {
        .init(.init(), synchronization: .readWriteLock)
    }()

    static var placeholder: UniContext = .init(.unknown)

    var trace: UniContextTraceProtocol { self }

    var credential: UniContextCredentialProtocol { self }
    
    let from: UniContextFrom

    let flowDomain: Request.Domain?
    
    init(_ from: UniContextFrom, flowDomain: Request.Domain? = nil) {
        self.from = from
        self.flowDomain = flowDomain
    }
}

extension UniContext: UniContextTraceProtocol {
    var traceId: String? {
        get { params["traceId"] as? String }
        set { params["traceId"] = newValue }
    }

    static var rootTraceId: String {
        get { _rootTraceId.value }
        set { _rootTraceId.value = newValue }
    }

    func newProcessSpan() -> UniContextTraceProtocol & UniContextProtocol {
        return newSpan()
    }

    func newSpan() -> UniContextTraceProtocol & UniContextProtocol {
        let context = UniContext(self.from)
        context.params = context.params.getImmutableCopy() + .readWriteLock
        context.traceId = LKTracing.newSpan(traceId: self.traceId ?? "")
        context.cp = self.cp
        return context
    }

    private static var _rootTraceId: SafeAtomic<String> = {
        .init(LKTracing.newSpan(traceId: PassportProbeHelper.shared.appLifeTrace), with: .readWriteLock)
    }()

}

extension UniContext: UniContextCredentialProtocol {
    var cp: String? {
        get { params["cp"] as? String }
        set { params["cp"] = newValue }
    }

    var name: String? {
        get { params["name"] as? String }
        set { params["name"] = newValue }
    }
    
    var type: Int8? {
        get { params["type"] as? Int8 }
        set { params["type"] = newValue }
    }
}
