//
//  NotificationSettingSoundModule.swift
//  LarkMine
//
//  Created by Yaoguoguo on 2022/10/8.
//

import Foundation
import EENavigator
import LarkContainer
import LarkSetting
import LarkMessengerInterface
import Swinject
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkOpenSetting
import LarkStorage
import LarkSettingUI

final class NotificationSettingSoundModule: BaseModule {
    private var userGeneralSettings: UserGeneralSettings?

    private var notifyConfig: NotifyConfig? {
        return self.userGeneralSettings?.notifyConfig
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self)

        self.notifyConfig?.notifySoundsDriver.distinctUntilChanged().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.context?.reload()
        }).disposed(by: self.disposeBag)
        self.userGeneralSettings?.fetchDeviceNotifySettingFromServer()
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        var items: [LarkSettingUI.BaseNormalCellProp] = []

        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        guard featureGatingService?.staticFeatureGatingValue(with: .notificationSound) ?? false else {
            return nil
        }

        guard let notifyConfig = self.notifyConfig else {
            return nil
        }

        for item in notifyConfig.notifySounds.items {
            let content = NotificationSoundType.getKeyByName(item.value).title
            let normalItem = NormalCellProp(title: item.name,
                                            accessories: [.text(content), .arrow()],
                                            onClick: { [weak self] _ in
                guard let `self` = self else { return }
                guard let vc = self.context?.vc else { return }
                guard let userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self) else { return }
                let soundVC = NotificationSoundViewController(title: item.name,
                                                              key: item.key,
                                                              selectedValue: item.value,
                                                              userGeneralSettings: userGeneralSettings)
                self.userResolver.navigator.push(soundVC, from: vc)
            })

            items.append(normalItem)
        }

        return items
    }

    override func createHeaderProp(_ key: String) -> HeaderFooterType? {
        return .custom {
          let view = TitleHeaderView(reuseIdentifier: nil)
          view.topSpacing = 26
          view.text = BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_Title
          return view
        }
    }
}
