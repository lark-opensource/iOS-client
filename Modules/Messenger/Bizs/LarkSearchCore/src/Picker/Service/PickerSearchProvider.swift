//
//  PickerSearchProvider.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/5/18.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
//
import LarkCore
import LarkContainer

enum SearchProviderEvent {
    case start
    case success([PickerItem])
    case fail(Error)
}

final class PickerSearchProvider: PickerRecommendLoadable, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    typealias ListVM = SearchListVM<Item>

    private var disposeBag = DisposeBag()

    var result: [PickerItem] = []

    typealias Item = LarkSDKInterface.Search.Result

    var results: [Item] = []
    var searchVM: SearchSimpleVM<Item>?

    var searchConfig = PickerSearchConfig()

    public init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    private var loadObservable: PublishSubject<PickerRecommendResult>?
    func load() -> Observable<PickerRecommendResult> {
        let ob = PublishSubject<PickerRecommendResult>()
        self.loadObservable = ob
        searchVM = makeSearchVM()
        self.disposeBag = DisposeBag() // 防止重复订阅
        searchVM?.result.stateObservableInMain
            .subscribe(onNext: { [weak self] (change) in
            self?.searchReceiveResult(state: change.state, results: change.state.results, event: change.event)
        }).disposed(by: self.disposeBag)
        searchVM?.query.text.accept("")
        return ob
    }

    func loadMore() -> Observable<PickerRecommendResult> {
        let ob = PublishSubject<PickerRecommendResult>()
        self.loadObservable = ob
        searchVM?.result.loadMore()
        return ob
    }

    func searchReceiveResult(state: ListVM.State, results: [Item], event: ListVM.Event) {
        switch event {
        case .fail(req: _, error: let error):
            PickerLogger.shared.error(module: PickerLogger.Module.recommend, event: "empty search error", parameters: error.localizedDescription)
            self.loadObservable?.onError(error)
            return
        default:
            break
        }
        switch state.state {
        case .normal:
            let items = results.map { result in
                PickerItemFactory.shared.makeItem(result: result)
            }
            PickerLogger.shared.info(module: PickerLogger.Module.recommend, event: "empty search success", parameters: "\(items)")
            self.loadObservable?.onNext(.init(items: items, hasMore: state.hasMore, isPage: false))
            self.loadObservable?.onCompleted()
        case .empty:
            PickerLogger.shared.error(module: PickerLogger.Module.recommend, event: "empty search empty")
        case .reloading:
            PickerLogger.shared.error(module: PickerLogger.Module.recommend, event: "empty search reloading")
        default:
            break
        }
    }

    // MARK: - Search Maker
    var searchLocation: String { "SearchPicker" }
    func makeSearchVM() -> SearchSimpleVM<Item> {
        let vm = SearchSimpleVM(result: makeListVM())
        configure(vm: vm)
        return vm
    }

    func configure(vm: SearchSimpleVM<Item>) {
        var context = vm.query.context.value
        context[AuthPermissionsKey.self] = searchConfig.permissions
        vm.query.context.accept(context)
    }

    func makeListVM() -> SearchListVM<Item> {
        // 使传空参数也可以搜索
        let shouldClear: (SRequestInfo) -> Bool = { _ in
            return false
        }
        return SearchListVM<Item>(source: makeSource(), pageCount: PickerConstant.Data.countPerPage, shouldClear: shouldClear)
    }

    func makeSource() -> SearchSource {
        let maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.addChatChatters))
        return maker.makeSource(config: self.searchConfig, supportRecommend: true)
    }
}
