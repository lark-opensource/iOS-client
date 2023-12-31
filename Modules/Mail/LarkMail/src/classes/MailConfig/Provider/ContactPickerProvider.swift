//
//  ContactPickerProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2021/8/30.
//

import Foundation
import EENavigator
import LarkContainer
import LarkModel
import LarkAccountInterface
#if MessengerMod
import LarkMessengerInterface
#endif
import MailSDK
import LarkModel
import UniverseDesignToast

class ContactPickerProvider: ContactPickerProxy {

    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func presentMailContactPicker(params: MailContactPickerParams, vc: UIViewController) {
#if MessengerMod
        var body = MailChatterPickerBody()
        body.title = params.title
        body.mailAccount = params.mailAccount
        body.selectedCount = params.selectedCount
        body.pickerDepartmentFG = params.pickerDepartmentFG
        body.selectedCallback = { [weak self] (fromVC, res) in
            guard let `self` = self else { return }
            let items = self.transformResult(res)
            if params.pickerDepartmentFG {
                asyncRunInMainThread {
                    UDToast.showLoading(with: params.loadingText, on: vc.view, disableUserInteraction: true)
                }
            }
            //做完之后要自己手动dismiss
            fromVC?.dismiss(animated: true, completion: {
                if params.pickerDepartmentFG {
                    let noEmailList = self.getNoEmailListIfNeeded(res)
                    params.selectedCallbackWithNoEmail?(items, noEmailList)
                } else {
                    params.selectedCallback?(items)
                }
            })
        }
        body.forceSelectedEmails = params.defaultSelectedMails
        body.defaultSelectedEmails = params.defaultSelectedMails
        body.maxSelectCount = params.maxSelectCount
        resolver.navigator.present(body: body, from: vc)

        // 埋点
        MailTracker.log(event: "email_select_contact_from_picker_view", params: nil)
#endif
    }

    func presentContactSearchPicker(title: String, confirmText: String, selected: [LarkModel.PickerItem], delegate: SearchPickerDelegate, vc: UIViewController) {
#if MessengerMod
        var contactSearchPickerBody = ContactSearchPickerBody()
        // TODO
        let featureConfig = PickerFeatureConfig(
            scene: .searchFilterByOpenMail,
            multiSelection: .init(isOpen: true, preselectItems: selected),
            navigationBar: .init(title: title, sureText: confirmText, closeColor: UIColor.ud.iconN1,
                                 canSelectEmptyResult: true, sureColor: UIColor.ud.primaryContentDefault),
            searchBar: .init(hasBottomSpace: false, autoFocus: true)
        )
        let chatEntity = PickerConfig.ChatEntityConfig(tenant: .inner,
                                                       join: .all,
                                                       publicType: .all,
                                                       crypto: .all,
                                                       searchByUser: .closeSearchByUser,
                                                       field: PickerConfig.ChatField(showEnterpriseMail: true))
        let chatterEntity = PickerConfig.ChatterEntityConfig(talk: .all,
                                                             resign: .unresigned,
                                                             externalFriend: .noExternalFriend,
                                                             existsEnterpriseEmail: .onlyExistsEnterpriseEmail)
        let mailUserEntity = PickerConfig.MailUserEntityConfig(extras: ["scene": "MAIL-MAIL_SEARCH_FILTER_SCENE"])

        let searchConfig = PickerSearchConfig(entities: [
            chatterEntity,
            chatEntity,
            mailUserEntity
        ], scene: "FILTER_MAIL_USER", permission: [])

        let contactConfig = PickerContactViewConfig(entries: [
            PickerContactViewConfig.Organization(preferEnterpriseEmail: true)
        ])

        contactSearchPickerBody.featureConfig = featureConfig
        contactSearchPickerBody.searchConfig = searchConfig
        contactSearchPickerBody.contactConfig = contactConfig
        contactSearchPickerBody.delegate = delegate
        resolver.navigator.present(body: contactSearchPickerBody, from: vc, prepare: { $0.modalPresentationStyle = .formSheet })
#endif
    }

    func asyncRunInMainThread(_ block: @escaping () -> Void) {
        if Thread.current == Thread.main {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
/*
 enum ItemType {
     case chatter
     case group
     case external
     case nameCard
     case sharedMailbox
     case mailGroup
 }
 */

#if MessengerMod
extension ContactPickerProvider {

    func getNoEmailListIfNeeded(_ result: ContactPickerResult) -> [MailContactPickerResItem] {
        guard let noEmailChatterInfos = result.extra as? [SelectChatterInfo] else { return [] }
        var items: [MailContactPickerResItem] = []
        for chatter in noEmailChatterInfos {
            let itemDisplayName = chatter.localizedRealName.isEmpty ? chatter.name : chatter.localizedRealName
            var item = MailContactPickerResItem(displayName: itemDisplayName,
                                                email: "",
                                                entityId: chatter.ID,
                                                type: chatter.isExternal ? .external : .chatter,
                                                avatarKey: chatter.avatarKey)
            if !chatter.isExternal {
                item.tenantId = try? resolver.resolve(assert: PassportUserService.self).user.tenant.tenantID
            }
            items.append(item)
        }
        return items

    }
    func transformResult(_ result: ContactPickerResult) -> [MailContactPickerResItem] {
        var items: [MailContactPickerResItem] = []
        for chatter in result.chatterInfos {
            let itemDisplayName = chatter.localizedRealName.isEmpty ? chatter.name : chatter.localizedRealName
            let item = MailContactPickerResItem(displayName: itemDisplayName,
                                                email: chatter.email,
                                                entityId: chatter.ID,
                                                type: chatter.isExternal ? .external : .chatter,
                                                avatarKey: chatter.avatarKey)
            if !chatter.isExternal {
                item.tenantId = try? resolver.resolve(assert: PassportUserService.self).user.tenant.tenantID
            }
            items.append(item)
        }
        for mailContact in result.mailContacts {
            var type: MailContactPickerResItem.ItemType = .nameCard
            switch mailContact.type {
            case .chatter:
                type = .chatter
            case .group:
                type = .group
            case .external:
                type = .external
            case .nameCard:
                type = .nameCard
            case .mailGroup:
                type = .mailGroup
            case .sharedMailbox:
                type = .sharedMailbox
            case .unknown, .noneType:
                type = .unknown
            @unknown default:
                assert(false, "@liutefeng")
            }
            let item = MailContactPickerResItem(displayName: mailContact.displayName,
                                                email: mailContact.email,
                                                entityId: mailContact.entityId,
                                                type: type,
                                                avatarKey: mailContact.avatarKey)
            if mailContact.type == .chatter {
                item.tenantId = "0"
            }
            items.append(item)
        }
        for chat in result.chatInfos {
            let item = MailContactPickerResItem(displayName: chat.name,
                                                email: "",
                                                entityId: chat.id,
                                                type: .group,
                                                avatarKey: chat.avatarKey)
            items.append(item)
        }
        return items
    }

}
#endif
