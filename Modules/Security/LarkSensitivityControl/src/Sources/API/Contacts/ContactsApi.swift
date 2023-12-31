//
//  ContactApi.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/15.
//

import Contacts

public extension ContactsApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "contacts"
    }
}

/// contact相关方法
public protocol ContactsApi: SensitiveApi {

    /// CNContactStore enumerateContacts
    static func enumerateContacts(forToken token: Token,
                                  contactsStore: CNContactStore,
                                  withFetchRequest fetchRequest: CNContactFetchRequest,
                                  usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws

    /// CNContactStore  requestAccess
    static func requestAccess(forToken token: Token,
                              contactsStore: CNContactStore,
                              forEntityType entityType: CNEntityType,
                              completionHandler: @escaping (Bool, Error?) -> Void) throws

    /// CNContactStore  execute
    static func execute(forToken token: Token, store: CNContactStore, saveRequest: CNSaveRequest) throws
}
