//
//  ContactWrapper.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/15.
//

import Contacts

final class ContactsWrapper: NSObject, ContactsApi {

    /// CNContactStore enumerateContacts
    static func enumerateContacts(forToken token: Token,
                                  contactsStore: CNContactStore,
                                  withFetchRequest fetchRequest: CNContactFetchRequest,
                                  usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        try contactsStore.enumerateContacts(with: fetchRequest, usingBlock: block)
    }

    /// CNContactStore  requestAccess
    static func requestAccess(forToken token: Token,
                              contactsStore: CNContactStore,
                              forEntityType entityType: CNEntityType,
                              completionHandler: @escaping (Bool, Error?) -> Void) throws {
        contactsStore.requestAccess(for: entityType, completionHandler: completionHandler)
    }

    /// CNContactStore  execute
    static func execute(forToken token: Token, store: CNContactStore, saveRequest: CNSaveRequest) throws {
        try store.execute(saveRequest)
    }
}
