//
//  MailMessageListHeaderManager.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/14.
//

import Foundation
import LarkAlertController
import EENavigator
import Homeric
import LarkUIKit
import RxSwift
import RustPB
import LarkTab
import UIKit
import FigmaKit

protocol MailMessageListHeaderManagerDelegate: AnyObject {
    func closeHeaderView()
}

class MailMessageListHeaderManager {
    
    lazy var mailmessagelistHeaderView: MailMessageListHeaderView = {
        let headerView = MailMessageListHeaderView()
        headerView.delegate = self
        return headerView
    }()
    weak var delegate: MailMessageListHeaderManagerDelegate?

    // MARK: property
    var fetcher: DataService? {
        return Store.fetcher
    }
    var feedCardId: String
    let disposeBag = DisposeBag()
    weak var clientDelegate: MailClientSettingDelegate?

    let accountContext: MailAccountContext
    let from: EENavigator.NavigatorFrom
   
    init(accountContext: MailAccountContext, feedCardId: String, from: EENavigator.NavigatorFrom) {
        self.accountContext = accountContext
        self.feedCardId = feedCardId
        self.from = from
    }
    
    func fetchOutboxStateForEnter(feedCardID: String, address: String, relayoutBlock: @escaping () -> Void) {
        fetcher?.getOutBoxMessageStateInFeed(feedCardID:feedCardID, messageIDs: []).subscribe(onNext: { [weak self] infos in
            guard let self = self else { return }
            if infos.contains(where: {$0.deliveryState == .sendError}) {
                mailmessagelistHeaderView = mailmessagelistHeaderView.showOutboxtips()
                relayoutBlock()
            } else {
                requestBlackListBlock(address: address, relayoutBlock: relayoutBlock)
            }
        }, onError: { error in
            MailLogger.error("Failed to get outbox message state, error: \(error)")
        }).disposed(by: disposeBag)
    }
    
    func fetchOutboxStateForChange(feedCardID: String, address: String, messageIDs: [String], relayoutBlock: @escaping () -> Void) {
        fetcher?.getOutBoxMessageStateInFeed(feedCardID: feedCardID, messageIDs:messageIDs).subscribe(onNext: { [weak self] infos in
            guard let self = self else { return }
            if infos.contains(where: {$0.deliveryState == .sendError}) {
                MailLogger.error("get outbox message state")
                let kvStore = accountContext.accountKVStore
                let showedFeedOutboxTipDic : [String: Bool] = [feedCardID: false]
                kvStore.set(showedFeedOutboxTipDic, forKey: UserDefaultKeys.dismissfeedMailOutboxTip)
                mailmessagelistHeaderView = mailmessagelistHeaderView.showOutboxtips()
                relayoutBlock()
            } else {
                dismissOutboxTips()
                requestBlackListBlock(address: address, relayoutBlock: relayoutBlock)
            }
        }, onError: { error in
            MailLogger.error("Failed to get outbox message state, error: \(error)")
        }).disposed(by: disposeBag)
    }
    
    func enterFeed(feedCardID: String, address: String, relayoutBlock: @escaping () -> Void) {
        if !isShowed() {
            fetchOutboxStateForEnter(feedCardID: feedCardID, address: address, relayoutBlock: relayoutBlock)
        } else {
            requestBlackListBlock(address: address, relayoutBlock: relayoutBlock)
        }
    }
    
    func requestBlackListBlock(address: String, relayoutBlock: @escaping () -> Void) {
        fetcher?.getBlockedAddresses(addresses: [address]).subscribe(onNext: { [weak self] blockedAddresses in
            guard let self = self else { return }
            if !blockedAddresses.isEmpty {
                mailmessagelistHeaderView = mailmessagelistHeaderView.showBlackTips()
                relayoutBlock()
            }
        }, onError: { error in
            MailLogger.error("Failed togetBlockedAddresses error: \(error)")
        }).disposed(by: disposeBag)
    }
    
    func isShowed() -> Bool {
        let kvStore = accountContext.accountKVStore
        var isShowed = true
        if let dismissDic: [String: Bool] = kvStore.value(forKey: UserDefaultKeys.dismissfeedMailOutboxTip) {
            isShowed = dismissDic[self.feedCardId] ?? true
        }
        return isShowed
    }
    
}

extension MailMessageListHeaderManager: MailOutboxTipsViewDelegate {
    func didClickDismissOutboxTips() {
        dismissOutboxTips()
        let kvStore = accountContext.accountKVStore
        let showedFeedOutboxTipDic : [String: Bool] = [self.feedCardId: true]
        kvStore.set(showedFeedOutboxTipDic, forKey: UserDefaultKeys.dismissfeedMailOutboxTip)
    }
    
    func didClickOutboxTips() {
        accountContext.navigator.switchTab(Tab.mail.url, from: from, animated: true) {  [weak self] _ in
            guard let self = self else { return }
            if let mailtabvc =             self.accountContext.navigator.navigation?.viewControllers.first?.animatedTabBarController?.viewControllers?.first as? MailTabBarController, let homevc = mailtabvc.content as? MailHomeController {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                    homevc.autoChangeLabel(Mail_LabelId_Outbox, title: BundleI18n.MailSDK.Mail_Outbox_OutboxMobile, isSystemLabel: true, updateTimeStamp: false)
                    homevc.reloadNavbar()
                }
            }
        }
        dismissOutboxTips()
    }
    
    func dismissOutboxTips() {
        mailmessagelistHeaderView = mailmessagelistHeaderView.dismissOutboxTips()
        delegate?.closeHeaderView()
    }
}
