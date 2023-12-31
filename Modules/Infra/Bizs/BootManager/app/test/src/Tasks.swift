//
//  Tasks.swift
//  BootManagerDev
//
//  Created by KT on 2020/6/12.
//

import Foundation
@testable import BootManager
import RunloopTools

class TaskFactory {
    static func register() {
        BootManager.register(SetupLoggerTask.self)
        BootManager.register(SetupSlardarTask.self)
        BootManager.register(SetupTeaTask.self)
        BootManager.register(PrivacyBizTask.self)
        BootManager.register(SetupMainTabTask.self)
        BootManager.register(SetupURLProtocolTask.self)
        BootManager.register(SetupTroubleKillerTask.self)
        BootManager.register(UtilsTask.self)
        BootManager.register(DebugTask.self)
        BootManager.register(ForceTouchTask.self)
        BootManager.register(SetupUATask.self)
        BootManager.register(SetupDocsTask.self)
        BootManager.register(SetupVCTask.self)
        BootManager.register(SetupOpenPlatformTask.self)
        BootManager.register(SetupMailTask.self)
        BootManager.register(SetupBDPTask.self)
        BootManager.register(SwitchAccountTask.self)
        BootManager.register(ClearCookieTask.self)
        BootManager.register(LaunchGuideTask.self)
        BootManager.register(CreatTeamTask.self)
        BootManager.register(LoginSuccessTask.self)
        BootManager.register(LoginTask.self)
        BootManager.register(PrivacyCheckTask.self)
        BootManager.register(FastLoginTask.self)
        BootManager.register(LaunchBlockRequestCheckTask.self)
        BootManager.register(SettingBundleTask.self) { SettingBundleTask() }
        BootManager.register(CalendarPreloadTask.self)
    }
}

open class TestFlowLaunchTask: FlowLaunchTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class TestAsyncLaunchTask: AsyncLaunchTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class TestBranchLaunchTask: BranchLaunchTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class TestFirstTabPreloadLaunchTask: FirstTabPreloadLaunchTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}

class SetupLoggerTask: TestFlowLaunchTask, Identifiable { static var identify = "SetupLoggerTask" }
class SetupSlardarTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupSlardarTask"
    override var deamon: Bool { return true }
}
class SetupTeaTask: TestFlowLaunchTask, Identifiable { static var identify = "SetupTeaTask" }
class SetupMainTabTask: TestFlowLaunchTask, Identifiable { static var identify = "SetupMainTabTask" }
class UtilsTask: TestFlowLaunchTask, Identifiable { static var identify = "UtilsTask" }
class SetupABTestTask: TestFlowLaunchTask, Identifiable { static var identify = "SetupABTestTask" }
class SettingBundleTask: TestFlowLaunchTask, Identifiable { static var identify = "SettingBundleTask" }
class DebugTask: TestFlowLaunchTask, Identifiable { static var identify = "DebugTask" }
class ForceTouchTask: TestFlowLaunchTask, Identifiable { static var identify = "ForceTouchTask" }
class SetupUATask: TestFlowLaunchTask, Identifiable { static var identify = "SetupUATask" }
class ClearCookieTask: TestFlowLaunchTask, Identifiable { static var identify = "ClearCookieTask" }
class LoginSuccessTask: TestFlowLaunchTask, Identifiable { static var identify = "LoginSuccessTask" }

// Delay
class SetupDocsTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupDocsTask"
    override var scope: Set<BizScope> { return [.docs] }
}
class SetupMailTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupMailTask"
    override var scope: Set<BizScope> { return [.mail] }
    override var delayType: DelayType? { return .delayForIdle }
}
class SetupVCTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupVCTask"
    override var scope: Set<BizScope> { return [.vc] }
}
class SetupOpenPlatformTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupOpenPlatformTask"
    override var scope: Set<BizScope> { return [.openplatform] }
    override var delayScope: Scope? { return .container }
}
class SetupBDPTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupBDPTask"
    override var scope: Set<BizScope> { return [.openplatform, .docs] }
}

class PrivacyBizTask: TestAsyncLaunchTask, Identifiable { static var identify = "PrivacyBizTask" }
class CreatTeamTask: TestAsyncLaunchTask, Identifiable { static var identify = "CreatTeamTask" }
class LoginTask: TestAsyncLaunchTask, Identifiable { static var identify = "LoginTask" }

var shouldSwitchAccountFailure = false
var shouldWaiteResponse = true
class SwitchAccountTask: TestAsyncLaunchTask, Identifiable {
    static var identify = "SwitchAccountTask"
    override func execute(_ context: BootContext) {
        super.execute(context)
        assert(Thread.isMainThread, "expect in main thread")
        if shouldSwitchAccountFailure {
            BootManager.shared.login()
        }
    }
}

class SetupTroubleKillerTask: TestFlowLaunchTask, Identifiable {
    static var identify = "SetupTroubleKillerTask"
    override var scheduler: Scheduler {
        return .async
    }

    override func execute(_ context: BootContext) {
        assert(!Thread.isMainThread, "expect in async")
    }
}

class SetupURLProtocolTask: TestAsyncLaunchTask, Identifiable {
    static var identify = "SetupURLProtocolTask"
    override var scheduler: Scheduler {
        return .concurrent
    }
    override func execute(_ context: BootContext) {
        super.execute(context)
        assert(!Thread.isMainThread, "expect in async")
    }
}

class CalendarPreloadTask: TestFirstTabPreloadLaunchTask, Identifiable {
    static var identify = "CalendarPreloadTask"

    override var firstTabURLString: String { return "calendar" }
}

class BootTaskFactory {
    static func register() {
        NewBootManager.register(NewSetupLoggerTask.self)
        NewBootManager.register(NewSetupSlardarTask.self)
        NewBootManager.register(NewSetupTeaTask.self)
        NewBootManager.register(NewPrivacyBizTask.self)
        NewBootManager.register(NewSetupMainTabTask.self)
        NewBootManager.register(NewSetupURLProtocolTask.self)
        NewBootManager.register(NewSetupTroubleKillerTask.self)
        NewBootManager.register(NewUtilsTask.self)
        NewBootManager.register(NewDebugTask.self)
        NewBootManager.register(NewForceTouchTask.self)
        NewBootManager.register(NewSetupUATask.self)
        NewBootManager.register(NewSetupDocsTask.self)
        NewBootManager.register(NewSetupVCTask.self)
        NewBootManager.register(NewSetupOpenPlatformTask.self)
        NewBootManager.register(NewSetupMailTask.self)
        NewBootManager.register(NewSetupBDPTask.self)
        NewBootManager.register(NewSwitchAccountTask.self)
        NewBootManager.register(NewClearCookieTask.self)
        NewBootManager.register(NewLaunchGuideTask.self)
        NewBootManager.register(NewCreatTeamTask.self)
        NewBootManager.register(NewLoginSuccessTask.self)
        NewBootManager.register(NewLoginTask.self)
        NewBootManager.register(NewPrivacyCheckTask.self)
        NewBootManager.register(NewFastLoginTask.self)
        NewBootManager.register(NewLaunchBlockRequestCheckTask.self)
        NewBootManager.register(NewSettingBundleTask.self) { NewSettingBundleTask() }
        NewBootManager.register(NewCalendarPreloadTask.self)
        NewBootManager.register(SetupGuideTask.self)
    }
}

open class NewTestFlowLaunchTask: FlowBootTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class NewTestAsyncLaunchTask: AsyncBootTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class NewTestBranchLaunchTask: BranchBootTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}
open class NewTestFirstTabPreloadLaunchTask: FirstTabPreloadBootTask {
    open override func execute(_ context: BootContext) {
        result.append(self.identify)
    }
}

class NewSetupLoggerTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupLoggerTask" }
class NewSetupSlardarTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupSlardarTask"
    override var deamon: Bool { return true }
}
class NewSetupTeaTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupTeaTask" }
class NewSetupMainTabTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupMainTabTask" }
class NewUtilsTask: NewTestFlowLaunchTask, Identifiable { static var identify = "UtilsTask" }
class NewSetupABTestTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupABTestTask" }
class NewSettingBundleTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SettingBundleTask" }
class NewDebugTask: NewTestFlowLaunchTask, Identifiable { static var identify = "DebugTask" }
class NewForceTouchTask: NewTestFlowLaunchTask, Identifiable { static var identify = "ForceTouchTask" }
class NewSetupUATask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupUATask" }
class NewClearCookieTask: NewTestFlowLaunchTask, Identifiable { static var identify = "ClearCookieTask" }
class NewLoginSuccessTask: NewTestFlowLaunchTask, Identifiable { static var identify = "LoginSuccessTask" }
class SetupGuideTask: NewTestFlowLaunchTask, Identifiable { static var identify = "SetupGuideTask" }

// Delay
class NewSetupDocsTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupDocsTask"
    override var scope: Set<BizScope> { return [.docs] }
}
class NewSetupMailTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupMailTask"
    override var scope: Set<BizScope> { return [.mail] }
    override var delayType: DelayType? { return .delayForIdle }
}
class NewSetupVCTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupVCTask"
    override var scope: Set<BizScope> { return [.vc] }
}
class NewSetupOpenPlatformTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupOpenPlatformTask"
    override var scope: Set<BizScope> { return [.openplatform] }
    override var delayScope: Scope? { return .container }
}
class NewSetupBDPTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupBDPTask"
    override var scope: Set<BizScope> { return [.openplatform, .docs] }
}

class NewPrivacyBizTask: NewTestAsyncLaunchTask, Identifiable { static var identify = "PrivacyBizTask" }
class NewCreatTeamTask: NewTestAsyncLaunchTask, Identifiable { static var identify = "CreatTeamTask" }
class NewLoginTask: NewTestAsyncLaunchTask, Identifiable { static var identify = "LoginTask" }

class NewSwitchAccountTask: NewTestAsyncLaunchTask, Identifiable {
    static var identify = "SwitchAccountTask"
    override func execute(_ context: BootContext) {
        super.execute(context)
        assert(Thread.isMainThread, "expect in main thread")
        if shouldSwitchAccountFailure {
            NewBootManager.shared.login()
        }
    }
}

class NewSetupTroubleKillerTask: NewTestFlowLaunchTask, Identifiable {
    static var identify = "SetupTroubleKillerTask"
    override var scheduler: Scheduler {
        return .async
    }

    override func execute(_ context: BootContext) {
        assert(!Thread.isMainThread, "expect in async")
    }
}

class NewSetupURLProtocolTask: NewTestAsyncLaunchTask, Identifiable {
    static var identify = "SetupURLProtocolTask"
    override var waiteResponse: Bool {
        return shouldWaiteResponse
    }
    override func execute(_ context: BootContext) {
        super.execute(context)
    }
}

class NewCalendarPreloadTask: NewTestFirstTabPreloadLaunchTask, Identifiable {
    static var identify = "CalendarSetupTask"

    override var firstTabURLString: String { return "calendar" }
}
