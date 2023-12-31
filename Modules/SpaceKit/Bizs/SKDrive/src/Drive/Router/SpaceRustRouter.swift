//
//  SpaceRustRouter.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/2/19.
//
//swiftlint:disable file_length line_length
// nolint: long parameters

import Foundation
import LarkRustClient
import RustPB
import LKCommonsLogging
import SwiftProtobuf
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import ServerPB
import LarkStorage
import SpaceInterface
import SKInfra

public typealias Command = RustPB.Basic_V1_Command

public typealias DriveUploadFile = Space_Drive_V1_DriveFile
//public typealias DriveUploadCallbackStatus = Space_Drive_V1_PushUploadCallback.Status
//public typealias DriveDownloadCallbackStatus = Space_Drive_V1_PushDownloadCallback.Status
public typealias DrivePushDownloadCallback = Space_Drive_V1_PushDownloadCallback
public typealias DrivePushUploadCallback = Space_Drive_V1_PushUploadCallback
public typealias DriveMonitorCallBack = Space_Drive_V1_MonitorCallback
public typealias DriveInitDriveRequest = Space_Drive_V1_InitDriveRequest
public typealias DriveInitDriveResponse = Space_Drive_V1_InitDriveResponse
public typealias DriveDownloadRequest = Space_Drive_V1_DownloadRequest
public typealias DriveDownloadResponse = Space_Drive_V1_DownloadResponse
public typealias DriveDownloadNormalRequest = Space_Drive_V1_DownloadNormalRequest
public typealias DriveDownloadNormalResponse = Space_Drive_V1_DownloadNormalResponse
public typealias DriveCancelDownloadRequest = Space_Drive_V1_CancelDownloadRequest
public typealias DriveCancelDownloadResponse = Space_Drive_V1_CancelDownloadResponse
//public typealias DriveUploadRequest = Space_Drive_V1_UploadRequest
public typealias DriveUploadResponse = Space_Drive_V1_UploadResponse
public typealias DriveCancelUploadRequest = Space_Drive_V1_CancelUploadRequest
public typealias DriveCancelUploadResponse = Space_Drive_V1_CancelUploadResponse
public typealias DriveUploadListRequest = Space_Drive_V1_UploadListRequest
public typealias DriveUploadListResponse = Space_Drive_V1_UploadListResponse
public typealias DriveResumeUploadRequest = Space_Drive_V1_ResumeUploadRequest
public typealias DriveResumeUploadResponse = Space_Drive_V1_ResumeUploadResponse
public typealias DriveDeleteUploadResourceRequest = Space_Drive_V1_DeleteUploadResourceRequest
public typealias DriveDeleteUploadResourceResponse = Space_Drive_V1_DeleteUploadResourceResponse
public typealias DriveCancelAllUploadRequest = Space_Drive_V1_CancelAllUploadRequest
public typealias DriveCancelAllUploadResponse = Space_Drive_V1_CancelAllUploadResponse
public typealias DriveResumeAllUploadRequest = Space_Drive_V1_ResumeAllUploadRequest
public typealias DriveResumeAllUploadResponse = Space_Drive_V1_ResumeAllUploadResponse
public typealias DriveRustConfig = Space_Drive_V1_DriveRustConfig
public typealias DriveGetUploadFileDataRequest = Space_Drive_V1_GetUploadFileDataRequest
public typealias DriveGetUploadFileDataResponse = Space_Drive_V1_GetUploadFileDataResponse
public typealias DriveCancelAllRequest = Space_Drive_V1_CancelAllRequest
public typealias DriveCancelAllResponse = Space_Drive_V1_CancelAllResponse
public typealias DriveMultiDownloadRequest = Space_Drive_V1_MultiDownloadRequest
public typealias DriveMultiDownloadResponse = Space_Drive_V1_MultiDownloadResponse
public typealias DriveCoverDownloadInfo = Space_Drive_V1_CoverDownloadInfo
public typealias DriveDownloadDocInfo = Space_Drive_V1_DocInfo
public typealias DriveDecryptRequest = Space_Drive_V1_DriveDecryptRequest
public typealias DriveDecryptResponse = Space_Drive_V1_DriveDecryptResponse

// MARK: - Rust Auto Refresher
public typealias SpaceListSubscriptionMessage = Space_Drive_V1_BroadcastPush
public typealias SpaceListSubscriptionErrorMessage = Space_Drive_V1_SubscribeErrPush

// MARK: - Guide
public typealias GuidePullProductGuideRequest = ServerPB_Guide_PullProductGuideRequest
public typealias GuidePullProductGuideResponse = ServerPB_Guide_PullProductGuideResponse
public typealias GuidePostUserConsumingGuideRequest = ServerPB_Guide_PostUserConsumingGuideRequest
public typealias GuidePostUserConsumingGuideResponse = ServerPB_Guide_PostUserConsumingGuideResponse
public typealias GuideScene = ServerPB_Guide_GuideScene

// MARK: - PDF Streaming
public typealias DriveGetDownloadRangeRequest = Space_Drive_V1_GetDownloadedRangesRequest
public typealias DeleteDownloadRecordRequest = Space_Drive_V1_DeleteDownloadRecordRequest
public typealias DeleteDownloadRecordResponse = Space_Drive_V1_DeleteDownloadRecordResponse

struct DriveRustUserInfo {
    let userId: String
    let tenantId: String
    let session: String
    let deviceID: String
}

protocol TypedRustPushHandler: RustPushHandler {
    associatedtype Response: SwiftProtobuf.Message
    func doProcessing(message: Response)
}

extension TypedRustPushHandler {
    func processMessage(payload: Data) {
        if let message = decode(payload: payload) {
            doProcessing(message: message)
        }
    }

    func decode(payload: Data) -> Response? {
        do {
            return try Response(serializedData: payload)
        } catch {
            RustClient.logger.error("Rust长链接消息解析失败", error: error)
        }
        return nil
    }
}

class PushDriveDownloadHandler: TypedRustPushHandler {
    static let logger = Logger.log(PushDriveDownloadHandler.self, category: "DocsSDK.drive")
    static let pdfLinearizedDownloadDomain = "pdf.linearized.download"
    
    static func factory(_ rust: SpaceRustRouter) -> () -> RustPushHandler {
        return { [weak rust] in
            return PushDriveDownloadHandler(rust)
        }
    }

    weak var service: SpaceRustRouter?

    init(_ rust: SpaceRustRouter?) {
        service = rust
    }

    func doProcessing(message: DrivePushDownloadCallback) {
        guard let service = service else {
            PushDriveDownloadHandler.logger.warn("Rust service has been deinit.")
            return
        }
        service.processPush(response: message)
    }
}

class PushDriveUploadHandler: TypedRustPushHandler {
    static let logger = Logger.log(PushDriveUploadHandler.self, category: "DocsSDK.drive")

    static func factory(_ rust: SpaceRustRouter) -> () -> RustPushHandler {
        return { [weak rust] in
            return PushDriveUploadHandler(rust)
        }
    }

    weak var service: SpaceRustRouter?

    init(_ rust: SpaceRustRouter?) {
        service = rust
    }

    func doProcessing(message: DrivePushUploadCallback) {
        guard let service = service else {
            PushDriveUploadHandler.logger.warn("Rust service has been deinit.")
            return
        }

        service.processPush(response: message)
    }
}

class PushMonitorEventHandler: TypedRustPushHandler {

    static let logger = Logger.log(PushMonitorEventHandler.self, category: "DocsSDK.drive")

    static func factory(_ rust: SpaceRustRouter) -> () -> RustPushHandler {
        return { [weak rust] in
            return PushMonitorEventHandler(rust)
        }
    }

    weak var service: SpaceRustRouter?

    init(_ rust: SpaceRustRouter?) {
        service = rust
    }

    func doProcessing(message: DriveMonitorCallBack) {
        guard let service = service else {
            PushMonitorEventHandler.logger.warn("Rust service has been deinit.")
            return
        }

        service.processPush(response: message)
    }
}


/// RustSDK调用中间层Router
public final class SpaceRustRouter {

    public let driveInitFinishObservable = BehaviorRelay<Bool>(value: false)

    private let spaceListPushSubject = PublishSubject<SpaceListSubscriptionMessage>()
    private let spaceListErrorPushSubject = PublishSubject<SpaceListSubscriptionErrorMessage>()

    static let logger = Logger.log(SpaceRustRouter.shared.self, category: "SpaceKit.rust")

    public static let shared = SpaceRustRouter()

    private let disposeBag = DisposeBag()

    private init() {

    }

    /// 获取所有文件获取数据库中所有未上传完成的文件夹token
    public static let mainMountPointToken = "all_files_token"
    @ThreadSafe
    private(set) var rustService: RustService?

    func update(rustService: RustService) {
        self.rustService = rustService
    }

    /// 初始化DriveSDK 工作队列，DB等，注册rust service消息回调（切换用户之后需要重新注册回调）
    ///
    /// - Parameters:
    ///   - storagePath: rust端db存放路径，存放文件上传、下载相关信息
    ///   - userId: 用户的id
    ///   - session: 用于后端鉴权
    /// - Returns: 成功为true，否则为false
    func config(storagePath: String,
                userInfo: DriveRustUserInfo,
                driveConfig: DriveRustConfig,
                disableCDNDownload: Bool = false,
                disableSmartUpload: Bool = false) {
        /// 注册Rust command
        rustService?.registerPushHandler(factories: [Command.suiteDrivePushDownloadProcess: PushDriveDownloadHandler.factory(self),
                                                     Command.suiteDrivePushUploadProgress: PushDriveUploadHandler.factory(self),
                                                     Command.suiteDrivePushMonitorEvent: PushMonitorEventHandler.factory(self)
        ])
        var request = DriveInitDriveRequest()
        request.forApp = false
        request.storagePath = storagePath
        request.userID = userInfo.userId
        request.disableCdnDownload = disableCDNDownload
        request.session = userInfo.session
        request.deviceID = userInfo.deviceID
        // 解决App 安装后沙盒目录路径更改，导致之前的任务上传失败
        request.rootPath = AbsPath.home.absoluteString
        // 是否动态分片上传
        request.disableSmartUpload = disableSmartUpload
        request.driveRustConfig = driveConfig
        request.tenantID = userInfo.tenantId

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return
        }

        let response: Observable<DriveInitDriveResponse> = service.sendAsyncRequest(request)
        response
        .subscribe(onNext: { (response) in
            DocsLogger.driveInfo("DriveSdk.init_sdk result: \(response.result)")
            self.driveInitFinishObservable.accept(true)
        }, onError: { (error) in
            DocsLogger.driveInfo("DriveSdk.init_sdk error: \(error)")
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - 下载相关接口
public extension SpaceRustRouter {

    /// 下载请求参数
    /// - Parameters:
    ///   - localPath: 本地缓存路径
    ///   - fileToken: 文件token
    ///   - mountNodePoint: 父节点，没有可传空，传空则进入“我的空间”；文档中的图片则为文档token
    ///   - mountPoint: 挂载点 "explorer"
    ///   - dataVersion: 文件数据版本号 不传则下载最新的版本(预留字段， 目前后台还未支持)
    ///   - priority: 下载优先级 不传默认为0， 低优先级传小于0的数值
    ///   - apiType: 下载文件类型, .preview = 相似文件, .drive 原始文件，.img 文档内图片下载，
    ///         详见：https://bytedance.feishu.cn/docs/doccn1PYVmgLg9EkiZEnSIDSCbf
    ///   - coverInfo: 缩略图信息，可自定义缩略图大小
    ///   - disableCDN: 不使用cdn下载，默认值为false, 表示使用cdn下载，传true时表示不使用cdn下载，小文件下载时传true可以减少一次请求
    struct DownloadRequestContext {
        let localPath: String
        let fileToken: String
        let docToken: String
        let docType: Int32?
        let mountNodePoint: String
        let mountPoint: String
        let dataVersion: String?
        let priority: DriveDownloadPriority
        let apiType: DriveDownloadRequest.ApiType
        let coverInfo: DriveCoverDownloadInfo?
        let authExtra: String?
        let disableCDN: Bool
        let disableCoverRetry: Bool
        let teaParams: [String: String]
        
        init(
            localPath: String,
            fileToken: String,
            docToken: String,
            docType: Int32?,
            mountNodePoint: String,
            mountPoint: String,
            dataVersion: String?,
            priority: DriveDownloadPriority,
            apiType: DriveDownloadRequest.ApiType,
            coverInfo: DriveCoverDownloadInfo?,
            authExtra: String?,
            disableCDN: Bool,
            disableCoverRetry: Bool = false,
            teaParams: [String: String]
        ) {
            self.localPath = localPath
            self.fileToken = fileToken
            self.docToken = docToken
            self.docType = docType
            self.mountNodePoint = mountNodePoint
            self.mountPoint = mountPoint
            self.dataVersion = dataVersion
            self.priority = priority
            self.apiType = apiType
            self.coverInfo = coverInfo
            self.authExtra = authExtra
            self.disableCDN = disableCDN
            self.disableCoverRetry = disableCoverRetry
            self.teaParams = teaParams
        }
    }
    
    static func constructDownloadRequest(context: DownloadRequestContext) -> DriveDownloadRequest {
        var request = DriveDownloadRequest()
        if let freeSize = SKFilePath.getFreeDiskSpace() {
            DocsLogger.driveInfo("free size: \(freeSize)")
            request.teaParams = ["available_space": String(freeSize)]
        }
        if let extra = context.authExtra {
            request.extra = extra
        }
        let range = (context.localPath as NSString).range(of: AbsPath.home.absoluteString, options: .literal)
        let relatePath: String
        if range.location != NSNotFound {
            relatePath = (context.localPath as NSString).substring(from: range.location + range.length)
            request.relativePath = true
        } else {
            relatePath = context.localPath
            request.relativePath = false
        }

        request.localPath = relatePath
        request.fileToken = context.fileToken
        request.mountNodePoint = context.mountNodePoint
        request.mountPoint = context.mountPoint
        request.apiType = context.apiType
        request.disableCdnDownload = context.disableCDN
        request.disableCoverRetry = context.disableCoverRetry
        request.teaParams = context.teaParams

        if !context.docToken.isEmpty {
            var docInfo = DriveDownloadDocInfo()
            docInfo.docToken = context.docToken
            docInfo.docType = Int32(context.docType ?? 2)
            request.docInfo = docInfo
        }

        if let dataVersion = context.dataVersion {
            request.dataVersion = dataVersion
        }
        
        if let coverInfo = context.coverInfo {
            request.coverInfo = coverInfo
        }

        request.priority = context.priority.rawValue
        return request
    }

    /// 单个下载文件（token）
    ///
    /// - Parameters:
    ///   - context: 构建下载请求的参数信息
    /// - Returns: key
    func download(request: DriveDownloadRequest) -> Observable<String> {
        DocsLogger.driveInfo("encrypted token:\(DocsTracker.encrypt(id: request.fileToken)), download param apiType: \(request.apiType)")
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just("")
        }

        return service.sendAsyncRequest(request) { (response: DriveDownloadResponse) -> String in
            return response.key
        }.catchError { (error) -> Observable<String> in
            SpaceRustRouter.logger.error("download failed", error: error)
            return .just("")
        }
    }

    /// 批量下载文件
    /// - Parameter requests: 单次下载的 Rust 请求
    /// - Returns: 返回下载文件 Token 和 下载id 的对应关系的 Map
    func download(requests: [DriveDownloadRequest]) -> Observable<[String: String]> {
        var request = DriveMultiDownloadRequest()
        request.downloadRequests = requests
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just([:])
        }

        return service.sendAsyncRequest(request) { (response: DriveMultiDownloadResponse) -> [String: String] in
            return response.keysMap
        }.catchError { (error) -> Observable<[String: String]> in
            SpaceRustRouter.logger.error("download requests failed", error: error)
            return .just([:])
        }

    }
    /// 根据URL下载文件
    ///
    /// - Parameters:
    ///   - remoteUrl: 远程下载地址
    ///   - localPath: 本地路径
    ///   - priority: 下载优先级 不传默认为0， 低优先级传小于0的数值
    ///   - slice: 是否启动分片下载，可以实现缓存下载，需要后台支持http range。
    ///   - authExtra: 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选
    /// - Returns: key
    func downloadNormal(remoteUrl: String,
                        localPath: String,
                        fileSize: String? = nil,
                        slice: Bool = true,
                        priority: DriveDownloadPriority = .default,
                        apiType: DriveDownloadRequest.ApiType = .drive,
                        teaParams: [String: String] = [:],
                        authExtra: String?) -> Observable<String> {
        var request = DriveDownloadNormalRequest()
        request.remoteURL = remoteUrl
        request.localPath = localPath
        request.withSlice = slice
        request.apiType = apiType
        if let extra = authExtra {
            request.extra = extra
        }

        request.priority = priority.rawValue
        request.teaParams = teaParams

        if let size = fileSize {
            request.fileSize = size
        }
        if let freeSize = SKFilePath.getFreeDiskSpace() {
            DocsLogger.driveInfo("free size: \(freeSize)")
            request.teaParams = ["available_space": String(freeSize)]
        }


        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just("")
        }
        return service.sendAsyncRequest(request) { (response: DriveDownloadNormalResponse) -> String in
            return response.key
        }.catchError { (error) -> Observable<String> in
            SpaceRustRouter.logger.error("download Normal failed", error: error)
            return .just("")
        }
    }

    /// 取消下载
    ///
    /// - Parameter key: key
    /// - Returns: 成功或失败  -1 代表异常
    func cancelDownload(key: String) -> Observable<Int> {
        var request = DriveCancelDownloadRequest()
        request.keys = [key]

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }
        return service.sendAsyncRequest(request) { (response: DriveCancelDownloadResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("cancelDownloadNew failed", error: error)
            return .just(-1)
        }
    }
}


// MARK: - 新引导接口
public extension SpaceRustRouter {

    /// 拉取引导
    ///
    /// - Parameters:
    ///   - guideScene: 引导场景类型，ccm需要传入ccm
    /// - Returns: 引导状态的Map
    func pullProductGuide(guideScene: GuideScene) -> Observable<[String: Bool]> {
        var request = GuidePullProductGuideRequest()
        request.scene = guideScene

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return Observable.of([:])
        }

        let response: Observable<GuidePullProductGuideResponse> = service.sendPassThroughAsyncRequest(request, serCommand: .pullProductGuide)
        return response.map { $0.guides }
    }

    /// 上报引导
    ///
    /// - Parameters:
    ///   - keys: 调用 Update 接口要传的引导 keys，用于 max_count > 1 的引导/小红点
    ///   - keyStep: 传空即可，引导的 key 对应的步骤
    ///   - context: 传空即可，引导上下文，类似于用户画像
    ///   - keysDone: 调用 Done 接口要传的引导完成的 key，用于 max_count == 1 的引导
    /// - Returns: 是否上报成功
    func postUserConsumingGuide(keys: [String],
                                keyStep: [String: Int32],
                                context: [String: String],
                                keysDone: [String]) {
        var request = GuidePostUserConsumingGuideRequest()
        request.keys = keys
        request.keyStep = keyStep
        request.context = context
        request.keysDone = keysDone

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return
        }

        let response: Observable<GuidePostUserConsumingGuideResponse> = service.sendPassThroughAsyncRequest(request, serCommand: .postUserConsumingGuideRequest)
        response.subscribe(onNext: { (response) in
            DocsLogger.driveInfo("Guide postUserConsumingGuide: \(response)")
        }, onError: { (error) in
            DocsLogger.driveInfo("Guide postUserConsumingGuide: \(error)")
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - 上传相关接口
public extension SpaceRustRouter {

    /// 上传文件
    /// - Returns: key，后端生成，用于断点续传、取消上传；失败则为空
    func upload(context: DriveUploadRequestContext) -> Observable<String> {
        var request = DriveUploadRequest()

        let range = (context.localPath as NSString).range(of: AbsPath.home.absoluteString, options: .literal)
        let relatePath: String
        if range.location != NSNotFound {
            relatePath = (context.localPath as NSString).substring(from: range.location + range.length)
            request.relativePath = true
        } else {
            relatePath = context.localPath
            request.relativePath = false
        }
        if let uploadCode = context.uploadCode {
            request.uploadCode = uploadCode
        }
        var extRust = context.extRust
        extRust["size_checker"] = "\(SettingConfig.sizeLimitEnable)"
        request.localPath = relatePath
        request.fileName = context.fileName
        request.mountNodePoint = context.mountNodePoint
        request.mountPoint = context.mountPoint
        request.priority = context.priority.rawValue
        request.extraParams = context.extraParams
        request.extRust = extRust
        request.scene = context.scene
        // For Upload Image
        if let objType = context.objType {
            request.objType = objType
        }

        if let apiType = context.apiType {
            request.apiType = apiType
        }

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just("")
        }

        return service.sendAsyncRequest(request) { (response: DriveUploadResponse) -> String in
            return response.key
        }.catchError { (error) -> Observable<String> in
            SpaceRustRouter.logger.error("upload failed", error: error)
            return .just("")
        }
    }

    /// 取消上传
    ///
    /// - Parameter key: key
    /// - Returns: 成功或失败，0是成功，-1代表异常
    func cancelUpload(key: String) -> Observable<Int> {
        var request = DriveCancelUploadRequest()
        request.keys = [key]

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }

        return service.sendAsyncRequest(request) { (response: DriveCancelUploadResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("cancelUpload failed", error: error)
            return .just(-1)
        }
    }

    /// 获取上传文件列表
    ///
    /// - Parameters:
    ///   - mountNodePoint: 文件夹Token
    ///   - forProgress: 获取上传状态进度
    ///   - scene: 区分场景，默认为unknown，获取drive的上传任务，.wiki为获取wiki的上传任务
    /// - Returns: 文件列表
    func uploadList(mountNodePoint: String, scene: DriveUploadScene = .unknown, forProgress: Bool = false) -> Observable<[DriveUploadFile]> {
        var request = DriveUploadListRequest()
        request.mountNodeToken = mountNodePoint
        request.forProgress = forProgress
        request.scene = scene
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just([])
        }
        return service.sendAsyncRequest(request) { (response: DriveUploadListResponse) -> [DriveUploadFile] in
            return response.list
        }.catchError { (error) -> Observable<[DriveUploadFile]> in
            SpaceRustRouter.logger.error("uploadList failed", error: error)
            return .just([])
        }
    }

    /// 获取单个上传文件信息(同步请求)
    ///
    /// - Parameters:
    ///   - key: 上传 Token
    /// - Returns: 文件信息
    func getUploadFileData(key: String) -> Observable<DriveUploadFile?> {
        var request = DriveGetUploadFileDataRequest()
        request.key = key
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(nil)
        }
        return service.sendAsyncRequest(request) { (response: DriveGetUploadFileDataResponse) -> DriveUploadFile? in
            return response.file
        }.catchError { (error) -> Observable<DriveUploadFile?> in
            SpaceRustRouter.logger.error("getUploadFileData failed", error: error)
            return .just(nil)
        }
    }

    /// 重试上传
    ///
    /// - Parameter key: key
    /// - Returns: 成功或失败  -1 代表异常
    func resumeUpload(key: String) -> Observable<Int> {
        var request = DriveResumeUploadRequest()
        request.key = key

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }
        return service.sendAsyncRequest(request) { (response: DriveResumeUploadResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("resumeUpload failed", error: error)
            return .just(-1)
        }
    }

    /// 删除上传数据资源
    ///
    /// - Parameter key: key
    /// - Returns: 成功或失败  -1 代表异常
    func deleteUploadResource(key: String) -> Observable<Int> {
        var request = DriveDeleteUploadResourceRequest()
        request.key = key

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }
        return service.sendAsyncRequest(request) { (response: DriveDeleteUploadResourceResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("deleteUploadResource failed", error: error)
            return .just(-1)
        }
    }

    /// 暂停所有正在上传的任务，包含Drive文件、Doc 附件、邮件等上传任务，可以使用'resumeAllUploadTask'来
    /// 恢复被暂停的任务
    ///
    /// - Returns: 成功或失败  -1 代表异常
    func pauseAllUploadTask() -> Observable<Int> {
        let request = DriveCancelAllUploadRequest()
        SpaceRustRouter.logger.info("Rust service pauseAllUploadTask")

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }
        return service.sendAsyncRequest(request) { (response: DriveCancelAllUploadResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("pauseAllUploadTask failed", error: error)
            return .just(-1)
        }
    }

    /// 恢复上传任务
    /// - Parameter includeFailed: true，用于冷启动恢复所有失败的上传文件；false，只会恢复使用'pauseAllUploadTask'暂停
    /// 的任务
    func resumeAllUploadTask(includeFailed: Bool = false) -> Observable<Int> {
        var request = DriveResumeAllUploadRequest()
        request.withFailed = includeFailed

        SpaceRustRouter.logger.info("Rust service resumeAllUploadTask includeFailed: \(includeFailed)")

        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(-1)
        }
        return service.sendAsyncRequest(request) { (response: DriveResumeAllUploadResponse) -> Int in
            return Int(response.result)
        }.catchError { (error) -> Observable<Int> in
            SpaceRustRouter.logger.error("resumeAllUploadTask failed", error: error)
            return .just(-1)
        }
    }
}

// MARK: - Push Handler
extension SpaceRustRouter {
    func processPush(response: DrivePushDownloadCallback) {
        SpaceRustRouter.logger.info("Recieve drive download push: \(String(describing: response))")

        if response.hasFailedInfo {
            DriveDownloadCallbackService.shared.onFailed(key: response.failedInfo.key,
                                                         errorCode: Int(response.failedInfo.errorCode))
            SpaceRustRouter.logger.info("Recieve drive download failed")
        } else {
            let context = DriveDownloadContext(callback: response)
            DriveDownloadCallbackService.shared.updateProgress(context: context)
            SpaceRustRouter.logger.info("Recieve drive download update progress")
        }
        reportDownloadFinished(response: response)
    }

    func processPush(response: DrivePushUploadCallback) {
        SpaceRustRouter.logger.info("Recieve drive upload push: \(String(describing: response))")
        if response.hasFailedInfo {
            DriveUploadCallbackService.shared.onFailed(key: response.failedInfo.key,
                                                       mountPoint: response.mountPoint,
                                                       scene: response.scene,
                                                       errorCode: Int(response.failedInfo.errorCode),
                                                       fileSize: Int64(response.bytesTotal) ?? 0)
            SpaceRustRouter.logger.info("Recieve drive upload failed")
        } else {
            let context = DriveUploadContext(callback: response)
            DriveUploadCallbackService.shared.updateProgress(context: context)
            SpaceRustRouter.logger.info("Recieve drive upload update progress:\(DocsTracker.encrypt(id: response.extraInfo.nodeToken))")
        }
        reportUploadFinished(response: response)
    }

    func processPush(response: DriveMonitorCallBack) {
        DocsTracker.log(event: response.event, parameters: response.params)
        SpaceRustRouter.logger.info("Recieve drive monitor push: \(response)")
    }
    
    private func reportUploadFinished(response: DrivePushUploadCallback) {
        if response.hasFailedInfo {
            if let module = DriveStatistic.moduleInfo(for: response.failedInfo.key, isUpload: true) {
                DriveStatistic.reportUpload(action: .finishUpload,
                                            fileID: "", module: module.module,
                                            subModule: module.subModule,
                                            srcModule: module.srcModule,
                                            isDriveSDK: module.isDriveSDK)
            }
        } else if response.status == .success {
            if let module = DriveStatistic.moduleInfo(for: response.key, isUpload: true) {
                let fileName = URL(fileURLWithPath: response.filePath).lastPathComponent
                DriveStatistic.reportUpload(action: .finishUpload,
                                            fileID: response.fileToken,
                                            fileSubType: SKFilePath.getFileExtension(from: fileName),
                                            module: module.module,
                                            subModule: module.subModule,
                                            srcModule: module.srcModule,
                                            isDriveSDK: module.isDriveSDK)
            }
        }
    }
    
    private func reportDownloadFinished(response: DrivePushDownloadCallback) {
        if response.hasFailedInfo {
            if let module = DriveStatistic.moduleInfo(for: response.failedInfo.key, isUpload: false) {
                DriveStatistic.reportDownload(action: .finishDownload,
                                              fileID: module.fileID,
                                              module: module.module,
                                              subModule: module.subModule,
                                              srcModule: module.srcModule,
                                              isExport: module.isExport,
                                              isDriveSDK: module.isDriveSDK)
            }
        } else if response.status == .success {
            if let module = DriveStatistic.moduleInfo(for: response.key, isUpload: false) {
                let fileName = URL(fileURLWithPath: response.filePath).lastPathComponent
                DriveStatistic.reportDownload(action: .finishDownload,
                                              fileID: module.fileID,
                                              fileSubType: SKFilePath.getFileExtension(from: fileName),
                                              module: module.module,
                                              subModule: module.subModule,
                                              srcModule: module.srcModule,
                                              isExport: module.isExport,
                                              isDriveSDK: module.isDriveSDK)
            }
        }
    }
}

extension SpaceRustRouter {

    /// 取消所有上传/下载请求
    ///
    /// - Parameters:
    /// - Returns: 成功或失败，0是成功，-1代表异常
    public func cancelAllRequest() -> Observable<Int32?> {
        let request = DriveCancelAllRequest()
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .just(nil)
        }
        return service.sendAsyncRequest(request) { (response: DriveCancelAllResponse) -> Int32? in
            return response.result
        }.catchError { (error) -> Observable<Int32?> in
            SpaceRustRouter.logger.error("Rust service cancelAllRequest failed", error: error)
            return .just(nil)
        }
    }
}

extension SpaceRustRouter: DriveRustRouterBase {

    public var mainMountPointTokenString: String {
        return SpaceRustRouter.mainMountPointToken
    }
    
    public func downloadNormal(remoteUrl: String,
                               localPath: String,
                               fileSize: String?,
                               slice: Bool,
                               priority: DriveDownloadPriority) -> Observable<String> {
        return downloadNormal(remoteUrl: remoteUrl,
                              localPath: localPath,
                              fileSize: fileSize,
                              slice: slice,
                              priority: priority,
                              authExtra: nil)
    }

    public func downloadfile(localPath: String,
                             fileToken: String,
                             mountNodePoint: String,
                             mountPoint: String) -> Observable<String> {
        let context = DownloadRequestContext(localPath: localPath,
                                             fileToken: fileToken,
                                             docToken: "",
                                             docType: nil,
                                             mountNodePoint: mountNodePoint,
                                             mountPoint: mountPoint,
                                             dataVersion: nil,
                                             priority: .default,
                                             apiType: .drive,
                                             coverInfo: nil,
                                             authExtra: nil,
                                             disableCDN: false,
                                             teaParams: [:])
        let request = SpaceRustRouter.constructDownloadRequest(context: context)
        
        return download(request: request)
    }
}

// MARK: - SM4GCM Thumbnail Decrypt
extension SpaceRustRouter: SM4GCMExternalDecrypter {

    enum RustSM4GCMDecryptError: Error {
        case rustServiceInvalid
        case rustDecryptFailed(message: String)
    }
    
    public func decrypt(encryptedData: Data, secret: String, nonce: String) throws -> Data {
        guard let rustService = rustService else {
            throw RustSM4GCMDecryptError.rustServiceInvalid
        }
        var request = DriveDecryptRequest()
        request.decryptType = .sm4Gcm
        request.key = secret
        request.nonce = nonce
        request.body = encryptedData
        let response: DriveDecryptResponse = try rustService.sendSyncRequest(request)
        guard response.success else {
            throw RustSM4GCMDecryptError.rustDecryptFailed(message: response.errorMessage)
        }
        return response.body
    }
}

extension DrivePushDownloadCallback: CustomStringConvertible {
    public var description: String {
        return "Key: \(self.key), status: \(self.status), moutPoint: \(self.mountPoint), scene: \(self.scene), bytesTransferred: \(self.bytesTransferred), bytesTotal: \(self.bytesTotal), dataVersion: \(self.dataVersion), failedInfo: \(self.failedInfo)"
    }
}

extension DrivePushUploadCallback: CustomStringConvertible {
    public var description: String {
        return "Key: \(self.key), status: \(self.status), moutPoint: \(self.mountPoint), scene: \(self.scene), bytesTransferred: \(self.bytesTransferred), bytesTotal: \(self.bytesTotal), dataVersion: \(self.dataVersion), failedInfo: \(self.failedInfo)"
    }
}
