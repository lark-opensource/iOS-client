//
//  MeetingService.swift
//  ByteViewInterface
//
//  Created by kiri on 2021/7/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// ByteView 模块对外提供的会议服务接口
public protocol MeetingService: AnyObject {
    /// 企业电话鉴权
    var isCompanyCallEnabled: Bool { get }

    /// 获取指定群所绑定的会议
    /// - Parameter groupId: 群id
    /// - Parameter callback: 群所绑定的会议Id的回调，可能会回调多次
    func getAssociatedMeeting(groupId: String, callback: @escaping (Result<String?, Error>) -> Void)

    var resources: MeetingResources { get }

    /// 摄像头是否被禁用
    var isCameraDenied: Bool { get }
    /// 麦克风是否被禁用
    var isMicrophoneDenied: Bool { get }
    /// 显示开启摄像头的alert
    func showCameraAlert()
    /// 显示开始麦克风的alert
    func showMicrophoneAlert()
    /// 创建一个会议监听
    func createMeetingObserver() -> MeetingObserver
    /// preview页面dissmiss，其他页面小窗
    func floatingOrDismissWindow()
}

public extension MeetingService {
    /// 当前会议列表
    var meetings: [Meeting] {
        createMeetingObserver().meetings
    }

    /// 查询当前会议，含preparing状态的会，比如preview/precheck中的会议
    var currentMeeting: Meeting? {
        createMeetingObserver().currentMeeting
    }
}

public enum MeetingError: Error, Equatable {
    case collaborationBlocked  // 屏蔽对方
    case collaborationBeBlocked // 被屏蔽
    case collaborationNoRights // 无权限
    case otherError
}

public protocol MeetingResources {
    var serviceCallName: String { get }
    var serviceCallIcon: UIImage { get }
    var isInCallText: String { get }
    var inRingingCannotJoinMeeting: String { get }
    var inRingingCannotCallVoIP: String { get }
}
