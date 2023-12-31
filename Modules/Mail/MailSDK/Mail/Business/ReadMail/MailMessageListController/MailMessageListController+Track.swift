//
//  MailMessageListController+Track.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/10/12.
//

import Foundation

extension MailMessageListController {
    func trackSpamBannerAppear() {
        if MailMessageListViewsPool.fpsOpt {
            guard currentPageCell?.mailMessageListView?.titleView?.initSpamNoticeFlag == true else {
                return
            }
        }
        guard currentPageCell?.mailMessageListView?.titleView?.spamNotice.isHidden == false else { return }
        let bannerType = (viewModel.mailItem?.messageItems.count ?? 0) > 1 ? "thread" : "single_mail"
        MailTracker.log(
            event: "email_not_spam_banner_view",
            params: ["label_item": statInfo.newCoreEventLabelItem, "banner_type": bannerType]
        )
    }

    func trackSpamBannerClick() {
        let bannerType = (viewModel.mailItem?.messageItems.count ?? 0) > 1 ? "thread" : "single_mail"
        MailTracker.log(
            event: "email_not_spam_banner_click",
            params: ["label_item": statInfo.newCoreEventLabelItem, "banner_type": bannerType, "click": "not_spam"]
        )
    }
}
