//
//  IMShareLeaderSettingModule.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/12/8.
//

import Foundation
import SKFoundation
import SKResource
import LarkContainer
import RxSwift
import LarkSettingUI
import LarkOpenSetting
import SKCommon

extension IMShareLeaderSettingModule {
    static let moduleProvider: ModuleProvider = { userResolver in
        guard UserScopeNoChangeFG.WWJ.imShareLeaderEnable else {
            DocsLogger.info("IMShareLeaderSettingModule: fg is disabled")
            return nil
        }
        do {
            let userSettings = try userResolver.resolve(assert: CCMUserSettings.self)
            return IMShareLeaderSettingModule(userResolver: userResolver, userSettings: userSettings)
        } catch {
            DocsLogger.error("CCMUserSettings not found from userResolver", error: error)
            return nil
        }
    }
}

private extension CCMCommonSettingsValue {
    var imShareLeaderEnable: Bool {
        guard case let .imShareLeader(state) = self else {
            spaceAssertionFailure("unexpected value type found: \(self)")
            return false
        }
        return state == .auto
    }
}

class IMShareLeaderSettingModule: BaseModule {

    private var switchEnable: Bool
    private let userSettings: CCMUserSettings

    init(userResolver: UserResolver, userSettings: CCMUserSettings) {
        self.userSettings = userSettings
        switchEnable = userSettings[.imShareLeader]?.imShareLeaderEnable ?? false
        super.init(userResolver: userResolver)

        userSettings.fetchCommonSettings(scenes: [.imShareLeader], meta: nil)
            .observeOn(MainScheduler.instance)
            .map { result in
                guard case let .imShareLeader(state) = result[.imShareLeader] else { return false }
                return state == .auto
            }
            .subscribe { [weak self] enable in
                self?.switchEnable = enable
                self?.context?.reload()
            } onError: { error in
                DocsLogger.error("get common setting fail", error: error)
            }
            .disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_GrantViewPermToMymanager_Radio,
                                        isOn: switchEnable,
                                        onSwitch: { [weak self] _, status in
            guard let self, self.switchEnable != status else { return }
            self.updateIMShareLeader(enable: status)
        })
        return SectionProp(items: [item])
    }

    private func updateIMShareLeader(enable: Bool) {
        userSettings.updateCommonSettings(with: [.imShareLeader: .imShareLeader(state: enable ? .auto : .close)], meta: nil)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self else { return }
                guard result[.imShareLeader] == true else {
                    self.context?.reload()
                    DocsLogger.error("update common setting fail without error")
                    return
                }
                // 这里 UI 已经先更新了，可以不 reload
                self.switchEnable = enable
            } onError: { [weak self] error in
                DocsLogger.error("update common setting fail", error: error)
                self?.context?.reload()
            }
            .disposed(by: disposeBag)
    }
}
