//
//  SetupLauncherTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/7.
//

import UIKit
import Foundation
import BootManager
import LarkPerf
import EENavigator

final class SetupLauncherTask: FlowBootTask, Identifiable {

    static var identify = "SetupLauncherTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        context.window?.backgroundColor = UIColor.ud.staticBlack

        AppStartupMonitor.shared.isBackgroundLaunch = UIApplication.shared.applicationState == .background
        // 暂时不知道此方法的作用，先搬过来
        self.hotLoadLKSplitVCDelegate()
    }

    /// EENavigator里有些方法依赖了当前UI架构的判断（如TopMost），
    /// 但目前iPad采用了自定义的LKSoplitViewController2，
    /// EENavigator找不到LKSoplitViewController2
    ///
    /// 为了解除 EENavigator 和 LarKUIKit 的依赖，
    /// 在EENavigator内声明了一个 Delegate：LKSplitVCDelegate,
    ///  然后在外面进行了实现；但是由于文件编译顺序，可能出现EENavigator找不到实现的情况
    ///
    /// 这里需要在足够早的时机先加载一下 LKSplitVCDelegate 的实现
    func hotLoadLKSplitVCDelegate() {
        let vc = UIViewController() as? LKSplitVCDelegate
        _ = vc?.lkTabIdentifier
        _ = vc?.lkTopMost
    }
}
