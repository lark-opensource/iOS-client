//
//  ECONetworkPipeline.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/1.
//

import Foundation
import LKCommonsLogging

private let PipelineLogger = Logger.oplog("ECONetworkServicePipeline", category: "ECONetwork")

public enum ECONetworkServicePipelineState: String {
    case inited
    case running
    case pending
    case cancelled
    case completed
    
    mutating func update(with semaphore: DispatchSemaphore, newState: ECONetworkServicePipelineState) -> Bool {
        semaphore.wait(); defer { semaphore.signal() }
        switch newState {
        case .inited: return false
        case .running: guard self == .inited || self == .pending  else { return false }
        case .pending: guard self == .running else { return false }
        case .cancelled: guard self == .pending || self == .running else { return false }
        case .completed: guard self == .running else { return false }
        }
        self = newState
        return true
    }
}

public final class ECONetworkServicePipeline<ResultType> {
    
    /// 总步骤
    public var totalStep: Int {steps.count}
    /// 当前步骤
    public private(set) var currentStepIndex: Int = 0
    /// 当前执行状态
    public private(set) var state: ECONetworkServicePipelineState = .inited
    
    /// pipeline 执行的步骤集
    private let steps: [ECONetworkPipelineStep]
    /// pipeline 发生异常后, 步骤集
    private let exceptionHandlers: [ECONetworkPipelineException]
    /// 处理线程
    private let operationQueue: OperationQueue
    /// 线程锁
    private let semaphore = DispatchSemaphore(value: 1)
    /// 贯穿 pipeline 的上下文
    private weak var task: ECONetworkServiceTask<ResultType>?
    /// pipeline 整个执行完成后的对外回调
    private var completionHandler: ((ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void)?
    
    /// 初始化 pipeline
    /// - Parameters:
    ///   - context: 用于贯穿 pipeline,传递数据的 context
    ///   - operationQueue: 操作的队列
    ///   - steps: 操作集
    init(
        operationQueue: OperationQueue,
        steps: [ECONetworkPipelineStep],
        exceptionHandlers: [ECONetworkPipelineException]
    ) {
        self.operationQueue = operationQueue
        self.steps = steps
        self.exceptionHandlers = exceptionHandlers
    }
}

extension ECONetworkServicePipeline {
    func setup(task: ECONetworkServiceTask<ResultType>, pipelineCompletionHandler: @escaping (ECONetworkResponse<ResultType>?, ECONetworkError?) -> Void) {
        self.task = task
        self.completionHandler = pipelineCompletionHandler
    }
    
    func execute(){
        let identifier = task?.identifier ?? ""
        let lastState = state
        guard currentStepIndex < steps.count,
              state.update(with: semaphore, newState: .running) else {
            PipelineLogger.warn("Pipeline<\(identifier)>: Can not be excute, state = \(self.state.rawValue)")
            return
        }
        operationQueue.addOperation { [weak self] in
            guard let task = self?.task,
                  let index = self?.currentStepIndex else {
                assertionFailure("context is nil")
                PipelineLogger.error("context is nil")
                self?.pipelineError(error: .innerError(OPError.unknownError(detail: "pipeline context is nil")))
                return
            }
            if lastState == .inited {
                PipelineLogger.info("Pipeline<\(identifier)>: Excuted")
                self?.excuteStep(task: task)
            } else {
                PipelineLogger.info("Pipeline<\(identifier)>: Resume step <\(index)>")
                self?.steps[index].resume()
            }
        }
    }
    
    func suspend() {
        let identifier = task?.identifier ?? ""
        guard state.update(with: semaphore, newState: .pending) else {
            PipelineLogger.warn("Pipeline<\(identifier)>: Can not be suspended, state = \(state.rawValue)")
            return
        }
        let index = currentStepIndex
        let step = steps[currentStepIndex]
        operationQueue.addOperation {
            PipelineLogger.info("Pipeline<\(identifier)>: Suspended step <\(index)>", additionalData:[
                "step": String(describing: step.self),
                "index": String(index)
            ])
            step.suspend()
        }
    }
    
    func cancel() {
        let identifier = task?.identifier ?? ""
        guard state.update(with: semaphore, newState: .cancelled) else {
            PipelineLogger.warn("Pipeline<\(identifier)>: Can not be cancelled, state = \(state.rawValue)")
            return
        }
        let index = currentStepIndex
        let step = steps[index]
        operationQueue.addOperation {
            PipelineLogger.info("Pipeline: \(identifier) Cancelled step <\(index)>", additionalData:[
                "step": String(describing: step.self),
                "index": String(index)
            ])
            step.cancel()
        }
    }
}

extension ECONetworkServicePipeline {
    private func excuteStep(task: ECONetworkServiceTask<ResultType>) {
        let identifier = task.identifier
        let index = currentStepIndex
        let currentStep = steps[index]
        PipelineLogger.info("Pipeline<\(identifier)>: Excute step <\(currentStepIndex)>",
                            additionalData:[
                                "step": String(describing: currentStep.self),
                                "index": String(currentStepIndex)
                            ])
        currentStep.process(task: task) { [weak self] (result) in
            switch result {
            case .success(let task):
                self?.stepComplete(task: task)
            case .failure(let error):
                // 将取消场景的错误处理为统一 Error,以便于后面识别
                
                self?.pipelineError(
                    error: self?.state == .cancelled ? .cancel : error
                )
            }
        }
    }
    
    private func excuteExceptionHandlers(task: ECONetworkServiceTask<ResultType>, error: ECONetworkError) {
        PipelineLogger.info("Pipeline<\(task.identifier)>: Excute exception handlers",
                            additionalData:[
                                "exceptionHandlers":  exceptionHandlers.map{"\($0.self)"}.joined(separator: ","),
                                "error": String(describing: error)
                            ])
        exceptionHandlers.forEach { excetionHandler in
            excetionHandler.exception(task: task, error: error)
        }
    }
    
    private func stepComplete(task: ECONetworkServiceTask<ResultType>) {
        PipelineLogger.info("Pipeline<\(task.identifier)>: Step <\(currentStepIndex)> completed",
                            additionalData:[
                                "index": String(currentStepIndex),
                                "step": String(describing: steps[currentStepIndex].self),
                                "state": state.rawValue
                            ])
        switch state {
        case .running:
            nextStep(task: task)
        case .cancelled:
            pipelineError(error: .cancel)
        case .pending:
            PipelineLogger.info("Pipeline<\(task.identifier)>: pipeline pending currentStep: <\(currentStepIndex)> ")
        case .inited, .completed:
            PipelineLogger.error("Pipeline<\(task.identifier)>: error state:\(state) currentStep: <\(currentStepIndex)> ")
        }
    }

    private func nextStep(task: ECONetworkServiceTask<ResultType>) {
        currentStepIndex += 1
        if currentStepIndex < steps.count {
            PipelineLogger.info("Pipeline<\(task.identifier)>: Next step <\(currentStepIndex)>",
                                additionalData:[
                                    "currentIndex": String(currentStepIndex - 1),
                                    "nextIndex": String(currentStepIndex),
                                    "count": String(steps.count)
            ])
            excuteStep(task: task)
        } else {
            PipelineLogger.info("Pipeline<\(task.identifier)>: Pipeline complete currentStepIndex=\(currentStepIndex)",
                                additionalData:[
                                    "count": String(steps.count)
            ])
            pipelineComplete()
        }
    }
    
    private func pipelineComplete(error: ECONetworkError? = nil) {
        guard state.update(with: semaphore, newState: .completed) else {
            PipelineLogger.warn("Can not be completed, state = \(state.rawValue)")
            assertionFailure("Can not be completed, state = \(state.rawValue)")
            return
        }
        let identifier = task?.identifier ?? ""
        PipelineLogger.info("Pipeline<\(identifier)>: Pipeline Completed")

        let response = task?.response
        let errorWrapper = ECONetworkErrorWapper(error: error)
        let log = """
        ECONetwork/request-id/\(task?.trace.getRequestID() ?? ""),
        result_type=\(error == nil ? "success" : "fail")
        domain=\(response?.request.url?.host ?? ""),
        path=\(response?.request.url?.path ?? ""),
        status_code=\(response?.response.statusCode ?? -1),
        err_code=\(errorWrapper?.errorCode ?? -1),
        err_msg=\(errorWrapper?.errorMessage ?? "")
        """
        task?.trace.info(log, tag: ECONetworkLogKey.endResponse)

        completionHandler?(response, error)
    }
    
    private func pipelineError(error: ECONetworkError) {
        guard let task = task else {
            assertionFailure("context is nil")
            PipelineLogger.error("context is nil")
            // 无法触发异常流, 提前结束
            pipelineComplete(error: .pipelineError(msg: "Pipeline context is nil"))
            return
        }
        PipelineLogger.error("Pipeline<\(task.identifier)>: Pipeline error step <\(currentStepIndex)>",
                            additionalData:[
                                "error": String(describing: error),
                                "index": String(currentStepIndex),
                                "step": String(describing: steps[currentStepIndex].self),
                                "state": state.rawValue
                            ])
        excuteExceptionHandlers(task: task, error: error)
        pipelineComplete(error: error)
    }
}

