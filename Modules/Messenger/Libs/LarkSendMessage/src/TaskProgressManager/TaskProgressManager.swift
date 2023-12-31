//
//  TaskProgressManager.swift
//  Lark
//
//  Created by lichen on 2017/4/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging // Logger
import RxSwift // Observable
import RustPB // Media_V1_FileState
import LarkContainer // PushMessage

public struct PushUploadFile: PushMessage {
    public let localKey: String
    public let key: String
    public let progress: Progress
    public let rate: Int64
    public let state: RustPB.Media_V1_FileState
    /// 没地方使用，先private预留
    private let type: RustPB.Basic_V1_File.EntityType

    public init(
        localKey: String,
        key: String,
        progress: Progress,
        state: RustPB.Media_V1_FileState,
        type: RustPB.Basic_V1_File.EntityType,
        rate: Int64
    ) {
        self.localKey = localKey
        self.key = key
        self.progress = progress
        self.state = state
        self.type = type
        self.rate = rate
    }
}

public protocol ProgressService {
    /// 使用方：进度相关
    var value: Observable<(String, Progress)> { get }
    func value(key: String) -> Observable<Progress>
    func getProgressValue(key: String) -> Progress?
    /// 使用方：速率相关
    var rateValue: Observable<(String, Int64)> { get }
    func rateValue(key: String) -> Observable<Int64>
    /// 使用方：上传完成
    var finish: Observable<PushUploadFile> { get }
    func finish(key: String) -> Observable<RustPB.Media_V1_FileState>

    /// 提供方：更新上传状态
    func dealUploadFileInfo(_ fileUploadInfo: PushUploadFile)
    /// 提供方：更新上传进度、速率
    func update(key: String, progress: Progress, rate: Int64?)
}

final class TaskProgressManager: ProgressService {
    static let logger: Log = Logger.log(TaskProgressManager.self, category: "lk.task.progress manager")

    private let queue: DispatchQueue = DispatchQueue(label: "com.lark.task.progress", qos: .userInitiated)

    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()

    /// 进度相关
    public var value: Observable<(String, Progress)> {
        return self.valueSubject.asObservable()
    }
    public func value(key: String) -> Observable<Progress> {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        var valueSignal = self.value.asObservable()
            .filter({ (taskKey, _) -> Bool in
                return taskKey == key
            })
            .map({ (_, progress) -> Progress in
                return progress
            })
        if let progress = self.caches[key] {
            valueSignal = valueSignal.startWith(progress)
        }
        return valueSignal
    }
    private var valueSubject: PublishSubject<(String, Progress)> = PublishSubject<(String, Progress)>()

    /// 速率相关
    private var rateValueSubject: PublishSubject<(String, Int64)> = PublishSubject<(String, Int64)>()
    public var rateValue: Observable<(String, Int64)> {
        return self.rateValueSubject.asObservable()
    }
    public func rateValue(key: String) -> Observable<Int64> {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        var rateValueSignal = self.rateValue.asObservable()
            .filter({ (taskKey, _) -> Bool in
                return taskKey == key
            })
            .map({ (_, rate) -> Int64 in
                return rate
            })
        return rateValueSignal
    }

    /// 上传完成
    public var finish: Observable<PushUploadFile> {
        return self.finishSubject.asObservable()
    }
    public func finish(key: String) -> Observable<RustPB.Media_V1_FileState> {
        return self.finish
            .filter({ pushUploadFile -> Bool in
                return pushUploadFile.localKey == key
            })
            .map({ pushUploadFile -> RustPB.Media_V1_FileState in
                return pushUploadFile.state
            })
    }
    private var finishSubject: PublishSubject<PushUploadFile> = PublishSubject<PushUploadFile>()

    /// 缓存进度（用户开始监听时设置初始值）
    private var caches: [String: Progress] = [:]

    // MARK: - lifeCycle
    init() {
        pthread_rwlock_init(&self.rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwlock)
    }

    private func removeRequest(fileUploadInfo: PushUploadFile) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        TaskProgressManager.logger.debug(
            "task progress manager remove",
            additionalData: [
                "key": fileUploadInfo.localKey
            ])
        caches[fileUploadInfo.localKey] = nil
        queue.async {
            self.finishSubject.onNext(fileUploadInfo)
        }
    }

    // MARK: - public methods
    public func dealUploadFileInfo(_ fileUploadInfo: PushUploadFile) {
        if fileUploadInfo.state == .uploading ||
            fileUploadInfo.state == .uploadWait ||
            fileUploadInfo.state == .uploadCreated {
            //更新进度和速率
            self.update(key: fileUploadInfo.localKey, progress: fileUploadInfo.progress, rate: fileUploadInfo.rate)
        } else {
            self.removeRequest(fileUploadInfo: fileUploadInfo)
        }
    }

    public func getProgressValue(key: String) -> Progress? {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return caches[key]
    }

    //更新进度和速率
    public func update(key: String, progress: Progress, rate: Int64? = -1) {
        _ = pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        TaskProgressManager.logger.debug(
            "task progress manager update",
            additionalData: [
                "key": key,
                "value": "\(Float(progress.completedUnitCount) / Float(progress.totalUnitCount))"
            ])

        caches[key] = progress
        queue.async {
            //更新进度
            self.valueSubject.onNext((key, progress))
            //更新速率
            if let rate = rate {
                self.rateValueSubject.onNext((key, rate))
            }
        }
    }
}
