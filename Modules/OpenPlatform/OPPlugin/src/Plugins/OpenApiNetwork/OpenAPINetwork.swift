//
//  OpenAPINetwork.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/10/22.
//


import ECOInfra
import LarkContainer
/// ECOInfra 进行了一次简单的封装
struct OpenAPINetwork {
    private static var networkService: ECONetworkService {
        Injected<ECONetworkService>().wrappedValue
    }
    /// 对 ECONetworkService create task 的一个简单封装 在 completeHandler 中加入了 task
    /// 创建请求任务 并且 resume
    /// 📣: 底层利用 NetworkClient 实现网络请求, Service 内含隐藏的  NetworkClient 复用逻辑, 在 RequestSetting, Queue, Channel 相同时,会复用 Client,以此利用 URLSession 的复用通道特性
    /// - Parameters:
    ///   - context: 当前环境的 context, 内部会从这个对象中获取需要的上下文数据
    ///   - config: 请求的配置信息
    ///   - params: 请求的 "接口" 的业务变量(与"接口"无关, 但与当前环境相关的变量, 由 context 提供)
    ///   - listeners: 进度监听
    ///   - requestCompletionHandler: (response, error: task)  请求结束的回调( 注意不是创建任务结束 )
    ///   - callbackQueue: 回调队列(包括完成回调, 和事件监听回调) 默认 main,  ⚠️不包括 middleware 执行队列
    static func startRequest<ParamsType, ResultType, ConfigType>(context: ECONetworkServiceContext,
                                                                 config: ConfigType.Type,
                                                                 params: ParamsType,
                                                                 callbackQueue: DispatchQueue = DispatchQueue.main,
                                                                 requestCompletionHandler:
                                                                 @escaping ((ECOInfra.ECONetworkResponse<ResultType>?,
                                                                             ECOInfra.ECONetworkError?,
                                                                             ECOInfra.ECONetworkServiceTask<ResultType>?) -> Void)) -> ECOInfra.ECONetworkServiceTask<ResultType>?
    where ParamsType == ConfigType.ParamsType,
          ResultType == ConfigType.ResultType,
          ConfigType: ECOInfra.ECONetworkRequestConfig {
              var task: ECOInfra.ECONetworkServiceTask<ResultType>?
              task = networkService.createTask(context: context,
                                               config: config,
                                               params: params,
                                               callbackQueue: callbackQueue,
                                               requestCompletionHandler: {
                  response, taskError in
                  // 这里的 task 没有 用 weak 或者 unowned
                  // 因为现有网络框架回调到这里的时候 task 已经被释放了。
                  // 所以这里强持有，有 retain cycle 的问题
                  // task = nil 打破 retain cycle
                  requestCompletionHandler(response, taskError, task)
                  task = nil
              })
              guard let requestTask = task else {
                  return nil
              }
              networkService.resume(task: requestTask)
              return requestTask
          }
}
