//
//  DocSearchAPIImpl.swift
//  CCMMod
//
//  Created by yinyuan on 2023/6/9.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging

#if MessengerMod
import LarkSDKInterface
#endif

import RustPB
import Swinject
import SKCommon
import SpaceInterface

public final class DocSearchAPIImpl: DocSearchAPI {
    
    static let logger = Logger.log(DocSearchAPIImpl.self, category: "Module.DocSearchAPIImpl")

    #if MessengerMod
    let searchAPI: SearchAPI
    #endif

    let disposeBag: DisposeBag = DisposeBag()

    public init(resolver: Resolver) {
        #if MessengerMod
        self.searchAPI = resolver.resolve(SearchAPI.self)!
        #endif

    }

    public func searchDoc(_ searchText: String?, docTypes: [String]?, callback: @escaping ([SKCommon.SearchDocResult]?, Error?) -> Void) {
        Self.logger.info("search doc searchText:\(searchText ?? ""), docTypes:\(docTypes ?? [])")
        #if MessengerMod
        var filter: LarkSDKInterface.SearchFilterParam? = nil
        if let docTypes = docTypes {
            filter = LarkSDKInterface.SearchFilterParam()
            filter?.docTypes = docTypes
        }
        let pageItemCount: Int32 = 200
        self.searchAPI
            .universalSearch(query: searchText ?? "",
                             scene: .searchDocAndWiki,
                             begin: 0,
                             end: pageItemCount,
                             moreToken: nil,
                             filter: filter,
                             needSearchOuterTenant: false,
                             authPermissions: [])
            .subscribe(onNext: { (response) in
                let results = response.results.map({ (searchResult) -> SearchDocResult in
                    var result = SearchDocResult()
                    result.title = searchResult.title.string
                    switch searchResult.meta {
                    //https://bytedance.feishu.cn/docs/doccnxfesEvyuhMPt3AU0hgiPFb
                    case let .doc(meta):
                        result.id = meta.id
                        result.ownerName = meta.ownerName
                        result.docType = meta.type.rawValue
                        result.url = meta.url
                        result.updateTime = meta.updateTime
                        result.isCrossTenant = meta.isCrossTenant
                        result.ownerID = meta.ownerID
                    case let .wiki(meta):
                        result.id = meta.id
                        result.ownerName = meta.ownerName
                        result.ownerID = meta.ownerID
                        result.docType = DocsType.wiki.rawValue
                        result.url = meta.url
                        result.wikiSubType = meta.type.rawValue
                        result.updateTime = meta.updateTime
                        result.isCrossTenant = meta.isCrossTenant
                    default:
                        break
                    }
                    return result
                })
                callback(results, nil)
            }, onError: { (error) in
                Self.logger.error("search doc failed", error: error)
                callback(nil, error)
            })
            .disposed(by: self.disposeBag)
        #endif
    }

}

