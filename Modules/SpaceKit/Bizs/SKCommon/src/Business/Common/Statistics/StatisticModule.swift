//
//  StatisticModule.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2021/3/16.
//  


import Foundation
import SpaceInterface

/// Drive 文件所处的层级或上一层级，用于埋点参数 src_module 和 module 的取值
public enum StatisticModule: String {
    case home
    case recent
    case quickaccess
    case favorite
    case personal
    case sharetome
    case offline
    case wiki
    case folder
    case shareFolder = "shared_folder"
    case search
    /// 日历附件
    case calendar
    /// 日历链接
    case calendarLink = "calendar_link"
    /// Email 附件
    case email
    /// Email 链接
    case emailLink = "email_link"
    /// 聊天里的附件
    case im
    /// 聊天里的链接
    case imLink = "im_link"
    /// 无法识别来源的链接
    case otherLink = "other_link"
    case doc
    case sheet
    case bitable
    case mindnote
    case docx
    /// 小程序
    case miniProgram = "mini_program"
    
    ///开平
    case webBroswer = "web_broswer"
    
    case unknown
}

extension DocsType {
    public var statisticModule: StatisticModule {
        switch self {
        case .doc:
            return .doc
        case .sheet:
            return .sheet
        case .bitable:
            return .bitable
        case .mindnote:
            return .mindnote
        default:
            return .unknown
        }
    }
}
