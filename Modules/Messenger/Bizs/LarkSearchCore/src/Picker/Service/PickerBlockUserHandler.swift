//
//  PickerBlockUserHandler.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/8/7.
//

import Foundation
import LarkModel
import UniverseDesignToast
import LarkSceneManager

class PickerBlockUserHandler: SearchPickerHandlerType {

    weak var picker: UIView?
    init(picker: UIView) {
        self.picker = picker
    }

    var pickerHandlerId: String { "BlockUser" }
    func pickerDisableItem(_ item: PickerItem) -> Bool {
        if isItemBlocked(item: item) { return true }
        if isItemCryptoChatDeny(item: item) { return true }
        if isItemSameTenantDeny(item: item) { return true }
        return false
    }

    func pickerWillSelect(item: PickerItem, isMultiple: Bool) -> Bool {
        guard let picker else { return true }
        if isItemBlocked(item: item) {
            UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_IM_CantSelectBlocked_Hover(), on: picker)
            return false
        }
        if isItemCryptoChatDeny(item: item) {
            UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_Chat_CantSecretChatWithUserSecurityRestrict(), on: picker)
            return false
        }
        if isItemSameTenantDeny(item: item) {
            UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_Groups_NoPermissionToAdd(), on: picker)
            return false
        }
        return true
    }

    private func isItemBlocked(item: PickerItem) -> Bool {
        if case .chatter(let chatter) = item.meta {
            let deniedReasons = chatter.deniedReasons ?? []
            if !deniedReasons.isEmpty {
                PickerLogger.shared.info(module: PickerLogger.Module.data, event: "block user handler", parameters: "\(chatter.id): \(deniedReasons)")
            }
            if deniedReasons.contains(.beBlocked) {
                return true
            }
        }
        return false
    }

    private func isItemCryptoChatDeny(item: PickerItem) -> Bool {
        if case .chatter(let chatter) = item.meta {
            let deniedReasons = chatter.deniedReasons ?? []
            if !deniedReasons.isEmpty {
                PickerLogger.shared.info(module: PickerLogger.Module.data, event: "block user handler", parameters: "\(chatter.id): \(deniedReasons)")
            }
            if deniedReasons.contains(.cryptoChatDeny) {
                return true
            }
        }
        return false
    }

    private func isItemSameTenantDeny(item: PickerItem) -> Bool {
        if case .chatter(let chatter) = item.meta {
            let deniedReasons = chatter.deniedReasons ?? []
            if !deniedReasons.isEmpty {
                PickerLogger.shared.info(module: PickerLogger.Module.data, event: "block user handler", parameters: "\(chatter.id): \(deniedReasons)")
            }
            if deniedReasons.contains(.sameTenantDeny) {
                return true
            }
        }
        return false
    }
}
