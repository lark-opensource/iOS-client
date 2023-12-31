//
//  CustomerContactViewModel.swift
//  LarkContact
//
//  Created by lichen on 2018/9/17.
//

import Foundation
import LarkUIKit
import LarkFoundation
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSDKInterface

final class CustomerContactViewModel {

    enum State {
        case `default`
        case loading
        case nomore
    }

    static let logger = Logger.log(CustomerContactViewModel.self, category: "Module.Contact.CustomerContactViewModel")

    private(set) var dataInFirstSection: [DataOfRow] = []
    private(set) var chatters: [(key: String, elements: [Chatter])] = []

    let api: ExternalContactsAPI
    let pushDriver: Driver<PushExternalContacts>
    var state: State = .default
    var tenantMap: [String: String] = [:]
    let showNormalNavigationBar: Bool
    let isUsingNewNaviBar: Bool
    private var cursor: String = "0"

    private(set) var contacts: [Contact] = []

    private var disposeBag = DisposeBag()
    private let lock: NSLock = NSLock()

    private var updateSubject = PublishSubject<Void>()
    var updateDriver: Driver<Void> {
        return updateSubject.asDriver(onErrorJustReturn: ())
    }

    init(api: ExternalContactsAPI,
         pushDriver: Driver<PushExternalContacts>,
         showNormalNavigationBar: Bool,
         isUsingNewNaviBar: Bool) {
        self.api = api
        self.pushDriver = pushDriver
        self.showNormalNavigationBar = showNormalNavigationBar
        self.isUsingNewNaviBar = isUsingNewNaviBar
        dataInFirstSection = []
        dataInFirstSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_ContactsNew,
                                                     icon: Resources.contact_application,
                                                     type: .contactApplication))
        dataInFirstSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup,
                                                     icon: Resources.group,
                                                     type: .group))
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
                return self.api.fetchTenant(tenantIds: tenantIds).map({ (tenants) -> ([Tenant], [Contact]) in
                    return (tenants, push.contacts)
                })
            })
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
        self.api.fetchExternalContacts(cursor: self.cursor, count: 100)
            .retry()
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
                return self.api.fetchTenant(tenantIds: tenantIds).map({ (tenants) -> ([Tenant], [Contact]) in
                    return (tenants, response.contacts)
                })
            })
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                response.0.forEach({ (tenant) in
                    self.tenantMap[tenant.id] = tenant.name
                })
                self.insertData(contacts: response.1)
                self.cursor = self.contacts.last?.id ?? "0"
                self.loadContactIfNeeded()
            }, onError: { [weak self] (error) in
                CustomerContactViewModel.logger.error("获取 contact 失败", error: error)
                self?.state = .default
            }).disposed(by: self.disposeBag)
    }

    func delete(chatter: Chatter) {
        if let contact = self.contacts.first(where: { (contact) -> Bool in
            return contact.chatterId == chatter.id
        }) {
            self.delete(contact: contact)
        }
    }

    private func delete(contact: Contact) {
        CustomerContactViewModel.logger.info("删除 contact")
        self.deleteData(contacts: [contact])
        let chatterId = contact.chatterId
        self.api.deleteContact(userId: chatterId).subscribe(onNext: { (_) in
            CustomerContactViewModel.logger.info("删除 contact 成功")
        }, onError: { [weak self] (error) in
            CustomerContactViewModel.logger.error("删除 contact 失败", error: error)
            self?.insertData(contacts: [contact])
        }).disposed(by: self.disposeBag)
    }

    private func deleteData(contacts deleteContacts: [Contact]) {
        lock.lock()
        defer { lock.unlock() }
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
            }) else { return }

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
        lock.lock()
        defer { lock.unlock() }
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
