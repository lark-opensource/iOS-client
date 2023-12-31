//
//  MailThreadListSync.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/9/18.
//

import Foundation
import RxSwift
import LarkUIKit
import EENavigator
import LarkSplitViewController
import UIKit

// MARK: protocol interface

protocol MailThreadListItemType {
    var threadId: String { get }

    var labels: [MailClientLabel] { get set }

    var fullLabels: [String] { get set }

    var messageId: String { get set }
    
    var summary: String { get }

    mutating func updateIsFlagged(isFlagged: Bool)
    mutating func updateIsRead(isRead: Bool)
    mutating func updateMsgCount(count: Int)
    mutating func updateFolders(folders: [String])
    mutating func updateMsgSummary(plainText: String)
}

protocol MailThreadListDataSource: AnyObject {
    /// 当前的Label Id
    var currentLabelId: String { get }

    /// label id that should be filter
    var syncFilterLabelIds: [String] { get }

    /// list data items
    var threadItems: [MailThreadListItemType] { get set }

    /// list data items
    var threadRemoteItems: [MailThreadListItemType] { get set }

    /// tableview
    var listTableView: UITableView { get }

    /// requestDisposeBag for mailthreadChange
    var mailThreadChangeBag: DisposeBag { get set }

    /// requestDisposeBag for multiThreadChange
    var mailMultiThreadChangeBag: DisposeBag { get set }
}

protocol MailThreadListDetailEnterAble {
    var listTableView: UITableView { get }

    /// current enter Mailpage's thread Id
    var markSelectedThreadId: String? { get }

    /// enter mail page
    func enterThread(at indexPath: IndexPath, scrollPosition: UITableView.ScrollPosition)
}

protocol MailThreadListSyncHandleAble: AnyObject {
    var disposeBag: DisposeBag { get }

    func handleMailThreadsChange(_ change: (threadId: String, labelIds: [String]))
    func handleMailMultiThreadsChange(_ change: Dictionary<String, (threadIds: [String], needReload: Bool)>, hasFilterThreads: Bool)
    func handleMailLabelChange(_ labels: [MailClientLabel])
}

final class MailThreadListSyncHandler {
    let _disposeBag = DisposeBag()
    var disposeBag: DisposeBag {
        return _disposeBag
    }
    weak var referrence: MailThreadListSyncAble?
    let serialQueue = DispatchQueue(label: "MailThreadListSyncHandler")
    
    let navigator: Navigatable
    
    init(navigator: Navigatable) {
        self.navigator = navigator
    }
}

protocol MailThreadListSyncAble: UIViewController, MailThreadListDataSource {
    var currentNavigator: Navigatable { get }
    
    var syncHandler: MailThreadListSyncHandleAble { get }

    /// add observe for sync list you should call it manually
    func configListSyncObserve()

    /// show emptyView when threadList is empty.
    func showEmptyView()
}

// MARK: private property

private var kSyncHandler: Void?
extension MailThreadListSyncAble {
    var syncHandler: MailThreadListSyncHandleAble {
        if let handler = objc_getAssociatedObject(self, &kSyncHandler) as? MailThreadListSyncHandleAble {
            return handler
        } else {
            let handler = MailThreadListSyncHandler(navigator: currentNavigator)
            handler.referrence = self
            objc_setAssociatedObject(self, &kSyncHandler, handler, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return handler
        }
    }
}

// MARK: protocol default imp -----------------------------------------

extension MailThreadListSyncAble {
    func configListSyncObserve() {
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .threadChange(let change):
                    self?.syncHandler.handleMailThreadsChange((change.threadId, change.labelIds))
                case .updateLabelsChange(let change):
                    self?.syncHandler.handleMailLabelChange(change.labels)
                case .multiThreadsChange(let change):
                    self?.syncHandler.handleMailMultiThreadsChange(change.label2Threads,
                                                                   hasFilterThreads: change.hasFilterThreads)
                default:
                    break
                }
            }).disposed(by: syncHandler.disposeBag)
    }
}

extension MailThreadListSyncHandler: MailThreadListSyncHandleAble {
    func handleMailThreadsChange(_ change: (threadId: String, labelIds: [String])) {
        let handler = self
        
        guard let self = referrence else {
            return
        }

        var trashedThreadIds = [String]()
        for filterLabelId in self.syncFilterLabelIds {
            if change.labelIds.contains(filterLabelId) {
                trashedThreadIds.append(change.threadId)
                break
            }
        }
        if !trashedThreadIds.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.syncReloadTableAfterActionIfNeeded(trashedThreadIds: trashedThreadIds)
            }
        } else {
            self.mailThreadChangeBag = DisposeBag()
            MailDataServiceFactory
                .commonDataService?
                .getMailThreadItemRequest(labelId: self.currentLabelId, threadId: change.threadId)
                .subscribe(onNext: { [weak self] (threadItem) in
                    guard let self = self else {
                        return
                    }

                    if let item = self.threadItems.first(where: { temp -> Bool in
                        temp.threadId == change.threadId
                    }) {
                        handler.serialQueue.sync { [weak self] in
                            self?.syncConstructMailThreadItem(listItem: item, threadItem: threadItem, isRemote: false)
                            self?.syncReloadTableAfterActionIfNeeded(trashedThreadIds: [])
                        }
                    }

                    if let item = self.threadRemoteItems.first(where: { temp -> Bool in
                        temp.threadId == change.threadId
                    }) {
                        handler.serialQueue.sync { [weak self] in
                            self?.syncConstructMailThreadItem(listItem: item, threadItem: threadItem, isRemote: true)
                            self?.syncReloadTableAfterActionIfNeeded(trashedThreadIds: [])
                        }
                    }
                }).disposed(by: self.mailThreadChangeBag)
        }
    }

    func handleMailMultiThreadsChange(_ label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>, hasFilterThreads: Bool) {
        guard let self = referrence else {
            return
        }
        var changeThreadIds: Set<String> = Set()
        for (_, (threadIds, _)) in label2Threads {
            changeThreadIds = changeThreadIds.union(Set(threadIds))
        }
        self.mailMultiThreadChangeBag = DisposeBag()
        MailDataServiceFactory
            .commonDataService?
            .getMailMultiThreadItemsRequest(fromLabel: self.currentLabelId,
                                            threadIds: Array(changeThreadIds)).subscribe(onNext: { [weak self] (resp) in
                                                guard let self = self else {
                                                    return
                                                }
                                                let newListItems = self.threadItems.map { (temp) -> MailThreadListItemType in
                                                    let item = temp
                                                    let mailItems = resp.threadItems.filter { (threadItem) -> Bool in
                                                        return threadItem.thread.id == item.threadId
                                                    }
                                                    if let mailItem = mailItems.first {
                                                        self.syncConstructMailThreadItem(listItem: item, threadItem: mailItem, isRemote: false)
                                                    }
                                                    return item
                                                }
                                                self.threadItems = newListItems

                let newRemoteListItems = self.threadRemoteItems.map { (temp) -> MailThreadListItemType in
                    let item = temp
                    let mailItems = resp.threadItems.filter { (threadItem) -> Bool in
                        return threadItem.thread.id == item.threadId
                    }
                    if let mailItem = mailItems.first {
                        self.syncConstructMailThreadItem(listItem: item, threadItem: mailItem, isRemote: true)
                    }
                    return item
                }
                self.threadRemoteItems = newRemoteListItems
                                                self.syncReloadTableAfterActionIfNeeded(trashedThreadIds: resp.disappearedThreadIds)
                                            }, onError: { (err) in
                                                assert(false, "get MultiThreadItems fail with error:\(err)")
                                            }).disposed(by: self.mailMultiThreadChangeBag)
    }

    func handleMailLabelChange(_ labels: [MailClientLabel]) {
        guard let self = referrence else {
            return
        }

        var labelMap = [String: MailClientLabel]()
        for temp in labels {
            labelMap[temp.id] = temp
        }

        for var temp in self.threadItems {
            let newLabels = temp.labels.compactMap({ (label) -> MailClientLabel? in
                if let newLabel = labelMap[label.id] {
                    return newLabel
                }

                return nil
            })
            temp.labels = newLabels
        }

        for var temp in self.threadRemoteItems {
            let newLabels = temp.labels.compactMap({ (label) -> MailClientLabel? in
                if let newLabel = labelMap[label.id] {
                    return newLabel
                }

                return nil
            })
            temp.labels = newLabels
        }

        UIView.performWithoutAnimation { [weak self] in
            self?.listTableView.reloadData()
        }
    }
}

// MARK: helper
extension MailThreadListSyncAble {
    func syncConstructMailThreadItem(listItem: MailThreadListItemType, threadItem: MailThreadItem, isRemote: Bool, isMulti: Bool = false) {
        var item = listItem
        // 因为搜索回来的label排序和db查询回来的label排序不一致，为了兼容不出现跳变的情况，需要做一次排序。
        var newLabels = [MailClientLabel]()
        var copy = threadItem.thread.labelIds
        for oldLabel in item.labels {
            if let newLabel = threadItem.thread.labelIds.first(where: { (temp) -> Bool in
                return temp == oldLabel.id
            }) {
                if let newTag = MailTagDataManager.shared.getTag(newLabel) {
                    newLabels.append(newTag)
                    copy.lf_remove(object: newLabel)
                }
            }
        }
        newLabels.append(contentsOf: MailTagDataManager.shared.getTagModels(copy))
        item.labels = MailThreadListLabelFilter.filterLabels(newLabels,
                                                                       atLabelId: Mail_LabelId_SEARCH,
                                                                       permission: .none)
        item.updateIsRead(isRead: threadItem.thread.isRead)
        if item.summary.isEmpty {
            item.updateMsgSummary(plainText: threadItem.thread.messageSummary)
        }
        item.updateIsFlagged(isFlagged: threadItem.thread.isFlagged)
        item.updateMsgCount(count: Int(threadItem.thread.messageCount))
        item.fullLabels = threadItem.thread.labelIds.map({ (label) -> String in
            return label
        })
        if isRemote {
            if let targetIndex = threadRemoteItems.firstIndex(where: ({ $0.threadId == item.threadId })) {
                asyncRunInMainThread { [weak self] in
                    self?.threadRemoteItems[targetIndex] = item
                    UIView.performWithoutAnimation { [weak self] in
                        self?.listTableView.reloadData()
                    }
                }
            }
        } else {
            if let targetIndex = threadItems.firstIndex(where: ({ $0.threadId == item.threadId })) {
                asyncRunInMainThread { [weak self] in
                    self?.threadItems[targetIndex] = item
                    UIView.performWithoutAnimation { [weak self] in
                        self?.listTableView.reloadData()
                    }
                }
            }
        }
    }

    func syncReloadTableAfterActionIfNeeded(trashedThreadIds: [String]) {
        asyncRunInMainThread { [weak self] in
            guard let `self` = self else { return }
            let preThreadItems = self.threadItems
            if !trashedThreadIds.isEmpty {
                self.threadItems.removeAll(where: { trashedThreadIds.contains($0.threadId) })
                self.threadRemoteItems.removeAll(where: { trashedThreadIds.contains($0.threadId) })
                UIView.performWithoutAnimation { [weak self] in
                    self?.listTableView.reloadData()
                }
            }
            var messageIds = self.threadItems.map({ $0.messageId })//.flatMap({ $0 })
            messageIds.append(contentsOf: self.threadRemoteItems.map({ $0.messageId }))
            // 请求并加上folders信息
            MailDataServiceFactory.commonDataService?.searchInWhichFolder(messageIds: messageIds)
            .subscribe(onNext: { [weak self] resp in
                guard let `self` = self else {
                    return
                }
                for messageFolders in resp.messageFolders {
                    if let index = self.threadItems.firstIndex(where: { return $0.messageId == messageFolders.messageID }) {
                        self.threadItems[index].updateFolders(folders: messageFolders.folders)
                    }
                    if let remoteIndex = self.threadRemoteItems.firstIndex(where: { return $0.messageId == messageFolders.messageID }) {
                        self.threadRemoteItems[remoteIndex].updateFolders(folders: messageFolders.folders)
                    }
                }
                self._syncReloadTableAfterActionIfNeeded(trashedThreadIds: trashedThreadIds)
            }).disposed(by: self.syncHandler.disposeBag)
        }
    }

    func _syncReloadTableAfterActionIfNeeded(trashedThreadIds: [String]) {
        // Delete removed items
        let preThreadItems = threadItems
        let preRemoteThreadItems = threadRemoteItems

        if !Store.settingData.mailClient {
            guard self.threadItems.count > 0 else {
                showEmptyView()
                return
            }
        }

        guard let enterInfo = self as? MailThreadListDetailEnterAble else {
            return
        }

        // Switch to next mail on regular layout
        let rootSizeClassIsRegular = view.window?.lkTraitCollection.horizontalSizeClass == .regular
        if rootSizeClassIsRegular {
            if let selectedThreadId = enterInfo.markSelectedThreadId,
            (self.threadItems + self.threadRemoteItems).first(where: { (temp) -> Bool in
                return selectedThreadId == temp.threadId
            }) == nil {
            // selectedThread is gone, try switching to next thread
            var hasVisitedEnterThread = false
            let firstThreadAfterEnterThread = (preThreadItems + preRemoteThreadItems).first { [weak self] (temp) -> Bool in
                guard let `self` = self else { return false }
                if !hasVisitedEnterThread {
                    if temp.threadId == enterInfo.markSelectedThreadId {
                        hasVisitedEnterThread = true
                    }
                    // filter out threads before selectedThread
                    return false
                } else {
                    // find the first thread after selectedThread & exists in new datasource
                    return (self.threadItems + self.threadRemoteItems).contains(where: { $0.threadId == temp.threadId })
                }
            }

            if let threadId = firstThreadAfterEnterThread?.threadId {
                if let idx = self.threadItems.firstIndex(where: { $0.threadId == threadId }) {
                    enterInfo.enterThread(at: IndexPath(row: idx, section: 0), scrollPosition: .none)
                } else if let removeIdx = self.threadRemoteItems.firstIndex(where: { $0.threadId == threadId }) {
                    enterInfo.enterThread(at: IndexPath(row: removeIdx, section: 1), scrollPosition: .none) // 这里有点难搞
                }
            } else {
                currentNavigator.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        }
        }
        if let threadActionAble = self as? MailThreadListMultiActionAble {
            threadActionAble.updateThreadActionBar()
        }
    }
}
