//
//  InlineCacheService.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/29.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkContainer
import RxSwift
import RustPB

// sourceID，sourceType相同时，只会有一份预览，当text变更时，需要移除上一次text的inline内存缓存
extension Url_V1_GetUrlPreviewRequest {
    var storeKey: String {
        return sourceID + "_" + "\(sourceType.rawValue)"
    }
}

extension InlinePreviewEntries {
    var storeKey: String {
        return sourceID + "_" + "\(sourceType.rawValue)"
    }
}

public final class InlineCacheService {
    static let logger = Logger.log(InlineCacheService.self, category: "InlineCacheService")

    public typealias Completion = (_ values: [InlinePreviewEntries], _ netCost: UInt64, _ error: Error?) -> Void
    // key: sourceID
    public typealias PushHandler = (_ values: [String: InlinePreviewEntries]) -> Void
    private var bucket: Int32 = 0

    private let urlAPI: URLPreviewAPI
    private let store = LRUCache<String, InlinePreviewEntries>(maxCapacity: 100)
    private let disposeBag = DisposeBag()
    private var pushHandlers = SafeDictionary<String, PushHandler>()

    public init(urlAPI: URLPreviewAPI, pushCenter: PushNotificationCenter) {
        self.urlAPI = urlAPI
        store.overflowCallback = { _, value in
            Self.logger.info("[URLPreview] LRU overflow: \(value.tcDescription)")
        }
        pushCenter.observable(for: InlinePreviewEntriesBody.self)
            .subscribe(onNext: { [weak self] entries in
                self?.handlePush(entries: entries)
            }).disposed(by: disposeBag)
    }

    /// 获取内存缓存Inline
    public func getInlineInMemory(request: Url_V1_GetUrlPreviewRequest) -> InlinePreviewEntries? {
        let key = request.storeKey
        let inline = store.getValue(key: key)
        if let inline = inline, inline.textMD5 == request.sourceTextMd5 {
            return inline
        } else if let inline = inline {
            // text变更，需要移除上一次的inline
            store.remove(key: inline.storeKey)
            Self.logger.info("[URLPreview] text changed & remove entry: newStoreKey = \(request.storeKey) -> newMD5 = \(request.sourceTextMd5) -> \(inline.tcDescription)")
            return nil
        }
        return nil
    }

    /// 获取内存缓存Inline
    public func getInlinesInMemory(requests: [Url_V1_GetUrlPreviewRequest]) -> [Url_V1_GetUrlPreviewRequest: InlinePreviewEntries] {
        let keys = requests.map({ $0.storeKey })
        let memoryValues = store.getValues(keys: keys)
        var result = [Url_V1_GetUrlPreviewRequest: InlinePreviewEntries]()
        var removingKeys = [String]()
        requests.forEach { request in
            if let value = memoryValues[request.storeKey] {
                if value.textMD5 == request.sourceTextMd5 {
                    result[request] = value
                } else {
                    // text变更，需要移除上一次的inline
                    removingKeys.append(value.storeKey)
                }
            }
        }
        if !removingKeys.isEmpty {
            store.remove(keys: removingKeys)
            Self.logger.info("[URLPreview] text changed & remove entry: \(removingKeys)")
        }
        return result
    }

    /// 从SDK获取Inline，不检查Memory Cache
    ///
    /// - Parameters:
    ///     - completion: 拉取完成的回调。仅回调一次。
    ///                   不保证线程
    public func getInlinesForceSDK(requests: [Url_V1_GetUrlPreviewRequest], strategy: Basic_V1_SyncDataStrategy, completion: Completion?) {
        _ = urlAPI.getUrlPreviewEntries(requests: requests, syncDataStrategy: strategy)
            .subscribe(onNext: { [weak self] (inlines, _, netCost) in
                var keyToInlines = inlines.reduce(into: [String: InlinePreviewEntries]()) { result, inline in
                    result[inline.storeKey] = inline
                }
                // 当没有预览时，也需要缓存，避免重复接口请求
                requests.forEach { request in
                    if keyToInlines[request.storeKey] == nil {
                        keyToInlines[request.storeKey] = InlinePreviewEntries(sourceID: request.sourceID,
                                                                              sourceType: request.sourceType,
                                                                              textMD5: request.sourceTextMd5,
                                                                              entries: [])
                    }
                }
                self?.saveEntries(entries: keyToInlines)
                completion?(inlines, netCost, nil)
            }, onError: { error in
                completion?([], 0, error)
            })
    }

    /// 注册Push
    ///
    /// - Returns: PushHandler标识，在不需要监听Push的时候，需要用该标识取消注册
    public func registerPush(handler: @escaping PushHandler) -> String {
        let identifier = uuid()
        assert(pushHandlers[identifier] == nil, "\(identifier) already exists")
        pushHandlers[identifier] = handler
        return identifier
    }

    /// 取消Push监听
    ///
    /// - Parameters:
    ///     - identifier: 注册时返回的identifier
    public func unregisterPush(identifier: String) {
        pushHandlers.removeValue(forKey: identifier)
    }
}

// MARK: - Private
extension InlineCacheService {
    private func saveEntries(entries: [String: InlinePreviewEntries]) {
        store.setValues(values: entries)
    }

    private func handlePush(entries: InlinePreviewEntriesBody) {
        var values = [String: InlinePreviewEntries]()
        entries.entries.forEach({ values[$0.value.storeKey] = $0.value })
        saveEntries(entries: values)
        let handlers = pushHandlers.getImmutableCopy()
        handlers.forEach { _, handler in
            handler(entries.entries)
        }
    }

    private func uuid() -> String {
        return String(OSAtomicIncrement32(&bucket))
    }
}
