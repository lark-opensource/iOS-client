//
//  DocHandler+Settings.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/12/8.
//

import Foundation
import EENavigator
import LarkSettingUI
import LarkOpenSetting
import SpaceInterface
import LarkContainer
import LarkNavigator
import SKFoundation
import SKResource

class CCMUserSettingsBodyHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { CCMUserScope.compatibleMode }
    func handle(_ body: CCMUserSettingsBody, req: EENavigator.Request, res: Response) throws {
        let controller = PageFactory.shared.generate(userResolver: userResolver, page: .ccm)
        controller.navTitle = SKResource.BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_Docs_Title_Mob
        res.end(resource: controller)
    }
}
