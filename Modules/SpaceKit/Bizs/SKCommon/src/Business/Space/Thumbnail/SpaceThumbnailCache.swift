//
//  SpaceThumbnailCache.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  

import Foundation
import Kingfisher
import RxSwift
import RxCocoa
import SKFoundation
import ByteWebImage

public final class SpaceThumbnailCache {
    private static var userTumbnailCachePath: SKFilePath {
        let path = SKFilePath.userSandboxWithLibrary(User.current.info?.userID ?? "default")
            .appendingRelativePath("thumbnail.cache")
        return path
    }
    private static let snapshotPath = userTumbnailCachePath.appendingRelativePath("snapshot.json")

    enum CacheError: LocalizedError {
        // 缓存中没有找到记录
        case recordNotFound
        // 缓存中有记录，但是 Kingfisher 中取不到图片
        case imageNotFound

        var errorDescription: String? {
            switch self {
            case .recordNotFound:
                return "record not found in cache"
            case .imageNotFound:
                return "record found but failed to get image from imageCache"
            }
        }
    }

    // 记录缩略图的更新时间、etag、是否是特殊的缩略图
    fileprivate struct Record: Codable {

        enum RecordType: Codable {
            case thumbnail(etag: String?)
            case specialPlaceholder(etag: String?)
            case emptyContent
            case contentDeleted
            case generating
            case unavailable

            private enum CodingKeys: String, CodingKey {
                case baseType
                case etag
            }

            private enum BaseType: String, Codable {
                case thumbnail
                case specialPlaceholder
                case emptyContent
                case contentDeleted
                case generating
                case unavailable
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let baseType = try container.decode(BaseType.self, forKey: .baseType)
                switch baseType {
                case .thumbnail:
                    let etag = try container.decodeIfPresent(String.self, forKey: .etag)
                    self = .thumbnail(etag: etag)
                case .specialPlaceholder:
                    let etag = try container.decodeIfPresent(String.self, forKey: .etag)
                    self = .specialPlaceholder(etag: etag)
                case .emptyContent:
                    self = .emptyContent
                case .contentDeleted:
                    self = .contentDeleted
                case .generating:
                    self = .generating
                case .unavailable:
                    self = .unavailable
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case let .thumbnail(etag):
                    try container.encode(BaseType.thumbnail, forKey: .baseType)
                    if let etag = etag {
                        try container.encode(etag, forKey: .etag)
                    }
                case let .specialPlaceholder(etag):
                    try container.encode(BaseType.specialPlaceholder, forKey: .baseType)
                    if let etag = etag {
                        try container.encode(etag, forKey: .etag)
                    }
                case .emptyContent:
                    try container.encode(BaseType.emptyContent,
                                         forKey: .baseType)
                case .contentDeleted:
                    try container.encode(BaseType.contentDeleted,
                                         forKey: .baseType)
                case .generating:
                    try container.encode(BaseType.generating,
                                         forKey: .baseType)
                case .unavailable:
                    try container.encode(BaseType.unavailable,
                                         forKey: .baseType)
                }
            }

            var thumbnailType: Thumbnail.ThumbnailType {
                switch self {
                case let .thumbnail(etag):
                    assertionFailure("thumbnail type should be handle specific")
                    return .thumbnail(image: UIImage(), etag: etag)
                case let .specialPlaceholder(etag):
                    assertionFailure("specialPlaceholder type should be handle specific")
                    return .specialPlaceholder(image: UIImage(), etag: etag)
                case .emptyContent:
                    return .emptyContent(image: nil)
                case .contentDeleted:
                    return .contentDeleted(image: nil)
                case .generating:
                    return .generating
                case .unavailable:
                    return .unavailable
                }
            }
        }

        let token: String
        var updatedTime: TimeInterval
        let type: RecordType

        var thumbnailType: Thumbnail.ThumbnailType { return type.thumbnailType }
    }

    public struct Thumbnail {

        enum ThumbnailType {
            case thumbnail(image: UIImage, etag: String?)
            case specialPlaceholder(image: UIImage, etag: String?)
            case emptyContent(image: UIImage?)
            case contentDeleted(image: UIImage?)
            case generating
            case unavailable

            fileprivate var recordType: Record.RecordType {
                switch self {
                case let .thumbnail(_, etag):
                    return .thumbnail(etag: etag)
                case let .specialPlaceholder(_, etag):
                    return .specialPlaceholder(etag: etag)
                case .emptyContent:
                    return .emptyContent
                case .contentDeleted:
                    return .contentDeleted
                case .generating:
                    return .generating
                case .unavailable:
                    return .unavailable
                }
            }
        }

        let updatedTime: TimeInterval
        let type: ThumbnailType

        var etag: String? {
            switch type {
            case let .thumbnail(_, etag):
                return etag
            default:
                return nil
            }
        }

        fileprivate var recordType: Record.RecordType {
            return type.recordType
        }
    }

    private var recordsMap: [String: Record] = [:]
    private let snapshotChangedSubject = PublishSubject<Void>()

    private var saveSnapshotObservable: Observable<Void> {
        return snapshotChangedSubject.asObservable()
            .throttle(.seconds(60), scheduler: MainScheduler.instance)
    }


    private let queue = DispatchQueue(label: "space.thumbnail.cache", qos: .default, attributes: [.concurrent])

    private let disposeBag = DisposeBag()

    var size: Observable<Float> {
        // 直接清理 imageCache 会影响到 Lark 的缩略图，暂时不计算缩略图的缓存大小
        return .just(0)
    }

    init() {
        queue.async(flags: [.barrier]) {
            self.load()
        }
        // 每60秒持久化一次缩略图信息
        saveSnapshotObservable
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.queue.async(flags: [.barrier]) {
                    self.save()
                }
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyDeletedEvent), name: .Docs.cipherChanged, object: nil)
    }

    // 收到秘钥删除事件后清空一下记录
    @objc
    private func didReceiveKeyDeletedEvent() {
        DocsLogger.info("space.thumbnail.cache --- clean up records when receive key deleted event")
        cleanAllCache()
    }

    // 尝试获取缩略图
    func get(key: String) -> Single<Thumbnail> {
        return Single.create { [self] single in
            guard let record = recordsMap[key] else {
                DocsLogger.info("space.thumbnail.cache --- get cache failed, record not found cacheKey:\(DocsTracker.encrypt(id: key))")
                single(.error(CacheError.recordNotFound))
                return Disposables.create()
            }
            switch record.type {
            case let .thumbnail(etag):
                // 缩略图为正常图片
                return getCache(key: key)
                    .map { image in
                        Thumbnail(updatedTime: record.updatedTime,
                                  type: .thumbnail(image: image, etag: etag))
                    }
                    .subscribe(onSuccess: {
                        // 读取 KF 缓存成功
                        DocsLogger.info("space.thumbnail.cache --- get cache from KF success cacheKey:\(DocsTracker.encrypt(id: key))")
                        single(.success($0))
                    }, onError: {
                        // 读取 KF 缓存失败
                        if case .imageNotFound = $0 as? CacheError {
                            // KF 中没有缓存，删除掉对应的缩略图信息
                            remove(key: key)
                        }
                        DocsLogger.info("space.thumbnail.cache --- get cache from KF failed cacheKey:\(DocsTracker.encrypt(id: key))")
                        single(.error($0))
                    })
            case let .specialPlaceholder(etag):
                // 缩略图为正常图片
                return getCache(key: key)
                    .map { image in
                        Thumbnail(updatedTime: record.updatedTime,
                                  type: .specialPlaceholder(image: image, etag: etag))
                    }
                    .subscribe(onSuccess: {
                        // 读取 KF 缓存成功
                        DocsLogger.info("space.thumbnail.cache --- get cache from KF success cacheKey:\(DocsTracker.encrypt(id: key))")
                        single(.success($0))
                    }, onError: {
                        // 读取 KF 缓存失败
                        if case .imageNotFound = $0 as? CacheError {
                            // KF 中没有缓存，删除掉对应的缩略图信息
                            remove(key: key)
                        }
                        DocsLogger.info("space.thumbnail.cache --- get cache from KF failed cacheKey:\(DocsTracker.encrypt(id: key))")
                        single(.error($0))
                    })
            default:
                // 缩略图为其他特殊情况（空白、被删除、没有封面）
                let thumbnail = Thumbnail(updatedTime: record.updatedTime,
                                          type: record.thumbnailType)
                DocsLogger.info("space.thumbnail.cache --- get cache from KF success cacheKey:\(DocsTracker.encrypt(id: key))")
                single(.success(thumbnail))
                return Disposables.create()
            }
        }.subscribeOn(ConcurrentDispatchQueueScheduler(queue: queue))   // 保证读取信息的操作派发到缓存线程
    }

    func getMemoryCache(key: String) -> UIImage? {
        return LarkImageService.shared.image(with: .default(key: key), cacheOptions: .memory)
    }

    // 从KF缓存读取图片
    private func getCache(key: String) -> Single<UIImage> {
        return Single.create { single in
            LarkImageService.shared.image(with: .default(key: key), cacheOptions: .all) { image, _ in
                if let image = image {
                    DocsLogger.info("space.thumbnail.cache --- get cache from Lark success cacheKey:\(DocsTracker.encrypt(id: key))")
                    single(.success(image))
                } else {
                    DocsLogger.error("space.thumbnail.cache --- retrieve from cache failed, image not found", component: LogComponents.spaceThumbnail)
                    single(.error(CacheError.imageNotFound))
                }
            }
            return Disposables.create()
        }
    }

    func save(key: String, token: String, thumbnail: Thumbnail) {
        DocsLogger.info("space.thumbnail.cache -- prepare to save thumbnail", extraInfo: ["key": DocsTracker.encrypt(id: key), "type": thumbnail.type])
        queue.async(flags: [.barrier]) {
            switch thumbnail.type {
            case let .thumbnail(image, _), let .specialPlaceholder(image, _):
                DocsLogger.info("space.thumbnail.cache -- saving image in LarkImageService", extraInfo: ["key": DocsTracker.encrypt(id: key)])
                LarkImageService.shared.cacheImage(image: image, resource: .default(key: key)) { image, path in
                    DocsLogger.info("space.thumbnail.cache --- save image callback called.",
                                    extraInfo: ["key": DocsTracker.encrypt(id: key), "image": String(describing: image), "path": String(describing: path)])
                }
            case let .emptyContent(image),
                 let .contentDeleted(image: image):
                if let specialImage = image {
                    DocsLogger.info("space.thumbnail.cache -- saving special in LarkImageService", extraInfo: ["key": DocsTracker.encrypt(id: key)])
                    LarkImageService.shared.cacheImage(image: specialImage, resource: .default(key: key)) { image, path in
                        DocsLogger.info("space.thumbnail.cache --- save special image callback called.",
                                        extraInfo: ["key": DocsTracker.encrypt(id: key), "image": String(describing: image), "path": String(describing: path)])
                    }
                }
            case .generating:
                break
            case .unavailable:
                break
            }
            let record = Record(token: token, updatedTime: Date().timeIntervalSince1970, type: thumbnail.type.recordType)
            self.recordsMap[key] = record
            self.snapshotChangedSubject.onNext(())
        }
    }

    func markExpire(keys: [String]) {
        queue.async(flags: [.barrier]) {
            keys.forEach { key in
                guard var record = self.recordsMap[key] else {
                    DocsLogger.info("space.thumbnail.cache --- mark non-exist cache as expire")
                    return
                }
                record.updatedTime = 0
                self.recordsMap[key] = record
            }
            self.snapshotChangedSubject.onNext(())
        }
    }

    func update(key: String) {
        queue.async(flags: [.barrier]) {
            guard var record = self.recordsMap[key] else {
                DocsLogger.warning("space.thumbnail.cache --- updating non-exist cache")
                return
            }
            record.updatedTime = Date().timeIntervalSince1970
            self.recordsMap[key] = record
            self.snapshotChangedSubject.onNext(())
        }
    }

    func remove(key: String) {
        queue.async(flags: [.barrier]) {
            LarkImageService.shared.removeCache(resource: .default(key: key))
            self.recordsMap[key] = nil
            self.snapshotChangedSubject.onNext(())
        }
    }

    func cleanUp(tokens: [String], completion: (() -> Void)?) {
        queue.async(flags: [.barrier]) {
            let keysToDelete = self.recordsMap.compactMap { (key, record) -> String? in
                guard tokens.contains(record.token) else { return nil }
                return key
            }
            self.cleanUp(keys: keysToDelete, completion: completion)
        }
    }

    func cleanMemoryCache() {
        LarkImageService.shared.cache().clearMemory()
    }

    func cleanAllCache(completion: (() -> Void)? = nil) {
        queue.async(flags: [.barrier]) {
            LarkImageService.shared.cache().clearMemory()
            let allKeys = self.recordsMap.keys.map { $0 }
            self.cleanUp(keys: allKeys, completion: completion)
        }
    }

    private func cleanUp(keys: [String], completion: (() -> Void)?) {
        keys.forEach {
            self.recordsMap[$0] = nil
            LarkImageService.shared.removeCache(resource: .default(key: $0))
        }
        self.save()
        completion?()
    }

    private func load() {
        DocsLogger.info("space.thumbnail.cache --- loading cache records")
        do {
            let data = try Data.read(from: Self.snapshotPath)
            let records = try JSONDecoder().decode([String: Record].self, from: data)
            recordsMap = records
        } catch {
            DocsLogger.error("space.thumbnail.cache --- failed to decode records", error: error)
        }
    }

    private func save() {
        DocsLogger.info("space.thumbnail.cache --- saving cache records")
        let recordsToSave = recordsMap
        DispatchQueue.global().async {
            do {
                let jsonEncoder = JSONEncoder()
                let data = try jsonEncoder.encode(recordsToSave)
                guard Self.snapshotPath.writeFile(with: data, mode: .over) else {
                    DocsLogger.error("space.thumbnail.cache --- failed to save records")
                    return
                }
            } catch {
                DocsLogger.error("space.thumbnail.cache --- failed to save records", error: error)
            }
        }
    }
}
