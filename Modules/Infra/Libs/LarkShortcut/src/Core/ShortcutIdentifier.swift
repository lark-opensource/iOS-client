//
//  ShortcutIdentifier.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation

/// 为了方便管理ShortcutAction.Identifier，代码里所有的Identifier声明在这里，并以Scope分区
/// 使用ShortcutAction.Identifier的地方可以写.vc(.startRecord)
public extension ShortcutAction.Identifier {
    static let vc = VcAction.self
}

// refact by 5.9 macro...

/// 视频会议的Actions
public struct VcAction: ShortcutActionIdentifierConvertible {
    static let scope = "vc"
}

public extension VcAction {
    /// 开启录制
    static let startRecord = id("startRecord")
    /// 大窗/小窗会中window，仅对非忙线会议有效
    static let floatWindow = id("floatWindow")
    /// 用户主动离会（非结束会议）
    static let leaveMeeting = id("leaveMeeting")
    /// pending到onTheCall
    static let waitingOnTheCall = id("waitingOnTheCall")
}

/// 方便scope创建ShortcutAction.Identifier
protocol ShortcutActionIdentifierConvertible/*: RawRepresentable */ {
    static var scope: String { get }
}

extension ShortcutActionIdentifierConvertible {
    static func id(_ rawValue: String) -> ShortcutAction.Identifier {
        ShortcutAction.Identifier("\(scope).\(rawValue)")
    }
}
