//
//  ECONetworkServicePipelineStep.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/6.
//

import Foundation

/// ECONetworkPipelineException
/// 异常处理步骤, 用于在 pipeline 发生异常后执行异常流
/// 部分步骤在正常流和异常流均有任务需要执行, 可以同时实现两个协议
protocol ECONetworkPipelineException {
    func exception<ResultType>(task: ECONetworkServiceTask<ResultType>, error: ECONetworkError)
}

/// ECONetworkPipelineStep
/// NetworkService 执行任务的独立步骤
/// 注意避免逻辑耦合, 确保每个 Step 是独立可测试的
protocol ECONetworkPipelineStep {
    /// 当前步骤要做的操作
    /// 因为 piple 中同步异步并存, 需要将同步也描述为异步信息
    /// ❗必须调用 callback 否者会使 pipeline 流程莫名中断
    /// - Parameters:
    ///   - context: pipeline 执行过程产生的数据
    ///   - callback: 执行结束回调
    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    )
    
    /*
     流程控制类函数, 默认啥也不做 (很多同步场景,没必要强行加个时机中断, 异步场景需要 override 实现)
     是否要带状态和控制能力, 由 实现类 自行决定, 一般同步不需要, 异步需要
     带状态的调用方(如 pipeline), 需要处理 suspend cancel 后任务仍然回调的场景(同步操作大多没有拦截时机)
     */
    
    /// 继续,(专用于控制操作,状态处理等.  业务逻辑在 process 里实现,不要耦合)
    /// ⚠️ resumeProcess 与 suspendProcess 必须成对实现, 并且逻辑上闭合, 否者会出现暂停了无法重新开始的场景
    func resume()
    /// 暂停
    /// ⚠️ resumeProcess 与 suspendProcess 必须成对实现, 并且逻辑上闭合, 否者会出现暂停了无法重新开始的场景
    func suspend()
    /// 取消
    func cancel()
}

extension ECONetworkPipelineStep {
    /// 默认啥也不干,  实现类执行决定如何 "重新"执行
    func resume() {}
    /// 默认啥也不干, 现类执行决定如何 "暂停"执行
    func suspend() {}
    /// 默认啥也不干, 实现类决定如何取消
    func cancel() {}
}


