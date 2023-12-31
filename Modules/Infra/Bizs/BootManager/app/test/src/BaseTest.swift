//
//  BaseTest.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/15.
//

import UIKit
import Foundation
import XCTest
import Swinject
@testable import BootManager

var result: [String] = []

class BaseTest: XCTestCase {

    override func setUp() {
        super.setUp()
        BootManager.isNewBoot = false
        TaskRegistry.clear()
        TaskFactory.register()
        BootManager.shared.dependency = BootManagerDependencyImpl()
        BootManager.shared.workplaces.values.forEach { (workspace) in
            BootManager.shared.finished(workspace: workspace)

        }
        result.removeAll()
        BootManager.shared.context.reset()
        shouldPrivacyCheckTask = false
        shouldFastLoginTask = false
        shouldLaunchBlockRequestCheckTask = false
        shouldGodoCreateTeam = false
        shouldGodoLogin = false
        shouldSwitchAccountFailure = false
        BootManager.shared.context.isFastLogin = true
        BootManager.shared.workplaces.removeAll()
        BootManager.shared.connectedContexts.removeAll()
        BootManager.shared.globalTaskRepo.onceTasks.removeAll()
        BootManager.shared.globalTaskRepo.onceUserScopeTasks.removeAll()
    }
}

class NewBaseTest: XCTestCase {
    override func setUp() {
        super.setUp()
        BootManager.isNewBoot = true
        BootTaskRegistry.clear()
        BootTaskFactory.register()
        NewBootManager.shared.dependency = BootManagerDependencyImpl()
        NewBootManager.shared.launchers.values.forEach { (workspace) in
            NewBootManager.shared.finished(launcher: workspace)

        }
        result.removeAll()
        NewBootManager.shared.context.reset()
        shouldPrivacyCheckTask = false
        shouldFastLoginTask = false
        shouldLaunchBlockRequestCheckTask = false
        shouldGodoCreateTeam = false
        shouldGodoLogin = false
        shouldSwitchAccountFailure = false
        NewBootManager.shared.context.isFastLogin = true
        NewBootManager.shared.launchers.removeAll()
        NewBootManager.shared.connectedContexts.removeAll()
        NewBootManager.shared.globalTaskRepo.onceTasks.removeAll()
        NewBootManager.shared.globalTaskRepo.onceUserScopeTasks.removeAll()
    }
}

extension String {
    var checkout: String {
        return self + "->"
    }
}

class BootManagerDependencyImpl: BootDependency {
    func tabStringToBizScope(_ tabString: String) -> BizScope? {
        return nil
    }

    func launchOptionToBizScope(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope? {
        return nil
    }

    var eventObserver: EventMonitorProtocol?
}
