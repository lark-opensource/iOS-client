//
//  RustCacheCleanTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/8/21.
//

import UIKit
import Foundation
import LarkCache
import LarkContainer
import RustPB
import LKCommonsLogging
import LarkRustClient
import RxSwift

// swiftlint:disable empty_count
final class RustCacheCleanTask: CleanTask {
    var name: String = "Rust Resource Clean Task"

    static let logger = Logger.log(RustCacheCleanTask.self, category: "RustCacheCleanTask")

    @Provider private var rustService: RustService

    var disposeBag = DisposeBag()

    func clean(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CACurrentMediaTime()
        disposeBag = DisposeBag()
        var request = Basic_V1_TriggerDataCleanRequest()
        request.timeLimit = Int32(config.global.cacheTimeLimit)
        request.execTimeLimit = Int32(config.global.sdkTaskCostLimit)
        request.cleanType = config.isUserTriggered ? .user : .auto
        rustService.sendAsyncRequest(request)
            .subscribe(onNext: { (response: Basic_V1_TriggerDataCleanResponse) in
                RustCacheCleanTask.logger.info("clean data success")
                var completed = true
                var count = 0
                var bytes = 0
                response.cleaned.forEach { (cleaned) in
                    /// 存在一个失败及判定为失败任务
                    if !cleaned.completed {
                        completed = false
                    }
                    if cleaned.count > 0 {
                        count += Int(cleaned.count)
                    } else if cleaned.bytes > 0 {
                        bytes += Int(cleaned.bytes)
                    }
                }
                var sizes: [TaskResult.Size] = []

                if count > 0 {
                    sizes.append(.count(count))
                }

                if bytes > 0 {
                    sizes.append(.bytes(bytes))
                }

                let endTime = CACurrentMediaTime()
                let result = TaskResult(
                    completed: completed,
                    costTime: Int((endTime - startTime) * 1_000),
                    sizes: sizes
                )
                completion(result)
            }, onError: { (error) in
                RustCacheCleanTask.logger.error("clean data failed", error: error)
                let endTime = CACurrentMediaTime()
                let result = TaskResult(
                    completed: false,
                    costTime: Int((endTime - startTime) * 1_000),
                    size: .bytes(0)
                )
                completion(result)
            }).disposed(by: disposeBag)
    }

    func size(config: CleanConfig, completion: @escaping Completion) {
        let request = Media_V1_GetResourcesSizeRequest()
        let startTime = CACurrentMediaTime()
        rustService.sendAsyncRequest(request) { (res: Media_V1_GetResourcesSizeResponse) -> Float in
            return res.sizeM
        }.subscribe(onNext: { (size) in
            RustCacheCleanTask.logger.info("get size success")
            let endTime = CACurrentMediaTime()
            let result = TaskResult(
                completed: true,
                costTime: Int((endTime - startTime) * 1_000),
                size: .bytes(Int(size * 1024 * 1024))
            )
            completion(result)
        }, onError: { (error) in
            RustCacheCleanTask.logger.error("get size failed", error: error)
            let endTime = CACurrentMediaTime()
            let result = TaskResult(
                completed: false,
                costTime: Int((endTime - startTime) * 1_000),
                size: .bytes(0)
            )
            completion(result)
        }).disposed(by: disposeBag)
    }

    func cancel() {
        disposeBag = DisposeBag()
        let request = Basic_V1_CancelDataCleanRequest()
        rustService.sendAsyncRequest(request)
            .subscribe(onNext: { (_) in
                RustCacheCleanTask.logger.info("cancel clean success")
            }, onError: { (error) in
                RustCacheCleanTask.logger.error("cancel clean failed", error: error)
            }).disposed(by: disposeBag)
    }
}
// swiftlint:enable empty_count
