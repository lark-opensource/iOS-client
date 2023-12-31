//
//  ExportDocumentDownloadError.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/23.
//
// https://bytedance.feishu.cn/docs/doccnjyJ20dBS2TEa18onyL2NRg
// https://bytedance.feishu.cn/docs/doccnbV7iqa4zhIUYNtqd3zj9ze#line-2

import Foundation
import SKResource
import SKCommon

enum ExportDownloadError: Error {
    case requestExportError

    case getExportResultStatusError
    case getExportResultNone
    case getExportResultPermission
    case getExportResultSize
    case getExportResultClose
    case getExportResultUnit
    case isCopyingFile

    case downloadFileError
    case dlpError(Int)

    var localizedDescription: String {
        switch self {
        case .requestExportError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .getExportResultStatusError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .getExportResultNone: return BundleI18n.SKResource.Doc_Document_ExportErrorNone
        case .getExportResultPermission: return BundleI18n.SKResource.Doc_Document_ExportServerNoPermission
        case .getExportResultSize: return BundleI18n.SKResource.Doc_Document_ExportOverSize
        case .getExportResultClose: return BundleI18n.SKResource.Doc_Document_ExportClose
        case .getExportResultUnit: return BundleI18n.SKResource.Doc_Document_ExportUnit
        case .downloadFileError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .isCopyingFile: return BundleI18n.SKResource.CreationMobile_Docs_duplicate_inProgress_toast
        case .dlpError(let code): return DlpErrorCode.errorMsg(with: code)
        }
    }

    var displayDescription: String {
        switch self {
        case .requestExportError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .getExportResultStatusError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .getExportResultNone: return BundleI18n.SKResource.Doc_Document_ExportErrorNone
        case .getExportResultPermission: return BundleI18n.SKResource.Doc_Document_ExportServerNoPermission
        case .getExportResultSize: return BundleI18n.SKResource.Doc_Document_ExportOverSize
        case .getExportResultClose: return BundleI18n.SKResource.Doc_Document_ExportClose
        case .getExportResultUnit: return BundleI18n.SKResource.Doc_Document_ExportUnit
        case .downloadFileError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .isCopyingFile: return BundleI18n.SKResource.CreationMobile_Docs_duplicate_inProgress_toast
        case .dlpError(let code): return DlpErrorCode.errorMsg(with: code)
        }
    }

    /// 轮询请求结果失败code
    // nolint: magic number
    static func exportResultErrorWithCode(_ code: Int) -> ExportDownloadError {
        switch code {
        case 1:
            return .getExportResultStatusError
        case 2:
            return .getExportResultStatusError
        case 3:
            return .getExportResultNone
        case 4:
            return .getExportResultPermission
        case 9004:
            return .getExportResultSize
        case 9012:
            return .getExportResultClose
        case 9013:
            return .getExportResultUnit
        case 4000080:
            return .isCopyingFile
        case 900099001, 900099002, 900099003, 900099004:
            return .dlpError(code)
        default:
            return .requestExportError
        }
    }
}

// https://bytedance.feishu.cn/docx/doxcneCjtBzcjVZkSF7kxfkyjIe
// 存在多种情况，具体根据code分析,该error只用于显示错误信息
enum NewExportDownloadError: Error {
    case requestExportError
    case requestExportErrorRetry
    case getExportResultPermission
    case getExportResultNone
    case getExportResultSize
    case getExportResultUnit

    case dlpError(Int)


    var localizedDescription: String {
        switch self {
        case .requestExportError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .requestExportErrorRetry: return BundleI18n.SKResource.CreationMobile_export_failed_retry
        case .getExportResultPermission: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_NoPermission
        case .getExportResultNone: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_deleted
        case .getExportResultSize: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_TooLarge
        case .getExportResultUnit: return BundleI18n.SKResource.Doc_Document_ExportUnit
        case .dlpError(let code): return DlpErrorCode.errorMsg(with: code)
        }
    }

    var displayDescription: String {
        switch self {
        case .requestExportError: return BundleI18n.SKResource.Doc_Document_ExportError
        case .requestExportErrorRetry: return BundleI18n.SKResource.CreationMobile_export_failed_retry
        case .getExportResultPermission: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_NoPermission
        case .getExportResultNone: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_deleted
        case .getExportResultSize: return BundleI18n.SKResource.CreationMobile_DocX_export_failed_TooLarge
        case .getExportResultUnit: return BundleI18n.SKResource.Doc_Document_ExportUnit
        case .dlpError(let code): return DlpErrorCode.errorMsg(with: code)
        }
    }

    /// 请求接口失败code
    // nolint: magic number
    static func exportResultErrorWithCode(_ code: Int) -> NewExportDownloadError {
        switch code {
        case 1004, 1014:
            return .requestExportError
        case 1001, 1003, 1005, 400080:
            return .requestExportErrorRetry
        case 1002:
            return .getExportResultPermission
        case 1006:
            return .getExportResultNone
        case 126:
            return .getExportResultUnit
        case 900099001, 900099002, 900099003, 900099004:
            return .dlpError(code)
        default:
            return .requestExportError
        }
    }

    /// 轮询请求结果失败code
    // nolint: magic number
    static func exportResultErrorWithJobStatus(_ status: Int) -> NewExportDownloadError {
        switch status {
        case 112, 124, 109, 6000:
            return .requestExportError
        case 3, 101, 102, 103, 108, 5000, 106, 122:
            return .requestExportErrorRetry
        case 110:
            return .getExportResultPermission
        case 111, 123:
            return .getExportResultNone
        case 107:
            return .getExportResultSize
        case 1016:
            return .getExportResultUnit
        case 900099001, 900099002, 900099003, 900099004:
            return .dlpError(status)
        default:
            return .requestExportError
        }
    }
}
