//
//  FileDownloadTask.swift
//  LarkFile
//
//  Created by SuPeng on 12/18/18.
//

import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast

private typealias Path = LarkSDKInterface.PathWrapper

enum FileDownloadTaskStatus: Equatable {
    case prepare
    case downloading(progress: Float, rate: Int64)
    //useLocalCache是否直接使用本地资源返回（可能是端上或sdk缓存, isCrypto资源是否加密
    case finish(isLocalCache: Bool, isCrypto: Bool)
    case pause(byUser: Bool)
    case fail(error: FileDownloadTaskError)

    var isDownloading: Bool {
        switch self {
        case .downloading:
            return true
        default:
            return false
        }
    }
}

enum FileDownloadTaskError: Error, Equatable {
    case downloadRequestFail(errorCode: Int)
    case downloadFail(errorCode: Int, message: String)
    case createDirFail
    case sourceFileBurned
    case sourceFileWithdrawn
    // 管理员删除，可恢复
    case sourceFileForzenByAdmin(errorCode: Int)
    // 管理员删除，不可恢复
    case sourceFileShreddedByAdmin(errorCode: Int)
    case securityControlDeny(errorCode: Int, message: String)
    case strategyControlDeny(errorCode: Int, message: String)
    // 风险文件不可下载
    case clientErrorRiskFileDisableDownload
    // ka脚本删除
    case sourceFileDeletedByAdminScript(errorCode: Int)

    var isAutoResumeable: Bool {
        switch self {
        case .sourceFileBurned, .sourceFileWithdrawn, .createDirFail, .sourceFileForzenByAdmin,
                .sourceFileShreddedByAdmin, .securityControlDeny, .sourceFileDeletedByAdminScript,
                .strategyControlDeny, .clientErrorRiskFileDisableDownload:
            return false
        case .downloadRequestFail, .downloadFail:
            return true
        }
    }
}

enum SDKFileCacheStrategy {
    case notUseSDKCache
    //是否使用sdk缓存
    case SDKCache
    //使用sdk加密缓存
    case SDKCacheCrypto
}

final class FileDownloadTask: Equatable {
    private var taskId: String {
        return file.messageId + file.fileKey
    }
    static let logger = Logger.log(FileDownloadTask.self, category: "Module.LarkFile")

    private let statusSubject = BehaviorRelay<FileDownloadTaskStatus>(value: .prepare)
    var currentStatus: FileDownloadTaskStatus {
        return statusSubject.value
    }
    var statusObservable: Observable<FileDownloadTaskStatus> {
        return statusSubject.asObservable()
    }

    let file: FileMessageInfo
    private let userID: String
    private let fileAPI: SecurityFileAPI
    private let downloadFileDriver: Driver<PushDownloadFile>
    private let messageDriver: Driver<PushChannelMessage>
    private var currentMessage: Message?

    private(set) var downloadedRatio: Float = 0
    private(set) var downloadedRate: Int64 = 0   //速率
    var remainDownloadSize: Int64 {
        return Int64(Float(file.fileSize) * (1.0 - downloadedRatio))
    }

    var toast: ((String) -> Void)?

    // 可感知埋点相关参数
    private(set) var hadBeenPaused: Bool = false
    private(set) var startTime: TimeInterval = 0

    private var disposeBag = DisposeBag()

    private let sdkFileCacheStrategy: SDKFileCacheStrategy

    private var useRustCache: Bool {
        return sdkFileCacheStrategy == .SDKCache || sdkFileCacheStrategy == .SDKCacheCrypto
    }

    init(userID: String,
         file: FileMessageInfo,
         fileAPI: SecurityFileAPI,
         sdkFileCacheStrategy: SDKFileCacheStrategy,
         downloadFileDriver: Driver<PushDownloadFile>,
         messageDriver: Driver<PushChannelMessage>) {
        self.userID = userID
        self.file = file
        self.fileAPI = fileAPI
        self.downloadFileDriver = downloadFileDriver
        self.messageDriver = messageDriver
        self.sdkFileCacheStrategy = sdkFileCacheStrategy
        if file.isFileExist {
            Self.logger.info("file logic trace file is exist \(self.file.fileKey) \(self.file.fileLocalURL) \(file.isEncrypted)")
            self.statusSubject.accept(.finish(isLocalCache: true, isCrypto: file.isEncrypted))
        }
    }

    func start() {
        guard !currentStatus.isDownloading else { return }

        statusSubject.accept(.downloading(progress: downloadedRatio, rate: downloadedRate))

        startTime = Date().timeIntervalSince1970

        if !useRustCache {
            //不使用rust缓存时，才有必要构建端上缓存目录
            //如果使用sdk缓存，这里会出问题，sdk缓存路径携带在了content.cacheFilePath中，存的是绝对路径。覆盖安装、升级等场景沙盒路径会产生变化，此时还用cacheFilePath就会出问题，本身使用sdk缓存时，这目录也不用建立
            do {
                if Path.useLarkStorage {
                    let messageDir = file.fileLocalPath.asAbsPath().parent()
                    let downloadDir = messageDir.parent()
                    try downloadDir.notStrictly.createDirectoryIfNeeded()
                    try messageDir.notStrictly.createDirectoryIfNeeded()
                } else {
                    let messageDir = Path.Old(URL(fileURLWithPath: (file.fileLocalPath as NSString).deletingLastPathComponent).path)
                    let downloadDir = Path.Old(URL(fileURLWithPath: (messageDir.rawValue as NSString).deletingLastPathComponent).path)
                    Self.logger.info("file logic trace file create dir \(self.file.fileKey) \(messageDir) \(downloadDir)")
                    try downloadDir.createDirectoryIfNeeded()
                    try messageDir.createDirectoryIfNeeded()
                }
            } catch {
                Self.logger.error("file logic trace file create dir fail \(self.file.fileKey)", error: error)
                statusSubject.accept(.fail(error: .createDirFail))
                return
            }
        }

        fileAPI
            .getFileMeta(fileKey: file.fileKey)
            .subscribe(onNext: { (meta) in
                self.downloadedRatio = Float(meta.progress ?? 0) / 100.0
                self.statusSubject.accept(.downloading(progress: self.downloadedRatio, rate: self.downloadedRate))
            })
            .disposed(by: disposeBag)

        //使用rust缓存时，absolutePath无用，sdk使用内部路径
        fileAPI
            .downloadFile(messageId: file.messageId,
                          key: file.fileKey,
                          authToken: file.authToken,
                          authFileKey: file.authFileKey,
                          absolutePath: useRustCache ? "" : file.fileLocalPath,
                          isCache: useRustCache,
                          type: .message,
                          channelId: file.channelId,
                          sourceType: file.messageSourceType,
                          sourceID: file.messageSourceId,
                          downloadFileScene: file.downloadFileScene)
            .subscribe(onError: { [weak self] (error) in
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .staticResourceFrozenByAdmin:
                        self?.statusSubject.accept(.fail(error: .sourceFileForzenByAdmin(errorCode: Int(error.errorCode))))
                    case .staticResourceShreddedByAdmin:
                        self?.statusSubject.accept(.fail(error: .sourceFileShreddedByAdmin(errorCode: Int(error.errorCode))))
                    case .securityControlDeny(let message):
                        self?.statusSubject.accept(.fail(error: .securityControlDeny(errorCode: Int(error.errorCode),
                                                                                     message: message)))
                    case .strategyControlDeny(let message):
                        self?.statusSubject.accept(.fail(error: .strategyControlDeny(errorCode: Int(error.errorCode), message: message)))
                    case .staticResourceDeletedByAdmin:
                        self?.statusSubject.accept(.fail(error: .sourceFileDeletedByAdminScript(errorCode: Int(error.errorCode))))
                    case .clientErrorRiskFileDisableDownload:
                        self?.statusSubject.accept(.fail(error: .clientErrorRiskFileDisableDownload))
                    default:
                        self?.statusSubject.accept(.fail(error: .downloadRequestFail(errorCode: Int(error.errorCode))))
                    }
                    return
                }
                self?.statusSubject.accept(.fail(error: .downloadRequestFail(errorCode: -1)))
            })
            .disposed(by: disposeBag)

        downloadFileDriver
            .drive(onNext: { [weak self] (push) in
                guard let self = self,
                      push.messageId == self.file.messageId,
                      push.key == self.file.fileKey else { return }
                switch push.state {
                case .downloading:
                    if push.progress > 0 {
                        self.downloadedRatio = Float(push.progress) / 100.0
                        self.downloadedRate = push.rate
                        self.statusSubject.accept(.downloading(progress: self.downloadedRatio, rate: self.downloadedRate))
                    }
                case .downloadSuccess:
                    self.downloadedRatio = 1
                    self.downloadedRate = 0
                    self.statusSubject.accept(.downloading(progress: 1, rate: self.downloadedRate))
                    if !self.useRustCache {
                        _ = fileDownloadCache(self.userID).saveFileName(self.file.fileRelativePath, size: Int(self.file.fileSize))
                    }
                    self.statusSubject.accept(.finish(isLocalCache: false, isCrypto: push.isEncrypted))
                case .downloadFail:
                    if self.currentMessage?.isRecalled ?? false {
                        self.statusSubject.accept(.fail(error: .sourceFileWithdrawn))
                    } else {
                        var (code, msg) = (-2, "")
                        if let error = push.error {
                            (code, msg) = (Int(error.code), error.details.debugMessage)
                        }
                        self.statusSubject.accept(.fail(error: .downloadFail(errorCode: code,
                                                                             message: msg)))
                    }
                case .downloadFailBurned:
                    self.statusSubject.accept(.fail(error: .sourceFileBurned))
                case .downloadFailRecall:
                    self.statusSubject.accept(.fail(error: .sourceFileWithdrawn))
                @unknown default:
                    break
                }
            })
            .disposed(by: disposeBag)

        messageDriver
            .drive(onNext: { [weak self] (message) in
                guard let self = self else { return }
                if message.message.id == self.file.messageId {
                    self.currentMessage = message.message
                }
            })
            .disposed(by: disposeBag)
    }

    func pause(byUser: Bool) {
        _ = fileAPI.cancelDownloadFile(
            messageId: file.messageId,
            key: file.fileKey,
            authToken: file.authToken,
            authFileKey: file.authFileKey,
            type: .message,
            channelId: file.channelId,
            sourceType: file.messageSourceType,
            sourceID: file.messageSourceId,
            downloadFileScene: file.downloadFileScene)
            .subscribe()
        dispose()
        statusSubject.accept(.pause(byUser: byUser))
        hadBeenPaused = true
    }

    func cancel() {
        downloadedRatio = 0
        downloadedRate = 0
        _ = fileAPI.cancelDownloadFile(
            messageId: file.messageId,
            key: file.fileKey,
            authToken: file.authToken,
            authFileKey: file.authFileKey,
            type: .message,
            channelId: file.channelId,
            sourceType: file.messageSourceType,
            sourceID: file.messageSourceId,
            downloadFileScene: file.downloadFileScene)
            .subscribe()
        dispose()
        statusSubject.accept(.prepare)
    }

    func fail(reason: String = "") {
        _ = fileAPI.cancelDownloadFile(
            messageId: file.messageId,
            key: file.fileKey,
            authToken: file.authToken,
            authFileKey: file.authFileKey,
            type: .message,
            channelId: file.channelId,
            sourceType: file.messageSourceType,
            sourceID: file.messageSourceId,
            downloadFileScene: file.downloadFileScene)
            .subscribe()
        dispose()
        statusSubject.accept(.fail(error: .downloadFail(errorCode: -2, message: reason)))
    }

    func dispose() {
        disposeBag = DisposeBag()
    }

    public static func == (lhs: FileDownloadTask, rhs: FileDownloadTask) -> Bool {
        return lhs.taskId == rhs.taskId && lhs.file.downloadFileScene == rhs.file.downloadFileScene
    }
}
