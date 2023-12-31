//
//  FeedMsgDisplayMoreSettingViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import Foundation
import LarkOpenFeed
import EENavigator
import RxSwift
import RxCocoa
import RustPB
import LarkContainer

final class FeedMsgDisplayMoreSettingViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    private let dependency: FeedMsgDisplayMoreSettingDependency
    private(set) var rows: [FeedSubFilterCellItem] = []
    private var labelRules: [FeedMsgDisplayFilterItem] = []
    private let disposeBag = DisposeBag()

    private let reloadDataSubject = ReplaySubject<Void>.create(bufferSize: 1)
    var reloadDataDriver: Driver<Void> {
        return reloadDataSubject.asDriver(onErrorJustReturn: ())
    }

    private var pushVCRelay = BehaviorRelay<PlainBody?>(value: nil)
    var pushVCDriver: Driver<PlainBody?> {
        return pushVCRelay.asDriver().skip(1)
    }

    private var showToastRelay = BehaviorRelay<String>(value: "")
    var showToastDriver: Driver<String> {
        return showToastRelay.asDriver()
    }

    init(userResolver: UserResolver, dependency: FeedMsgDisplayMoreSettingDependency) {
        self.userResolver = userResolver
        self.dependency = dependency
        loadOptions()
    }

    // MARK: - Private
    private func loadOptions() {
        labelRules = dependency.getLabelRules()
        let rows = createRows(labelRules)
        reload(rows)
    }

    private func createRows(_ items: [FeedMsgDisplayFilterItem]) -> [FeedSubFilterCellItem] {
        var rows: [FeedSubFilterCellItem] = []
        for item in items {
            rows.append(transformToCellModel(item))
        }
        return rows
    }

    private func reload(_ rows: [FeedSubFilterCellItem]) {
        self.rows = rows
        reloadDataSubject.onNext(())
        if rows.isEmpty {
            showToastRelay.accept(BundleI18n.LarkFeed.Lark_FeedFilter_NoLabelsCreatedYet_Toast)
        }
    }

    func pushToMsgDisplaySettingPage(_ selectedItem: FeedMsgDisplayFilterItem) {
        let filterName = selectedItem.itemTitle ?? ""
        let body = FeedMsgDisplaySettingBody(filterName: filterName, currentItem: selectedItem)
        body.selectObservable.subscribe(onNext: { [weak self] item in
            guard let self = self else { return }
            self.updateOptions(item)
        }).disposed(by: disposeBag)
        self.pushVCRelay.accept(body)
    }

    private func updateOptions(_ item: FeedMsgDisplayFilterItem) {
        guard let itemId = item.itemId,
              let index = labelRules.firstIndex(where: { $0.itemId == itemId }) else { return }
        //Data
        labelRules[index] = item
        syncFilterItemData(item)
        //UI
        var rows = self.rows
        rows[index] = transformToCellModel(item)
        reload(rows)
    }

    private func syncFilterItemData(_ item: FeedMsgDisplayFilterItem) {
        dependency.updateLabelRuleItem(item)
    }

    private func transformToCellModel(_ item: FeedMsgDisplayFilterItem) -> FeedSubFilterCellItem {
        let cellModel = FeedSubFilterCellModel(
            title: item.itemTitle ?? "",
            subTitle: item.subTitle,
            item: item,
            showEditBtn: !item.selectedTypes.isEmpty,
            tapHandler: { [weak self] index in
                guard let self = self, index < self.labelRules.count else { return }
                let selectedItem = self.labelRules[index]
                self.pushToMsgDisplaySettingPage(selectedItem)
            })
        return cellModel
    }

    // MARK: - Public
    func getNavTitle() -> String {
        return BundleI18n.LarkFeed.Lark_FeedFilter_MessageDisplaySettings_ForTeamsAndLabelsOnly_Button
    }

    func saveOptions() {
        dependency.saveChangedLabelRuleItems()
    }
}
