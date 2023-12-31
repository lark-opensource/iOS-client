//
//  MomentSettingAssembly.swift
//  Moment
//
//  Created by panbinghua on 2022/8/24.
//

import Foundation
import LarkNavigation
import LarkContainer
import LarkOpenSetting
import LarkTab
import LarkSetting
import EENavigator
import LarkUIKit

public final class MomentSettingAssembly {

    @_silgen_name("Lark.OpenSetting.MomentSettingAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.momentEntry.moduleKey, provider: { userResolver in
            guard let navigationService = try? userResolver.resolve(assert: NavigationService.self) else { return nil }
            guard let fgService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            let hadMomentTab = navigationService.checkInTabs(for: .moment)
            ///和产品确认 ipad上需要屏蔽公司圈的设置
            guard hadMomentTab else { return nil }
            return GeneralBlockModule(
                userResolver: userResolver,
                title: Tab.moment.remoteName ?? Tab.moment.tabName,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: MomentsSettingBody(), from: vc)
                })
        })
    }
}
