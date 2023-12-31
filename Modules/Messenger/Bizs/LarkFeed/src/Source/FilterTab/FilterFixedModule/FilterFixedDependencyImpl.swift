//
//  FilterFixedDependencyImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/6.
//

import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkOpenFeed
import LarkAccountInterface
import LarkMessengerInterface
import Swinject
import LarkContainer

final class FilterFixedDependencyImpl: FilterFixedDependency {
    private let userResolver: UserResolver
    private let dataStore: FilterDataStore
    let filterActionHandler: FilterActionHandler
    private let feedAPI: FeedAPI
    private let context: FeedContextService
    let selectionHandler: FeedFilterSelectionAbility
    let pushFeedFixedFilterSettings: Observable<FeedThreeColumnSettingModel>?
    let pushDynamicNetStatus: Observable<PushDynamicNetStatus>?
    let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         dataStore: FilterDataStore,
         filterActionHandler: FilterActionHandler,
         feedAPI: FeedAPI,
         context: FeedContextService,
         selectionHandler: FeedFilterSelectionAbility,
         pushFeedFixedFilterSettings: Observable<FeedThreeColumnSettingModel>? = nil,
         pushDynamicNetStatus: Observable<PushDynamicNetStatus>? = nil
    ) throws {
        self.userResolver = userResolver
        self.dataStore = dataStore
        self.feedAPI = feedAPI
        self.context = context
        self.selectionHandler = selectionHandler
        self.pushFeedFixedFilterSettings = pushFeedFixedFilterSettings
        self.pushDynamicNetStatus = pushDynamicNetStatus
        self.filterActionHandler = filterActionHandler
    }

    var fixedDataSource: [FilterItemModel] {
        return dataStore.commonlyFiltersDS
    }

    var dataSource: [FilterItemModel] {
        return dataStore.usedFiltersDS
    }

    var commonlyFiltersDSDriver: Driver<[FilterItemModel]> {
        return dataStore.commonlyFiltersDSDriver
    }

    func getThreeColumnsSettings(tryLocal: Bool) -> Observable<FeedThreeColumnSettingModel> {
        return feedAPI.getThreeColumnsSettings(tryLocal: tryLocal).map({ (response) in
            return FeedThreeColumnSettingModel.transform(response)
        })
    }

    func updateThreeColumnsSettings(showEnable: Bool, scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Observable<Void> {
        return feedAPI.updateThreeColumnsSettings(showEnable: showEnable, scene: scene).flatMap({ _ -> Observable<Void> in
            return .just(())
        })
    }

    func getUnreadFeedsNum() -> Observable<Int> {
        return feedAPI.getUnreadFeedsNum().map({ (response) in
            return Int(response.allUnreadPreviewCount)
        })
    }

    func getSubTabUnreadNum(type: Feed_V1_FeedFilter.TypeEnum, subId: String?) -> Int? {
        guard let subId = subId, !subId.isEmpty else { return nil }
        guard let source = FeedFilterListSourceFactory.source(for: type) else { return nil }
        do {
            let items = try source.itemsProvider(userResolver, subId)
            if let item = items.first(where: { $0.subTabId == subId }) {
                return item.unread
            }
        } catch {
            let errorMsg = "no itemsProvider \(type)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.Filter.threeColumns(node: .getSubTabUnreadNum, info: info)
        }
        return nil
    }

    func showFlagInCommonlyUsedFilters(_ commonlyUsedFilters: [Feed_V1_FeedFilter]) {
        feedAPI.updateCommonlyUsedFilters(commonlyUsedFilters).subscribe().disposed(by: disposeBag)
    }

    func getCurrentFilterTab() -> Feed_V1_FeedFilter.TypeEnum {
        return context.dataSourceAPI?.currentFilterType ?? .unknown
    }

    func changeFilterTab(_ type: Feed_V1_FeedFilter.TypeEnum) {
        guard let mainVC = context.page as? FeedMainViewController else { return }
        DispatchQueue.main.async {
            mainVC.changeTab(type, .fixedViewTabCheck)
            mainVC.filterTabView.filterFixedView?.changeViewTab(type)
        }
    }

    func localChangeCommonlyFilters(_ filters: [FilterItemModel]) {
        dataStore.localChangeCommonlyFilters(filters)
    }

    func updateFilterSelection(_ selection: FeedFilterSelection) {
        selectionHandler.updateFilterSelection(selection)
    }
}
