//
//  SelectContactListViewModel.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import Contacts
import libPhoneNumber_iOS
import LKCommonsLogging
import LarkUIKit
import LarkSensitivityControl

final class SelectContactListViewModel: NSObject {

    // contacts
    var allContacts = [AddressBookContact]()
    var orderedContacts = [String: [AddressBookContact]]()
    // contact 额外信息
    var contactExtras = [ContactExtraInfo]()
    /// 多选模式
    var filteredContacts = [AddressBookContact]()
    /// 选中的联系人
    private(set) var selectedContacts = [AddressBookContact]()
    /// 选择超出个数限制
    typealias OverLimitHandle = (() -> Void)
    var overLimitHandle: OverLimitHandle = {}
    /// 获取联系人请求回调
    typealias FetchContactsRespond = (( _ contacts: [String: [AddressBookContact]]) -> Void)
    private var fetchContactsRespond: FetchContactsRespond = { _ in }

    // local
    private static let logger = Logger.log(SelectContactListViewModel.self, category: "LarkUIKit.SelectContactListViewModel")
    private var contactsStore: CNContactStore?
    private var lastSearchWorkItem: DispatchWorkItem?
    var sortedContactKeys = [String]()
    let contactTableSelectType: ContactTableSelectType
    let contactType: ContactContentType
    /// 通讯录导入个数上限
    let contactNumberLimit: Int?
    var sectionsCount: Int {
        switch listMode {
        case .defaultMode:
            return sortedContactKeys.count
        case .searchMode:
            return 1
        }
    }
    /// rx signals
    let disposeBag = DisposeBag()
    private let errorPublish = PublishSubject<NSError>()
    private let orderedContactsBehavior = BehaviorRelay<[String: [AddressBookContact]]>(value: [String: [AddressBookContact]]())
    private let filterRelay = BehaviorRelay<[AddressBookContact]>(value: [])
    /// 单选模式下，选择的联系人
    private let selectContactRelay = BehaviorRelay<AddressBookContact?>(value: nil)
    /// 多选模式下，已选中的联系人列表
    private let selectedContactsRelay = BehaviorRelay<[AddressBookContact]>(value: [])
    var errorDriver: Driver<NSError> {
        return errorPublish.asDriver(onErrorRecover: { _ in
            Driver<NSError>.empty()
        }).skip(1)
    }
    private let reloadDataRelay = BehaviorRelay<Void>(value: ())
    var orderedContactsDriver: Driver<[String: [AddressBookContact]]> {
        return orderedContactsBehavior.asDriver().skip(1)
    }
    var filterContactsDriver: Driver<[AddressBookContact]> {
        return filterRelay.asDriver().skip(1)
    }
    var selectedContactsDriver: Driver<[AddressBookContact]> {
        return selectedContactsRelay.asDriver().skip(1)
    }
    var selectContactDriver: Driver<AddressBookContact?> {
        return selectContactRelay.asDriver().skip(1)
    }
    var reloadDataDriver: Driver<Void> {
        return reloadDataRelay.asDriver().skip(1)
    }
    private let contactsLoadedRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var contactsLoadedObservable: Observable<Bool> {
        return contactsLoadedRelay.asObservable().skip(1).take(1)
    }
    private let listModeRelay: BehaviorRelay<ContactListMode> = BehaviorRelay(value: .defaultMode)
    var listModeDriver: Driver<ContactListMode> {
        return listModeRelay.asDriver().skip(1).distinctUntilChanged()
    }
    var listMode: ContactListMode {
        return listModeRelay.value
    }

    private var validCountryCodeProvider: MobileCodeProvider?
    var invalidCountryCodeErrorMessage: String?

    init(contactTableSelectType: ContactTableSelectType,
         contactContentType: ContactContentType,
         overLimitHandle: @escaping OverLimitHandle,
         contactNumberLimit: Int? = nil,
         validCountryCodeProvider: MobileCodeProvider? = nil,
         invalidCountryCodeErrorMessage: String? = nil) {
        self.contactTableSelectType = contactTableSelectType
        self.contactType = contactContentType
        self.overLimitHandle = overLimitHandle
        self.contactNumberLimit = contactNumberLimit
        self.validCountryCodeProvider = validCountryCodeProvider
        self.invalidCountryCodeErrorMessage = invalidCountryCodeErrorMessage
    }

    /// 获取本地通讯录数据
    func getLocalContactsAsync() {
        ContactService.getContactsAsync(token: Token("LARK-PSDA-address_book_access_contact"),
                                        dataType: contactType == .email ? .email : .phone,
                                        successCallback: { [weak self] contactsDataInfo in
            guard let self = self else { return }

            self.orderedContacts = contactsDataInfo.orderedContacts
            self.allContacts = contactsDataInfo.allContacts
            self.sortedContactKeys = contactsDataInfo.sortedContactKeys
            self.orderedContactsBehavior.accept(self.orderedContacts)
            self.contactsLoadedRelay.accept(true)
            SelectContactListViewModel.logger.debug("requestContacts:",
                                                    additionalData: ["allContacts": "\(contactsDataInfo.allContacts)",
                                                        "contactNumberLimit": "\(self.contactNumberLimit ?? 0)"])
        }) { [weak self] failedInfo in
            guard let self = self else { return }
            if let error = failedInfo.error {
                self.errorPublish.onNext(error)
            }
        }
    }

    func isBlockedContact(_ contact: AddressBookContact) -> Bool {
        var countryCode = contact.countryCode
        if let validCountryCodeProvider = validCountryCodeProvider, !countryCode.isEmpty, countryCode != ContactService.DummyCountryCode {
            let plusSign = "+"
            if !countryCode.hasPrefix(plusSign) {
                countryCode = plusSign + countryCode
            }
            if validCountryCodeProvider.searchCountry(searchCode: countryCode) == nil {
                return true
            }
        }

        return false
    }

    func isSelectedContact(_ contact: AddressBookContact) -> Bool {
        return selectedContacts.contains { (innerContact) -> Bool in
            return contact == innerContact
        }
    }

    func getIndexOfSelectedContact(_ contact: AddressBookContact) -> Int? {
        return self.selectedContacts.firstIndex(of: contact)
    }

    func contactCellViewModelForIndexPath(indexPath: IndexPath) -> ContactCellViewModel? {
        var contact: AddressBookContact?
        switch listMode {
        case .defaultMode:
            guard self.sortedContactKeys.count > indexPath.section else {
                return nil
            }
            let sectionKey = self.sortedContactKeys[indexPath.section]
            guard let _contact = self.orderedContacts[sectionKey]?[indexPath.row] else { return nil }
            contact = _contact
        case .searchMode:
            if filteredContacts.count > indexPath.row {
                contact = filteredContacts[indexPath.row]
            }
        }
        if let contact = contact {
            let tag = getContactTagOfContact(contact: contact)
            let cellVM = ContactCellViewModel(contact: contact,
                                              contactSelectType: self.contactTableSelectType,
                                              contactTag: tag,
                                              blocked: isBlockedContact(contact))
            return cellVM
        }
        return nil
    }

    func getContactTagOfContact(contact: AddressBookContact) -> ContactTag? {
        guard !self.contactExtras.isEmpty else { return nil }

        return self.contactExtras.first(where: {
            $0.contact.identifier == contact.identifier
        })?.contactTag
    }

    func getRowsInSection(section: Int) -> Int {
        switch listMode {
        case .defaultMode:
            if sortedContactKeys.count > section,
                let contactsForSection = self.orderedContacts[self.sortedContactKeys[section]] {
                return contactsForSection.count
            }
            return 0
        case .searchMode:
            return self.filteredContacts.count
        }
    }

    func didSelectedContact(contact: AddressBookContact) {
        switch self.contactTableSelectType {
        case .single:
            selectContactRelay.accept(contact)
        case .multiple:
            if let index = selectedContacts.firstIndex(of: contact) {
                selectedContacts.remove(at: index)
            } else {
                if let contactNumberLimit = contactNumberLimit,
                    selectedContacts.count >= contactNumberLimit {
                    self.overLimitHandle()
                } else {
                    selectedContacts.append(contact)
                }
            }
            selectedContactsRelay.accept(selectedContacts)
        }
    }

    func clearSearchCache() {
        filteredContacts.removeAll()
    }
}

// MARK: - Search Mode
extension SelectContactListViewModel {
    func updateSearchResults(for searchText: String) {
        if let lastSearchItem = lastSearchWorkItem {
            lastSearchItem.cancel()
        }
        lastSearchWorkItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            let filteredContacts = self.allContacts.filter { (contact) -> Bool in
                var valid = (contact.fullName.range(of: searchText) != nil)
                    || (contact.email?.range(of: searchText) != nil)
                    || (contact.phoneNumber?.range(of: searchText) != nil)

                if !valid, contact.fullName.isChineseString(), searchText.isLetterString() {
                    let pinyin = contact.fullName.transformToPinyin(hasBlank: false)
                    let upper = pinyin.uppercased()
                    let searchTextUpper = searchText.uppercased()
                    valid = (pinyin.range(of: searchTextUpper) != nil) || (upper.range(of: searchTextUpper) != nil)
                }

                if !valid, searchText.isLetterString(), contact.fullName.isLetterString() {
                    let searchLower = searchText.lowercased()
                    let fullNameLower = contact.fullName.lowercased()
                    valid = fullNameLower.range(of: searchLower) != nil
                }

                return valid
            }
            DispatchQueue.main.async {
                self.filteredContacts = filteredContacts
                self.filterRelay.accept(self.filteredContacts)
            }
        }
        DispatchQueue.global().async(execute: lastSearchWorkItem!)
    }

    func setListMode(listMode: ContactListMode) {
        SelectContactListViewModel.logger.debug("setListMode", additionalData: ["listMode": "\(listMode)"])
        self.listModeRelay.accept(listMode)
    }
}

// MARK: - DataSource
extension SelectContactListViewModel {
    /// 刷新联系人数据
    func updateContactExtraInfos(extraInfos: [ContactExtraInfo]) {
        self.contactExtras = extraInfos
        self.reloadDataRelay.accept(())
    }
}

// MARK: - Other

extension String {
    subscript(r: Range<Int>) -> String? {
        let stringCount = count as Int
        if (stringCount < r.upperBound) || (stringCount < r.lowerBound) {
            return nil
        }
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[startIndex..<endIndex])
    }

    func transformToPinyin(hasBlank: Bool = false) -> String {
        let stringRef = NSMutableString(string: self) as CFMutableString
        CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
        let pinyin = stringRef as String
        return hasBlank ? pinyin : pinyin.replacingOccurrences(of: " ", with: "")
    }

    func transformToPinyinHead(lowercased: Bool = false) -> String {
        let pinyin = transformToPinyin(hasBlank: true).capitalized
        var headPinyinStr = ""
        for ch in pinyin {
            if ch <= "Z" && ch >= "A" {
                headPinyinStr.append(ch)
            }
        }
        return lowercased ? headPinyinStr.lowercased() : headPinyinStr
    }

    func isChineseString() -> Bool {
        let copyStr = String(self)
        let trimmingStr = copyStr.trimmingCharacters(in: NSCharacterSet.whitespaces)
        guard !trimmingStr.isEmpty else {
            return false
        }
        var result = true
        for ch in trimmingStr {
            if ch.isWhitespace {
                continue
            }
            result = result && ch.isChinese()
            if !result {
                break
            }
        }
        return result
    }

    func isLetterString() -> Bool {
        let copyStr = String(self)
        let trimmingStr = copyStr.trimmingCharacters(in: NSCharacterSet.whitespaces)
        guard !trimmingStr.isEmpty else {
            return false
        }
        var result = true
        for ch in trimmingStr {
            if ch.isWhitespace {
                continue
            }
            result = result && (ch.isLetter() || ch.isWhitespace)
            if !result {
                break
            }
        }
        return result
    }
}

extension Character {
    func canTransformToPinyinHead() -> Bool {
        return isChinese() || isLetter()
    }

    func isChinese() -> Bool {
        return "\u{4E00}" <= self && self <= "\u{9FA5}"
    }

    func isLetter() -> Bool {
        return self >= "A" && self <= "z"
    }
}
