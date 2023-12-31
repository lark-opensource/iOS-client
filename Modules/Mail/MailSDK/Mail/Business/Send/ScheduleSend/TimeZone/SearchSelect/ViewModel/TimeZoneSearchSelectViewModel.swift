//
//  TimeZoneSearchSelectViewModel.swift
//  AnimatedTabBar
//
//  Created by 张威 on 2020/1/8.
//

import RxCocoa
import RxSwift

/// 搜索
final class SearchSelectTimeZoneViewModel {

    private struct CellItem: TimeZoneSearchResultCellDataType {
        let model: TimeZoneModel
        var cityName: String

        var cityIncludingDescription: String {
            BundleI18n.MailSDK.Mail_Common_Includes(cityName)
        }
        var gmtOffsetDescription: String { model.gmtOffsetDescription }
        var timeZoneName: String { model.name }
    }

    enum SearchResult {
        case empty
        case items([TimeZoneSearchResultCellDataType])
        case error(Error)

        var itemCount: Int {
            switch self {
            case .items(let cellItems): return cellItems.count
            default: return 0
            }
        }
    }

    typealias QueryResultPair = (query: String, result: SearchResult)

    var lastQueryResult: BehaviorRelay<QueryResultPair?> = BehaviorRelay(value: nil)
    let isLoading = BehaviorRelay(value: false)
    var onTimeZoneSelect: ((TimeZoneModel) -> Void)?

    private let service: TimeZoneSelectService
    private var lastSearchingDisposable: Disposable?
    private lazy var disposeBag = DisposeBag()

    init(service: TimeZoneSelectService) {
        self.service = service
    }

    func clearResultIfNeeded() {
        lastQueryResult.accept(nil)
    }

    func cancelLoadingIfNeeded() {
        lastSearchingDisposable?.dispose()
        if isLoading.value {
            isLoading.accept(false)
        }
    }

    func reloadCellItems(by query: String) {
        lastSearchingDisposable?.dispose()
        isLoading.accept(true)
        lastQueryResult.accept(nil)
        lastSearchingDisposable = service.getCityTimeZones(by: query)
            .map { (pairs: [TimeZoneService.TimeZoneCityPair]) in
                let cellItems = pairs.map { pair in
                    pair.cityNames.map { CellItem(model: pair.timeZone, cityName: $0) }
                }.flatMap { $0 }

                if cellItems.isEmpty {
                    return .empty
                } else {
                    return .items(cellItems)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: {[weak self ] result in
                    self?.lastQueryResult.accept((query: query, result: result))
                },
                onError: { [weak self ] error in
                    self?.lastQueryResult.accept((query: query, result: .error(error)))
                    self?.isLoading.accept(false)
                },
                onCompleted: {[weak self] in
                    self?.isLoading.accept(false)
                }
            )
        lastSearchingDisposable?.disposed(by: disposeBag)
    }

}

extension SearchSelectTimeZoneViewModel {

    func numberOfRows() -> Int {
        lastQueryResult.value?.result.itemCount ?? 0
    }

    func cellData(forRowAt indexPath: IndexPath) -> TimeZoneSearchResultCellDataType? {
        guard let queryResult = lastQueryResult.value?.result,
            case .items(let cellItems) = queryResult,
            indexPath.row < cellItems.count else {
            return nil
        }
        return cellItems[indexPath.row]
    }

    func selectCellData(forRowAt indexPath: IndexPath) {
        guard let cellItem = cellData(forRowAt: indexPath) as? CellItem else {
            return
        }
        onTimeZoneSelect?(cellItem.model)
    }

}
