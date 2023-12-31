//
//  BadgeSettingViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/4.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa

final class BadgeSettingViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var settingService: SettingService?

    private let disposeBag = DisposeBag()

    private(set) var dataSource: [SectionData] = []

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(completion: @escaping () -> Void) {
        if let config = settingService?.value(forKeyPath: \.listBadgeConfig) {
            dataSource = makeDataSource(with: config)
        }
        completion()
        settingService?.observe(forKeyPath: \.listBadgeConfig)
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] badgeConfig in
                guard let self = self else { return }
                self.dataSource = self.makeDataSource(with: badgeConfig)
                completion()
            })
            .disposed(by: disposeBag)
    }

    private func makeDataSource(with badgeConfig: Rust.ListBadgeConfig) -> [SectionData] {
        let firstSection = SectionData(
            headerTitle: nil,
            items: [
                CellData(
                    accessType: .switchType(isOn: badgeConfig.enable),
                    title: I18N.Todo_Settings_BadgeCountTitle,
                    subTitle: I18N.Todo_Settings_BadgeCountDesc
                )
            ],
            footerTitle: nil
        )

        if !badgeConfig.enable {
            return [firstSection]
        }

        var items = [
            CellData(
                accessType: .checkMark(isChecked: badgeConfig.type == .overdue),
                title: I18N.Todo_Settings_BadgeCountOverdue,
                subTitle: I18N.Todo_Settings_BadgeCountShowForOverdue,
                badgeType: .overdue
            ),
            CellData(
                accessType: .checkMark(isChecked: badgeConfig.type == .overdueAndToday),
                title: I18N.Todo_Settings_BadgeCountOverdueAndToday,
                subTitle: I18N.Todo_Settings_BadgeCountShowForOverdueAndToday,
                badgeType: .overdueAndToday
            )
        ]
        if FeatureGating(resolver: userResolver).boolValue(for: .settingRed) {
            let item = CellData(
                accessType: .checkMark(isChecked: badgeConfig.type == .ownedByMeUnfinished),
                title: I18N.Todo_Settings_BadgeCountOngoingOwned_Option,
                subTitle: "",
                badgeType: .ownedByMeUnfinished
            )
            items.append(item)
        }
        let secondSection = SectionData(
            headerTitle: I18N.Todo_Settings_BadgeCountShowFor,
            items: items,
            footerTitle: nil
        )
        return [firstSection, secondSection]
    }

    struct SectionData {
        var headerTitle: String?
        var items: [CellData]
        var footerTitle: String?
    }

    enum AccessoryType {
        case switchType(isOn: Bool)
        case checkMark(isChecked: Bool)
    }

    struct CellData {
        var accessType: AccessoryType
        var title: String
        var subTitle: String
        fileprivate var badgeType: Rust.ListBadgeType?
    }
}

extension BadgeSettingViewModel {

    func updateSettingEnable(isOn: Bool, onError: @escaping () -> Void) {
        guard let settingService = settingService else { return }
        Setting.Track.clickAllowBadge(isOn: isOn)
        var config = settingService.value(forKeyPath: \.listBadgeConfig)
        let oldConfig = config
        config.enable = isOn
        settingService.update(config, forKeyPath: \.listBadgeConfig) { [weak self] in
            onError()
            self?.settingService?.updateCache(oldConfig, forKeyPath: \.listBadgeConfig)
        }
    }

    func updateType(at indexPath: IndexPath, onError: @escaping () -> Void) {
        guard let item = itemData(at: indexPath), let type = item.badgeType, let settingService = settingService else {
            return
        }
        Setting.Track.clickBadgeType(type: type)
        var config = settingService.value(forKeyPath: \.listBadgeConfig)
        let oldConfig = config
        config.type = type
        settingService.update(config, forKeyPath: \.listBadgeConfig) { [weak self] in
            onError()
            self?.settingService?.updateCache(oldConfig, forKeyPath: \.listBadgeConfig)
        }
    }
}

extension BadgeSettingViewModel {

    func sectionCount() -> Int {
        return dataSource.count
    }

    func itemCount(in section: Int) -> Int {
        guard checkSection(in: section) else {
            return 0
        }
        return dataSource[section].items.count
    }

    func itemData(at indexPath: IndexPath) -> CellData? {
        guard checkItems(at: indexPath) else {
            return nil
        }
        return dataSource[indexPath.section].items[indexPath.row]
    }

    func headerTitle(in section: Int) -> String? {
        guard checkSection(in: section) else {
            return nil
        }
        return dataSource[section].headerTitle
    }

    func footerTitle(in section: Int) -> String? {
        guard checkSection(in: section) else {
            return nil
        }
        return dataSource[section].footerTitle
    }

    func checkSection(in section: Int) -> Bool {
        guard section >= 0 && section < dataSource.count else {
            return false
        }
        return true
    }

    func checkItems(at indexPath: IndexPath) -> Bool {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && section < dataSource.count
                && row >= 0
                && row < dataSource[section].items.count else {
            return false
        }
        return true
    }

}
