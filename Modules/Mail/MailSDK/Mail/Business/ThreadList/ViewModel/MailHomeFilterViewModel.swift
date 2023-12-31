//
//  MailHomeFilterViewModel.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/23.
//

import Foundation
import RxSwift
import RxRelay

class MailHomeFilterViewModel {
    var selectedFilter: BehaviorRelay<(filterType: MailThreadFilterType, isReset: Bool)> // 选择的filter

    var showFilterMenu: PublishSubject<[MailThreadFilterType]> = PublishSubject()

    var didSwitchToUnread: Bool = false

    init() {
        // 默认all label
        selectedFilter = BehaviorRelay(value: (.allMail, true))
    }
}

// MARK: input
extension MailHomeFilterViewModel {
    /// 会触发数据加载
    /// - Parameter type: type description
    func didSelectFilter(type: MailThreadFilterType) {
        didSwitchToUnread = (selectedFilter.value.filterType == .allMail && type == .unread)
        selectedFilter.accept((type, false))
    }

    func showMenu() {
        if self.selectedFilter.value.filterType == .allMail {
            showFilterMenu.onNext([.unread])
        }
    }

    /// 不会触发数据加载
    /// - Parameter type: type description
    func resetFilter(type: MailThreadFilterType = .allMail) {
        didSwitchToUnread = (selectedFilter.value.filterType == .allMail && type == .unread)
        selectedFilter.accept((type, true))
    }
}

// MARK: helper
extension MailHomeFilterViewModel {
    func shouldShowFilter(_ labelId: String) -> Bool {
        if labelId == Mail_LabelId_Stranger && !FeatureManager.open(.stranger, openInMailClient: false) {
            return true
        }
        return labelId == Mail_LabelId_Inbox ||
               labelId == Mail_LabelId_Spam ||
               labelId == Mail_LabelId_Important ||
               labelId == Mail_LabelId_Other ||
               !systemLabels.contains(labelId) ||
                labelId == Mail_LabelId_SHARED
    }
}
