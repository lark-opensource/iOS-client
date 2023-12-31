//
//  LeaderLinkShareModule.swift
//  SKCommon
//
//  Created by peilongfei on 2023/7/18.
//  

import SKFoundation
import SKResource
import LarkOpenSetting
import LarkContainer
import RxSwift
import LarkSettingUI
import SwiftyJSON
import SKCommon

let leaderShareLinkModuleProvider: ModuleProvider = { userResolver in
    guard UserScopeNoChangeFG.PLF.managerDefaultviewSubordinateEnable else {
        DocsLogger.info("LeaderShareLinkModule: fg is disabled")
        return nil
    }
    return LeaderShareLinkModule(userResolver: userResolver)
}

final class LeaderShareLinkModule: BaseModule {

    private let leaderShareLinkKey = "leaderShareLinkKey"
    private var isLeaderViewEnabled: Bool = false

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        let userId = User.current.info?.userID ?? ""
        self.isLeaderViewEnabled = CCMKeyValue.userDefault(userId).bool(forKey: leaderShareLinkKey)
        WorkspaceManagementAPI.getCommonSetting(scenes: [.allowLeaderView], meta: nil)
            .observeOn(MainScheduler.instance)
            .map({ result in
                guard case let .allowLeaderView(enable) = result[.allowLeaderView] else { return false }
                return enable
            })
            .subscribe(onSuccess: { [weak self] enable in
                guard let self = self else { return }
                self.isLeaderViewEnabled = enable
                self.context?.reload()
            }, onError: { error in
                DocsLogger.error("LeaderShareLinkModule: get common setting fail", error: error)
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.SKResource.Lark_PermSettings_Docs_AllowManagerAccess_Checkbox,
                                        isOn: self.isLeaderViewEnabled,
                                        onSwitch: { [weak self] _, status in
            guard let self = self, self.isLeaderViewEnabled != status else { return }
            self.updateLeaderShareLink(enable: status)
        })
        return SectionProp(items: [item])
    }

    private func updateLeaderShareLink(enable: Bool) {
        WorkspaceManagementAPI.updaetCommonSetting(settings: [.allowLeaderView: !self.isLeaderViewEnabled], meta: nil)
            .observeOn(MainScheduler.instance)
            .map({ result in
                return result[.allowLeaderView] == true
            })
            .subscribe(onSuccess: { [weak self] flag in
                guard let self = self else { return }
                if flag {
                    self.isLeaderViewEnabled = enable
                    let userId = User.current.info?.userID ?? ""
                    CCMKeyValue.userDefault(userId).set(self.isLeaderViewEnabled, forKey: self.leaderShareLinkKey)
                } else {
                    DocsLogger.error("LeaderShareLinkModule: updaet common setting fail")
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("LeaderShareLinkModule: updaet common setting fail", error: error)
                self.context?.reload()
            }).disposed(by: disposeBag)
    }
}
