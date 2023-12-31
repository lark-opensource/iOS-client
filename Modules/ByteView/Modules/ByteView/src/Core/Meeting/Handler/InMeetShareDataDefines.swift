//
//  InMeetShareDataDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/3/20.
//

import Foundation
import ByteViewNetwork

protocol InMeetShareDataListener: AnyObject {
    /// 共享内容变化
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene)
}

extension InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {}
}

enum InMeetShareSceneType: String, Hashable, CustomStringConvertible {
    /// 没有共享
    case none
    /// 自己在共享屏幕
    case selfSharingScreen
    /// 其他人在共享屏幕
    case othersSharingScreen
    /// 妙享（共享文档）
    case magicShare
    /// 投屏转妙享
    case shareScreenToFollow
    /// 共享白板
    case whiteboard

    var description: String { rawValue }
}

struct InMeetShareScene {
    /// 共享场景类型
    var shareSceneType: InMeetShareSceneType
    /// 共享屏幕数据
    var shareScreenData: ScreenSharedData?
    /// 妙享数据
    var magicShareData: MagicShareDocument?
    /// 共享白板数据
    var whiteboardData: WhiteboardInfo?
    /// 投屏转妙享数据
    var shareScreenToFollowData: MagicShareDocument?
    /// 本地投屏
    var isLocalProjection: Bool
}

extension InMeetShareScene: Equatable {
    static func == (lhs: InMeetShareScene, rhs: InMeetShareScene) -> Bool {
        return lhs.shareSceneType == rhs.shareSceneType
        && lhs.shareScreenData == rhs.shareScreenData
        && lhs.magicShareData == rhs.magicShareData
        && lhs.whiteboardData == rhs.whiteboardData
        && lhs.shareScreenToFollowData == rhs.shareScreenToFollowData
        && lhs.isLocalProjection == rhs.isLocalProjection
    }
}

extension InMeetShareScene {

    /// 默认非共享非本地投屏场景
    static let defaultNone = InMeetShareScene(shareSceneType: .none, isLocalProjection: false)

    var isNone: Bool {
        shareSceneType == .none
    }

    var isSelfSharingScreen: Bool {
        shareSceneType == .selfSharingScreen
    }

    var isOthersSharingScreen: Bool {
        shareSceneType == .othersSharingScreen
    }

    var isMagicShare: Bool {
        shareSceneType == .magicShare
    }

    var isShareScreenToFollow: Bool {
        shareSceneType == .shareScreenToFollow
    }

    var isWhiteboard: Bool {
        shareSceneType == .whiteboard
    }

    /// 妙享或者投屏转妙享的文档
    var magicShareDocument: MagicShareDocument? {
        switch shareSceneType {
        case .magicShare: return magicShareData
        case .shareScreenToFollow: return shareScreenToFollowData
        default: return nil
        }
    }

    /// 把当前状态转换成SceneManager的场景
    var contentMode: InMeetSceneManager.ContentMode {
        switch shareSceneType {
        case .othersSharingScreen:
            return .shareScreen
        case .magicShare, .shareScreenToFollow:
            return .follow
        case .whiteboard:
            return .whiteboard
        case .selfSharingScreen:
            return .selfShareScreen
        case .none:
            return isLocalProjection ? .selfShareScreen : .flow
        }
    }

    /// 有人在共享内容
    var isSharingContent: Bool {
        return [.othersSharingScreen, .magicShare, .shareScreenToFollow, .whiteboard, .selfSharingScreen].contains(shareSceneType)
    }

    /// 有人正在共享屏幕
    var isSharingScreen: Bool {
        return shareScreenData?.isSharing == true
    }

    /// 当前共享人，**不区分共享内容类型**
    var sharer: ByteviewUser? {
        if let sharer = shareScreenData?.participant {
            return sharer
        } else if let sharer = whiteboardData?.sharer {
            return sharer
        } else if let sharer = magicShareData?.participantId {
            return ByteviewUser(id: sharer.id, type: sharer.type, deviceId: sharer.deviceId)
        } else {
            return nil
        }
    }

    /// 共享屏幕的用户identifier
    var sharingScreenSharerIdentifier: String? {
        return shareScreenData?.identifier
    }

    /// 有人正在共享文档
    var isSharingDocument: Bool {
        return magicShareData?.urlString.isEmpty == false
    }

    /// 共享文档的用户identifier
    var sharingDocumentSharerIdentifier: String? {
        return magicShareData?.identifier
    }

    /// 有人正在共享白板
    var isSharingWhiteboard: Bool {
        return whiteboardData?.whiteboardIsSharing == true
    }

    /// 共享白板的用户identifier
    var sharingWhiteboardSharerIdentifier: String? {
        return whiteboardData?.sharer.identifier
    }

    /// 判断指定用户是否是共享人
    func isSelfSharingContent(with user: ByteviewUser) -> Bool {
        if shareSceneType == .selfSharingScreen {
            return true
        } else if let ssData = shareScreenData, ssData.isSharing {
            return ssData.identifier == user.identifier
        } else if let msData = magicShareData, !msData.urlString.isEmpty {
            return msData.identifier == user.identifier
        } else if let wbData = whiteboardData, wbData.whiteboardIsSharing {
            return wbData.sharer.identifier == user.identifier
        } else {
            return false
        }
    }
}

extension VideoChatInMeetingInfo {

    /// 有人正在共享屏幕、文档或白板
    var isSharingContent: Bool {
        isSharingScreen || isSharingDocument || isSharingWhiteboard
    }

    /// 有人正在共享屏幕
    var isSharingScreen: Bool {
        return shareScreen?.isSharing ?? false
    }

    /// 有人正在共享文档
    var isSharingDocument: Bool {
        if let info = followInfo {
            return !info.url.isEmpty
        }
        return false
    }

    /// 有人正在共享白板
    var isSharingWhiteboard: Bool {
        return whiteboardInfo?.whiteboardIsSharing ?? false
    }

    /// 正在共享的用户的ID
    var sharingIdentifiers: Set<ByteviewUser> {
        var identifiers = [shareScreen?.participantId.pid, followInfo?.participantId.pid]
        if let isSharing = whiteboardInfo?.whiteboardIsSharing, isSharing {
            identifiers.append(whiteboardInfo?.sharer.participantId.pid)
        }
        return Set(identifiers.filter { $0?.id.isEmpty == false }.compactMap { $0 })
    }

    /// 检查特定用户是否正在共享屏幕、文档或白板
    /// - Parameter account: 特定用户
    /// - Returns: 特定用户是否在共享内容
    func checkIsUserSharingContent(with account: ByteviewUser?) -> Bool {
        guard let account = account else { return false }
        if isSharingScreen { return shareScreen?.participant == account }
        if isSharingDocument { return followInfo?.user == account }
        if isSharingWhiteboard { return whiteboardInfo?.sharer == account }
        return false
    }

    /// 可以支持进入投屏转妙享
    var isShareScreenToFollowEnabled: Bool {
        return isFreeToBrowseEnabled && (shareScreen?.ccmInfo?.url.isEmpty == false)
    }

    /// 投屏转妙享支持自由浏览
    var isFreeToBrowseEnabled: Bool {
        guard isSharingScreen else { return false }
        return !(shareScreen?.ccmInfo?.isAllowFollowerOpenCcm == false)
    }

    /// 投屏转妙享的共享人ID
    var shareScreenToFollowMemberId: String? {
        return shareScreen?.ccmInfo?.memberID
    }

}
