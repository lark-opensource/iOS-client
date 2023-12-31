//
//  DataService+Download.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/25.
//

import Foundation
import RxSwift
import RustPB
import LarkStorage

/// 通过Mail封装的接口下载Drive文件

extension DataService {
    /// context:  drive 下载request context参数
    /// messageID: 文件管理的邮件id
    /// scene: mail 文件下载场景
    func download(context: DriveDownloadRequestCtx,
                  messageID: String?,
                  scene: MailFileDownloadScene,
                  forceDownload: Bool = false) -> Observable<(key: String?, cachePath: String?)> {
        var request = Email_Client_V1_MailFileDownloadRequest()
        request.driveReq = constructDriveDownloadReq(context: context)
        if let msgID = messageID {
            request.messageID = msgID
        }
        request.mailScene = scene
        request.forceDownload = forceDownload
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailFileDownloadResponse) -> (key: String, cachePath: String) in
            DataService.logger.info("[mail_client] [downloadFile] start download key: \(response.driveResp.key), path: \(response.path)")
            return (key: response.driveResp.key, cachePath: response.path)
        }).observeOn(MainScheduler.instance)
    }
    
    func cancelDownload(key: String) -> Observable<Int>{
        var request = Email_Client_V1_MailCancelFileDownloadRequest()
        request.driveReq.keys = [key]
        
        return sendAsyncRequest(request) { (response: Email_Client_V1_MailCancelFileDownloadResponse) -> Int in
            DataService.logger.info("[mail_client] [downloadFile] cancle key: \(key), result \(response.driveResp.result)")
            return Int(response.driveResp.result)
        }.observeOn(MainScheduler.instance)
    }
    
    private func constructDriveDownloadReq(context: DriveDownloadRequestCtx) -> Space_Drive_V1_DownloadRequest {
        var driveReq = Space_Drive_V1_DownloadRequest()
        driveReq.fileToken = context.fileToken
        driveReq.mountNodePoint = context.mountNodePoint
        driveReq.mountPoint = "email"
        // 传给rust的path是绝对路径或相对路径
        let range = (context.localPath as NSString).range(of: AbsPath.home.absoluteString, options: .literal)
        if range.location != NSNotFound {
            driveReq.localPath = (context.localPath as NSString).substring(from: range.location + range.length)
            driveReq.relativePath = true
        } else {
            driveReq.localPath = context.localPath
            driveReq.relativePath = false
        }
        driveReq.apiType = context.downloadType.apiType
        if let coverInfo = getCoverInfo(with: context.downloadType) {
            driveReq.coverInfo = coverInfo
        }
        
        driveReq.priority = context.priority.rawValue
        driveReq.disableCdnDownload = context.disableCdn
        return driveReq
    }
    private func getCoverInfo(with type: DriveDownloadRequestCtx.DriveDownloadType) -> Space_Drive_V1_CoverDownloadInfo? {
        guard case let .thumbnail(width, height) = type else { return nil }
        var info = Space_Drive_V1_CoverDownloadInfo()
        info.width = Int32(width)
        info.height = Int32(height)
        info.policy = "allow_up"
        return info
    }

}

extension DriveDownloadRequestCtx.DriveDownloadType {
    var apiType: Space_Drive_V1_DownloadRequest.ApiType {
        switch self {
        case .originFile:
            return .drive
        case .previewFile:
            return .preview
        case .image:
            return .img
        case .thumbnail(_, _):
            return .cover
        }
    }
}
