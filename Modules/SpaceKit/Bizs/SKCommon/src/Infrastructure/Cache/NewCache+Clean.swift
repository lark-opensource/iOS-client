//
//  NewCache+Clean.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/8/19.
//

import Foundation
import SKFoundation
import YYCache
import RxSwift
import SKInfra

public struct CleanResult {
    public let completed: Bool
    public let costTime: Int
    public let size: Int
}

extension NewCache {
    func cleanCancel() {
    }

    func cacheSize() -> Observable<CleanResult> {
        guard User.current.info?.userID != nil else {
            let ob = Observable<CleanResult>.create { (observer) -> Disposable in
                observer.onNext(CleanResult(completed: false, costTime: 0, size: 0))
                observer.onCompleted()
                return Disposables.create()
            }
            return ob
        }

        DocsLogger.info("--cacheSize-- begin", component: LogComponents.newCache)

        let clientVar = Observable<CleanResult>.create { (observer) -> Disposable in
            self.sql?.getTotalSize(complete: { (suc, time, count) in
                DocsLogger.info("--cacheSize--end--clientVar--suc=\(suc),time=\(time),count=\(count)--", component: LogComponents.newCache)

                observer.onNext(CleanResult(completed: suc, costTime: time, size: count))
                observer.onCompleted()
            })
            return Disposables.create()
        }
        return clientVar
    }

    func cacheClean(maxSize: Int, ageLimit: Int, isUserTrigger: Bool) -> Observable<CleanResult> {
        guard User.current.info?.userID != nil else {
            let ob = Observable<CleanResult>.create { (observer) -> Disposable in
                observer.onNext(CleanResult(completed: false, costTime: 0, size: 0))
                observer.onCompleted()
                return Disposables.create()
            }
            return ob
        }

        DocsLogger.info("--cacheClean-- begin, maxSize=\(maxSize),ageLimit=\(ageLimit),isUserTrigger=\(isUserTrigger)", component: LogComponents.newCache)

        if isUserTrigger {
            //发通知，通知预加载停止
            NotificationCenter.default.post(name: Notification.Name.Docs.userWillCleanNewCache, object: nil)
            CCMKeyValue.globalUserDefault.set(false, forKey: UserDefaultKeys.didOpenOneDocsFile)
            cachedDictQueue.async {
                self.metaDataCache.removeAll()
                self.clientVarCache = DocValueCache<H5DataRecordKey, H5DataRecord>()
            }
        }

        let clientVar = Observable<CleanResult>.create { (observer) -> Disposable in
            self.sql?.cacheTrim(maxSize: maxSize, ageLimit: ageLimit, isUserTrigger: isUserTrigger, complete: { (suc, time, resultCount, trimSize) in
                DocsLogger.info("--cacheClean-- end--suc=\(suc),clientVar=\(resultCount)--trimSize=\(trimSize)--time=\(time)-", component: LogComponents.newCache)
                observer.onNext(CleanResult(completed: suc, costTime: time, size: trimSize))
                observer.onCompleted()
            })
            return Disposables.create()
        }
        return clientVar
    }
}
