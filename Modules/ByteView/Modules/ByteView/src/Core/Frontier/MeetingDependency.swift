//
//  MeetingDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/1.
//

import Foundation
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork
import LarkShortcut

public protocol MeetingDependency: AnyObject {
    var account: AccountInfo { get }
    var setting: UserSettingManager { get }
    var httpClient: HttpClient { get }
    var router: RouteDependency { get }
    var storage: LocalStorage { get }
    var lark: LarkDependency { get }
    var calendar: CalendarDependency { get }
    var messenger: MessengerDependency { get }
    var minutes: MinutesDependency { get }
    var live: LiveDependency { get }
    var ccm: CCMDependency { get }
    var heimdallr: HeimdallrDependency { get }
    var myAI: MyAIDependency { get }
    var shortcut: ShortcutService? { get }

    /// 几个版本后废弃
    var globalStorage: LocalStorage { get }
    var perfMonitor: PerfMonitorDependency { get }
}
