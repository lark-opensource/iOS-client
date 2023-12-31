//
//  MinimumLaunchTask.swift
//  LarkMinimumMode
//
//  Created by Supeng on 2021/5/7.
//

import UIKit
import Foundation
import BootManager
import LarkContainer
import LarkFeatureGating
import LarkExtensions
import LarkLocalizations
import LarkSetting
import LarkStorage

public final class MinimumModeTask: UserFlowBootTask, Identifiable {
    public static var identify = "MinimumModeTask"

    public override class var compatibleMode: Bool { Minimum.userScopeCompatibleMode }

    public override func execute(_ context: BootContext) {
        if KVPublic.Core.minimumMode.value() {
            let domainSetting = DomainSettingManager.shared.currentSetting
            var urlStr = ""
            if let domain = domainSetting[.basicMode]?.first {
                urlStr = "https://\(domain)/basic-mobile-page/"
            }
            let vc = MainWebContainerViewController(userResolver: userResolver, urlStr: urlStr, navigationBarHidden: true)
            let nav = UINavigationController(rootViewController: vc)
            context.window?.rootViewController = nav
        }
        let minimumService = try? userResolver.resolve(assert: MinimumModeInterface.self)
        let fgService = try? userResolver.resolve(assert: FeatureGatingService.self)

        self.forceChangModeIfNeeded(fgValue: fgService?.staticFeatureGatingValue(with: "mobile.core.basic_mode") ?? false,
                                    minimumService: minimumService,
                                    context: context)
    }

    func forceChangModeIfNeeded(fgValue: Bool,
                                minimumService: MinimumModeInterface?,
                                context: BootContext) {

        guard fgValue else { return }

        // context.window?.rootViewController可能会变化，延迟执行，等rootViewController稳定
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let inMinimumMode = KVPublic.Core.minimumMode.value()
            minimumService?.forceChangModeIfNeeded { (finish) in
                // 基本模式下，web页面无法做国际化，此页面默认写死中文文案
                let title: String = inMinimumMode ? "出现了一些错误，请重启\(LanguageManager.bundleDisplayName)" : BundleI18n.LarkMinimumMode.Lark_Legacy_BasicModeErrorOccurredPlsRestart()
                let confirm: String = inMinimumMode ? "重启" : BundleI18n.LarkMinimumMode.Lark_Legacy_BasicModeErrorOccurredPlsRestartButton
                let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: confirm, style: .default, handler: { _ in
                    finish()
                }))
                context.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
