//
//  MailRecallManager.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/5/6.
//

import Foundation
import RxSwift

extension Notification.Name {
    static let mailRecallStateUpdate = Notification.Name(rawValue: "updateRecallState")
    static let mailRecalledChange = Notification.Name(rawValue: "mailRecalledChange")
}

enum MailRecallError: Int32 {
    /// 24小时前发送的邮件不允许撤回
    case sentLongTimeAgo = 480
    /// 不是已发送的邮件不允许撤回
    case notInSentState = 481
    /// 邮件已发起过撤回
    case hasBeenRecalled = 482
    /// 搬家域名不可发起撤回
    case migrationDomain = 483

    var errorText: String {
        switch self {
        case .sentLongTimeAgo:
            return BundleI18n.MailSDK.Mail_Recall_FailTimeout
        case .notInSentState:
            return BundleI18n.MailSDK.Mail_Recall_FailNotSent
        case .hasBeenRecalled:
            return BundleI18n.MailSDK.Mail_Recall_FailRecalled
        case .migrationDomain:
            // 这个case展示弹窗 其他展示toast
            return ""
        }
    }
}

enum MailRecallState: UInt {
    // hide recall banner
    case none = 0
    // show loading icon，hide detail button，hide recall button
    case request
    // show loading icon & datail button，hide recall button
    case processing
    // show completed icon & detail button，hide recall button
    case done
    // UI same as completed
    case allSuccess
    // UI same as completed
    case allFail
    // UI same as completed
    case someFail

    /// 成功文案，替换时使用
    var completedText: String {
        switch self {
        case .allFail:
            return BundleI18n.MailSDK.Mail_Recall_FailedToRecallEmail
        case .someFail:
            return BundleI18n.MailSDK.Mail_Recall_SomeEmailsRecalled
        case .allSuccess:
            return BundleI18n.MailSDK.Mail_Recall_EmailRecalled
        case .done, .none, .request, .processing:
            // none, request, processing 为还没处理完，不应显示完成文案，返回默认文案
            // done 代表已撤回，但是rust未计算完成结果，使用默认文案，到详情查看状态
            return BundleI18n.MailSDK.Mail_Recall_BannerRecalled
        }
    }

    /// 各状态对应的banner文案
    var bannerText: String {
        switch self {
        case .allFail:
            return BundleI18n.MailSDK.Mail_Recall_FailedToRecallEmail
        case .someFail:
            return BundleI18n.MailSDK.Mail_Recall_SomeEmailsRecalled
        case .allSuccess:
            return BundleI18n.MailSDK.Mail_Recall_EmailRecalled
        case .none, .request, .processing:
            return BundleI18n.MailSDK.Mail_Recall_BannerRecalling
        case .done:
            return BundleI18n.MailSDK.Mail_Recall_BannerRecalled
        }
    }
}

class MailRecallManager {

    typealias NativeRequestStatus = (isRequesting: Bool, isRequested: Bool)
    typealias NativeRequestInfo = (requestingSet: Set<String>, requestedSet: Set<String>)

    static let shared = MailRecallManager()
    let recallTimeLimit: TimeInterval = 24 * 60 * 60

    var isRecallEnabled: Bool {
        return Store.settingData.getCachedCurrentSetting()?.emailRecall == true
    }

    /// 记录requesting和requested状态，更新相关UI
    /// [accountID: (requestingList, requestedList)]
    private var requestStatusMap: ThreadSafeDictionary<String, NativeRequestInfo> = ThreadSafeDictionary()
    private let bag = DisposeBag()

    private init() { }

    private func getRequestStatus(messageID: String, accountID: String) -> NativeRequestStatus {
        var requestStatus: NativeRequestStatus = (false, false)
        if let statusInfo = requestStatusMap[accountID] {
            requestStatus.isRequesting = statusInfo.requestingSet.contains(messageID)
            requestStatus.isRequested = statusInfo.requestedSet.contains(messageID)
        }
        return requestStatus
    }

    private func updateRequestStatus(messageID: String, accountID: String, isRequesting: Bool, isRequested: Bool) {
        var statusInfo = requestStatusMap.value(ofKey: accountID) ?? (Set([]), Set([]))
        if isRequesting {
            statusInfo.requestingSet.insert(messageID)
        } else {
            statusInfo.requestingSet.remove(messageID)
        }

        if isRequested {
            statusInfo.requestedSet.insert(messageID)
        } else {
            statusInfo.requestedSet.remove(messageID)
        }
        requestStatusMap.updateValue(statusInfo, forKey: accountID)
    }

    func shouldShowRecallAction(for messageItem: MailMessageItem, myUserId: String) -> Bool {
        let notRecalled = messageItem.message.deliveryState != .recall
        let mailDelivered = messageItem.message.deliveryState == .delivered || messageItem.message.deliveryState == .sentToSelf
        let recallStateIsNone = recallState(for: messageItem) == .none
        return MailRecallManager.shared.isRecallEnabled == true && messageItem.isFromMe && notRecalled && mailDelivered && recallStateIsNone
    }

    func recallState(for mail: MailMessageItem) -> MailRecallState {
        var state: MailRecallState = .none
        switch mail.message.recallStatus {
        case .none:
            let requestStatus = getRequestStatus(messageID: mail.message.id,
                                                 accountID: Store.settingData.currentAccount.value?.mailAccountID ?? "")
            if requestStatus.isRequested {
                state = .processing
            } else if requestStatus.isRequesting {
                state = .request
            } else {
                state = .none
            }
        case .processing:
            state = .processing
        case .done:
            state = .done
        case .allSuccess:
            state = .allSuccess
        case .allFail:
            state = .allFail
        case .someFail:
            state = .someFail
        @unknown default:
            mailAssertionFailure("handle unknown recallState")
            state = .none
        }
        return state
    }

    func recall(for messageId: String, in threadId: String, completion: ((Error?) -> Void)? = nil) {
        let accountID = Store.settingData.currentAccount.value?.mailAccountID ?? ""
        updateRequestStatus(messageID: messageId, accountID: accountID, isRequesting: true, isRequested: false)

        Store.fetcher?.recallMessage(id: messageId).subscribe(
            onNext: { [weak self] (_) in
                self?.updateRequestStatus(messageID: messageId, accountID: accountID, isRequesting: false, isRequested: true)
                completion?(nil)
                // Post notification, in case MailListVC is a different object
                EventBusManager.shared.$recallStateUpdate.accept((threadId, messageId, nil))
            },
            onError: { [weak self] (error) in
                self?.updateRequestStatus(messageID: messageId, accountID: accountID, isRequesting: false, isRequested: false)
                completion?(error)
                // Post notification, in case MailListVC is a different object
                EventBusManager.shared.$recallStateUpdate.accept((threadId, messageId, nil))
            }).disposed(by: self.bag)
    }
}
