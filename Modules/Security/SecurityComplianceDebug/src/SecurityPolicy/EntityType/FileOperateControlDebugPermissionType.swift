//
//  FileOperateControlDebugPermissionType.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/12/22.
//

import Foundation
import LarkSecurityAudit

enum FileOperateDebugPermissionType: String, CaseIterable {
    case unknown

    /// 上传文件
    case fileUpload

    /// 导入为在线文档
    case fileImport

    /// 下载
    case fileDownload

    /// 导出
    case fileExport

    /// 打印
    case filePrint

    /// 用其他应用打开
    case fileAppOpen

    /// 查看文件夹
    case fileAccessFolder

    /// 查看云文档/文件
    case fileRead

    /// 编辑云文档/文件
    case fileEdit

    /// 评论云文档/文件
    case fileComment

    /// 复制内容/创建副本
    case fileCopy

    /// 删除
    case fileDelete

    /// 分享
    case fileShare

    /// 搜索
    case search

    /// 本地文件对外分享
    case localFileShare

    /// 本地文件预览
    case localFilePreview

    /// 云文档打开和预览
    case docPreviewAndOpen

    /// 隐私设置 gps 地理位置权限
    case privacyGpsLocation

    /// PC 端粘贴保护
    case pcPasteProtection

    /// Web 端粘贴保护
    case webPasteProtection

    /// 移动端粘贴保护 (ios/android)
    case mobilePasteProtection

    /// 移动端 截屏保护 (ios/android)
    case mobileScreenProtect

    /// PC端 截屏保护
    case pcScreenProtect

    /// 云文档下载, 仅用于KA环境，SaaS为Null
    case docDownload

    /// 云文档导出, 仅用于KA环境，SaaS为Null
    case docExport

    /// 云文档打印, 仅用于KA环境，SaaS为Null
    case docPrint

    /// 百科词库阅读权限
    case baikeRepoView
}

extension FileOperateDebugPermissionType {
    var permissionType: PermissionType {
        switch self {
        case .unknown:
            return .unknown
        case .fileUpload:
            return .fileUpload
        case .fileImport:
            return .fileImport
        case .fileDownload:
            return .fileDownload
        case .fileExport:
            return .fileExport
        case .filePrint:
            return .filePrint
        case .fileAppOpen:
            return .fileAppOpen
        case .fileAccessFolder:
            return .fileAccessFolder
        case .fileRead:
            return .fileRead
        case .fileEdit:
            return .fileEdit
        case .fileComment:
            return .fileComment
        case .fileCopy:
            return .fileCopy
        case .fileDelete:
            return .fileDelete
        case .fileShare:
            return .fileShare
        case .search:
            return .search
        case .localFileShare:
            return .localFileShare
        case .localFilePreview:
            return .localFilePreview
        case .docPreviewAndOpen:
            return .docPreviewAndOpen
        case .privacyGpsLocation:
            return .privacyGpsLocation
        case .pcPasteProtection:
            return .pcPasteProtection
        case .webPasteProtection:
            return .webPasteProtection
        case .mobilePasteProtection:
            return .mobilePasteProtection
        case .mobileScreenProtect:
            return .mobileScreenProtect
        case .pcScreenProtect:
            return .pcScreenProtect
        case .docDownload:
            return .docDownload
        case .docExport:
            return .docExport
        case .docPrint:
            return .docPrint
        case .baikeRepoView:
            return .baikeRepoView
        }
    }
}
