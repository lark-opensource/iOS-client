//
//  NetworkModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import RustPB
import LKCommonsTracker
import LarkSDKInterface
import LarkContainer
import Homeric
import LarkOpenSetting
import LarkStorage
import LarkSettingUI

final class WifiSwich4GModule: BaseModule {

    private var rustService: SDKRustService?

    static let userStore = \WifiSwich4GModule._userStore

    @KVBinding(to: userStore, key: KVKeys.Setting.General.wifiSwitch4G)
    var isOn: Bool

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.rustService = try? userResolver.resolve(assert: SDKRustService.self)
        fetchWifiSwich4G()
    }
    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_Core_WifiWeakSwitchCellular_Option,
                                         isOn: isOn,
                                         onSwitch: { [weak self] _, isOn in
            self?.updateWifiSwich4G(isOn)
        })
        return SectionProp(items: [item], footer: .title(BundleI18n.LarkMine.Lark_Core_WifiWeakSwitchCellular_Desc))
    }

    // 设置wifi切换4g
    private func updateWifiSwich4G(_ isOn: Bool) {
        var request = RustPB.Tool_V1_MultiNetRequest()
        request.isOn = isOn
        let trackerParams: [String: String] = ["click": "weak_wifi", "target": "none", "is_on": isOn ? "true" : "false"]
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK,
                              params: trackerParams))
        self.rustService?.sendAsyncRequest(request)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                SettingLoggerService.logger(.module(self.key)).info("api/set/req: \(isOn) res: ok")
                self.isOn = isOn
            }, onError: { [weak self] error in
                guard let self = self else { return }
                SettingLoggerService.logger(.module(self.key)).info("api/set/req: \(isOn) res: error: \(error)")
                self.context?.reload()
            })
            .disposed(by: self.disposeBag)
    }

    // 获取wifi切4g开关
    private func fetchWifiSwich4G() {
        let request = RustPB.Tool_V1_MultiNetRequest()
        self.rustService?.sendAsyncRequest(request)
            .subscribe(onNext: { [weak self] (resp: Tool_V1_MultiNetResponse) in
                guard let self = self else { return }
                SettingLoggerService.logger(.module(self.key)).info("api/get/res: \(resp.isOn) current: \(self.isOn)")
                if self.isOn != resp.isOn {
                    self.isOn = resp.isOn
                    self.context?.reload()
                }
            })
            .disposed(by: self.disposeBag)
    }
}
