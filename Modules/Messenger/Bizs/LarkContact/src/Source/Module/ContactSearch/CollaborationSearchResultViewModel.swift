//
//  CollaborationSearchResultViewModel.swift
//  LarkContact
//
//  Created by Nix Wang on 2022/11/24.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkSearchCore
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface

enum CollaborationSearchState: CustomStringConvertible {
    case idle
    case loading
    case loadingMore
    case noResults(String)
    case success(CollaborationTenantModel)
    case failure(Error)

    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .loading:
            return "loading"
        case .loadingMore:
            return "ladingMore"
        case .noResults(_):
            return "noResults"
        case .success(let model):
            return "success(count: \(model.tenants.count), hasMore: \(model.hasMore))"
        case .failure(let error):
            return "failure(\(error.localizedDescription))"
        }
    }

}

class CollaborationSearchResultViewModel {
    typealias Tenant = Contact_V1_CollaborationTenant

    static let logger = Logger.log(CollaborationSearchResultViewModel.self, category: "Module.IM.Message")

    let query = BehaviorRelay(value: "")
    let state = BehaviorRelay(value: CollaborationSearchState.idle)
    let associationContactType: AssociationContactType?
    var result = BehaviorRelay(value: CollaborationTenantModel(tenants: [], hasMore: false))

    private static let pageCount = 30

    private let departmentAPI: CollaborationDepartmentAPI
    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    init(departmentAPI: CollaborationDepartmentAPI, associationContactType: AssociationContactType?) {
        self.departmentAPI = departmentAPI
        self.associationContactType = associationContactType
        query
            .debounce(.milliseconds(Int(SearchRemoteSettings.shared.searchDebounce * 1000)),
                      scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] query in
                guard let self = self else { return }

                self.loadData(query: query, isLoadMore: false)
            })
            .disposed(by: disposeBag)
    }

    func loadMore() {
        loadData(query: query.value, isLoadMore: true)
    }

    func loadData(query: String, isLoadMore: Bool) {
        Self.logger.info("n_action_collaboration_search_start: load more \(isLoadMore)")

        searchDisposeBag = DisposeBag()
        if !isLoadMore {
            self.result.accept(CollaborationTenantModel(tenants: [], hasMore: false))
        }

        if query.isEmpty {
            Self.logger.info("n_action_collaboration_search_empty")

            self.state.accept(.idle)
            return
        }

        self.state.accept(isLoadMore ? .loadingMore : .loading)
        self.departmentAPI.fetchCollaborationTenant(offset: self.result.value.tenants.count, count: Self.pageCount, showConnectType: associationContactType, query: query)
            .subscribe(onNext: { [weak self] model in
                guard let self = self else { return }

                if !isLoadMore && model.tenants.isEmpty {
                    self.state.accept(.noResults(query))
                    return
                }

                Self.logger.info("n_action_collaboration_search_succ: \(model.tenants.count) results, has more: \(model.hasMore)")
                var tenants = self.result.value.tenants
                tenants.append(contentsOf: model.tenants)
                self.result.accept(CollaborationTenantModel(tenants: tenants, hasMore: model.hasMore))
                self.state.accept(.success(self.result.value))
            }) { [weak self] error in
                guard let self = self else { return }

                Self.logger.error("n_action_collaboration_search_fail: \(error)")
                self.state.accept(.failure(error))
            }
            .disposed(by: self.searchDisposeBag)
    }
}
