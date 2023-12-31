//
//  DriveCommonEnum.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/3/31.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation

/// 文件传输状态错误
///
/// - `default`: 默认错误
/// - userCancel: 用户取消
/// - pathError: 路径错误
enum DriveTransmissionError: Int {
    /// 默认错误
    case `default` = 2
    /// 用户取消传输
    case userCancel = 1000
}


// ----------------------------------------------------------------------------------------------------------------

enum DriveError: Error, LocalizedError {
    case network
    case permissionError
    case fileInfoError
    case fileInfoDataError
    case fileInfoParserError
    case fileEditTypeError
    case previewFetchError
    case previewDataError
    case fetchHistoryError

    case previewArchiveDataError
    case previewLocalArchiveTooLarge

    case blockByTNS(redirectURL: URL)
    case serverError(code: Int)

    public var errorDescription: String? {
        switch self {
        case .network:              return BundleI18n.SKResource.Doc_Doc_NetException
        case .fileInfoDataError:    return "后台文件信息数据错误"
        case .fileInfoParserError:  return "解析后台文件信息数据错误"
        case .permissionError:      return "获取用户权限失败"
        case .fileInfoError:        return "获取文件信息失败"
        case .previewFetchError:    return "获取后台预览信息失败"
        case .previewDataError:     return "后台预览信息数据错误"
        case .serverError(let code): return "服务端错误\(code)"
        case .fetchHistoryError:        return "获取历史版本记录错误"
        case .previewArchiveDataError:  return "获取压缩文件目录错误"
        case .previewLocalArchiveTooLarge: return "文件过大，暂不支持预览查看"
        case .fileEditTypeError: return "file_edit_type request fail"
        case .blockByTNS: return "file info block by TNS cross brand policy"
        }
    }

    var code: String {
        switch self {
        case .network:              return DriveResultCode.noNetwork.rawValue
        case .fileInfoDataError:    return DriveResultCode.fileInfoDataError.rawValue
        case .fileInfoParserError:  return DriveResultCode.fileInfoDataError.rawValue
        case .permissionError:      return DriveResultCode.fetchPermissionFail.rawValue
        case .fileInfoError:        return DriveResultCode.fetchFileInfoFail.rawValue
        case .previewFetchError:    return DriveResultCode.fetchPreviewUrlFail.rawValue
        case .previewDataError:     return DriveResultCode.perviewUrlDataError.rawValue
        case .serverError(let code): return "\(code)"
        case .fetchHistoryError:    return ""
        case .previewArchiveDataError, .previewLocalArchiveTooLarge:  return ""
        case .fileEditTypeError: return ""
        case .blockByTNS: return "\(DocsNetworkError.Code.tnsCrossBrandBlocked.rawValue)"
        }
    }
}

enum DriveResult<T> {
    case success(T)
    case failure(Error)
}

enum DriveStage {
    case begin
    case end
}
