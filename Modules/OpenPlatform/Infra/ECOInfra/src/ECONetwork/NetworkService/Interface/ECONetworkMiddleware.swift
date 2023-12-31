//
//  ECONetworkMiddleware.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

/// ECONetworkMiddleware
/// 目前包含 4 个阶段, 供中间件在不同阶段 获取,修改 请求数据
/// 不同 middleware 会依赖不同类型 Context, 定义入参为 Context 基协议, 需要内部做判断
/// 抛出 error 代表需要 "中断整个流程" , 用于业务异常和逻辑错误
public protocol ECONetworkMiddleware {
    
    /// 外界对 Request 做注入的时机 
    /// 此阶段 Request 不稳定,  Request 内数据未被序列化,
    /// Request 会按中间件的数组序传递, 后一个中间件得到的 Request 是前一个的处理结果(不建议前后依赖)
    /// ✅ 用于: 修改 request, 添加 domain, 添加公共参数, 注入 session 等.
    /// ❌ 不用于: 序列化 (有专门的序列化阶段在这之后) , 也不建议 log, monitor 等需要稳定数据的场景
    /// 修改后的结果从返回值提供
    /// - Parameters:
    ///   -  task: 请求任务, 内含部分内部字段如 trace, 和请求发起时的 context. 供中间件调用
    ///   - request: 用于修改的请求结构体
    /// - Returns: 返回修改后的 Request,  抛出错误代表要中断流程, 不会再执行后面的中间件, 并且结束后续其他操作
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error>
    
    
    /// 请求开始前
    /// Request 已被序列化, 等同于最终请求的 Request,  不再会被修改
    /// 是最接近请求开始前的节点
    /// ✅ 用于: log, monitor 等需要确定 Request 数据的场景
    /// ❌ 此阶段无法再对 Request 做修改
    /// - Parameters:
    ///   -  task: 请求任务, 内含部分内部字段如 trace, 和请求发起时的 context. 供中间件调用
    ///   - request: 稳定的请求结构体
    /// - Returns: 抛出错误代表要中断流程, 不会再执行后面的中间件, 并且结束后续其他操作
    func willStartRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<Void, Error>
    
    /// 请求刚完成, 刚收到回调
    /// Response 为原始数据, 未经过序列化, 可能在后面阶段被修改
    /// 是最接近请求刚结束的节点
    /// ✅ 用于: 需要最原始未经处理 Response 的场景, 如 logger , metrics 等
    /// ❌ 此阶段无法对 response 做修改
    /// - Parameters:
    ///   -  task: 请求任务, 内含部分内部字段如 trace, 和请求发起时的 context. 供中间件调用
    ///   - request: 稳定的请求结构体
    /// - Returns: 抛出错误代表要中断流程, 不会再执行后面的中间件, 并且结束后续其他操作
    func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error>
    
    /// 外界对 Response 做注入的时机, 在这个阶段修改 Response
    /// 此阶段 Response 不稳定,  Response 已被反序列化, 能拿到解析后的数据,
    /// Response 会按中间件的数组序传递, 后一个中间件得到的 Response 是前一个的处理结果(不建议前后依赖)
    /// ✅ 用于: 修改 Response 结果, 修改解析后的数据, 注入 Header 等,
    /// ❌ 不用于: 序列化 (有专门的序列化阶段在这之后) , 也不建议 log, monitor 等需要稳定数据的场景
    /// 修改后的结果从返回值提供
    /// - Parameters:
    ///   -  task: 请求任务, 内含部分内部字段如 trace, 和请求发起时的 context. 供中间件调用
    ///   - request: 用于修改的请求结构体
    /// - Returns: 返回修改后的 Response,  抛出错误代表要中断流程, 不会再执行后面的中间件, 并且结束后续其他操作
    func processResponse<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<ECONetworkResponse<ResultType>, Error>
    
    
    /// 请求发生异常, 供中间件实现监听,log 逻辑的时机
    /// ✅ 用于: 埋点, 打日志
    /// ❌ 不用于: 处理请求结果 (在 请求的 callback 中统一处理即可)
    /// - Parameters:
    ///   -  task: 请求任务, 内含部分内部字段如 trace, 和请求发起时的 context. 供中间件调用
    ///   - error: 当前的错误
    func requestException<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        error: Error,
        request: ECONetworkRequest?,
        response: ECONetworkResponse<ResultType>?
    )
}

/// ECONetworkMiddleware 默认行为
public extension ECONetworkMiddleware {
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        return .success(request)
    }
    
    func willStartRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<Void, Error> {
        return .success(())
    }
    
    func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error> {
        return .success(())
    }
    
    func processResponse<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<ECONetworkResponse<ResultType>, Error> {
        return .success(response)
    }
    
    func requestException<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        error: Error,
        request: ECONetworkRequest?,
        response: ECONetworkResponse<ResultType>?
    ) {}
}
