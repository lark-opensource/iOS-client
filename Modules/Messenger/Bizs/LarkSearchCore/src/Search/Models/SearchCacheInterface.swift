//
//  SearchCacheInterface.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/4/14.
//

import Foundation
import RustPB
import LarkSearchFilter
import LarkSDKInterface
import RxSwift

public struct SearchCacheData {
    public let key: String
    public let results: [SearchResultType]
    public let timpStamp: Date
    public let quary: String
    public let filters: [SearchFilter]
    public let lastVisitIndex: IndexPath
    public var showRequestColdTip: Bool?
    public init(key: String, quary: String, filters: [SearchFilter], results: [SearchResultType], visitIndex: IndexPath) {
        self.key = key
        self.results = results
        self.quary = quary
        self.filters = filters
        self.timpStamp = Date()
        self.lastVisitIndex = visitIndex
    }
}

public protocol SearchCache {
    func set(key: String, quary: String, filers: [SearchFilter], results: [SearchResultType], visitIndex: IndexPath, showRequestColdTip: Bool?)
    func getCacheData(key: String) -> Observable<SearchCacheData?>
}
