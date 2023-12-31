//
//  OPMockECONetworkService.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/28.
//
import LarkAssembler
import Swinject
import RustPB
@testable import ECOInfra
import OPFoundation


final class OPECONetworkServiceMockAssembly: LarkAssemblyInterface {
    public init() {}
    
    public func registContainer(container: Swinject.Container) {
        
        container.register(ECONetworkService.self) { _ in
            return OPMockECONetworkService()
        }.inObjectScope(.container)
    }
}


class OPMockECONetworkService: ECONetworkService {
    var mockResult: (Any?, ECONetworkError?)? = (nil, nil)
    var mockResultDic: [String: (Any?, ECONetworkError?)] = [:]
    var mockResultMap: [AnyHashable: (Any?, ECONetworkError?)] = [:]
    var requestCompletionHandlers: [AnyHashable: ((Any?, ECONetworkError?) -> Void)] = [:]
    
    func addMockResultDic(path: String, result: (Any?, ECONetworkError?)) {
        mockResultDic[path] = result
    }

    func post(url: String, header: [String : String], params: [String : Any], context: ECONetworkServiceContext, requestCompletionHandler: ((ECOInfra.ECONetworkResponse<[String : Any]>?, ECOInfra.ECONetworkError?) -> Void)?) -> ECOInfra.ECONetworkServiceTask<[String : Any]>? {
        guard let task = createTask(
            context: context,
            config: ECONetworkRequestConveniencePostConfig.self,
            params: params,
            callbackQueue: DispatchQueue.main,
            requestCompletionHandler: requestCompletionHandler
        ) else {
            return nil
        }
        
        do {
            try task.request.update(withURL: url)
        } catch _ {
            return nil
        }
        
        return task
    }

    func get(url: String, header: [String : String], params: [String : String]?, context: ECONetworkServiceContext, requestCompletionHandler: ((ECOInfra.ECONetworkResponse<[String : Any]>?, ECOInfra.ECONetworkError?) -> Void)?) -> ECOInfra.ECONetworkServiceTask<[String : Any]>? {
        return nil
    }

    func post<ResultType>(url: String, header: [String : String], params: [String : Any], context: ECOInfra.ECONetworkServiceContext, requestCompletionHandler: ((ECOInfra.ECONetworkResponse<ResultType>?, ECOInfra.ECONetworkError?) -> Void)?) -> ECOInfra.ECONetworkServiceTask<ResultType>? where ResultType : Decodable {
        return nil
    }

    func get<ResultType>(url: String, header: [String : String], params: [String : String]?, context: ECOInfra.ECONetworkServiceContext, requestCompletionHandler: ((ECOInfra.ECONetworkResponse<ResultType>?, ECOInfra.ECONetworkError?) -> Void)?) -> ECOInfra.ECONetworkServiceTask<ResultType>? where ResultType : Decodable {
        return nil
    }
    
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
    ResultType == ConfigType.ResultType {
        let task = ECONetworkServiceTask<ResultType>(
            config: config,
            context: context,
            type: config.taskType,
            pipeline: ECONetworkServicePipeline(operationQueue: .main, steps: [], exceptionHandlers: []),
            callbackQueue: .main
        )
        task.trace.genRequestID("gadget")
        self.requestCompletionHandlers[task.identifier] = { data,e in
            guard let data = data as? ResultType else {
                requestCompletionHandler?(nil, e)
                return
            }
            var res = ECONetworkResponse<ResultType>(statusCode: 200,
                                                     request: URLRequest(url: URL(string: "https://www.feishu.cn")!), //改path
                                                     response: HTTPURLResponse(),
                                                     trace: task.trace)
            res.updateResult(result: data)
            requestCompletionHandler?(res, e)
        }
        return task
    }
    
    /// 添加任务监听, 线程安全
    func addListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    ) {
        
    }
    
    /// 移除任务监听, 线程安全
    func removeListener<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        listener: ECOProgressListener
    ) {
        
    }
    
    /// 使用 task 开启任务, 线程安全
    func resume<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        if let result = mockResultMap[task.identifier] {
            requestCompletionHandlers[task.identifier]?(result.0, result.1)
            return
        }
        if mockResultDic.count > 0 {
            requestCompletionHandlers[task.identifier]?(mockResultDic[task.request.path]?.0, mockResultDic[task.request.path]?.1)
        } else {
            requestCompletionHandlers[task.identifier]?(mockResult?.0, mockResult?.1)
        }
    }
    
    /// 使用 task 暂停任务, 线程安全
    func suspend<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        
    }
    
    /// 使用 task 取消任务, 线程安全
    func cancel<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        
    }
}
