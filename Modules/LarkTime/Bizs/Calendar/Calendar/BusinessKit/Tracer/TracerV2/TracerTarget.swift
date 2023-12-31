//
//  TracerTarget.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/23.
//

import Foundation

enum TracerTarget: String {
    /// 无
    case none
    /// 日历主视图
    case cal_calendar_main_view
    /// 日历详情页
    case cal_calendar_detail_view
    /// 分享含有选人组件页
    case cal_calendar_share_invite_view
    /// 日历权限设置页
    case cal_calendar_access_setting_view
    /// 日历分享确认页
    case cal_calendar_share_confirm_view
    /// 日历订阅者页
    case cal_calendar_subscribers_view
    /// 日历默认权限设置页
    case cal_calendar_default_access_view
    /// 日历二维码页
    case cal_calendar_qr_code_view
    /// 日历删除确认页
    case cal_calendar_delete_confirm_view
    /// 日历设置页
    case cal_calendar_setting_view
    /// 日历更多操作页
    case cal_calendar_more_view
    /// 日历分享页，支持以直接选人、链接、二维码等方式分享日历，同时对管理员支持权限设置
    case cal_calendar_share_view
    /// 完整创建日程页
    case cal_event_full_create_view
    /// 新建日历邀请他人订阅页
    case cal_calendar_create_invite_view
    /// 新建日历邀请他人订阅确认页
    case cal_calendar_create_invite_confirm_view
}
