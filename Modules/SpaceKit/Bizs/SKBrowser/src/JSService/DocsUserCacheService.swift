//
//  DocsCacheService.swift
//  SpaceKit
//
//  Created by liweiye on 2019/12/24.
//

import Foundation
import RxSwift
import SpaceInterface
import SKCommon
import SKFoundation
import SKInfra

public final class DocsUserCacheService {

    public init() {
        DocsLogger.info("DocsUserCacheService init!")
    }

    private var docsCacheSize: Observable<Float> {
        // 废弃逻辑
        return Observable.create { (observer) -> Disposable in
            observer.onNext(0)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    private var docsClearCache: Observable<Void> {
        // 废弃逻辑
        return Observable.create { (observer) -> Disposable in
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }

    @available(*, deprecated, message: "Use CleanTask related method instead")
    // Drive缓存大小
    private var driveCacheSize: Observable<Float> {
        return .just(0)
    }

    @available(*, deprecated, message: "Use CleanTask related method instead")
    // Drive清理缓存逻辑
    private var driveClearCache: Observable<Void> {
        return .just(())
    }

    private var spaceThumbnailCacheSize: Observable<Float> {
        guard let spaceThumbnailManager = DocsContainer.shared.resolve(SpaceThumbnailManager.self) else {
            return .just(0)
        }
        return spaceThumbnailManager.totalCacheSize
    }

    private var clearSpaceThumbnailCache: Observable<Void> {
        guard let spaceThumbnailManager = DocsContainer.shared.resolve(SpaceThumbnailManager.self) else {
            return .just(())
        }
        return Observable.create { observer in
            spaceThumbnailManager.cleanAllCache {
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

extension DocsUserCacheService: DocsUserCacheServiceProtocol {

    public func calculateCacheSize() -> Observable<Float> {
        return Observable.zip(driveCacheSize, docsCacheSize, spaceThumbnailCacheSize) { $0 + $1 + $2 }
    }

    public func clearCache() -> Observable<Void> {
        return Observable.zip(driveClearCache, docsClearCache, clearSpaceThumbnailCache) { _, _, _ in }
    }
}
