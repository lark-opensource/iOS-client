//
//  CommonDownloadProvider.swift
//  LarkMail
//
//  Created by NewPan on 2021/8/2.
//

#if CCMMod
import SpaceInterface
import Swinject
import RxSwift
import MailSDK
import LarkContainer

class DriveDownloadProvider {
    private var downloader: DocCommonDownloadProtocol? {
        return try? resolver.resolve(assert: DocCommonDownloadProtocol.self)
    }
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}

extension DocCommonDownloadStatus {
    var toAttachmentDownloadStatus: DriveDownloadResponseCtx.DownloadStatus {
        switch self {
        case .pending: return .pending
        case .inflight: return .inflight
        case .failed: return .failed
        case .success: return .success
        case .queue: return .queue
        case .ready: return .ready
        case .cancel: return .cancel
        @unknown default:
            assert(false, "@liutefeng")
            return .failed
        }
    }
}

extension DocCommonDownloadResponseContext {
    func toAttachmentResp(reqestCtx: DriveDownloadRequestCtx) -> DriveDownloadResponseCtx {
        return DriveDownloadResponseCtx(requestContext: reqestCtx,
                                        downloadStatus: downloadStatus.toAttachmentDownloadStatus,
                                        downloadProgress: downloadProgress,
                                        errorCode: errorCode,
                                        key: key,
                                        path: localFilePath)
    }
}

extension DocCommonDownloadRequestContext {
    static func from(mailCtx: DriveDownloadRequestCtx) -> DocCommonDownloadRequestContext {
        let priority: DocCommonDownloadPriority = .custom(priority: mailCtx.priority.rawValue)
        let downloadType: DocCommonDownloadType
        switch mailCtx.downloadType {
        case .originFile:
            downloadType = .originFile
        case .previewFile:
            downloadType = .previewFile
        case .image:
            downloadType = .image
        case .thumbnail(let width, let height):
            downloadType = .cover(width: width, height: height, policy: .allowUp)
        @unknown default:
            assert(false, "@liutefeng")
            downloadType = .originFile
        }
        return DocCommonDownloadRequestContext(fileToken: mailCtx.fileToken,
                                               mountNodePoint: mailCtx.mountNodePoint,
                                               mountPoint: "email",
                                               priority: priority,
                                               downloadType: downloadType,
                                               localPath: mailCtx.localPath,
                                               isManualOffline: false,
                                               disableCdn: mailCtx.disableCdn)
    }
}

extension DriveDownloadProvider: DriveDownloadProxy {
    func download(with context: DriveDownloadRequestCtx, messageID: String?) -> Observable<DriveDownloadResponseCtx> {
        guard let downloader = downloader else {
            return Observable<DriveDownloadResponseCtx>.empty()
        }
        return downloader
            .download(with: DocCommonDownloadRequestContext.from(mailCtx: context))
            .map({ return $0.toAttachmentResp(reqestCtx: context) })
    }
    func cancel(with key: String) -> Observable<Bool> {
        guard let downloader = downloader else {
            return Observable<Bool>.empty()
        }
        return downloader.cancelDownload(key: key)
    }
}
#endif
