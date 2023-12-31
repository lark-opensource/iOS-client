//
//  InMeetFollowListener.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/8/1.
//

import Foundation

protocol InMeetFollowListener: AnyObject {
    func didReceiveFollowEvent(_ event: InMeetFollowEvent)
    func didUpdateFollowStatus(_ status: InMeetFollowViewModelStatus, oldValue: InMeetFollowViewModelStatus)
    func didUpdateLocalDocuments(_ documents: [MagicShareDocument], oldValue: [MagicShareDocument])
    func didUpdateMyselfInterpreterStatus(_ status: Bool)
    /// 投屏转妙享“共享人已更换内容”提示的显示状态有变化时触发
    /// - Parameter status: 是否显示提示信息
    func didUpdateShowPresenterChangedContentHint(_ showHint: Bool)
}

extension InMeetFollowListener {
    func didReceiveFollowEvent(_ event: InMeetFollowEvent) {}
    func didUpdateFollowStatus(_ status: InMeetFollowViewModelStatus, oldValue: InMeetFollowViewModelStatus) {}
    func didUpdateLocalDocuments(_ documents: [MagicShareDocument], oldValue: [MagicShareDocument]) {}
    func didUpdateMyselfInterpreterStatus(_ status: Bool) {}
    func didUpdateShowPresenterChangedContentHint(_ showHint: Bool) {}
}
