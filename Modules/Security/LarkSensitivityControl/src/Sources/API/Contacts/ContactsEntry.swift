//
//  ContactEntry.swift
//  LarkSensitivityControl
//
//  Created by yangyfian on 2023/3/15.
//

import Contacts

/// Calendar
final public class ContactsEntry: NSObject, ContactsApi {

    private static func getService() -> ContactsApi.Type {
        if let service = LSC.getService(forTag: tag) as? ContactsApi.Type {
            return service
        }
        return ContactsWrapper.self
    }

    /// CNContactStore enumerateContacts
    public static func enumerateContacts(forToken token: Token,
                                         contactsStore: CNContactStore,
                                         withFetchRequest fetchRequest: CNContactFetchRequest,
                                         usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        let context = Context([AtomicInfo.Contacts.enumerateContacts.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().enumerateContacts(forToken: token, contactsStore: contactsStore,
                                           withFetchRequest: fetchRequest, usingBlock: block)
    }

    /// CNContactStore  requestAccess
    public static func requestAccess(forToken token: Token,
                                     contactsStore: CNContactStore,
                                     forEntityType entityType: CNEntityType,
                                     completionHandler: @escaping (Bool, Error?) -> Void) throws {
        let context = Context([AtomicInfo.Contacts.requestAccess.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAccess(forToken: token, contactsStore: contactsStore,
                                       forEntityType: entityType, completionHandler: completionHandler)
    }

    /// CNContactStore  execute
    public static func execute(forToken token: Token, store: CNContactStore, saveRequest: CNSaveRequest) throws {
        let context = Context([AtomicInfo.Contacts.execute.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().execute(forToken: token, store: store, saveRequest: saveRequest)
    }
}
