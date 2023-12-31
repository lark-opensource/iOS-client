//
//  TimeZoneQuickSelectViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/1/8.
//

import Foundation
import RxCocoa
import RxSwift

final class TimeZoneQuickSelectViewModel {

    struct TimeZoneSelectHandler {

        enum Reason {
            // 用户点击选中
            case userClicked
            // 之前的选中时区被删除
            case previousDeleted
        }

        var handle: (_ timeZone: TimeZoneModel, _ reason: Reason) -> Void
    }

    var onTimeZoneSelect: TimeZoneSelectHandler?
    var onTableViewDataUpdate: (() -> Void)?

    typealias CellViewData = TimeZoneQuickSelectCellDataType
    private  struct CellItem: CellViewData {
        var isLocal: Bool = false
        var timeZoneName: String { model.standardName(for: anchorDate) }
        var gmtOffsetDescription: String { model.getGmtOffsetDescription(date: anchorDate) }
        let model: TimeZoneModel
        let anchorDate: Date

        fileprivate(set) var isSelected: Bool

        fileprivate init(model: TimeZoneModel, anchorDate: Date, isSelected: Bool = false) {
            self.model = model
            self.anchorDate = anchorDate
            self.isSelected = isSelected
        }
    }

    private typealias CellItems = (localItem: CellItem, recentItems: [CellItem])

    private var cellItems: CellItems
    private let service: TimeZoneSelectService
    private let selectedTimeZone: BehaviorRelay<TimeZoneModel>
    private var disposeBag = DisposeBag()
    private let reloadRecentTimeZonesSubject = PublishSubject<Void>()

    init(service: TimeZoneSelectService, selectedTimeZone: BehaviorRelay<TimeZoneModel>, anchorDate: Date) {
        self.service = service
        self.selectedTimeZone = selectedTimeZone

        typealias Input = (local: TimeZoneModel, recents: [TimeZoneModel], selected: TimeZoneModel)
        typealias Output = CellItems
        // generate cellItems
        let generateCellItems = { (input: Input) -> Output in
            var localItem = CellItem(
                model: input.local,
                anchorDate: anchorDate,
                isSelected: input.local.identifier == input.selected.identifier
            )
            localItem.isLocal = true
            let recentItems = input.recents
                .filter { $0.identifier != input.local.identifier }
                .map { CellItem(model: $0, anchorDate: anchorDate, isSelected: $0.identifier == input.selected.identifier) }
            return (localItem: localItem, recentItems: recentItems)
        }

        // 初始化 cellItems
        let input = (local: TimeZone.current, recents: [TimeZone](), selected: selectedTimeZone.value)
        cellItems = generateCellItems(input)

        // 关注 selectedTimeZone，根据变化 update cellItems
        selectedTimeZone.skip(1)
            .subscribe(onNext: { [weak self] selectedTimeZone in
                guard let self = self else { return }
                let input = (
                    local: self.cellItems.localItem.model,
                    recents: self.cellItems.recentItems.map { $0.model },
                    selected: selectedTimeZone
                )
                self.cellItems = generateCellItems(input)
                self.onTableViewDataUpdate?()
            })
            .disposed(by: disposeBag)

        // 获取 recent time zones，update cellItems
        reloadRecentTimeZonesSubject.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            service.getRecentTimeZones()
                .subscribe(onNext: { [weak self] rawTimeZones in
                    guard let self = self else { return }

                    // timeZones 去重，去重条件：name 相等，且 secondsFromGMT 相等
                    var timeZones = [TimeZoneModel]()
                    var set = Set<String>()
                    for timeZone in rawTimeZones {
                        let key = "\(timeZone.standardName(for: Date()))\(timeZone.secondsFromGMT)"
                        if !set.contains(key) {
                            set.insert(key)
                            timeZones.append(timeZone)
                        }
                    }

                    let input = (
                        local: self.cellItems.localItem.model,
                        recents: timeZones,
                        selected: self.selectedTimeZone.value
                    )
                    self.cellItems = generateCellItems(input)
                    self.onTableViewDataUpdate?()
                })
                .disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)

        reloadRecentTimeZonesSubject.onNext(())
    }
}

extension TimeZoneQuickSelectViewModel {

    func numberOfSections() -> Int {
        cellItems.recentItems.isEmpty ? 1 : 2
    }

    func numberOfRows(in section: Int) -> Int {
        if section == 0 { return 1 }
        if section == 1 { return cellItems.recentItems.count }
        return 0
    }

    func cellData(forRowAt indexPath: IndexPath) -> TimeZoneQuickSelectCellDataType? {
        guard indexPath.row >= 0 && indexPath.section < 2 else { return nil }
        if indexPath.section == 0 {
            return cellItems.localItem
        }
        guard indexPath.row < cellItems.recentItems.count else { return nil }
        return cellItems.recentItems[indexPath.row]
    }

    func deleteCellData(forRowAt indexPath: IndexPath, onTimeZoneSelected: TimeZoneSelectHandler? = nil) {
        guard let cellItem = cellData(forRowAt: indexPath) as? CellItem else { return }
        // 查看要删除的时区中，是否有被选中的，如果有，重新选中本地时区
        if cellItem.isSelected {
            onTimeZoneSelect?.handle(cellItems.localItem.model, .previousDeleted)
        }

        service.deleteRecentTimeZones(by: [cellItem.model.identifier])
            .subscribe(onNext: { [weak self] in
                self?.reloadRecentTimeZonesSubject.onNext(())
            })
            .disposed(by: self.disposeBag)
    }

    func deleteAllCellData() {
        guard !cellItems.recentItems.isEmpty else { return }

        // 查看要删除的时区中，是否有被选中的，如果有，重新选中本地时区
        let selectedTimeZone = cellItems.recentItems
            .filter { $0.isSelected }
            .map { $0.model }
            .first
        if selectedTimeZone != nil {
            onTimeZoneSelect?.handle(cellItems.localItem.model, .previousDeleted)
        }

        let ids = cellItems.recentItems.map { $0.model.identifier }
        service.deleteRecentTimeZones(by: ids)
            .subscribe(onNext: { [weak self] in
                self?.reloadRecentTimeZonesSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    func selectCellData(forRowAt indexPath: IndexPath) {
        guard let cellItem = cellData(forRowAt: indexPath) as? CellItem else { return }
        onTimeZoneSelect?.handle(cellItem.model, .userClicked)
    }
}
