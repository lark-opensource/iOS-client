//
//  NotesRuntime.swift
//  ByteView
//
//  Created by imac-pro on 2023/5/29.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol NotesRuntime: AnyObject {

    /// 纪要文档链接
    var notesUrl: String { get }

    /// 文档容器
    var documentVC: UIViewController { get }

    /// 文档状态
    var status: NotesDocumentStatus { get }

    /// 文档相关事件回调
    func setDelegate(_ delegate: NotesRuntimeDelegate)

    /// 调用web的方法
    func invoke(command: String,
                payload: [String: Any]?,
                callback: NotesInvokeCallBack?)

    /// 客户端收到agendaReady、notesReady，或者主持人身份变化时，推送会中相关信息
    func updateMeetingInfo(isRecordTipEnabled: Bool, isRecording: Bool, isHostOrCohost: Bool, deviceId: String, meetingId: String, apiVersion: Int64)

    /// 客户端收到agendaReady调用，或者当前激活的议程信息变化时，推送当前激活议程相关信息
    func updateActiveAgenda(_ agendaInfo: AgendaInfo, pausedAgenda: PausedAgenda, meetingPassedTime: Int64)

    /// 客户端收到Notice，触发文档内显示“外部权限”提示
    /// 可调用的方法汇总：https://bytedance.feishu.cn/wiki/wikcnj6btyaGwkN4itN8YlCQoTf
    func showNotesPermissionHint(_ content: String)

    /// 打开权限设置页面
    func openPermissionSettings()

    /// 设置快捷共享按钮的显示样式
    func setQuickShareButtonHidden(_ isHidden: Bool, isTapEnabled: Bool)
}

protocol NotesRuntimeDelegate: AnyObject {

    /// 文档中的web事件回调
    func notesRuntime(_ notesRuntime: NotesRuntime, onInvoke data: [String: Any]?, callback: NotesInvokeCallBack?)

    /// 文档中的用户事件回调
    func notesRuntime(_ notesRuntime: NotesRuntime, onEvent event: NotesDocumentEvent)

    /// 文档中的用户操作回调
    func notesRuntime(_ notesRuntime: NotesRuntime, onOperation operation: NotesDocumentOperation) -> Bool
}
