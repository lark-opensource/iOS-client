//
//  FilterSortViewModel.swift
//  LarkFeed
//
//  Created by kangsiwan on 2020/12/23.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import LarkContainer
import LarkOpenFeed
import LarkMessengerInterface
import EENavigator

final class FilterSortViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }

    // 数据源
    var dataSourceSubject = PublishSubject<[[FilterItemModel]]>()
    var dataSourceDriver: Driver<[[FilterItemModel]]> {
        return dataSourceSubject.asDriver(onErrorJustReturn: [[]])
    }

    var targetIndex: IndexPath?

    var hudShowRelay = BehaviorRelay<Bool>(value: false)
    var hudShowDriver: Driver<Bool> {
        return hudShowRelay.asDriver().skip(1)
    }

    var toastRelay = BehaviorRelay<String>(value: "")
    var toastDriver: Driver<String> {
        return toastRelay.asDriver().skip(1)
    }

    private var pushVCRelay = BehaviorRelay<PlainBody?>(value: nil)
    var pushVCDriver: Driver<PlainBody?> {
        return pushVCRelay.asDriver().skip(1)
    }

    private var refreshSectionRelay = BehaviorRelay<FeedSortSectionVM.SectionType>(value: (.unknown))
    var refreshSectionDriver: Driver<FeedSortSectionVM.SectionType> {
        return refreshSectionRelay.asDriver().skip(1)
    }

    var reloadSwitchRelay = BehaviorRelay<Void>(value: ())
    var reloadSwitchDriver: Driver<Void> {
        return reloadSwitchRelay.asDriver().skip(1)
    }

    var pushSelectVCRelay = BehaviorRelay<[FilterItemModel]>(value: [])
    var pushSelectVCDriver: Driver<[FilterItemModel]> {
        return pushSelectVCRelay.asDriver().skip(1)
    }

    /// 数据源
    private var _items: [FeedSortSectionVM] = []
    var items: [FeedSortSectionVM] {
        return _items
    }

    func update(_ items: [FeedSortSectionVM]) {
        self._items = items

        itemsMap.removeAll()
        for element in items {
            itemsMap[element.type] = element
        }
    }

    var itemsMap: [FeedSortSectionVM.SectionType: FeedSortSectionVM] = [:]
    let editBlackList: [Feed_V1_FeedFilter.TypeEnum]
    let commonlyEditBlackList: [Feed_V1_FeedFilter.TypeEnum] = [.inbox, .message]
    let filterMoveBlackList: [Feed_V1_FeedFilter.TypeEnum] = [.inbox, .message]

    var msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem] = [:] //不包含标签分组
    // TODO: 应该兼容更多像标签这样的二级分组，例如团队，团队的ID可能和标签ID重复，所以还需要进行优化
    var feedGroupDisplaySettingMap: [Int64: FeedMsgDisplayFilterItem]?
    var filtersModel: FiltersModel?

    // 控制section0的switch
    var isSwitchOpen = false
    private var _needSwitch = false
    var needSwitch: Bool {
        return _needSwitch
    }
    func setNeedSwitch() {
        _needSwitch = true
    }

    // 埋点使用的状态
    var displayRuleChanged: Bool = false
    var labelSecondaryRuleChanged: Bool = false

    var maxLimitWidth: CGFloat = 0.0 {
        didSet {
            // 考虑转屏情况，若最大宽度发生变化，则刷新下常用分组数据和UI
            if oldValue != maxLimitWidth {
                guard let sectionVM = itemsMap[.commonlyFilters], sectionVM.section < items.count,
                      var item = sectionVM.rows.first as? FeedCommonlyFilterModel else { return }
                item.maxLimitWidth = maxLimitWidth
                var tempItems = items
                tempItems[sectionVM.section] = refreshDataForSectionVM(sectionVM, [item])
                update(tempItems)

                reloadSection(.commonlyFilters)
            }
        }
    }
    let dependency: FilterSettingDependency
    let disposeBag = DisposeBag()

    init(dependency: FilterSettingDependency) {
        self.dependency = dependency
        editBlackList = Feed.Feature(dependency.userResolver).groupSettingEnable ?
            [.inbox, .message] : [.inbox, .message, .mute]
    }
}

// MARK: - Public
extension FilterSortViewModel {
    func getNavTitle() -> String {
        return dependency.addMuteGroupEnable ? BundleI18n.LarkFeed.Lark_Feed_EditCategory :
                                               BundleI18n.LarkFeed.Lark_Feed_FilterEdit
    }

    func getTargetIndex(_ unAdds: [FilterItemModel]) -> IndexPath? {
        guard dependency.highlight,
              let sectionVM = itemsMap[.insert], sectionVM.section < items.count,
              let index = unAdds.firstIndex(where: { $0.type == .delayed || $0.type == .flag }) else { return nil }
        let targetIndex = IndexPath(row: index, section: sectionVM.section)
        return targetIndex
    }

    func reloadSection(_ section: FeedSortSectionVM.SectionType) {
        refreshSectionRelay.accept(section)
    }

    func pushViewControllerByBody(_ body: PlainBody) {
        pushVCRelay.accept(body)
    }
}
