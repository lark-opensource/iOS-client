//
//  ProfileSettingAssembly.swift
//  LarkProfile
//
//  Created by hupingwu on 2023/10/24.
//

import Foundation
import LarkNavigation
import LarkContainer
import LarkOpenSetting
import LarkSetting
import EENavigator
import LarkUIKit

public final class ProfileSettingAssembly {
    @_silgen_name("Lark.OpenSetting.ProfileSettingAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.profileMultiLanguage.moduleKey) { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_Title) { userResolver, from in
                    userResolver.navigator.push(MultiLanguageViewController(userResolver: userResolver), from: from)
            }
        }
    }
}
