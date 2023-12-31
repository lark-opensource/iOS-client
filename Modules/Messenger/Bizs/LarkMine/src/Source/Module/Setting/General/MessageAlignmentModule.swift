//
//  MessageAlignModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import LarkStorage
import LarkSDKInterface
import EENavigator
import LarkOpenSetting
import LarkSettingUI
import LarkContainer
import LarkSetting

final class MessageAlignmentModule: BaseModule {

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        NotificationCenter.default.rx
            .notification(NSNotification.Name("ChatSupportAvatarLeftRightChanged"))
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            })
            .disposed(by: disposeBag)
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        let supportLeftRight = KVPublic.Setting.chatSupportAvatarLeftRight(fgService: try? userResolver.resolve(assert: FeatureGatingService.self)).value()
        let str = supportLeftRight ? BundleI18n.LarkMine.Lark_Settings_MessageAlignLeftAndRight : BundleI18n.LarkMine.Lark_Settings_MessageAlignLeft
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_Settings_MessageAlignment,
                                         accessories: [.text(str), .arrow()]) { [weak self] _ in
            guard let self = self, let vc = self.context?.vc else { return }
            self.userResolver.navigator.push(ChatAvatarLayoutSettingViewController(userResolver: self.userResolver), from: vc)
        }
        return [item]
    }
}
