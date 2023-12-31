//
//  EnterChatLocationModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/4.
//

import Foundation
import UIKit
import RxSwift
import LarkOpenSetting
import LKCommonsTracker
import Homeric
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkSettingUI

private let settingKey = "GLOBALLY_ENTER_CHAT_POSITION"

final class EnterChatLocationModule: BaseModule {

    enum Status: Int {
        case whereItLeftOff
        case mostRecentUnread
    }

    var status: Status = .whereItLeftOff

    private var service: UserUniversalSettingService?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.service = try? self.userResolver.resolve(assert: UserUniversalSettingService.self)
        self.service?.getIntUniversalUserObservableSetting(key: settingKey)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.status = (response ?? 1) == 1 ? .whereItLeftOff : .mostRecentUnread
                self.context?.reload()
                SettingLoggerService.logger(.module(self.key)).info("api/get/res: \(response)")
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let whereItLeftOff = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_WhenILeftOff,
                                            accessories: [.checkMark(isShown: status == .whereItLeftOff)],
                                            onClick: { [weak self] _ in
            self?.update(status: .whereItLeftOff)
        })
        let mostRecentUnread = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_TheMostRecentUnreadMessage,
                                              accessories: [.checkMark(isShown: status == .mostRecentUnread)],
                                              onClick: { [weak self] _ in
            self?.update(status: .mostRecentUnread)
        })
        return SectionProp(items: [whereItLeftOff, mostRecentUnread])
    }

    private func track(click_type: String, view_type: String) {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "efficiency_chat_start_from",
            "target": "none",
            "click_type": click_type,
            "view_type": view_type
        ]))
    }

    private func update(status: Status) {
        guard status != self.status else { return }
        let origin = self.status
        self.status = status
        self.context?.reload()

        self.service?.setUniversalUserConfig(values: [settingKey: .intValue(status == .whereItLeftOff ? 1 : 2)])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let click_type = status == .whereItLeftOff ? "left_off" : "most_recent_unread"
                let view_type = status == .mostRecentUnread ? "left_off" : "most_recent_unread"
                self.track(click_type: click_type, view_type: view_type)
                SettingLoggerService.logger(.module(self.key)).info("api/set/req: status: \(status.rawValue); res: ok")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.status = origin
                self.context?.reload()
                SettingLoggerService.logger(.module(self.key)).error("api/set/req: status: \(status.rawValue); res: error: \(error)")
            }).disposed(by: disposeBag)
        }
}
