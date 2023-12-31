//
//  CustomRingtoneSettingModule.swift
//  ByteViewMessenger
//
//  Created by kiri on 2023/6/2.
//

import Foundation
import LarkOpenSetting
import LarkContainer
import ByteViewSetting
import LarkSettingUI

final class CustomRingtoneSettingModule: BaseModule {
    private var setting: UserSettingManager? { try? userResolver.resolve(assert: UserSettingManager.self) }

    var ringingName: String {
        if self.setting?.customRingtone == CustomRingtoneType.spring.ringtoneName {
            return I18n.View_G_UpbeatRingtone
        } else {
            return I18n.View_G_DefaultRingtone
        }
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        addStateListener(.viewWillAppear) { [weak self] in
            self?.context?.reload()
        }
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        if key == "customizeRingtone" {
            let contentText: String = self.ringingName
            let item = NormalCellProp(title: I18n.View_G_MeetingRingtone,
                                      accessories: [.text(contentText, spacing: 4), .arrow()],
                                      onClick: { [weak self] _ in
                guard let `self` = self, let from = self.context?.vc else { return }
                let vc = LarkOpenSetting.SettingViewController(name: "customizeRing")
                vc.patternsProvider = { [
                    .wholeSection(pair: PatternPair("customizeRingtoneSetting", ""))
                ] }
                vc.registerModule(CustomRingtoneDetailSettingModule(userResolver: self.userResolver), key: "customizeRingtoneSetting")
                vc.navTitle = I18n.View_G_MeetingRingtone
                self.userResolver.navigator.push(vc, from: from)
            })
            return [item]
        }
        return nil
    }
}

/// 铃声
enum CustomRingtoneType {
    case `default` // 默认铃声
    case spring // 欢快，upbeat

    var ringtoneName: String {
        switch self {
        case .`default`:
            return "vc_call_ringing.mp3"
        case .spring:
            return "vc_call_ringing_spring.mp3"
        }
    }

    var ringtoneURL: URL? {
        switch self {
        case .`default`:
            return Bundle.main.url(forResource: "vc_call_ringing", withExtension: "mp3")
        case .spring:
            return Bundle.main.url(forResource: "vc_call_ringing_spring", withExtension: "mp3")
        }
    }

    var displayName: String {
        switch self {
        case .default:
            return I18n.View_G_DefaultRingtone
        case .spring:
            return I18n.View_G_UpbeatRingtone
        }
    }
}
