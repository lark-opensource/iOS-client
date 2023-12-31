//
//  NetworkService.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation
import LKCommonsLogging
import Swinject
import LarkSetting

let DefaultQueueName = "ECONetwork.NetworkService.DefaultQueue"

/// ECONetworkService
/// ✏️ 需要使用者, 在发起请求前, 明确根据接口协议先 "定义" 好接口. 取代在运行时动态拼装数据
/// 这些内容会以 ECONetworkRequestConfig.Type 静态类型传入, 包括: scheme, path, method 等
/// 能在调用时动态传入的只有:
///   1. context 描述环境变量 ,  用于 middleware, serializer 从上下文中获取必要数据
///   2. params 描述接口变量 , 当前调用接口需要的业务参数
/// context 与 middleware, serilizer(一般不用 context) 需要的类型适配才能正常工作
/// ParamsType 与 requestSerilizer 适配, ResultType 与 responseSerilizer 适配
/// 详见文档:  https://bytedance.feishu.cn/docs/doccnsv1jh6b7XbimJQR5s04A5c
final class ECONetworkServiceImpl: ECONetworkService {
    private let enableFixGenericCrash: Bool
    
    static let logger = Logger.oplog(ECONetworkServiceImpl.self, category: "ECONetwork")
    private let resolver: Resolver
    private let operationQueue: OperationQueue
    private var clients: [String: WeakReference<ECONetworkClientProtocol>] = [:]
    private var rustClients: [String: WeakReference<ECONetworkRustHttpClientProtocol>] = [:]
    private var requestingTasks: ECOGenericDictionary<String> = ECOGenericDictionary<String>()
    private let semaphore = DispatchSemaphore(value: 1)
    
    public init(resolver: Resolver) {
        let fixGenericCrashFG = FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.network.fix_econetwork_generic_crash") // Global
        self.enableFixGenericCrash = fixGenericCrashFG && Float(UIDevice.current.systemVersion) == 15.4
        self.resolver = resolver
        self.operationQueue = OperationQueue()
        self.operationQueue.name = DefaultQueueName
        if enableFixGenericCrash {
            self.operationQueue.maxConcurrentOperationCount = 1
        }
    }

    func get(
        url: String,
        header: [String : String],
        params: [String : String]?,
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<[String : Any]>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<[String : Any]>? {
        guard let task = createTask(
            context: context,
            config: ECONetworkRequestConvenienceGetConfig.self,
            params: params,
            requestCompletionHandler: requestCompletionHandler
        ) else {
            return nil
        }
        
        do {
            try task.request.update(withURL: url)
        } catch let error {
            Self.logger.error("Convenience create task fail: \(error.localizedDescription)")
            return nil
        }
        
        task.request.mergingHeaderFields(with: header)
        return task
    }

    func post(
        url: String,
        header: [String : String],
        params: [String : Any],
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<[String : Any]>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<[String : Any]>? {
        guard let task = createTask(
            context: context,
            config: ECONetworkRequestConveniencePostConfig.self,
            params: params,
            requestCompletionHandler: requestCompletionHandler
        ) else {
            return nil
        }
        
        do {
            try task.request.update(withURL: url)
        } catch let error {
            Self.logger.error("Convenience create task fail: \(error.localizedDescription)")
            return nil
        }
        
        task.request.mergingHeaderFields(with: header)
        return task
    }

    func get<ResultType>(
        url: String,
        header: [String : String],
        params: [String : String]?,
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where ResultType : Decodable {
        guard let task = createTask(
            context: context,
            config: ECONetworkRequestDecodableGetConfig<ResultType>.self,
            params: params,
            requestCompletionHandler: requestCompletionHandler
        ) else {
            return nil
        }
        
        do {
            try task.request.update(withURL: url)
        } catch let error {
            Self.logger.error("Convenience create task fail: \(error.localizedDescription)")
            return nil
        }
        
        task.request.mergingHeaderFields(with: header)
        return task
    }

    func post<ResultType>(
        url: String,
        header: [String : String],
        params: [String : Any],
        context: ECONetworkServiceContext,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where ResultType : Decodable {
        guard let task = createTask(
            context: context,
            config: ECONetworkRequestDecodablePostConfig<ResultType>.self,
            params: params,
            requestCompletionHandler: requestCompletionHandler
        ) else {
            return nil
        }
        
        do {
            try task.request.update(withURL: url)
        } catch let error {
            Self.logger.error("Convenience create task fail: \(error.localizedDescription)")
            return nil
        }
        
        task.request.mergingHeaderFields(with: header)
        return task
    }

    /// 创建请求任务
    /// 📣: 底层利用 NetworkClient 实现网络请求, Service 内含隐藏的  NetworkClient 复用逻辑, 在 RequestSetting, Queue, Channel 相同时,会复用 Client,以此利用 URLSession 的复用通道特性
    /// - Parameters:
    ///   - context: 当前环境的 context, 是应用级别的变量.  中间件会通过这个变量实现 往 Request/Response 注入数据的能力
    ///   - config: 请求的配置信息
    ///   - params: "接口" 的业务变量, 当前调用的接口级别的变量, 用于作为实现接口业务的参数, 会由 requestSerilizer 序列化为 http 协议
    ///   - requestCompletionHandler: 请求结束的回调( 注意不是创建任务结束 )
    ///   - callbackQueue: 回调队列(包括完成回调, 和事件监听回调) 默认 main,  ⚠️不包括 middleware 执行队列
    public func createTask<ParamsType, ResultType, ConfigType: ECONetworkRequestConfig>(
        context: ECONetworkServiceContext,
        config: ConfigType.Type,
        params: ParamsType,
        callbackQueue: DispatchQueue = DispatchQueue.main,
        requestCompletionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    ) -> ECONetworkServiceTask<ResultType>? where
        ParamsType == ConfigType.ParamsType,
        ResultType == ConfigType.ResultType {
        
        // 实际验证中发现, 虽然接口非可选, 但存在由 OC 传入的空值, 由于整套框架基于 context 设计, 这种情况下容易导致内部 crash, 不允许继续请求
        let optionalContext: ECONetworkServiceContext? = context
        let optionalTrace: OPTrace? = optionalContext?.getTrace()
        guard let context = optionalContext, optionalTrace != nil else {
            logECONetworkError(domain: config.domain, path: config.path, trace: nil, errMsg: "Create task fail: context or trace is nil")
            assertionFailure("Create task fail: context or trace is nil")
            return nil
        }
        var requestStep : ECONetworkPipelineStep
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.network.rust.opt.enable") {
            guard let client = getRustClient(
                channel: config.channel,
                requestSetting: config.setting
            ) else {
                logECONetworkError(
                    domain: config.domain,
                    path: config.path,
                    trace: context.getTrace(),
                    errMsg: "Create task fail: get client \(config.channel) before client register"
                )
                assertionFailure("Get client \(config.channel) before client register, check assembly")
                return nil
            }
            requestStep = ECONetworkServiceStepRustPerformRequest(client: client)

            // 将 client 缓存起来(内部为弱引用), 在 setting 相同的情况下复用通道
            saveRustClient(
                client: client,
                channel: config.channel,
                setting: config.setting
            )
        } else {
            guard let client = getClient(
                channel: config.channel,
                requestSetting: config.setting
            ) else {
                logECONetworkError(
                    domain: config.domain,
                    path: config.path,
                    trace: context.getTrace(),
                    errMsg: "Create task fail: get client \(config.channel) before client register"
                )
                assertionFailure("Get client \(config.channel) before client register, check assembly")
                return nil
            }
            requestStep = ECONetworkServiceStepPerformRequest(client: client)

            // 将 client 缓存起来(内部为弱引用), 在 setting 相同的情况下复用通道
            saveClient(
                client: client,
                channel: config.channel,
                setting: config.setting
            )
        }
        
        let middlewares = config.middlewares
         
        /*
         NetworkService 内部的采用 Pipeline 模式
         具体执行逻辑写在 ECONetworkPipelineSteps 中, 使用 task 作为 context 串联整个流程
         最重要的目的 ✨ : 将每个步骤解耦, 相互不依赖, 让每个步骤可被独立测试
         同时: 能方便的修改逻辑, 新增步骤; 独立中断,重启,控制每个步骤; 若将来有多种不同流程也能较快组合.
         所以, 注意保持步骤原子性, 避免一个操作内部调用另一个操作的逻辑耦合行为.
         */
        let monitorEnd = ECONetworkServiceStepMonitorEnd()
        let steps:[ECONetworkPipelineStep] = [
            // 开始执行, 戳个点
            ECONetworkServiceStepMonitorStart(monitorEnd: monitorEnd),
            // 调用中间件 注入,修改  Request
            ECONetworkServiceStepProcessRequest(middlewares: middlewares),
            // 序列化 Request
            ECONetworkServiceStepSerializeInputParams(serializer: config.requestSerializer, params: params),
            // 调用中间件, 通知即将发起请求
            ECONetworkServiceStepWillStartRequest(middlewares: middlewares),
            // 开始真正的网络请求
            requestStep,
            // 调用中间件, 通知请求已完成
            ECONetworkServiceStepDidCompleteRequest(middlewares: middlewares),
            // 执行 response 校验, 判断是否通过定义的校验规则
            ECONetworkServiceStepValidateResponse(validator: config.responseValidator),
            // 反序列化 Response data
            ECONetworkServiceStepSerializeResponse(serilizer: config.responseSerializer),
            // 调用中间件, 注入,修改 Response
            ECONetworkServiceStepProcessResponse(middlewares: middlewares),
            // 执行完了, 戳个点
            monitorEnd,
            // 清理上下文临时垃圾
            ECONetworkServiceStepCleanWorkSpace()
        ]
        
        /// 异常流, 当pipeline 发生 error 时, 下面这些 handler 会依次拿到 error
        let exceptionHandlers:[ECONetworkPipelineException] = [
            // 调度中间件, 通知请求发生异常
            ECONetworkServiceStepRequestException(middlewares: middlewares),
            // 埋异常点
            monitorEnd,
            // 清理上下文临时垃圾
            ECONetworkServiceStepCleanWorkSpace()
        ]
        let requestPipeline = ECONetworkServicePipeline<ResultType>(
            // 目前对内部任务没做进一步队列管理, pipeline 留个队列设置接口给 service 设置. 以后根据需要处理
            operationQueue: operationQueue,
            steps: steps,
            exceptionHandlers: exceptionHandlers
        )
        // 创建 task
        let task = ECONetworkServiceTask<ResultType>(
            config: config,
            context: context,
            type: config.taskType,
            pipeline: requestPipeline,
            callbackQueue: callbackQueue
        )
        // 将 task 设为贯穿 pipeline 的 context
        requestPipeline.setup(
            task: task,
            pipelineCompletionHandler: { [weak self, weak task] response, error in
            callbackQueue.async {
                requestCompletionHandler?(response, error)
            }
            guard let self = self, let task = task else {
                // service 或 task 被意外释放, 属于异常情况需要排查, task 在请求期间应该被 service 持有.
                assertionFailure(" self or task is nil")
                return
            }
            self.removeRequestingTask(task)
        })

        let logCreateTask = {
            Self.logger.info(
                "Create NetworkService Task <\(task.identifier)>",
                additionalData:[
                    "taskIdentifier": task.identifier,
                    "config": config.description(),
                    "callbackQueue": callbackQueue.label,
                ]
            )
        }
        if enableFixGenericCrash {
            operationQueue.addOperation {
                logCreateTask()
            }
        } else {
            logCreateTask()
        }
        return task
    }

    private func logECONetworkError(domain: String?, path: String, trace: OPTrace?, errMsg: String) {
        let log = """
        ECONetwork/trace-id/\(trace?.traceId ?? ""),
        domain=\(domain ?? ""),
        path=\(path),
        info=\(errMsg)
        """
        Self.logger.info(log, tag: ECONetworkLogKey.startRequestError)

        OPMonitor(kEventName_econetwork_error)
            .tracing(trace)
            .addCategoryValue(ECONetworkMonitorKey.domain, domain)
            .addCategoryValue(ECONetworkMonitorKey.path, path)
            .setErrorMessage(errMsg)
            .flush()
    }
    
    // 添加监听者, 线程安全
    public func addListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    ) {
        task.progress.addListener(listener: listener)
    }
    
    // 移除监听者, 线程安全
    public func removeListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    ) {
        task.progress.removeListener(listener: listener)
    }

    /// 使用 task 开启任务, 线程安全
    public func resume<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        addRequestingTask(task)
        task.requestPipeline.execute()
        Self.logger.info("resume network service task: \(task.identifier),  requesting task count: \(requestsCount)")
    }
    
    /// 使用 task 暂停任务, 线程安全
    public func suspend<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        removeRequestingTask(task)
        task.requestPipeline.suspend()
        Self.logger.info("suspend network service task: \(task.identifier),  requesting task count: \(requestsCount)")
    }

    /// 使用 task 取消任务, 线程安全
    public func cancel<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        removeRequestingTask(task)
        task.requestPipeline.cancel()
        Self.logger.info("cancel network service task: \(task.identifier),  requesting task count: \(requestsCount)")
    }
    
    deinit {
        print("service deinit")
    }
}

//MARK: - Client
extension ECONetworkServiceImpl {
    
    /// 根据类型获取 Client, 会根据 "type" , "Setting", "queue" 决定是否要复用
    /// ECONetworkRequestSetting 内部使用所有配置字段生成了 Hash.
    /// 在获取 Client 时, 会先用 setting 与 type 的 hash 尝试找 Client, 找不到的情况下在用 DI 获取
    /// - Parameters:
    ///   - channel: 请求通道
    ///   - requestSetting: ECONetworkRequestSetting 请求相关的配置(如超时等).
    ///   - queue: 操作的线程
    /// - Returns: ECONetworkClient
    private func getClient(
        channel: ECONetworkChannel,
        requestSetting: ECONetworkRequestSetting
    ) -> ECONetworkClientProtocol? {
        semaphore.wait()
        let clientsCopy = clients
        semaphore.signal()
        
        if let client = clientsCopy[getClientKey(with: channel, setting: requestSetting)] as? ECONetworkClientProtocol {
            return client
        } else {
            Self.logger.info("New client with type:\(channel.rawValue)", additionalData:[
                "setting": String(describing: requestSetting),
                "currentCount": String(clientsCopy.count),
            ])
            return resolver.resolve(
                ECONetworkClientProtocol.self,
                name: channel.rawValue,
                arguments: operationQueue, requestSetting
            ) // Global
        }
    }
    
    private func getRustClient(
        channel: ECONetworkChannel,
        requestSetting: ECONetworkRequestSetting
    ) -> ECONetworkRustHttpClientProtocol? {
        semaphore.wait()
        let clientsCopy = rustClients
        semaphore.signal()
        
        if let client = clientsCopy[getClientKey(with: channel, setting: requestSetting)] as? ECONetworkRustHttpClientProtocol {
            return client
        } else {
            Self.logger.info("New client with type:\(channel.rawValue)", additionalData:[
                "setting": String(describing: requestSetting),
                "currentCount": String(clientsCopy.count),
            ])
            //预期ECONetwork不提供native的调用方式，随着FG全量下线native方式
            return resolver.resolve(
                ECONetworkRustHttpClientProtocol.self,
                name: ECONetworkChannel.rust.rawValue,
                arguments: operationQueue, requestSetting
            ) // Global
        }
    }
    
    /// 添加一个 Client, 内部为弱引用, 不会持有 client
    private func saveClient(
        client: ECONetworkClientProtocol,
        channel: ECONetworkChannel,
        setting: ECONetworkRequestSetting
    ) {
        semaphore.wait(); defer { semaphore.signal() }
        clients[getClientKey(with: channel, setting: setting)] = WeakReference(value: client)
    }
    
    private func saveRustClient(
        client: ECONetworkRustHttpClientProtocol,
        channel: ECONetworkChannel,
        setting: ECONetworkRequestSetting
    ) {
        semaphore.wait(); defer { semaphore.signal() }
        rustClients[getClientKey(with: channel, setting: setting)] = WeakReference(value: client)
    }
    
    private func getClientKey(
        with channel: ECONetworkChannel,
        setting: ECONetworkRequestSetting
    ) -> String {
        String(channel.hashValue) + "_" + String(setting.hashValue)
    }
}

//MARK: - Task
extension ECONetworkServiceImpl {
    private func removeRequestingTask<ResultType>(_ task: ECONetworkServiceTask<ResultType>) {
        semaphore.wait(); defer { semaphore.signal() }
        requestingTasks.removeValue(forKey: task.identifier)
    }
    
    private func addRequestingTask<ResultType>(_ task: ECONetworkServiceTask<ResultType>) {
        semaphore.wait(); defer { semaphore.signal() }
        requestingTasks[task.identifier] = task
    }
    
    private var requestsCount: Int {
        semaphore.wait(); defer { semaphore.signal() }
        return requestingTasks.count
    }
}
