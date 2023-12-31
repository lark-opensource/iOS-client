//
//  MagicShareModels.swift
//  ByteView
//
//  Created by chentao on 2020/4/9.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

indirect enum InMeetFollowViewModelStatus: Equatable {
    case free(document: MagicShareDocument, newShare: Bool)
    case following(document: MagicShareDocument, newShare: Bool)
    case sharing(document: MagicShareDocument)
    case shareScreenToFollow
    case none

    func isSharing() -> Bool {
        if case .sharing = self {
            return true
        } else {
            return false
        }
    }

    func isFollowing() -> Bool {
        switch self {
        case .following:
            return true
        default:
            return false
        }
    }

    var msShareStatus: MSShareStatus {
        switch self {
        case .sharing:
            return .sharing
        case .following:
            return .following
        case .free:
            return .free
        case .shareScreenToFollow:
            return .shareScreenToFollow
        default:
            return .free
        }
    }
}

struct InMeetFollowEvent {
    let action: Action
    let document: MagicShareDocument
    let status: MagicShareDocumentStatus
    let createSource: MagicShareRuntimeCreateSource
    let clearStoredPos: Bool

    enum Action {
        case push
        case popTo
        case replace
        case updateStatus
        case reload
    }
}

extension Array where Element == FollowState {
    func validWebDatas() -> [FollowWebData] {
        return self.filter({ $0.dataType == .followWebData }).compactMap({ $0.webData })
    }
}

extension Array where Element == FollowPatch {
    func validWebDatas() -> [FollowWebData] {
        return self.filter({ $0.dataType == .followWebData }).compactMap({ $0.webData })
    }
}

/// 主/被共享人位置变化回调数据结构
struct MagicShareDocumentLocation {
    let space: String
    let x: CGFloat
    let y: CGFloat
}

extension MagicShareDocumentLocation: Decodable {
    enum CodingKeys: String, CodingKey {
        case space
        case x
        case y
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        space = try values.decode(String.self, forKey: .space)
        x = try values.decode(CGFloat.self, forKey: .x)
        y = try values.decode(CGFloat.self, forKey: .y)
    }
}

struct MagicSharePresenterFollowerLocation {
    let presenter: MagicShareDocumentLocation
    let follower: MagicShareDocumentLocation
}

extension MagicSharePresenterFollowerLocation: Decodable {
    enum CodingKeys: String, CodingKey {
        case presenter
        case follower
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        presenter = try values.decode(MagicShareDocumentLocation.self, forKey: .presenter)
        follower = try values.decode(MagicShareDocumentLocation.self, forKey: .follower)
    }
}

struct MagicShareRelativePosition: Decodable {
    let angle: Int
    let pointerVisible: Bool
    let visible: Bool

    enum CodingKeys: String, CodingKey {
        case angle
        case pointerVisible
        case visible
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        angle = try values.decode(Int.self, forKey: .angle)
        pointerVisible = try values.decode(Bool.self, forKey: .pointerVisible)
        visible = try values.decode(Bool.self, forKey: .visible)
    }
}

enum MagicShareOperation: Equatable {
    /// 打开了链接，包含Docs文档、其他类型的文档、外部链接等
    case openUrl(url: String)

    /// 从A文档自动跳转到wiki链接，需要从MS记录的[VC]中移除A
    case openMoveToWikiUrl(wikiUrl: String, originUrl: String)

    /// 打开了链接，在正式打开前需要执行handler的一些预操作
    case openUrlWithHandlerBeforeOpen(url: String, handler: () -> Void)

    /// 文档的名字有变化
    case onTitleChange(title: String)

    /// 显示UserProfile页面，VC侧小窗后再在Lark上打开
    case showUserProfile(userId: String)

    /// VC小窗，并获取可以push的VC
    case setFloatingWindow(getFromVCHandler: (UIViewController?) -> Void)

    /// 打开/关闭附件
    case openOrCloseAttachFile(isOpen: Bool)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.openUrl(lUrl), .openUrl(url: rUrl)):
            return lUrl == rUrl
        case let (.openMoveToWikiUrl(wikiUrl: lWikiUrl, originUrl: lOriginUrl), .openMoveToWikiUrl(wikiUrl: rWikiUrl, originUrl: rOriginUrl)):
            return lWikiUrl == rWikiUrl && lOriginUrl == rOriginUrl
        case let (.openUrlWithHandlerBeforeOpen(url: lUrl, _), .openUrlWithHandlerBeforeOpen(url: rUrl, _)):
            return lUrl == rUrl
        case let (.onTitleChange(title: lTitle), .onTitleChange(title: rTitle)):
            return lTitle == rTitle
        case let (.showUserProfile(userId: lUserID), .showUserProfile(userId: rUserID)):
            return lUserID == rUserID
        default:
            return false
        }
    }
}

extension FollowShareSubType {

    var isSheetStyle: Bool {
        return [.ccmSheet, .ccmWikiSheet, .ccmBitable].contains(self)
    }

    /// 当前文档类型支持横屏
    /// 判断不包含.ccmPpt类型（ppt支持横屏FG未全量，FG关闭时仅演示模式支持横屏）
    func isLandscapeEnabled(setting: MeetingSettingManager) -> Bool {
        var validType: [FollowShareSubType] = [.ccmSheet, .ccmWikiSheet, .ccmBitable]
        if setting.isMSDocXHorizontalEnabled {
            validType.append(.ccmDocx)
            validType.append(.ccmWikiDocX)
        }
        if setting.isMSMindnoteHorizontalEnabled {
            validType.append(.ccmMindnote)
            validType.append(.ccmWikiMindnote)
        }
        return validType.contains(self)
    }

}

enum MagicShareRuntimeCreateSource: Int {
    case newShare = 0 // 非文档共享状态下，发起新共享
    case reload // 点刷新按钮触发重新加载
    case reShare // 重新共享了文档，需要区分是否与上次为同一共享人
    case becomePresenter // 点“成为共享人”（不触发文档重新加载）
    case toPresenter // 点“转移共享人给别人”
    case popBack // 回退到上一篇文档
    case untracked // 不需要上报的场景
}

// MARK: - 妙享支持增量数据

/// 妙享同步数据，分为State或Patch
protocol FollowSyncDataGenerable {}

extension FollowState: FollowSyncDataGenerable {}

extension FollowPatch: FollowSyncDataGenerable {}

enum MagicShareFollowSyncDataType {
    case state
    case patch
}

/// MS增量发送的额外数据
struct MagicShareMetaJsonObject: Decodable {
    /// 代表时间的ID
    let id: Int64
    /// 代表所属模块的Key
    let stateKey: String

    enum CodingKeys: String, CodingKey {
        case id
        case stateKey
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        stateKey = try values.decode(String.self, forKey: .stateKey)
    }
}
