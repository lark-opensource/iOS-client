//
//  EmlPreviewViewModel.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2022/1/27.
//

import Foundation
import RxSwift

public enum EMLFileDownloadState {
    case downloading(progress: Double)
    case success(fileURL: URL)
    case interrupted(reason: String)
}

public protocol EMLFileProvider {
    var localFileURL: URL? { get } // 如果已下载完成，提供LocalFileURL，直接从本地打开
    func download() -> Observable<EMLFileDownloadState>
    func cancelDownload()
}

struct EmlPreviewError: Error {
    var message: String
}

struct DriveFileDesc {
    let fileToken: String
    let name: String
    let fileSize: Int64
    let isLarge: Bool
}

class EmlPreviewViewModel: MailMessageListControllerViewModel {
    enum FileSource {
        case drive(DriveFileDesc)
        case eml(URL)
        case approval(String)
        case imFile(EMLFileProvider)
    }

    private let disposeBag = DisposeBag()
    private let fileSource: FileSource
    private var clearTmpFilesToken: String?
    private var sharedServices: MailSharedServices?

    let shitThreadID: String
    static let fakeLabelId = "shit_label_id"

    static func genShitThreadID() -> String {
        UUID().uuidString
    }

    deinit {
        MailMessageListController.logger.debug("EmlPreviewViewModle deinit")

        // 删除临时文件.
        guard let token = clearTmpFilesToken else { return }

        _ = MailDataSource
            .shared
            .clearEmlTmpFiles(token: token)
            .subscribe(onNext: nil)
            .disposed(by: DisposeBag())
    }

    init(
        shitThreadID: String,
        fileSource: FileSource,
        templateRender: MailMessageListTemplateRender,
        forwardInfo: DataServiceForwardInfo?,
        sharedServices: MailSharedServices
    ) {
        self.fileSource = fileSource
        self.shitThreadID = shitThreadID
        self.sharedServices = sharedServices
        super.init(templateRender: templateRender, imageService: sharedServices.imageService, forwardInfo: forwardInfo, isBot: false, isFeed: false, fromNotice: false)
    }

    func driveFileLocalPath(desc: DriveFileDesc) -> URL {
        let url = FileOperator.getAttachmentCacheDirURL(userID: sharedServices?.user.userID)
        let type = (desc.name as NSString).pathExtension
        MailLogger.info("EML preview wih type \(type)")
        return url.appendingPathComponent("\(desc.fileToken).\(type)")
    }

    override func loadMailItem(threadId: String,
                               labelId: String,
                               messageId: String?,
                               loadRemote: Bool? = nil,
                               forwardInfo: DataServiceForwardInfo?,
                               successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                               errorCallback: ((Error) -> Void)?) {
        switch fileSource {
        case .drive(let desc):
            MailLogger.info("EML load from drive")
            if let path = cachePathIfExist(desc: desc) {
                // 已经缓存在本地.
                MailLogger.info("EML load from drive but local found")
                openEml(localPath: path,
                        threadId: threadId,
                        successCallback: successCallback,
                        errorCallback: errorCallback)
                return
            }

            // 从网络加载.
            loadEmlViaDrive(desc: desc, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
        case .eml(let url):
            MailLogger.info("EML load from local")
            openEml(localPath: url.relativePath, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
        case .approval(let instanceCode):
            MailLogger.info("LoadMailInstance from \(instanceCode)")
            openApprovalMail(instanceCode: instanceCode, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
        case .imFile(let provider):
            MailLogger.info("LoadMailInstance from IM")
            openEMLFrom(provider: provider, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
        }
    }

    private func openEMLFrom(provider: EMLFileProvider, threadId: String,
                             successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                             errorCallback: ((Error) -> Void)?) {
        if let fileURL = provider.localFileURL {
            openEml(localPath: fileURL.relativePath, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
        } else {
            asyncRunInMainThread { [weak self] in
                guard let self = self else { return }
                provider.download().subscribe{ [weak self] downloadState in
                    guard let self = self else { return }
                    switch downloadState {
                    case .downloading(progress: _):
                        break
                    case .success(fileURL: let fileURL):
                        self.openEml(localPath: fileURL.relativePath, threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
                    case .interrupted(reason: let reason):
                        errorCallback?(EmlPreviewError(message: reason))
                    }
                } onError: { err in
                    MailLogger.error("openEMLFromProvider error \(err)")
                    errorCallback?(err)
                }.disposed(by: self.disposeBag)
            }
        }
    }

    private func openApprovalMail(instanceCode: String,
                                  threadId: String,
                                  successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                                  errorCallback: ((Error) -> Void)?) {
        MailDataSource.shared
            .openPreviewMail(instanceCode: instanceCode)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] resp in
                guard let self = self else { return }
                MailLogger.info("LoadMailInstance success \(instanceCode)")
                self.clearTmpFilesToken = resp.token

                var msgItem = MailMessageItem()
                msgItem.message = resp.message
                var mailItem = MailItem(threadId: threadId, messageItems: [msgItem],
                                        composeDrafts: [], labels: [],
                                        code: .none,
                                        isExternal: false, isFlagged: false,
                                        isRead: true, isLastPage: true)
                mailItem.shouldHideFlag = true
                mailItem.shouldHideContextMenu = true
                mailItem.shouldForceDisplayBcc = true
                mailItem.shouldForcePopActionSheet = true

                successCallback?(mailItem, true)
            } onError: { err in
                MailLogger.error("LoadMailInstance error \(err)")
                errorCallback?(err)
            }.disposed(by: self.disposeBag)
    }

    private func openEml(localPath: String,
                         threadId: String,
                         successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                         errorCallback: ((Error) -> Void)?) {
        guard FileOperator.isExist(at: localPath) else {
            errorCallback?(EmlPreviewError(message: "eml file not exist at \(localPath)"))
            return
        }
        MailDataSource.shared
            .openEml(localPath: localPath)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] resp in
                guard let self = self else { return }
                self.clearTmpFilesToken = resp.token

                var msgItem = MailMessageItem()
                msgItem.message = resp.message
                var mailItem = MailItem(threadId: threadId, messageItems: [msgItem],
                                        composeDrafts: [], labels: [],
                                        code: .none,
                                        isExternal: false, isFlagged: false,
                                        isRead: true, isLastPage: true)
                mailItem.shouldHideFlag = true
                mailItem.shouldHideContextMenu = true
                mailItem.shouldForceDisplayBcc = true
                mailItem.shouldForcePopActionSheet = true

                successCallback?(mailItem, false)
            } onError: { err in
                errorCallback?(err)
            }.disposed(by: self.disposeBag)
    }

    private func loadEmlViaDrive(desc: DriveFileDesc, threadId: String,
                                 successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                                 errorCallback: ((Error) -> Void)?) {
        guard let userId = sharedServices?.user.info?.userID, let downloader = sharedServices?.driveDownloader else {
            errorCallback?(EmlPreviewError(message: "userid or downloader is empty."))
            return
        }

        let localPath = driveFileLocalPath(desc: desc)
        let ctx = DriveDownloadRequestCtx(fileToken: desc.fileToken,
                                          mountNodePoint: userId,
                                          localPath: localPath.relativePath,
                                          downloadType: .originFile,
                                          priority: .userInteraction)
        downloader.download(with: ctx)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] (responseCtx) in
                guard let self = self else { return }
                switch responseCtx.downloadStatus {
                case .failed:
                    errorCallback?(EmlPreviewError(message: "download failed"))
                case .success:
                    self.saveToCacheIfNeed(desc: desc, path: responseCtx.path ?? "")
                    self.openEml(localPath: responseCtx.path ?? "", threadId: threadId, successCallback: successCallback, errorCallback: errorCallback)
                default:
                    break
                }
            }).disposed(by: self.disposeBag)
    }
    
    private func saveToCacheIfNeed(desc: DriveFileDesc, path: String) {
        guard !path.isEmpty else {
            return
        }
        if enableCacheImageAndAttach() {
            sharedServices?.preloadCacheManager.attachCache.saveFile(key: desc.fileToken, filePath: path, fileName: desc.name, type: .transient)
        }
    }
    private func cachePathIfExist(desc: DriveFileDesc) -> String? {
        if enableCacheImageAndAttach() {
            if let path = sharedServices?.preloadCacheManager.attachCache.getFile(key: desc.fileToken)?.path, path.exists {
                return path.absoluteString
            } else {
                return nil
            }
        } else {
            let path = driveFileLocalPath(desc: desc)
            if FileOperator.isExist(at: path.relativePath) {
                return path.relativePath
            } else {
                return nil
            }
        }
    }
    
    private func enableCacheImageAndAttach() -> Bool {
        return sharedServices?.featureManager.open(.offlineCacheImageAttach, openInMailClient: false) == true &&
        sharedServices?.featureManager.open(.offlineCache, openInMailClient: false) == true
    }
}
