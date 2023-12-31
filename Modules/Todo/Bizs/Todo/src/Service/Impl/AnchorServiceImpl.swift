//
//  AnchorServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2021/6/29.
//

import LarkContainer
import RxSwift
import CTFoundation
import LKCommonsLogging

class AnchorServiceImpl: AnchorService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    private let entityCache = LRUCache<String, HangEntity>(capacity: 1_024, useLock: true)
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(AnchorServiceImpl.self, category: "Todo.AnchorServiceImpl")

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func cacheHangEntity(_ hangEntity: HangEntity, forPoint point: HangPoint) {
        assert(!hangEntity.previewID.isEmpty && !point.previewID.isEmpty)
        guard !hangEntity.previewID.isEmpty, !point.previewID.isEmpty else { return }
        if !point.url.isEmpty {
            entityCache.setValue(hangEntity, forKey: point.url)
        }
        entityCache.setValue(hangEntity, forKey: point.previewID)
    }

    func cacheHangEntity(_ hangEntity: HangEntity, forUrl urlStr: UrlStr) {
        assert(!hangEntity.previewID.isEmpty && !urlStr.isEmpty)
        guard !hangEntity.previewID.isEmpty, !urlStr.isEmpty else { return }
        entityCache.setValue(hangEntity, forKey: urlStr)
    }

    func getCachedHangEntity(forPoint point: HangPoint) -> HangEntity? {
        // assert(!point.previewID.isEmpty)
        guard !point.previewID.isEmpty else { return nil }
        return entityCache.value(forKey: point.previewID)
    }

    func getCachedHangEntity(forUrl urlStr: UrlStr) -> HangEntity? {
        assert(!urlStr.isEmpty)
        return entityCache.value(forKey: urlStr)
    }

    func generateHangEntity(forUrl urlStr: UrlStr) -> Maybe<HangEntity> {
        if let cached = getCachedHangEntity(forUrl: urlStr) {
            return Maybe<HangEntity>
                .just(cached)
                .delay(.milliseconds(100), scheduler: MainScheduler.instance)
        }
        return .create { [weak self] observer in
            guard let self = self, let fetchApi = self.fetchApi else {
                observer(.completed)
                return Disposables.create()
            }
            fetchApi.generateAnchorHangEntity(by: urlStr)
                .take(1)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onNext: { [weak self] entity in
                        guard var entity = entity else {
                            observer(.completed)
                            return
                        }
                        // 基于 url 生成 entity，previewID 为空，需要自行生成
                        if entity.previewID.isEmpty {
                            entity.previewID = UUID().uuidString
                        }
                        self?.entityCache.setValue(entity, forKey: urlStr)
                        observer(.success(entity))
                    },
                    onError: {
                        observer(.error($0))
                    }
                )
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }

    func getHangEntities(forPoints points: [HangPoint], sourceId: String) -> Return<[HangEntity]> {
        assert(!points.isEmpty)
        let cached = points.compactMap(getCachedHangEntity(forPoint:))
        if cached.count == points.count {
            return .sync(value: cached)
        }
        let completion = Return<[HangEntity]>.Completion()
        fetchApi?.getAnchorHangEntities(forPoints: points, with: sourceId)
            .take(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] entities in
                    entities.forEach { entity in
                        self?.entityCache.setValue(entity, forKey: entity.previewID)
                        self?.entityCache.setValue(entity, forKey: entity.url.url)
                    }
                    completion.onSuccess?(entities)
                },
                onError: {
                    completion.onError?($0)
                }
            )
            .disposed(by: disposeBag)
        return .async(completion: completion)
    }

}
