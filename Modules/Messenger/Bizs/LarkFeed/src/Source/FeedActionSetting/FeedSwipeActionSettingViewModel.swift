//
//  FeedSwipeActionSettingViewModel.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import LarkModel
import LarkOpenFeed
import UniverseDesignIcon
import LarkSwipeCellKit
import RustPB
import LarkContainer
import RxSwift
import RxCocoa

extension FeedActionType {
    var actionIcon: UIImage {
        switch self {
        case .shortcut:
            return UDIcon.setTopOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .flag:
            return UDIcon.flagOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .done:
            return UDIcon.doneOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .label:
            return UDIcon.labelChangeOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .mute:
            return UDIcon.alertsOffOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        default:
            return UIImage()
        }
    }
    var settingTitle: String {
        switch self {
        case .shortcut:
            return BundleI18n.LarkFeed.Lark_Core_PinChatToTop_Button
        case .flag:
            return BundleI18n.LarkFeed.Lark_IM_MarkAMessageToArchive_Button
        case .done:
            return BundleI18n.LarkFeed.Lark_Legacy_DoneNow
        case .label:
            return BundleI18n.LarkFeed.Lark_Core_LabelTab_Title
        case .mute:
            return BundleI18n.LarkFeed.Lark_Core_TouchAndHold_MuteChats_Button
        default:
            return ""
        }
    }

    var settingDesc: String {
        switch self {
        case .shortcut:
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_PinTop_Text
        case .flag:
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_Flag_Text
        case .done:
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_Done_Text
        case .label:
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_Label_Text
        case .mute:
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_Mute_Text
        default:
            return ""
        }

    }
    var bgColor: UIColor {
        switch self {
        case .shortcut:
            return UIColor.ud.colorfulBlue
        case .flag:
            return UIColor.ud.R600
        case .done:
            return UIColor.ud.colorfulTurquoise
        case .label:
            return UIColor.ud.colorfulWathet
        case .mute:
            return UIColor.ud.colorfulIndigo
        default:
            return .clear
        }
    }
}

extension Feed_V1_FeedSlideActionSetting.FeedSlideActionType {
    var actionType: FeedActionType? {
        switch self {
        case .done:
            return .done
        case .flag:
            return .flag
        case .feedGroup:
            return .label
        case .mute:
            return .mute
        case .shortcut:
            return .shortcut
        case .unknownActionType:
            return nil
        @unknown default:
            assertionFailure("unknown feed slide action type \(self)")
            return nil
        }
    }
}

class FeedSwipeActionSettingViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let settingStore: FeedSettingStore

    private let bag = DisposeBag()
    private var dataSource: [FeedSwipeOrientationViewModel] = []
    init(resolver: UserResolver, settingStore: FeedSettingStore) {
        self.userResolver = resolver
        self.settingStore = settingStore
        self.dataSource = makeDataSource(with: settingStore.currentActionSetting)
        updateSettings()
    }
    private let reloadDataPublish = PublishSubject<()>()
    var reloadData: Driver<()> {
        reloadDataPublish.asDriver(onErrorJustReturn: ())
    }

    var title: String = BundleI18n.LarkFeed.Lark_ChatSwipeActions_Mobile_Title

    var numberOfSections: Int {
        return dataSource.count
    }
    var numberOfRows: Int {
        return 1
    }

    func item(at index: Int) -> FeedSwipeOrientationViewModel {
        guard index >= 0 && index < dataSource.count else {
            assertionFailure("invalid index")
            return FeedSwipeOrientationViewModel(orientation: .left, actions: [], title: "", slideOn: false)
        }
        return dataSource[index]
    }

    private func makeDataSource(with data: FeedActionSettingData) -> [FeedSwipeOrientationViewModel] {
        let leftSlideSettings = data.leftSlideSettings.compactMap { $0.actionType }
        let rightSlideSettings = data.rightSlideSettings.compactMap { $0.actionType }
        let rightViewModel = FeedSwipeOrientationViewModel(orientation: .right,
                                                           actions: rightSlideSettings,
                                                           title: BundleI18n.LarkFeed.Lark_ChatSwipeActions_RightSwipe_Mobile_Button,
                                                           slideOn: data.rightSlideOn)
        let leftViewModel = FeedSwipeOrientationViewModel(orientation: .left,
                                                          actions: leftSlideSettings.reversed(), // 左滑: 排在前面的显示在右边
                                                          title: BundleI18n.LarkFeed.Lark_ChatSwipeActions_LeftSwipe_Mobile_Button,
                                                          slideOn: data.leftSlideOn)
        return [rightViewModel, leftViewModel]
    }

    private func updateSettings() {
        settingStore.getFeedActionSetting(forceUpdate: true).subscribe(onNext: {[weak self] data in
            guard let self = self else { return }
            self.dataSource = self.makeDataSource(with: data)
            self.reloadDataPublish.onNext(())
        }).disposed(by: bag)
    }
}

struct FeedSwipeOrientationViewModel {
    var orientation: SwipeActionsOrientation
    var actions: [FeedActionType]
    var title: String
    let slideOn: Bool

    var notSet: Bool {
        return actions.isEmpty || !slideOn
    }
    var detailText: String {
        if notSet {
            return BundleI18n.LarkFeed.Lark_ChatSwipeActions_Off_Mobile_Button
        } else {
            return actions.map { $0.settingDesc }.joined(separator: "、")
        }
    }
}
