//
//  VCTopStructureSelectViewController.swift
//  LarkContact
//
//  Created by Yuri on 2022/5/17.
//

import Foundation
import UIKit
import LarkSearchCore
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface

final class VCTopStructureSelectViewController: TopStructureSelectViewController {
    /// 搜索群鉴权
    var checkSearchChatDeniedReasonForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?
    var checkSearchChatDeniedReasonForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?
    /// 搜索人鉴权
    var checkSearchChatterDeniedReasonForDisabledPick: ((Bool) -> Bool)?
    var checkSearchChatterDeniedReasonForWillSelected: ((Bool, UIViewController) -> Bool)?
    private var currentTenantID: String {
        return passportUserService.userTenant.tenantID
    }
    override func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        if let checkSearchChatDeniedReasonForDisabledPick = self.checkSearchChatDeniedReasonForDisabledPick,
           let selectChatType = option.asPickerSelectChatType(),
           checkSearchChatDeniedReasonForDisabledPick(selectChatType) {
            return true
        }

        if let checkSearchChatterDeniedReasonForDisabledPick = self.checkSearchChatterDeniedReasonForDisabledPick,
           let chatterPickerSelectedInfo = option.asChatterPickerSelectedInfo(),
           checkSearchChatterDeniedReasonForDisabledPick(chatterPickerSelectedInfo.isExternal(currentTenantId: currentTenantID)) {
            return true
        }

        return super.picker(picker, disabled: option, from: from)
    }

    override func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        if let checkSearchChatDeniedReasonForWillSelected = self.checkSearchChatDeniedReasonForWillSelected,
           let selectChatType = option.asPickerSelectChatType(),
           !checkSearchChatDeniedReasonForWillSelected(selectChatType, self) {
            return false
        }

        if let checkSearchChatterDeniedReasonForWillSelected = self.checkSearchChatterDeniedReasonForWillSelected,
           let chatterPickerSelectedInfo = option.asChatterPickerSelectedInfo(),
           !checkSearchChatterDeniedReasonForWillSelected(chatterPickerSelectedInfo.isExternal(currentTenantId: currentTenantID), self) {
            return false
        }
        return super.picker(picker, willSelected: option, from: from)
    }
}
