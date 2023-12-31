//
//  MailThreadListHeaderView+notice.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/7/4.
//

import Foundation
import UniverseDesignNotice

extension MailThreadListHeaderView: UDNoticeDelegate {
    /// 右侧文字按钮点击事件回调
    func handleLeadingButtonEvent(_ button: UIButton) {
        if mailClientExpiredView?.leadingButton == button {
            delegate?.clientReVerify()
        } else if outOfOfficeView?.leadingButton == button {
            delegate?.didClickedSettingButton()
        } else if outboxTipsView?.leadingButton == button {
            delegate?.didClickDismissOutboxTips()
        } else if bilingReminderNotice?.leadingButton == button || serviceSuspensionNotice?.leadingButton == button {
            delegate?.storageLimitContactHelp()
        } else if mailClientPassLoginExpiredView?.leadingButton == button {
            delegate?.clientReLink()
        } else if clearTrashTipsView?.leadingButton == button {
            delegate?.clickTrashClearAll()
        } else if preloadCacheNotice?.leadingButton == button {
            guard let cacheNotice = preloadCacheNotice else { return }
            delegate?.preloadCacheTipShowDetail(preloadProgress: cacheNotice.preloadProgress)
        }
    }

    /// 右侧图标按钮点击事件回调
    func handleTrailingButtonEvent(_ button: UIButton) {
        if bilingReminderNotice?.trailingButton == button || serviceSuspensionNotice?.trailingButton == button {
            delegate?.storageLimitCancelWarning()
        } else if outboxTipsView?.trailingButton == button {
            delegate?.didClickDismissOutboxTips()
        } else if preloadCacheNotice?.trailingButton == button {
            guard let cacheNotice = preloadCacheNotice else { return }
            delegate?.dismissPreloadCacheTip(preloadProgress: cacheNotice.preloadProgress)
        }
    }

    /// 文字按钮/文字链按钮点击事件回调
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        if URL.absoluteString == kHeaderOutboxTextBtnUrl {
            delegate?.didClickOutboxTips()
        }
    }
}
