//
//  ResourceManager.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/5/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

open class ResourceManager<ResourceImpl, C: ResourceStorage> where C.ResourceItem == ResourceImpl {

    public var cache: C
    public var downloader: ResourceDownloader
    public var cacheOptions: [ResourceStorageOption] = [] {
        didSet {
            cache.options = cacheOptions
        }
    }

    public init(downloader: ResourceDownloader, cache: C) {
        self.downloader = downloader
        self.cache = cache
    }

    @discardableResult
    public func fetchResource(key: String,
                              authToken: String?,
                              downloadOptions: DownloadOptions? = nil,
                              async: Bool = true,
                              compliteHandler: @escaping (Error?, ResourceImpl?) -> Void) -> ResourceDownloadTaskImpl? {
        if cache.isCached(key: key) {
            if async {
                cache.get(key: key, resourceBlock: { (resource) in
                    compliteHandler(nil, resource)
                })
            } else {
                compliteHandler(nil, cache.get(key: key))
            }

            return nil
        }
        return downloader.downloadResource(key: key, authToken: authToken, onStateChangeBlock: { [weak self] (state) in
            if state.readyState == .done {
                if state.data != nil {
                    if let resource = ResourceImpl.generate(data: state.data!) as? ResourceImpl {
                        compliteHandler(state.error, state.data != nil ? resource : nil)
                        self?.cache.store(key: key, resource: resource, compliteHandler: nil)
                    } else {
                        compliteHandler(PlainError("Resource.gennerate can not convert data to ResourceImpl"), nil)
                    }
                } else {
                    compliteHandler(state.error, nil)
                }
            }
        }, options: downloadOptions)
    }
}
