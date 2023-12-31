//
//  AsyncDataProcessViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/2/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkCore

open class AsyncDataProcessViewModel<RefreshSignalType: OuputTaskTypeInfo, DataSourceType: Collection>: NSObject {
    private let logger = Logger.log(AsyncDataProcessViewModel.self, category: "AsyncDataProcessViewModel")
    /// ui数据源
    public var uiDataSource: DataSourceType
    /// 队列
    public var queueManager: QueueManager<RefreshSignalType> = QueueManager<RefreshSignalType>()
    /// 刷新信号
    public var tableRefreshPublish: PublishSubject<(RefreshSignalType, newDatas: DataSourceType?, outOfQueue: Bool)>
        = PublishSubject<(RefreshSignalType, newDatas: DataSourceType?, outOfQueue: Bool)>()
    public lazy var tableRefreshDriver: Driver<RefreshSignalType> = self.transRefreshPublish()

    private let disableUIOutputCounter = OperatorCounter()
    public var enableUIOutputDriver: Driver<Bool> {
        return disableUIOutputCounter
            .hasOperatorObservable
            .map({ !$0 })
            .asDriver(onErrorJustReturn: true)
            .filter({ [weak self] (_) -> Bool in
                guard let self = self else { return false }
                return self.uiDataSourceCache != nil
            })
            .do(onNext: { [weak self] (enable) in
                guard let self = self else { return }
                if enable, let uiDataSourceCache = self.uiDataSourceCache {
                    self.uiDataSource = uiDataSourceCache
                }
                self.uiDataSourceCache = nil
            })
    }
    private var uiDataSourceCache: DataSourceType?

    /// 是否产生UI刷新任务
    public var enableUIOutput: Bool {
        return !disableUIOutputCounter.hasOperator
    }

    /// 并行处理方法
    public lazy var concurrentHandler: (Int, (Int) -> Void) -> Void = {
        return { [weak self] iterations, work in
            guard let self = self else { return }
            self.queueManager.concurrent(count: iterations, perform: work)
        }
    }()

    public init(uiDataSource: DataSourceType) {
        self.uiDataSource = uiDataSource
    }

    public func uiOutput(enable: Bool, indentify: String) {
        if enable {
            disableUIOutputCounter.decrease(category: indentify)
        } else {
            disableUIOutputCounter.increase(category: indentify)
        }
    }

    private func transRefreshPublish() -> Driver<RefreshSignalType> {
        return tableRefreshPublish
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (refreshType, datas, outOfQueue) -> Observable<RefreshSignalType> in
                guard let self = self else { return .empty() }
                guard self.enableUIOutput else {
                    if let datas = datas {
                        self.uiDataSourceCache = datas
                    }
                    return .empty()
                }
                return Observable.create({ [weak self] (obsever) -> Disposable in
                    guard let self = self else { return Disposables.create() }
                    if outOfQueue {
                        if let datas = datas {
                            self.uiDataSource = datas
                        }
                        self.logger.info("Schedule trace tableRefreshPublish in flatMap onNext direct \(refreshType.describ)")
                        obsever.onNext(refreshType)
                    } else {
                        let start = CACurrentMediaTime()
                        self.queueManager.addOutput(type: refreshType, task: { [weak self] in
                            guard let self = self else { return }
                            if let datas = datas {
                                self.uiDataSource = datas
                            }
                            self.logger.info("Schedule trace tableRefreshPublish in flatMap onNext in outputQueue \(Int64((CACurrentMediaTime() - start) * 1000))")
                            obsever.onNext(refreshType)
                        })
                    }
                    return Disposables.create()
                })
            }.asDriver(onErrorRecover: { _ in Driver<(RefreshSignalType)>.empty() })
    }
    /// 恢复队列
    public func resumeQueue() {
        self.queueManager.resumeQueue()
    }
    /// 暂停队列
    public func pauseQueue() {
        self.queueManager.pauseQueue()
    }
    /// 取消队列中的任务
    public func cancelAllTask() {
        self.queueManager.cancelAllTask()
    }
    /// 队列是否处于暂停状态
    public func queueIsPause() -> Bool {
        return self.queueManager.queueIsPause()
    }
}
