//
//  LarkGuideInterface.swift
//  LarkGuide
//
//  Created by zhenning on 2020/08/12.
//

import UIKit
import Foundation
import ServerPB
import RustPB
import RxSwift
import LarkGuideUI
import LarkContainer

public typealias GetUserGuideRequest = RustPB.Onboarding_V1_GetUserGuideRequest
public typealias GetUserGuideResponse = RustPB.Onboarding_V1_GetUserGuideResponse
public typealias PostUserConsumingGuideRequest = RustPB.Onboarding_V1_PostUserConsumingGuideRequest
public typealias PostUserConsumingGuideResponse = RustPB.Onboarding_V1_PostUserConsumingGuideResponse
public typealias UserGuideViewAreaPair = RustPB.Onboarding_V1_UserGuideViewAreaPair
public typealias UserGuideViewArea = RustPB.Onboarding_V1_Area
public typealias UserGuideInfo = RustPB.Onboarding_V1_UserGuideInfo
// 任务队列管理
public typealias GuideConfigProvider = (() -> GuideUIType)
public typealias TaskDismissHandler = (() -> Void)
public typealias TaskDidAppearHandler = ((_ guideKey: String) -> Void)
public typealias TaskWillAppearHandler = ((_ guideKey: String) -> Void)

public protocol UserGuideAPI {

    /// 获取用户引导配置列表
    ///
    /// - Returns: 用户引导可视区域配置列表
    func fetchUserGuide() -> Observable<[UserGuideViewAreaPair]>

    /// 获取CCM用户引导信息
    func getCCMUserGuide() -> Observable<[ServerPB_Guide_UserGuideViewAreaPair]>

    /// 同步用户引导状态
    ///
    /// - Parameter guideKeys: 已展示的用户引导Key列表
    /// - Returns: void
    func postUserConsumingGuide(guideKeys: [String]) -> Observable<Void>
}

// MARK: - Struct
/// 多设备会实时同步引导key的变化
public struct PushUserGuideUpdatedMessage: PushMessage {
    public let pairs: [Onboarding_V1_UserGuideViewAreaPair]

    public init(pairs: [Onboarding_V1_UserGuideViewAreaPair]) {
        self.pairs = pairs
    }
}

struct GuideViewAreaInfo: Codable {
    public var key: String
    public var priority: Int64
    init(key: String,
         priority: Int64) {
        self.key = key
        self.priority = priority
    }
}

/// 引导信息
struct GuideKeyInfo: Codable {
    let key: String
    // 是否可以展示（未展示过情况下）
    var canShow: Bool
    // 权重
    let keyOrder: Int64
    let viewArea: GuideViewAreaInfo
    // 队列中的优先级
    var priority: Int64 {
        return self.keyOrder + self.viewArea.priority
    }

    enum CodingKeys: String, CodingKey {
        case key = "key"
        case canShow = "can_show"
        case keyOrder = "key_order"
        case viewArea = "view_area"
        case priority = "priority"
    }

    init(key: String,
         canShow: Bool,
         keyOrder: Int64,
         viewArea: GuideViewAreaInfo) {
        self.key = key
        self.canShow = canShow
        self.keyOrder = keyOrder
        self.viewArea = viewArea
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(canShow, forKey: .canShow)
        try container.encode(keyOrder, forKey: .keyOrder)
        try container.encode(viewArea, forKey: .viewArea)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? container.decode(String.self, forKey: .key)) ?? ""
        canShow = (try? container.decode(Bool.self, forKey: .canShow)) ?? false
        keyOrder = (try? container.decode(Int64.self, forKey: .keyOrder)) ?? 0
        viewArea = (try? container.decode(GuideViewAreaInfo.self, forKey: .viewArea)) ?? GuideViewAreaInfo(key: "", priority: 0)
    }
}

public struct GuideTask {
    let key: String
    let priority: Int64
    let viewAreaKey: String
    let guideConfigProvider: GuideConfigProvider
    // server 下发是否可以展示
    var canShow: Bool = false
    var canReplay: Bool? = false
    var isMock: Bool? = false
    var customWindow: UIWindow?
    var viewTapHandler: GuideViewTapHandler?
    var dismissHandler: TaskDismissHandler?
    var didAppearHandler: TaskDidAppearHandler?
    var willAppearHandler: TaskWillAppearHandler?

    init(key: String,
         priority: Int64,
         viewAreaKey: String,
         guideConfigProvider: @escaping GuideConfigProvider,
         canShow: Bool = false,
         canReplay: Bool? = false,
         isMock: Bool? = false,
         customWindow: UIWindow? = nil,
         viewTapHandler: GuideViewTapHandler? = nil,
         dismissHandler: TaskDismissHandler? = nil,
         didAppearHandler: TaskDidAppearHandler? = nil,
         willAppearHandler: TaskWillAppearHandler? = nil) {
        self.key = key
        self.priority = priority
        self.viewAreaKey = viewAreaKey
        self.guideConfigProvider = guideConfigProvider
        self.canShow = canShow
        self.canReplay = canReplay
        self.isMock = isMock
        self.customWindow = customWindow
        self.viewTapHandler = viewTapHandler
        self.dismissHandler = dismissHandler
        self.didAppearHandler = didAppearHandler
        self.willAppearHandler = willAppearHandler
    }
}
