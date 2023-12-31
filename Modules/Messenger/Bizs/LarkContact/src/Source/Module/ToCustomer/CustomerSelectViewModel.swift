//
//  CustomerSelectViewModel.swift
//  LarkContact
//
//  Created by lichen on 2018/9/17.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSDKInterface

final class CustomerSelectViewModel {
    enum State {
        case `default`
        case loading
        case nomore
    }

    private let isShowGroup: Bool
    private let externalContactsAPI: ExternalContactsAPI
    private let pushDriver: Driver<PushExternalContacts>

    // expose var, shared with VC. should modify in main thread
    private(set) var dataInFirstSection: [DataOfRow] = []
    private(set) var chatters: [(key: String, elements: [Chatter])] = []
    private(set) var tenantMap: [String: String] = [:]

    private var state: State = .default
    private var cursor: String = "0"
    private var contacts: [Contact] = []

    private let disposeBag = DisposeBag()

    private var updateSubject = PublishSubject<Void>()
    var updateDriver: Observable<Void> {
        return updateSubject.asObservable()
    }

    init(isShowGroup: Bool,
         externalContactsAPI: ExternalContactsAPI,
         pushDriver: Driver<PushExternalContacts>) {

        self.externalContactsAPI = externalContactsAPI
        self.isShowGroup = isShowGroup
        self.pushDriver = pushDriver

        dataInFirstSection = []
        if isShowGroup {
            dataInFirstSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup,
                                                icon: Resources.group,
                                                type: .group))
        }
        self.addObserver()
        self.loadContactIfNeeded()
    }

    private func addObserver() {
        pushDriver
            .asObservable()
            .flatMap({ [weak self] (push) -> Observable<([Tenant], [Contact])> in
                guard let `self` = self else {
                    return Observable.just(([], []))
                }
                self.state = push.hasMore ? .default : .nomore
                let tenantIds = push.contacts.map({ (contact) -> String in
                    if let chatter = contact.chatter {
                        return chatter.tenantId
                    } else {
                        return ""
                    }
                })
                return self.externalContactsAPI.fetchTenant(tenantIds: tenantIds).map({ (tenants) -> ([Tenant], [Contact]) in
                    return (tenants, push.contacts)
                })
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                push.0.forEach({ (tenant) in
                    self.tenantMap[tenant.id] = tenant.name
                })
                let insertContacts = push.1.filter { !$0.isDeleted }
                let deleteContacts = push.1.filter { $0.isDeleted }
                if !insertContacts.isEmpty { self.insertData(contacts: insertContacts) }
                if !deleteContacts.isEmpty { self.deleteData(contacts: deleteContacts) }
                CustomerContactViewModel.logger.info("收到 PushExternalContacts 推送， new count \(insertContacts.count), delete count \(deleteContacts.count)")
            }).disposed(by: disposeBag)
    }

    func loadContactIfNeeded() {
        if self.state != .default { return }
        self.state = .loading
        CustomerContactViewModel.logger.info("开始获取 contact cursor \(self.cursor)")
        self.externalContactsAPI.fetchExternalContacts(cursor: self.cursor, count: 100)
            .retry()
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] (response) -> Observable<([Tenant], [Contact])> in
                guard let `self` = self else {
                    return Observable.just(([], []))
                }
                CustomerContactViewModel.logger.info("获取 contact 成功 cursor \(self.cursor) count \(response.contacts.count) hasMore \(response.hasMore)")
                self.state = response.hasMore ? .default : .nomore
                let tenantIds = response.contacts.map({ (contact) -> String in
                    if let chatter = contact.chatter, self.tenantMap[chatter.tenantId] == nil {
                        return chatter.tenantId
                    } else {
                        return ""
                    }
                })
                return self.externalContactsAPI.fetchTenant(tenantIds: tenantIds).map({ (tenants) -> ([Tenant], [Contact]) in
                    return (tenants, response.contacts)
                })
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                response.0.forEach({ (tenant) in
                    self.tenantMap[tenant.id] = tenant.name
                })
                self.cursor = self.contacts.last?.id ?? "0"
                self.insertData(contacts: response.1)
                self.loadContactIfNeeded()
            }, onError: { [weak self] (error) in
                CustomerContactViewModel.logger.error("获取 contact 失败", error: error)
                self?.state = .default
            }).disposed(by: self.disposeBag)
    }

    private func deleteData(contacts deleteContacts: [Contact]) {
        assert(Thread.isMainThread, "should occur on main thread!")

        deleteContacts.compactMap({ (contact) -> Chatter? in
            return contact.chatter
        }).lf_sorted(by: { (first, second) -> Bool in
            return first.sortIndexName < second.sortIndexName
        }, getIndexKey: { (chatter) -> String in
            return chatter.sortIndexName
        }).forEach { (key: String, elements: [Chatter]) in
            guard let index = self.chatters.firstIndex(where: { (arg) -> Bool in
                let (contactKey, _) = arg
                return contactKey == key
            }) else {
                return
            }

            let (_, oldElements) = self.chatters[index]
            let newElements = oldElements.filter({ (chatter) -> Bool in
                return !elements.contains(chatter)
            })
            if newElements.isEmpty {
                self.chatters.remove(at: index)
            } else {
                self.chatters[index] = (key: key, elements: newElements)
            }
        }
        self.contacts.lf_removeObjectsInArray(deleteContacts)
        self.updateSubject.onNext(())
    }

    private func insertData(contacts insertContacts: [Contact]) {
        assert(Thread.isMainThread, "should occur on main thread!")
        let insertContacts = insertContacts.filter({ (contact) -> Bool in
            assert(contact.chatter != nil)
            return contact.chatter != nil && contact.isDeleted == false
        })

        self.contacts.lf_appendContentsIfNotContains(insertContacts)

        var insertNewSection: Bool = false

        insertContacts.compactMap({ (contact) -> Chatter? in
            return contact.chatter
        }).lf_sorted(by: { (first, second) -> Bool in
            return first.sortIndexName < second.sortIndexName
        }, getIndexKey: { (chatter) -> String in
            return chatter.sortIndexName
        }).forEach { (key: String, elements: [Chatter]) in
            if let index = self.chatters.firstIndex(where: { (arg) -> Bool in
                let (contactKey, _) = arg
                return contactKey == key
            }) {
                let (_, oldElements) = self.chatters[index]
                let newElements = oldElements.lf_mergeUniqueContinuous(array: elements, comparable: { (first, second) -> Int in
                    if first.localizedName == second.localizedName { return 0 }
                    if first.localizedName < second.localizedName { return 1 }
                    return -1
                })

                self.chatters[index] = (key: key, elements: newElements)
            } else {
                insertNewSection = true
                self.chatters.append((key: key, elements: elements))
            }
        }

        // 如果有新 section 重新排序
        if insertNewSection {
            self.chatters.sort { (first, second) -> Bool in
                return first.key < second.key
            }
        }

        self.updateSubject.onNext(())
    }
}
