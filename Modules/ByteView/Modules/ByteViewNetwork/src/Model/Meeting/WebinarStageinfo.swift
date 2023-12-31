//
//  WebinarStageInfo.swift
//  ByteViewNetwork
//
//  Created by liujianlong on 2023/3/6.
//

import Foundation

public struct WebinarStageInfo: Equatable {
    public struct DraggedLayoutInfo: Equatable {
        /// 整个嘉宾区域相对于舞台(16:9)的比例
        public var guestAreaRatio: Double
        /// 单个嘉宾视频流的长宽比(拖拽之后固定)
        public var guestItemRatio: Double
        /// 嘉宾的整体布局，存的是列数，根据列数再计算行数
        public var guestLayoutColumn: [Int32] = []
        public init(guestAreaRatio: Double, guestItemRatio: Double, guestLayoutColumn: [Int32]) {
            self.guestAreaRatio = guestAreaRatio
            self.guestItemRatio = guestItemRatio
            self.guestLayoutColumn = guestLayoutColumn
        }
    }
    public enum WebinarStageAction: Int {
        case unkonwn = 0
        case sync = 1
        case unsync = 2
    }
    public enum SharingPosInfo: Int {
        case shareUnknown = 0
        case shareLeft = 1
        case shareRight = 2
    }
    public enum NewFloatingLayoutInfo: Int {
        case floatingUnknown = 0
        case floatingTop = 1
        case floatingBottom = 2
    }

    public var actionV2: WebinarStageAction
    public var sharingPosition: SharingPosInfo
    public var backgroundToken: String?
    public var backgroundURL: String?
    public var syncUser: ByteviewUser?
    public var guests: [ByteviewUser]
    public var allowGuestsChangeView: Bool
    public var showFullVideoFrame: Bool
    public var hideSharing: Bool

    public var draggedLayoutInfo: DraggedLayoutInfo?
    public var guestFloatingPos: NewFloatingLayoutInfo
    public var version: Int64?

    public init(actionV2: WebinarStageAction,
                sharingPosition: SharingPosInfo,
                backgroundToken: String?,
                backgroundURL: String?,
                syncUser: ByteviewUser?,
                guests: [ByteviewUser],
                allowGuestsChangeView: Bool,
                showFullVideoFrame: Bool,
                hideSharing: Bool,
                draggedLayoutInfo: DraggedLayoutInfo?,
                guestFloatingPos: NewFloatingLayoutInfo,
                version: Int64?) {
        self.actionV2 = actionV2
        self.sharingPosition = sharingPosition
        self.backgroundToken = backgroundToken
        self.backgroundURL = backgroundURL
        self.syncUser = syncUser
        self.guests = guests
        self.allowGuestsChangeView = allowGuestsChangeView
        self.showFullVideoFrame = showFullVideoFrame
        self.hideSharing = hideSharing
        self.draggedLayoutInfo = draggedLayoutInfo
        self.guestFloatingPos = guestFloatingPos
        self.version = version
    }
}

extension WebinarStageInfo: CustomStringConvertible {
    public var description: String {
        // URL 中含有 token, 避免打印
        "action:\(actionV2),syncUser:\(syncUser),guests:\(guests),allowChangeView:\(allowGuestsChangeView),showFullVideoFrame:\(showFullVideoFrame),version:\(version)"
    }
}
