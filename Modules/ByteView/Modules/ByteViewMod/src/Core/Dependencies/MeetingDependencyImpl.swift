//
//  MeetingDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/1.
//

import Foundation
import ByteView
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import LarkContainer
import EEAtomic
import LarkAccountInterface
import LarkShortcut

extension Logger {
    static let dependency = getLogger("Dependency")
}

final class MeetingDependencyImpl: MeetingDependency {
    let userResolver: UserResolver
    let account: AccountInfo
    let setting: UserSettingManager
    let httpClient: HttpClient
    var router: RouteDependency { LarkRouteDependency(userResolver: self.userResolver) }
    var heimdallr: HeimdallrDependency { HeimdallrDependencyImpl() }

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.account = try userResolver.resolve(assert: AccountInfo.self)
        self.setting = try userResolver.resolve(assert: UserSettingManager.self)
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
    }

    lazy var lark: LarkDependency = {
        do {
            return try userResolver.resolve(assert: LarkDependency.self)
        } catch {
            Logger.dependency.error("resolve LarkDependency failed, \(error)")
            return DefaultLarkDependency(userResolver: userResolver)
        }
    }()

    lazy var perfMonitor: ByteView.PerfMonitorDependency = PerfMonitorDependencyImpl()

    var storage: LocalStorage {
        LocalStorageImpl(space: .user(id: userResolver.userID))
    }

    var globalStorage: LocalStorage {
        LocalStorageImpl(space: .global)
    }

    var calendar: CalendarDependency {
        #if CalendarMod
        return CalendarDependencyImpl(userResolver: userResolver)
        #else
        return DefaultCalendarDependency()
        #endif
    }

    var messenger: ByteView.MessengerDependency {
        #if MessengerMod
        return MessengerDependencyImpl(userResolver: userResolver)
        #else
        return DefaultMessengerDependency()
        #endif
    }

    var minutes: MinutesDependency {
        #if MinutesMod
        return MinutesDependencyImpl(userResolver: userResolver)
        #else
        return DefaultMinutesDependency()
        #endif
    }

    var live: LiveDependency {
        #if LarkLiveMod
        return LiveDependencyImpl(userResolver: userResolver)
        #else
        return DefaultLiveDependency()
        #endif
    }

    lazy var ccm: CCMDependency = {
        #if CCMMod
        return CCMDependencyImpl(userResolver: userResolver)
        #else
        return DefaultCCMDependency()
        #endif
    }()

    var myAI: MyAIDependency {
        #if MessengerMod
        return MyAIDependencyImpl(userResolver: userResolver)
        #else
        return DefaultMyAIDependency()
        #endif
    }

    var shortcut: ShortcutService? {
        try? userResolver.resolve(assert: ShortcutService.self)
    }
}
