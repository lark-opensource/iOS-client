//
//  SelectContactListDelegate.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2021/2/21.
//
import UIKit
import Foundation
import RxSwift

public enum LifeCycleEventType {
    case viewDidLoad
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidDisappear
}

/// 列表状态
public enum ContactListMode {
    /// 默认模式
    case defaultMode
    /// 搜索模式
    case searchMode
}

/// 联系人额外信息
public struct ContactExtraInfo {
    var contact: AddressBookContact
    var contactTag: ContactTag
    public init(contact: AddressBookContact,
                contactTag: ContactTag) {
        self.contact = contact
        self.contactTag = contactTag
    }
}

public protocol SelectContactListControllerDelegate: AnyObject {
    /// 搜索联系人结果变化
    func onContactSearchChanged(filteredContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController)
    /// 多选模式下，选中联系人发生变化
    func selectedContactsChanged(selectedContacts: [AddressBookContact],
                                 contentType: ContactContentType,
                                 from: UIViewController)
    /// 单选模式下选择联系人
    func didChooseContactInSingleType(contact: AddressBookContact,
                                      contentType: ContactContentType,
                                      from: UIViewController)
    /// 多选模式下选择联系人
    func didSelectContactInMultipleType(contact: AddressBookContact,
                                        contentType: ContactContentType,
                                        toSelected: Bool,
                                        from: UIViewController)

    /// 请求获取通讯录的错误
    func showErrorForRequestContacts(error: NSError,
                                     contentType: ContactContentType,
                                     from: UIViewController)

    /// 点击右上角导航按钮
    func didTapNaviBarRightItem(selectedContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController)

    /// 点击选择列表的indexView
    func didSelectSectionIndexView(section: Int,
                                   contentType: ContactContentType,
                                   from: UIViewController)

    /// vc 生命周期回调
    func onLifeCycleEvent(type: LifeCycleEventType)

    /// 列表初始化完成
    func onPageInitFinished()

    /// 获取联系人列表加载完成
    /// @params loaded: 是否加载完成
    /// @params allContacts: 所有通讯录联系人
    func onContactsDataLoadedByExtrasIfNeeded(loaded: Bool,
                                              allContacts: [AddressBookContact]) -> Observable<[ContactExtraInfo]>?

    /// 通讯录模式状态变化
    func onContactListModeDidChange(listMode: ContactListMode)
}

public extension SelectContactListControllerDelegate {
    func onContactSearchChanged(filteredContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController) {}

    func selectedContactsChanged(selectedContacts: [AddressBookContact],
                                 contentType: ContactContentType,
                                 from: UIViewController) {}

    func didChooseContactInSingleType(contact: AddressBookContact,
                                      contentType: ContactContentType,
                                      from: UIViewController) {}

    func didSelectContactInMultipleType(contact: AddressBookContact,
                                        contentType: ContactContentType,
                                        toSelected: Bool,
                                        from: UIViewController) {}

    func showErrorForRequestContacts(error: NSError,
                                     contentType: ContactContentType,
                                     from: UIViewController) {}

    func didTapNaviBarRightItem(selectedContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController) {}

    func didSelectSectionIndexView(section: Int,
                                   contentType: ContactContentType,
                                   from: UIViewController) {}

    func onContactsDataLoadedByExtrasIfNeeded(loaded: Bool,
                                              allContacts: [AddressBookContact]) -> Observable<[ContactExtraInfo]>? {
        return nil
    }

    func onLifeCycleEvent(type: LifeCycleEventType) {}

    func onPageInitFinished() {}

    func onContactListModeDidChange(listMode: ContactListMode) {}
}
