//
//  UserFocusState.swift
//  EEAtomic
//
//  Created by Hayden Wang on 2021/9/8.
//

import UIKit
import RustPB
import LarkFoundation
import LarkFocusInterface

// MARK: UserFocusType

/// 自定义模式类型
///
/// ```
/// enum UserFocusType {
///     case unknown   = 0  // 未知
///     case custom    = 1  // 自定义状态
///     case noDisturb = 2  // 请勿打扰
///     case inMeeting = 3  // 会议中
///     case onLeave   = 4  // 请假中
///     case notCustom = 5  // 非自定义状态
/// }
/// ```
public typealias UserFocusType = RustPB.Contact_V1_UserCustomStatus.TypeEnum

/// 自定义状态类型 V2
///
/// ```
/// enum TypeV2: SwiftProtobuf.Enum {
///     case unknownV2 = 0
///     case systemV2  = 1  // 系统状态
///     case commonV2  = 2  // 普通状态
///     case customV2  = 3  // 自定义状态
/// }
/// ```
public typealias UserFocusTypeV2 = RustPB.Contact_V1_UserCustomStatus.TypeV2

// MARK: - UserFocusStatus

/// 用户的个人状态
///
/// ```
/// struct UserFocusStatus {
///     var id: Int64
///     var type: UserFocusType
///     var title: String
///     var iconKey: String
///     var effectiveInterval: FocusEffectiveTime
///     var isNotDisturbMode: Bool
///     var lastSelectedDuration: FocusDurationType   // 上次选择的开启时间
///     var lastCustomizedEndTime: Int64              // 上次选择的自定义时间
///     var syncSettings: Dictionary<Int64, Bool>     // 状态同步设置
///     var orderWeight: Int32                        // 状态展示排序依据
///     var displayPriority: Int32                    // 状态生效优先级（小的优先级高）
///     var eventName: String                         // 服务端下发的埋点名称
/// }
/// ```
public typealias UserFocusStatus = RustPB.Contact_V1_UserCustomStatus

public extension UserFocusStatus {

    /// 是否是系统默认状态（请勿打扰、会议中、请假中），默认状态不可删除，且不可修改名称图标
    var isDefault: Bool {
        typeV2 != .customV2
    }

    /// 是否有同步设置（目前只有会议中、请假中两个默认状态有同步设置）
    var hasSyncSettings: Bool {
        !syncSettings.isEmpty
    }

    var isActive: Bool {
        // 判断生效时间段的格式是否合法
        guard effectiveInterval.isValid else { return false }
        // 判断当前时间是否属于生效时间段
        let curTime = FocusUtils.shared.currentServerTime
        return curTime >= effectiveInterval.startTime
            && curTime <= effectiveInterval.endTime
    }

    /// 用户自定义状态
    static let custom: UserFocusStatus = {
        var status = UserFocusStatus()
        status.type = .custom
        status.typeV2 = .customV2
        status.eventName = "customized"
        return status
    }()
}

public extension Array where Element == UserFocusStatus {

    var topActive: Element? {
        self.filter({ $0.isActive })
            .sorted(by: { $0.effectiveInterval.startTime > $1.effectiveInterval.startTime })
            .sorted(by: { $0.displayPriority < $1.displayPriority })
            .first
    }

    func ordered() -> [Element] {
        return self.sorted(by: { $0.orderWeight < $1.orderWeight })
    }
}

extension String {

    func toImage() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 40)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// 遵循 FocusStatus 协议，实现 Chatter / User 通用
extension UserFocusStatus: FocusStatus {}

extension UserFocusStatus {

    /// 系统自动状态需要分栏展示在上部
    var isSystemStatus: Bool {
        return typeV2 == .systemV2
    }

    /// 用户自己创建的个人状态
    var isCustomStatus: Bool {
        return typeV2 == .customV2
    }

    /// 是否可以修改或删除（仅自己创建的状态可以修改删除）
    var canEdit: Bool {
        return typeV2 == .customV2
    }

    /// 系统状态是否在生效期间内（仅对 typeV2 == .systemV2 有效）
    var isInEffectivePeriod: Bool {
        guard typeV2 == .systemV2 else { return false }
        return systemValidInterval.isActive
    }
}

// MARK: - Debug Description

extension UserFocusStatus: CustomStringConvertible {

    public var description: String {
        return "<\(title.desensitized()), id: \(id), time: \(effectiveInterval), silent: \(isNotDisturbMode)>"
    }
}
