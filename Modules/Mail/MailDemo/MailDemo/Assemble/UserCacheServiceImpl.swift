//
//  UserCacheServiceImpl.swift
//  LarkSDK
//
//  Created by SuPeng on 1/7/20.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkFoundation
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkCache
import LarkFileKit
import LarkStorage

final class UserCacheServiceImpl: UserCacheService {
    @Provider private var resourceAPIGetter: ResourceAPI
    @InjectedLazy private var userSpaceService: UserSpaceService
   // private let docsUserCacheService: DocsCacheDependency

    private static let logger = Logger.log(UserCacheServiceImpl.self, category: "Library.UserCacheSpace")

    func calculateCacheSize() -> Observable<Float> {
        let native = Observable<Float>.create { [weak self] (observer) -> Disposable in
            guard let self = self,
                  let currentUserDirectoryPath = self.userSpaceService.currentUserDirectory?.path
            else {
                observer.onCompleted()
                return Disposables.create()
            }

            let fileSize = Path(currentUserDirectoryPath).recursizeFileSize
            observer.onNext(Float(Int(truncatingIfNeeded: fileSize)) / (1024 * 1024))
            observer.onCompleted()

            return Disposables.create()
        }.subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "calculate_cache_size"))

        let cleanTasks = Observable<Float>.create { (observer) -> Disposable in
            let cleanConfig = CleanConfig(
                isUserTriggered: true,
                cleanInterval: 0,
                cacheTimeLimit: 0)
            CacheManager.shared.size(config: cleanConfig) { (sizes) in
                observer.onNext(Float(sizes.cleanBytes) / (1024 * 1024))
                observer.onCompleted()
            }
            return Disposables.create()
        }.subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "calculate_cache_size"))

        return Observable.combineLatest(native, cleanTasks) { (nativeSize, taskSize) -> Float in
            UserCacheServiceImpl.logger.info("called calculateCacheSize(): native:\(nativeSize) taskSize:\(taskSize)")
            return nativeSize + taskSize
        }
    }

    func clearCache() -> Observable<Float> {
        UserCacheServiceImpl.logger.info("called clearCache()")
        let startTime = Date().timeIntervalSince1970

        let nativeClear = Observable<Void>.create { [weak self] (observer) -> Disposable in
            guard let self = self,
                  let currentUserDirectoryPath = self.userSpaceService.currentUserDirectory?.path
            else {
                    observer.onNext(())
                    observer.onCompleted()
                    return Disposables.create()
            }

            Path(currentUserDirectoryPath).eachChildren { try? $0.deleteFile() }
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }.subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "clear_cache"))

        let cleanTaskClear = Observable<Void>.create { (observer) -> Disposable in
            let cleanConfig = CleanConfig(
                isUserTriggered: true,
                cleanInterval: 0,
                cacheTimeLimit: 0)
            CacheManager
                .shared
                .clean(config: cleanConfig) {
                    observer.onNext(())
                    observer.onCompleted()
                }
            return Disposables.create()
        }.subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "clear_cache"))

        let native = appendEndTime(to: nativeClear,
                                   of: "native",
                                   from: startTime)

        let cleanTask = appendEndTime(to: cleanTaskClear, of: "larkCache", from: startTime)

        return Observable<Void>.combineLatest(native, cleanTask) { nativeTime, cleanTaskTime in
            UserCacheServiceImpl.logger.info("clearCache() got four signals")
            Tracker.post(SlardarEvent(
                name: "disk_size_monitor",
                metric: [
                    "native_clear_cache": nativeTime,
                    "clean_task_clear_cache": cleanTaskTime
                ],
                category: [:],
                extra: [:])
            )
            return ()
        }.flatMap(calculateCacheSize)
    }

    func appendEndTime(to observable: Observable<Void>,
                       of business: String,
                       from startTime: Double) -> Observable<Double> {
        return observable.flatMap { _ -> Observable<Double> in
            return Observable.create { observer in
                let timeConsuming = Date().timeIntervalSince1970 - startTime
                observer.onNext(timeConsuming)
                observer.onCompleted()
                UserCacheServiceImpl.logger.info("\(business) finished cache clearing in \(timeConsuming)s")
                return Disposables.create()
            }
        }
    }
}

extension String {
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }
}
