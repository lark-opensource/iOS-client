//
//  DocumentProvider.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/13.
//

import Foundation
import RxSwift
import LarkCore
import UIKit
import RustPB
import LarkFeatureGating
import LarkAccountInterface
import LarkSearchCore
import LarkSDKInterface
import LarkContainer

final class DocumentProvider: SearchResultViewListBindDelegate, IMMentionDataConvertable {
    var context: IMMentionContext
    
    private let disposeBag = DisposeBag()
    
    var result: [[IMMentionOptionType]] = [[]]
    
    var showDocumentOwner: Bool
    var showChatterMail: Bool

    var currentUserId: String {
        return self.userService?.user.userID ?? ""
    }
    
    var currentTenantId: String {
        return self.userService?.userTenant.tenantID ?? ""
    }
    
    typealias Item = SearchResultType
    
    var results: [Item] = []
    
    var resultView: SearchResultView = SearchResultView(tableStyle: .plain)
    
    var listvm: ListVM { searchVM.result }
    
    var listState: SearchListStateCases?
    
    var searchParameters: IMMentionSearchParameters
    
    private var searchText = ""
    func search(text: String) {
        searchText = text
        searchVM.query.text.accept(text)
    }
    
    var searchRequest: PublishSubject<ProviderEvent>?
    func search(query: String?) -> Observable<ProviderEvent> {
        clearRequest()
        let eventSignal = PublishSubject<ProviderEvent>()
        self.searchRequest = eventSignal
        search(text: query ?? "")
        return eventSignal.asObservable().timeout(10, scheduler: MainScheduler.instance)
    }
    
    func loadMore() -> Observable<ProviderEvent> {
        clearRequest()
        let eventSignal = PublishSubject<ProviderEvent>()
        self.searchRequest = eventSignal
        searchVM.result.loadMore()
        return eventSignal.asObservable().timeout(10, scheduler: MainScheduler.instance)
    }
    
    private func clearRequest() {
        searchRequest?.onCompleted()
        searchRequest = nil
    }

    let userResolver: LarkContainer.UserResolver
    let userService: PassportUserService?
    init(resolver: LarkContainer.UserResolver, context: IMMentionContext, parameters: IMMentionSearchParameters) {
        self.userResolver = resolver
        self.userService = try? resolver.resolve(assert: PassportUserService.self)
        self.context = context
        self.searchParameters = parameters
        self.showDocumentOwner = parameters.document?.showDocumentOwner ?? false
        self.showChatterMail = parameters.chatter?.showChatterMail ?? false
        self.bindResultView().disposed(by: disposeBag)
    }
    
    func searchReceiveResult(state: ListVM.State, results: [Item], event: ListVM.Event) {
        let logger = IMMentionLogger.shared
        guard let signal = self.searchRequest else { return }
        switch event {
        case .fail(req: _, error: let error):
            logger.error(module: .provider, event: "doc request failed", parameters: error.localizedDescription)
            signal.onNext(ProviderEvent.fail(.request(error)))
            signal.onCompleted()
            return
        default:
            break
        }
        switch state.state {
        case .normal:
            let items = convert(results: results)
            let res = ProviderResult(result: [items], hasMore: state.hasMore)
            logger.info(module: .provider, event: "doc request success", parameters: "query=\(searchText)&count=\(results.count)")
            signal.onNext(.success(.init(query: searchText, res: res)))
            signal.onCompleted()
        case .empty:
            logger.error(module: .provider, event: "doc request empty")
        case .reloading:
            logger.info(module: .provider, event: "doc request reloading")
        default:
            break
        }
    }
    
    // MARK: - Search Maker
    var searchLocation: String { "Mention" }
    lazy var searchVM: SearchSimpleVM<Item> = {
        let vm = SearchSimpleVM(result: makeListVM())
        configure(vm: vm)
        return vm
    }()
    func configure(vm: SearchSimpleVM<Item>) {
        var context = vm.query.context.value
        context[SearchRequestIncludeOuterTenant.self] = searchParameters.chatter?.includeOuter
        vm.query.context.accept(context)
    }

    func makeListVM() -> SearchListVM<Item> {
        // 使传空参数也可以搜索
        let shouldClear: (SRequestInfo) -> Bool = {
            (requestInfo) -> Bool in
            return false
        }
        return SearchListVM<Item>(source: makeSource(), pageCount: 20, shouldClear: shouldClear)
    }
    
    func makeSource() -> SearchSource {
        // note subclass override
        var maker = IMMentionSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.atUsers), parameters: searchParameters, chatID: context.currentChatId)
        maker.doNotSearchResignedUser = true
        return maker.makeAndReturnProtocol()
    }
}
