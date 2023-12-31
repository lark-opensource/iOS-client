//
//  AppLockSettingTimerSelectModule.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/14.
//

import LarkContainer
import LarkOpenSetting
import LarkSettingUI
import LarkSecurityComplianceInfra

typealias AppLockSettingTimerSelectModuleHandler = (_ flag: Int) -> Void

final class AppLockSettingTimerSelectVC: SettingViewController, UserResolverWrapper {

    let handler: AppLockSettingTimerSelectModuleHandler
    let userResolver: UserResolver

    init(resolver: UserResolver, handler: @escaping AppLockSettingTimerSelectModuleHandler) {
        self.userResolver = resolver
        self.handler = handler
        super.init()

        navTitle = BundleI18n.AppLock.Lark_Screen_LockTime
        patternsProvider = { return [
            .wholeSection(pair: PatternPair("appLockSettingTimerSelect", ""))
        ]}
        registerModule(AppLockSettingTimerSelectModule(userResolver: userResolver), key: "appLockSettingTimerSelect")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 五个可选择的时间选项
final class AppLockSettingTimerSelectModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?

    private let timerFlags: [Int] = [0, 1, 5, 10, 15]

    override func createSectionProp(_ key: String) -> SectionProp? {
        var items = [NormalCellProp]()
        items = timerFlags.map { flag in
            NormalCellProp(title: appLockSettingService?.configInfo.timerFlagDesc(flag: flag) ?? "",
                           accessories: [.checkMark(isShown: appLockSettingService?.configInfo.timerFlag == flag)],
                           onClick: { [weak self] _ in
                guard let self else { return }
                self.triggerTimerSelectAction(flag: flag)
                self.context?.reload()
            })
        }
        return SectionProp(items: items)
    }

    private func triggerTimerSelectAction(flag: Int) {
        // 选中时间后退出
        guard let targetViewController = self.context?.vc as? AppLockSettingTimerSelectVC else { return }
        targetViewController.popSelf(animated: true, completion: { [weak targetViewController] in
            targetViewController?.handler(flag)
            SCMonitor.info(business: .app_lock, eventName: "set_time", category: ["time": "\(flag)"])
        })
    }
}
