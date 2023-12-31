//
//  MailKVStore.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/10/17.
//

import Foundation
import LarkStorage

public enum MailBiz: String {
    case normal      = "normal"
    case threadList  = "threadList"
    case msgList     = "msgList"
    case sendPage    = "sendPage"
    case settingPage = "settingPage"

    public var isolationId: String {
        "MailBiz_" + rawValue
    }
}

struct MailKVStore {

    private var kvStore: KVStore
    private let space: Space
    private var mSpace: MSpace = .global
    private var mailBiz: MailBiz = .normal
    private var reportTea: Bool = true

    var userID: String? {
        switch space {
        case .user(let userID):
            return userID
        default:
            return nil
        }
    }

    /// 工厂方法
    init(space: Space, mSpace: MSpace, mailBiz: MailBiz, reportTea: Bool = true) {
        self.space = space
        self.mSpace = mSpace
        self.mailBiz = mailBiz
        self.reportTea = reportTea
        self.kvStore = MailKVStore.contructStore(space: space, self.mSpace, self.mailBiz, reportTea: reportTea)
    }

    init(space: Space, mSpace: MSpace, reportTea: Bool = true) {
        self.space = space
        self.mSpace = mSpace
        self.reportTea = reportTea
        self.kvStore = MailKVStore.contructStore(space: space, self.mSpace, self.mailBiz, reportTea: reportTea)
    }
    
    private static func contructStore(space: Space,
                                      _ mSpace: MSpace, _ mailBiz: MailBiz, reportTea: Bool = true) -> KVStore {
        var store = KVStores.in(space: space)
            .in(domain: Domain.biz.mail
                .child(mSpace.isolationId)
                .child(mailBiz.isolationId)
            ).udkv()
        if space != .global {
            // 由于mail的domain是变参，会影响迁移部分，所以使用动态配置迁移的方式
            store = store.usingMigration(configs: 
            [.from(userDefaults: .standard, items: [.key("Mail_Send_Mention_Add_Address_Key"),
                                                    .key("MailSpamAlert.dontShowAlert"),
                                                    .key("MailAttachmentAlert.dontShowAlert")]),
            .from(userDefaults: .standard, prefixPattern: "MailCoreDefaultPrefix"),
            .from(userDefaults: .standard, prefixPattern: "mail_client_have_displayed_lms_"),
            .from(userDefaults: .standard, prefixPattern: "mail_client_account_onboard_"),
            .from(userDefaults: .standard, prefixPattern: "MailClient_ShowLoginPage_"),
            .from(userDefaults: .standard, prefixPattern: "mail_readstat_warning_")])
        }

        if reportTea {
            return store.usingTracker(biz: mailBiz.isolationId, scene: Store.settingData.getMailAccountType())
        } else {
            return store
        }
    }

    func value<T: Codable>(forKey key: String) -> T? {
        return kvStore.value(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        return kvStore.bool(forKey: key)
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        kvStore.set(value, forKey: key)
    }

    /// 同 UserDefaults#register(defaults:)，数据不落盘
    func register(defaults: [String: Any]) {
        kvStore.register(defaults: defaults)
    }

    /// 迁移数据到 store 中，如果 store 已经存在该 key，则忽略
    func migrate(values: [String: Any]) {
        kvStore.migrate(values: values)
    }

    func contains(key: String) -> Bool {
        kvStore.contains(key: key)
    }

    func removeValue(forKey key: String) {
        kvStore.removeValue(forKey: key)
    }

    func clearAll() {
        kvStore.clearAll()
    }

    func allValues() -> [String: Any] {
        return kvStore.allValues()
    }
}

extension MailKVStore: TypedSpaceCompatible {}

public enum MSpace: Isolatable {
    case global
    case account(id: String)

    static let globalRepr = "MailGlobal"
    static let accountPrefix = "MailAccount_"

    public var isolationId: String {
        switch self {
        case .global: return Self.globalRepr
        case .account(let id): return Self.accountPrefix + id
        }
    }
}
