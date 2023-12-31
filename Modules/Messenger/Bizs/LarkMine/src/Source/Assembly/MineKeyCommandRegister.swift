//
//  MineKeyCommandRegister.swift
//  LarkMine
//
//  Created by 李晨 on 2021/2/9.
//

import UIKit
import Foundation
import LarkKeyCommandKit
import LarkAccountInterface
import LarkMessengerInterface
import LarkUIKit
import EENavigator
import LarkOpenSetting
import LarkContainer

public final class MineKeyCommandRegister {
    public static func registerSettingKeyCommand(resolver: Container) {
        KeyCommandKit.shared.register(
            keyBinding: KeyCommandBaseInfo(
                input: ",",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkMine.Lark_NewSettings_ShortcutSetting
            ).binding(
                tryHandle: { (_) -> Bool in
                    // 已登录
                    let passportService = try? resolver.resolve(assert: PassportService.self)
                    guard passportService?.foregroundUser != nil else { return false } // foregroundUser
                    return
                        // 没有打开设置页
                        !((UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as?
                            UINavigationController)?.viewControllers.first is SettingViewController) && {
                                // 只在主 scene 上响应
                                if #available(iOS 13.0, *) {
                                    return UIApplication.shared.keyWindow?.windowScene?.sceneInfo.isMainScene() ?? true
                                } else {
                                    return true
                                }
                            }()
                }, handler: {
                    let body = MineSettingBody()
                    let navigator = Container.shared.getCurrentUserResolver().navigator // foregroundUser
                    guard let fromVC = navigator.mainSceneWindow?.lu.visibleViewController() else {
                        assertionFailure("缺少跳转的From")
                        return
                    }
                    navigator.presentOrPush(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: fromVC,
                        prepareForPresent: { (vc) in
                        vc.modalPresentationStyle = .formSheet
                        }
                    )
                }
            )
        )
    }
}
