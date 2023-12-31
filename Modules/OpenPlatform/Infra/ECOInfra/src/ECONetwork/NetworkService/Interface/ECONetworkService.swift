//
//  ECONetworkService.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation

/// ECONetworkService
/// ✏️ 需要使用者, 在发起请求前, 明确根据接口协议先 "定义" 好接口. 取代在运行时动态拼装数据
/// 这些内容会以 ECONetworkRequestConfig.Type 静态类型传入, 包括: scheme, path, method 等
/// 能在调用时动态传入的只有:
///   1. context 描述环境变量 ,  用于 middleware, serializer 从上下文中获取必要数据
///   2. params 描述接口变量 , 当前调用接口需要的业务参数
/// context 与 middleware, serilizer(一般不用 context) 需要的类型适配才能正常工作
/// ParamsType 与 requestSerilizer 适配, ResultType 与 responseSerilizer 适配
/// 详见文档:  https://bytedance.feishu.cn/docs/doccnsv1jh6b7XbimJQR5s04A5c
public protocol ECONetworkService {


    /// - Parameters:
    ///   - url: 请求的 完整url
    ///   - header: 请求的 header, 如没有 content-type 会默认添加 content-type 为 application/json
    ///   - params: 会作为 url query，如果存在和url参数同名query只会附加不会覆盖
    ///   - context: 使用 OpenECONetworkAppContext 即可, 如与容器无关则可使用 OpenECONetworkContext
    ///   - requestCompletionHandler: 会将 URLSessionDataTask 接收到的 data 解析为 [String: Any]，作为 response 的 result 返回
    ///   代码示例见 https://bytedance.feishu.cn/wiki/WoO6w7wanisIr4k517lc43fXn8g#SLv0dPTcho07hzxaYAzc6Kw4nVe
    func get(
        url: String,
        header: [String: String],
        params: [String: String]?,
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<[String: Any]>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<[String: Any]>?

    /// - Parameters:
    ///   - url: 请求的 完整url
    ///   - header: 请求的 header, 如没有 content-type 会默认添加 content-type 为 application/json
    ///   - params: request 的 body
    ///   - context: 使用 OpenECONetworkAppContext 即可, 如与容器无关则可使用 OpenECONetworkContext
    ///   - requestCompletionHandler: 会将 URLSessionDataTask 接收到的 data 解析为 [String: Any]，作为 response 的 result 返回
    ///   代码示例见 https://bytedance.feishu.cn/wiki/WoO6w7wanisIr4k517lc43fXn8g#SLv0dPTcho07hzxaYAzc6Kw4nVe
    func post(
        url: String,
        header: [String: String],
        params: [String: Any],
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<[String: Any]>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<[String: Any]>?

    /// - Parameters:
    ///   - url: 请求的 完整url
    ///   - header: 请求的 header, 如没有 content-type 会默认添加 content-type 为 application/json
    ///   - params: 会作为 url query，如果存在和url参数同名query只会附加不会覆盖
    ///   - context: 使用 OpenECONetworkAppContext 即可, 如与容器无关则可使用 OpenECONetworkContext
    ///   - requestCompletionHandler:
    ///     1. ResultType 为 response 返回的 result 数据类型。需要遵守 Decodable, 支持 SwiftyJSON
    ///     2. result 的数据来源为 URLSessionDataTask 接收到的 data
    ///   代码示例见 https://bytedance.feishu.cn/wiki/WoO6w7wanisIr4k517lc43fXn8g#SLv0dPTcho07hzxaYAzc6Kw4nVe
    func get<ResultType>(
        url: String,
        header: [String: String],
        params: [String: String]?,
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where ResultType : Decodable

    /// - Parameters:
    ///   - url: 请求的 完整url
    ///   - header: 请求的 header, 如没有 content-type 会默认添加 content-type 为 application/json
    ///   - params: request 的 body
    ///   - context: 使用 OpenECONetworkAppContext 即可, 如与容器无关则可使用 OpenECONetworkContext
    ///   - requestCompletionHandler:
    ///     1. ResultType 为 response 返回的 result 数据类型。需要遵守 Decodable, 支持 SwiftyJSON
    ///     2. result 的数据来源为 URLSessionDataTask 接收到的 data
    ///   代码示例见 https://bytedance.feishu.cn/wiki/WoO6w7wanisIr4k517lc43fXn8g#SLv0dPTcho07hzxaYAzc6Kw4nVe
    func post<ResultType>(
        url: String,
        header: [String: String],
        params: [String: Any],
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where ResultType : Decodable

    /// 创建请求任务
    /// 📣: 底层利用 NetworkClient 实现网络请求, Service 内含隐藏的  NetworkClient 复用逻辑, 在 RequestSetting, Queue, Channel 相同时,会复用 Client,以此利用 URLSession 的复用通道特性
    /// - Parameters:
    ///   - context: 当前环境的 context, 内部会从这个对象中获取需要的上下文数据
    ///   - config: 请求的配置信息
    ///   - params: 请求的 "接口" 的业务变量(与"接口"无关, 但与当前环境相关的变量, 由 context 提供)
    ///   - listeners: 进度监听
    ///   - requestCompletionHandler: 请求结束的回调( 注意不是创建任务结束 )
    ///   - callbackQueue: 回调队列(包括完成回调, 和事件监听回调) 默认 main,  ⚠️不包括 middleware 执行队列
    func createTask<ParamsType, ResultType, ConfigType: ECONetworkRequestConfig>(
        context: ECONetworkServiceContext,
        config: ConfigType.Type,
        params: ParamsType,
        callbackQueue: DispatchQueue,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where
        ParamsType == ConfigType.ParamsType,
        ResultType == ConfigType.ResultType

    /// 添加任务监听, 线程安全
    func addListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    )
    
    /// 移除任务监听, 线程安全
    func removeListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    )

    /// 使用 task 开启任务, 线程安全
    func resume<ResultType>(task: ECONetworkServiceTask<ResultType>)

    /// 使用 task 暂停任务, 线程安全
    func suspend<ResultType>(task: ECONetworkServiceTask<ResultType>)

    /// 使用 task 取消任务, 线程安全
    func cancel<ResultType>(task: ECONetworkServiceTask<ResultType>)
}
