//
//  ThreadActionDataManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/26.
//

import Foundation
import RxSwift
import Homeric
import LKCommonsLogging
import UniverseDesignToast

class ThreadActionDataManager {
    private static let logger = Logger.log(ThreadActionDataManager.self, category: "Module.DataManager")

    static let shared = ThreadActionDataManager()

    let disposeBag = DisposeBag()

    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }
}

// MARK: - MailAction
extension ThreadActionDataManager {
    func flag(threadID: String, fromLabel: String, msgIds: [String], sourceType: MailTracker.SourcesType) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_FLAG, params: [MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType), MailTracker.threadCountParamKey(): 1])
        self.fetcher?.multiMutLabelForThread(threadIds: [threadID],
                                            addLabelIds: [Mail_LabelId_FLAGGED],
                                            removeLabelIds: [],
                                            fromLabelID: fromLabel)
        .subscribe(onNext: { (response) in

        }, onError: { (error) in

        }).disposed(by: self.disposeBag)
    }

    func unFlag(threadID: String, fromLabel: String, msgIds: [String], sourceType: MailTracker.SourcesType) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_FLAG, params: [MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType), MailTracker.threadCountParamKey(): 1])
        self.fetcher?.multiMutLabelForThread(threadIds: [threadID],
                                            addLabelIds: [],
                                            removeLabelIds: [Mail_LabelId_FLAGGED],
                                            fromLabelID: fromLabel)
        .subscribe(onNext: { (response) in

        }, onError: { (error) in

        }).disposed(by: self.disposeBag)
    }

    func archiveMail(threadID: String, fromLabel: String, msgIds: [String], sourceType: MailTracker.SourcesType, on view: UIView? = nil) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_ARCHIVE, params: [MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType), MailTracker.threadCountParamKey(): 1])

        self.fetcher?.archive(threadID: threadID, fromLabelID: fromLabel).subscribe(onNext: { (response) in
            if let view = view {
                MailRoundedHUD.remove(on: view)
                if sourceType.supportUndo() {
                    MailUndoToastFactory.showMailActionToast(by: response.uuid, type: .archive, fromLabel: fromLabel, toastText: BundleI18n.MailSDK.Mail_ThreadAction_ArchiveToast, on: view, feedCardID: nil)
                } else {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_ArchiveToast, on: view)
                }
            }
        }, onError: { (error) in

        }).disposed(by: self.disposeBag)
    }

    func trashMail(threadID: String, fromLabel: String, msgIds: [String], sourceType: MailTracker.SourcesType, feedCardId: String? = nil, on view: UIView) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_TRASH, params: [MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType), MailTracker.threadCountParamKey(): 1])
        self.fetcher?.trash(threadID: threadID, fromLabelID: fromLabel, feedCardId: feedCardId).subscribe(onNext: { (response) in
            if fromLabel == Mail_LabelId_Scheduled {
                MailRoundedHUD.remove(on: view)
                ActionToast.removeToast(on: view)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SendLater_Cancelsucceed, on: view)
            } else {
                MailUndoToastFactory.showMailActionToast(by: response.uuid, type: .trash, fromLabel: fromLabel, toastText: BundleI18n.MailSDK.Mail_ThreadAction_TrashToast, on: view, feedCardID: feedCardId)
            }
        }, onError: { (error) in
        }).disposed(by: self.disposeBag)
    }

    func deletePermanently(threadIDs: [String], fromLabel: String, sourceType: MailTracker.SourcesType) -> Observable<Void> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.deletePermanently(labelID: fromLabel, threadIDs: threadIDs)
    }

    func spamMail(threadID: String, fromLabel: String, msgIds: [String], sourceType: MailTracker.SourcesType, ignoreUnauthorized: Bool, on view: UIView? = nil, handler: (()->Void)? = nil) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_SPAM, params: [MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType), MailTracker.threadCountParamKey(): 1])
        self.fetcher?.spam(threadID: threadID, fromLabelID: fromLabel, ignoreUnauthorized: ignoreUnauthorized).subscribe(onNext: { (response) in
            if let view = view {
                MailRoundedHUD.remove(on: view)
                ActionToast.removeToast(on: view)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_SpamToast, on: view)
            }
            handler?()
        }, onError: { (error) in

        }).disposed(by: self.disposeBag)
    }

    /// 实际上就是moveToInbox
    func notSpamMail(threadID: String, fromLabel: String, msgIds: [String] = [], sourceType: MailTracker.SourcesType, ignoreUnauthorized: Bool, supportUndo: Bool = false,
                            on view: UIView? = nil, handler: (()->Void)? = nil) {
        self.fetcher?.notSpam(threadID: threadID, fromLabelID: fromLabel, ignoreUnauthorized: ignoreUnauthorized).subscribe(onNext: { (response) in
            if let view = view {
                MailRoundedHUD.remove(on: view)
                ActionToast.removeToast(on: view)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_NotSpam, on: view)
            }
            handler?()
        }, onError: { (_) in

        }).disposed(by: self.disposeBag)
    }

    func moveToInbox(threadID: String, fromLabel: String, msgIds: [String] = [], sourceType: MailTracker.SourcesType, on view: UIView? = nil) {
        self.fetcher?.moveToInbox(threadID: threadID, fromLabelID: fromLabel).subscribe(onNext: { (response) in
            if let view = view, sourceType.supportUndo() {
                MailUndoToastFactory.showMailActionToast(by: response.uuid, type: .moveto, fromLabel: fromLabel, toastText: BundleI18n.MailSDK.Mail_ThreadAction_InboxToast, on: view, feedCardID: nil)
            }
        }, onError: { (response) in

        }).disposed(by: self.disposeBag)
    }
    
    func deleteDraft(draftID: String,
                            threadID: String,
                            feedCardId: String? = nil,
                            onSuccess: (() -> Void)? = nil,
                            onError: (() -> Void)? = nil,
                            on view: UIView? = nil) {
        self.fetcher?.deleteDraft(draftID: draftID, threadID: threadID, feedCardId: feedCardId).subscribe(onNext: { _ in
            ThreadActionDataManager.logger.info("deleteDraft succ")
            onSuccess?()
        }, onError: { (error) in
            ThreadActionDataManager.logger.error("deleteDraft failed", error: error)
            onError?()
        }).disposed(by: self.disposeBag)
    }

    func unreadMail(threadID: String, fromLabel: String = "", isRead: Bool, msgIds: [String] = [], fromSearch: Bool = false, sourceType: MailTracker.SourcesType, on view: UIView? = nil) {
        let event = isRead ? Homeric.EMAIL_THREAD_MARKASREAD : Homeric.EMAIL_THREAD_MARKASUNREAD
        MailTracker.log(event: event, params: [MailTracker.threadCountParamKey(): 1, MailTracker.isMultiselectParamKey(): false, MailTracker.sourceParamKey(): MailTracker.source(type: sourceType)])
        if !fromSearch {
            markReadStatus(threadID: threadID, fromLabel: fromLabel, isRead: isRead, supportUndo: false, on: view)
        } else {
            markReadStatus(threadID: threadID, fromLabel: Mail_LabelId_SEARCH, isRead: isRead, supportUndo: false, on: view)
        }
    }

    func markAllAsRead(labelID: String) -> Observable<Void> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.markAllAsRead(labelID: labelID)
    }
}

// MARK: private method
extension ThreadActionDataManager {
    private func markReadStatus(threadID: String, fromLabel: String, isRead: Bool, supportUndo: Bool = false, on view: UIView?) {
        self.fetcher?.updateThreadReadStatus(threadID: threadID, fromlabel: fromLabel, read: isRead).subscribe(onNext: { (response) in
            ThreadActionDataManager.logger.info("changelabel success isRead: \(isRead)")
            if let view = view, !isRead {
                ActionToast.removeToast(on: view) // 新增左右滑undo后，undo toast显示停留时间较长
                UDToast.removeToast(on: view)
                let config = UDToastConfig(toastType: .success, text: BundleI18n.MailSDK.Mail_ThreadAction_Unread, operation: nil)
                UDToast.showToast(with: config, on: view, disableUserInteraction: false, operationCallBack: nil)
            }
        }, onError: { (error) in
            ThreadActionDataManager.logger.error("markReadStatus failed", error: error)
        }).disposed(by: self.disposeBag)
    }
}
