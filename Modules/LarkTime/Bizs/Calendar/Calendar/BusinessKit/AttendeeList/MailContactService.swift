//
//  MailContactService.swift
//  Calendar
//
//  Created by huoyunjie on 2022/12/26.
//

import Foundation
import RustPB
import LarkContainer
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import LKCommonsLogging

struct MailContactParsed: Equatable {
    var avatartKey: String?
    var displayName: String?
    var calendarId: String?
    var relationTag: Basic_V1_TagData?
    var tenantId: String?
    var type: Basic_V1_SearchByContactEntity.ContactEntityType
    var valid: Bool = false // 解析数据是否有效
    var entityId: String?
}

struct MailParsed {
    static let logger = Logger.log(MailContactParsed.self, category: "lark.calendar.mail_contact_parsed")

    static func logInfo(_ message: String) {
        logger.info(message)
    }

    static func logError(_ message: String) {
        logger.error(message)
    }

    static func logWarn(_ message: String) {
        logger.warn(message)
    }

    static func logDebug(_ message: String) {
        logger.debug(message)
    }
}

class MailContactService: UserResolverWrapper {

    typealias MailContactMap = SafeDictionary<String, MailContactParsed>

    @ScopedInjectedLazy var rustApi: CalendarRustAPI?

    private var mailContactsParsed: MailContactMap = [:] + .readWriteLock

    private let bag = DisposeBag()

    let rxDataChanged = PublishRelay<Void>()

    private let loadingMailContact: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func loadMailContact(mails: [String]) {
        var fixedMails = mails
        loadingMailContact.safeRead { (loadingMails) in
            // 过滤掉正在 loading 的 mail
            fixedMails = mails.filter { !loadingMails.contains($0) }
        }
        self.setLoadingMailContact(mails: Set(fixedMails))
        guard !fixedMails.isEmpty else { return }
        rustApi?.loadMailContactData(mails: fixedMails)
            .subscribeForUI(onNext: { [weak self] response in
                self?.processResponse(requestMails: fixedMails, response: response)
                self?.cancelLoadingMailContact(mails: Set(fixedMails))
            }, onError: { [weak self] err in
                MailParsed.logError("loadMailContactData error: \(err)")
                self?.cancelLoadingMailContact(mails: Set(fixedMails))
            })
            .disposed(by: bag)
    }

    // 获取有效的邮箱联系人解析数据
    func getMailContactsParsed(mails: [String], loadIfNotExist: Bool = false) -> MailContactMap {
        let missedMail = mails.filter({ !mailContactsParsed.keys.contains($0) })
        if !missedMail.isEmpty && loadIfNotExist {
            loadMailContact(mails: missedMail)
        }
        return mailContactsParsed.filter({ mails.contains($0.key) && $0.value.valid })
    }

    private func processResponse(requestMails: [String],
                                 response: Calendar_V1_LoadMailContactDataResponse) {
        let chatterCalendarMap = response.chatterCalendarMap
        var needNotification = false
        requestMails.forEach { mail in
            if let entity = response.searchMailEntities[mail] {
                var mailContactParsed = MailContactParsed(type: entity.searchEntityType)
                let valid = entity.searchEntityType != .unknownEntity
                if valid {
                    mailContactParsed.valid = true
                    mailContactParsed.displayName = entity.displayName
                    mailContactParsed.avatartKey = entity.avatarKey
                    mailContactParsed.relationTag = entity.relationTag
                    mailContactParsed.calendarId = chatterCalendarMap[entity.entityID]
                    mailContactParsed.tenantId = entity.tenantID
                    mailContactParsed.entityId = entity.entityID
                }
                if mailContactsParsed[mail] != mailContactParsed {
                    mailContactsParsed[mail] = mailContactParsed
                    needNotification = true
                }
            } else {
                // response 中没有返回的 mail，表示不能解析，需要在 mailContactsParsed 中移除原先的缓存
                mailContactsParsed.removeValue(forKey: mail)
                needNotification = true
            }
        }
        if needNotification {
            rxDataChanged.accept(())
        }
    }

    private func setLoadingMailContact(mails: Set<String>) {
        self.loadingMailContact.safeWrite(all: { (set) in
            set = set.union(mails)
        })
    }

    private func cancelLoadingMailContact(mails: Set<String>) {
        self.loadingMailContact.safeWrite(all: { (set) in
            set = set.subtracting(mails)
        })
    }
}
