//
//  FeedSwipeActionConfigViewModel.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/12.
//

import Foundation
import LarkSwipeCellKit
import LarkOpenFeed
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignCheckBox

typealias FeedSlideActionType = Feed_V1_FeedSlideActionSetting.FeedSlideActionType
extension FeedActionType {
    var slideActionType: FeedSlideActionType {
        switch self {
        case .shortcut:
            return .shortcut
        case .flag:
            return .flag
        case .label:
            return .feedGroup
        case .mute:
            return .mute
        case .done:
            return .done
        default:
            return .unknownActionType
        }
    }

    // actionType是否支持重滑删除
    var swipeToDeleteRow: Bool {
        switch self {
        case .done:
            return true
        case .blockMsg, .clearBadge, .debug,
                .deleteLabel, .flag, .joinTeam,
                .jump, .label, .mute, .removeFeed,
                .teamHide, .shortcut:
            return false
        @unknown default:
            return false
        }
    }
}

enum FeedSwipeActionConfigCellType {
    case switchCell(data: FeedSettingSwitchCellViewModel)
    case checkCell(data: FeedSettingCheckCellViewModel)
}

struct FeedSettingCheckCellViewModel {
    let boxType: UDCheckBoxType
    let actionType: FeedActionType
    var icon: UIImage {
        return actionType.actionIcon.ud.colorize(color: UIColor.ud.iconN1)
    }
    var title: String {
        return actionType.settingDesc
    }
    let selected: Bool
    let enable: Bool
    init(actionType: FeedActionType, selected: Bool, enable: Bool, boxType: UDCheckBoxType) {
        self.actionType = actionType
        self.selected = selected
        self.enable = enable
        self.boxType = boxType
    }
}

struct FeedSettingSwitchCellViewModel {
    var title: String
    var status: Bool
}

extension SwipeActionsOrientation {
    var selectLimited: Int {
        switch self {
        case .left:
            return 2
        case .right:
            return 1
        @unknown default:
            FeedContext.log.error("feedlog/actionSetting/updateFeedActionSetting unknown orientation type \(self)")
            return 0
        }
    }
}

class FeedSwipeActionConfigViewModel {
    enum Tips {
        case info(String)
        case fail(String)
    }
    private let reqInterval = 500 // 单位ms，限制频繁发送请求
    private let bag = DisposeBag()
    private let orientation: SwipeActionsOrientation
    private let selectLimited: Int // 最多选择N个
    private var settingData: FeedActionSettingData
    private let settingStore: FeedSettingStore
    // 列表顺序
    private let allActions: [FeedActionType] = [.flag, .shortcut, .label, .mute, .done]

    init(settingStore: FeedSettingStore, orientation: SwipeActionsOrientation) {
        self.settingStore = settingStore
        self.settingData = settingStore.currentActionSetting
        self.orientation = orientation
        self.selectLimited = orientation.selectLimited
        self.dataSource = self.makeDataSource(data: settingData)
        self.monitorDataChanged()
    }

    var title: String {
        if orientation == .left {
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_LeftSwipe_Mobile_Button
        } else {
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_RightSwipe_Mobile_Button
        }
    }

    var detailLabel: String {
        return BundleI18n.LarkFeed.Lark_ChatSwipeActions_EnableSwipe_Mobile_Desc(selectLimited)
    }

    var dataSource: [[FeedSwipeActionConfigCellType]] = []

    private let reloadDataPublish = PublishSubject<(FeedActionSettingData)>()
    var reloadData: Driver<(FeedActionSettingData)> {
        reloadDataPublish.asDriver(onErrorJustReturn: settingData)
    }

    private let toastPublish = PublishSubject<Tips>()
    var toast: Driver<Tips> {
        toastPublish.asDriver(onErrorJustReturn: .info(""))
    }

    // MARK: - INPUT
    func changeSwitch(status: Bool) {
        if orientation == .left {
            self.settingData.leftSlideOn = status
        } else {
            self.settingData.rightSlideOn = status
        }
        self.dataSource = self.makeDataSource(data: settingData)
        reloadDataPublish.onNext(settingData)
    }

    func selectCell(section: Int, row: Int) {
        guard dataSource.count > section, dataSource[section].count > row else {
            FeedContext.log.error("feedlog/actionSetting/updateFeedActionSetting invalid index")
            return
        }
        let selectCount = totalSelectCount(data: settingData)
        let selectItem = dataSource[section][row]
        guard case let .checkCell(data) = selectItem else { return }
        if selectLimited > 1 { // 多选
            if !data.selected && selectCount >= selectLimited { // 选中的总数已经达到最大值，当前选择的选项为未选中状态，弹toast提示"最多选择N个"
                self.toastPublish.onNext(.info(BundleI18n.LarkFeed.Lark_ChatSwipeActions_EnableSwipe_Mobile_Desc(selectLimited)))
            } else {
                toggle(data.actionType)
                self.dataSource = makeDataSource(data: settingData)
                self.reloadDataPublish.onNext(settingData)
            }
        } else { // 单选
            if !data.selected { // 未选中, 切换到当前选择的选项；如果当前为选择状态，不处理
                switchTo(action: data.actionType)
                self.dataSource = makeDataSource(data: settingData)
                self.reloadDataPublish.onNext(settingData)
            }
        }
    }

    // MARK: - Helper
    private func monitorDataChanged() {
        // 设置内容发生变化，并且间隔500ms发起请求
        self.reloadData.asObservable()
            .distinctUntilChanged()
            .debounce(.milliseconds(reqInterval), scheduler: MainScheduler.instance)
            .flatMap {[weak self] data -> Observable<Feed_V1_UpdateFeedActionSettingResponse> in
                guard let self = self else { return .empty()}
                guard data != self.settingStore.currentActionSetting else { return .empty() }
                FeedContext.log.info("feedlog/actionSetting/updateFeedActionSetting data changed")
                return self.settingStore.updateFeedAction(settingData: data).catchError {[weak self] (error) -> Observable<Feed_V1_UpdateFeedActionSettingResponse> in
                    guard let self = self else { return .empty()}
                    FeedContext.log.error("feedlog/actionSetting/updateFeedActionSetting", error: error)
                    // 保存失败时报重置
                    self.settingData = self.settingStore.currentActionSetting
                    self.dataSource = makeDataSource(data: self.settingData)
                    self.reloadDataPublish.onNext(self.settingData)
                    self.toastPublish.onNext(.fail(BundleI18n.LarkFeed.Lark_ChatSwipeActions_SettingsUnsaved_Toast))
                    return .empty()
                }
            }.subscribe(onNext: { _ in
                FeedContext.log.info("feedlog/actionSetting/updateFeedActionSetting success")
            }).disposed(by: bag)
    }
    private func makeDataSource(data: FeedActionSettingData) -> [[FeedSwipeActionConfigCellType]] {
        var selectedActions = [FeedActionType]()
        var firstSectionTitle: String = ""
        var slideOn: Bool = false
        if orientation == .left {
            selectedActions = data.leftSlideSettings.compactMap { $0.actionType }
            firstSectionTitle = BundleI18n.LarkFeed.Lark_ChatSwipeActions_EnableLeftSwipe_Mobile_Toggle
            slideOn = data.leftSlideOn
        } else {
            selectedActions = data.rightSlideSettings.compactMap { $0.actionType }
            firstSectionTitle = BundleI18n.LarkFeed.Lark_ChatSwipeActions_EnableRightSwipe_Mobile_Toggle
            slideOn = data.rightSlideOn
        }

        var sections = [[FeedSwipeActionConfigCellType]]()
        var firstSection = [FeedSwipeActionConfigCellType]()

        let data = FeedSettingSwitchCellViewModel(title: firstSectionTitle, status: slideOn)
        firstSection.append(.switchCell(data: data))
        sections.append(firstSection)

        if slideOn {
            var secondSection = [FeedSwipeActionConfigCellType]()
            let overLimit = selectedActions.count >= selectLimited
            for action in allActions {
                let selected = selectedActions.contains(action)
                let enable = selectLimited == 1 ? true : (selected || !overLimit) // 单选的情况下不需要置灰
                let boxType = selectLimited > 1 ? UDCheckBoxType.multiple : UDCheckBoxType.single
                let vm = FeedSettingCheckCellViewModel(actionType: action,
                                                       selected: selected,
                                                       enable: enable,
                                                       boxType: boxType)
                secondSection.append(.checkCell(data: vm))
            }
            sections.append(secondSection)
        }
        return sections
    }

    private func totalSelectCount(data: FeedActionSettingData) -> Int {
        if orientation == .left {
            return data.leftSlideSettings.count
        } else {
            return data.rightSlideSettings.count
        }
    }

    // 单选的情况，选中当前选项，并反选之前选中的选项
    private func switchTo(action: FeedActionType) {
        if orientation == .left {
            settingData.leftSlideSettings = [action.slideActionType]
        } else {
            settingData.rightSlideSettings = [action.slideActionType]
        }
    }

    private func toggle(_ action: FeedActionType) {
        if orientation == .left {
            settingData.leftSlideSettings = updateSettings(settingData.leftSlideSettings, action: action)
        } else {
            settingData.rightSlideSettings = updateSettings(settingData.rightSlideSettings, action: action)
        }
    }

    private func updateSettings(_ settings: [FeedSlideActionType], action: FeedActionType) -> [FeedSlideActionType] {
        var newSettings = settings
        if settings.contains(action.slideActionType) {
            newSettings.lf_remove(object: action.slideActionType)
        } else {
            newSettings.append(action.slideActionType)
        }
        // 排序
        let orderedActions = allActions.map { $0.slideActionType }.filter { newSettings.contains($0) }
        return orderedActions
    }
}
