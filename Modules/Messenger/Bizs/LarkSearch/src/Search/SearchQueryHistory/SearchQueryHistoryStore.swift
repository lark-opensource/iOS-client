//
//  SearchQueryHistoryStore.swift
//  LarkSearch
//
//  Created by SuPeng on 5/6/19.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RxCocoa
import ServerPB
import LarkSearchCore
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkContainer
import LarkRustClient

final class SearchQueryHistoryStore {
    static let logger = Logger.log(SearchQueryHistoryStore.self, category: "SearchQueryHistoryStore")

    let searchAPI: SearchAPI

    private let disposeBag = DisposeBag()

    let infosVariable: BehaviorRelay<[SearchHistoryInfo]> = BehaviorRelay(value: [])

    init(searchAPI: SearchAPI) {
        self.searchAPI = searchAPI
    }

    // 上传history info
    func save(info: SearchHistoryInfo, userResolver: UserResolver) {
        // 先检查fg状态，再决定是否过滤无query
        if SearchFeatureGatingKey.searchHistoryOptimize.isUserEnabled(userResolver: userResolver) {
            guard !info.query.isEmpty || !info.searchAction.filters.isEmpty else { return }
        } else {
            guard !info.query.isEmpty else { return }
        }
        SearchQueryHistoryStore.logger.info("[LarkSearch] start send search history",
                                            additionalData: ["query": info.query.lf.dataMasking,
                                                             "source": "\(info.searchAction.tab)"])
        var infos = self.infosVariable.value
        infos.removeAll { (historyInfo) -> Bool in
            historyInfo.query == info.query
        }
        infos.insert(info, at: 0)
        infosVariable.accept(infos)

        var request = PutSearchQueryHistoryRequest()
        request.queryMeta = info
        request.clientType = .ios
        let history = (try? userResolver.resolve(assert: RustService.self))?.sendPassThroughAsyncRequest(request, serCommand: .putSearchQueryHistory)

        history?.subscribe { event in
            SearchQueryHistoryStore.logger.info("succeed save search history，\(event)")
        } onError: { error in
            SearchQueryHistoryStore.logger.error("saving search history on error!，\(error.localizedDescription)")
        }
    }

    func deleteAllInfos(on window: UIWindow?, callback: @escaping (Bool) -> Void = { _ in }) {
        SearchQueryHistoryStore.logger.info("[LarkSearch] clear search histories")
        searchAPI.deleteAllSearchInfos().observeOn(MainScheduler.instance).subscribe({ [weak self] (event) in
            switch event {
            case .next:
                self?.infosVariable.accept([])
            case .error:
                guard let window = window else {
                    assertionFailure("缺少Window")
                    return
                }
                SearchQueryHistoryStore.logger.info("[LarkSearch] clear search histories failed")
                UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_DeleteFail, on: window)
            default: break
            }
            if case .next = event {
                callback(true)
            } else {
                callback(false)
            }
        }).disposed(by: disposeBag)
    }

    // 上传feedBack
    func saveSearch(searchText: String,
                    offset: Int32,
                    searchModel: SearchHistoryModel,
                    scene: SearchScene,
                    session: String,
                    imprID: String?) {
        let feedback = SearchFeedback.feedBackWith(model: searchModel, offset: offset)
        searchAPI
            .putSearch(feedbacks: [feedback],
                       searchText: searchText,
                       scene: scene,
                       searchSession: session,
                       imprID: imprID)
            .observeOn(MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
    }
}

typealias PutSearchQueryHistoryRequest = ServerPB_Usearch_PutSearchQueryHistoryRequest
typealias PutSearchQueryHistoryResponse = ServerPB_Usearch_PutSearchQueryHistoryResponse
