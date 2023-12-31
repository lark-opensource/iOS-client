//
//  FeedListViewController+Flag.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/5.
//

import Foundation
import LarkAlertController
import EENavigator
import UniverseDesignDialog
import LarkUIKit
import LarkMessengerInterface

// MARK: 只针对 flagedVM
extension FeedListViewController {

    func _markForFlag(_ cellViewModel: FeedCardCellViewModel) {
        showAlertForFilterSetting(cellViewModel)
        guard listViewModel.filterType == .flag else { return }
        // 标记处理页标记Cell已处理的话, 该Cell会消失, iPad上需要选中下一Feed
        selectNextFeedIfNeeded(feedId: cellViewModel.feedPreview.id)
    }

    // 当用户没有标记分组且将feed置为标记时，需要弹框引导用户去开启分组功能
    private func showAlertForFilterSetting(_ cellViewModel: FeedCardCellViewModel) {
        guard !cellViewModel.feedPreview.basicMeta.isFlaged else { return }
        let ishasFlagTab = self.delegate?.isHasFlagGroup() ?? false
        guard !ishasFlagTab else { return }
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkFeed.Lark_IM_Marked_EnableAndViewAllMarkedMessagesAndChats_Text, numberOfLines: 0)
        dialog.addSecondaryButton(text: BundleI18n.LarkFeed.Lark_Feed_GotIt, dismissCompletion: {
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Feed_MarkForLaterDirectioButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            guard let window = self.view.window else { return }
            let body = FeedFilterSettingBody(highlight: true)
            self.userResolver.navigator.present(body: body,
                                                wrap: LkNavigationController.self,
                                                from: window,
                                                prepare: { $0.modalPresentationStyle = .formSheet },
                                                animated: true)
        })
        self.present(dialog, animated: true, completion: nil)
    }
}
