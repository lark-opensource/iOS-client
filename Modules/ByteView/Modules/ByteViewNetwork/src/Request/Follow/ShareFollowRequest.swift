//
//  ShareFollowRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会中共享文档 VC_SHARE_FOLLOW_REQUEST
/// - SHARE_FOLLOW = 2330
/// - Videoconference_V1_ShareFollowRequest
public struct ShareFollowRequest {
    public static let command: NetworkCommand = .rust(.shareFollow)
    public typealias Response = ShareFollowResponse

    public init(meetingId: String, breakoutMeetingId: String?, action: Action, url: String, initSource: FollowInfo.InitSource,
                shareId: String?, authorityMask: Int32?, lifeTime: FollowInfo.LifeTime?, transPresenterData: TransPresenterData?) {
        self.meetingId = meetingId
        self.breakoutMeetingId = breakoutMeetingId
        self.action = action
        self.url = url
        self.initSource = initSource
        self.shareId = shareId
        self.authorityMask = authorityMask
        self.lifeTime = lifeTime
        self.transPresenterData = transPresenterData
    }

    public var meetingId: String

    /// 分组会议id
    public var breakoutMeetingId: String?

    /// 开始结束状态
    public var action: Action

    /// 分享路径
    public var url: String

    /// 开启follow的源头
    public var initSource: FollowInfo.InitSource

    public var shareId: String?

    /// 授予读/写权限
    public var authorityMask: Int32?

    /// 共享的文档的生命周期，是永久共享权限还是临时共享权限
    public var lifeTime: FollowInfo.LifeTime?

    /// 转移共享者
    public var transPresenterData: TransPresenterData?

    public enum Action: Int, Equatable {
        case unknown // = 0
        case start // = 1
        case stop // = 2

        /// 共享中更新 Options
        case updateOptions // = 3

        /// 共享中切换强制跟随
        case transPresenter // = 4

        /// 共享中请求成为主共享人
        case takeOver // = 5
        case reactivate // = 6
    }

    public struct TransPresenterData {
        public init(newPresenter: ByteviewUser) {
            self.newPresenter = newPresenter
        }

        /// 新共享者
        public var newPresenter: ByteviewUser
    }
}

/// Videoconference_V1_ShareFollowResponse
public struct ShareFollowResponse {
    public var openInBrowser: Bool
    public var followInfo: FollowInfo
}

extension ShareFollowRequest: CustomStringConvertible {

    public var description: String {
        String(
            indent: "ShareFollowRequest",
            "meetingId: \(meetingId)",
            "breakoutMeetingId: \(breakoutMeetingId)",
            "action: \(action)",
            "url: \(url.hash)",
            "lifeTime: \(lifeTime)",
            "initSource: \(initSource)"
        )
    }
}

extension ShareFollowRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_ShareFollowRequest
    func toProtobuf() throws -> Videoconference_V1_ShareFollowRequest {
        var options = PBFollowInfo.Options()
        options.defaultFollow = true
        var request = ProtobufType()
        request.options = options
        request.meetingID = meetingId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        request.url = url
        request.initSource = .init(rawValue: initSource.rawValue) ?? .unknownInitSource
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutMeetingId) {
            request.breakoutMeetingID = id
            request.associateType = .breakoutMeeting
        } else {
            request.associateType = .meeting
        }
        if let mask = authorityMask {
            request.authorityMask = mask
        } else {
            request.clearAuthorityMask()
        }
        if let shareID = shareId {
            if case .takeOver = action {
                var takeOverData = ProtobufType.TakeOverData()
                takeOverData.shareID = shareID
                request.takeOver = takeOverData
            } else if case .reactivate = action {
                var reactivateData = ProtobufType.ReactivateData()
                reactivateData.shareID = shareID
                request.reactivateData = reactivateData
            }
        }

        if let shareTransData = transPresenterData {
            request.transPresenterData = ProtobufType.TransPresenterData()
            request.transPresenterData.newPresenter = shareTransData.newPresenter.pbType
        }
        if let shareLifeTime = lifeTime {
            request.lifeTime = .init(rawValue: shareLifeTime.rawValue) ?? .unknown
        }
        return request
    }
}

extension ShareFollowResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_ShareFollowResponse
    init(pb: Videoconference_V1_ShareFollowResponse) throws {
        self.openInBrowser = pb.openInBrowser
        self.followInfo = pb.followInfo.vcType
    }
}
