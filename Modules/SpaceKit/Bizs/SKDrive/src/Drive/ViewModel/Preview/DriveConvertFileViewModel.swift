//
//  DriveImportAsDocsViewModel.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/26.

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import LarkUIKit
import LKCommonsLogging
import SpaceInterface
import SKInfra
import LarkDocsIcon
import RxSwift

class DriveConvertFileViewModel: NSObject, DKConvertFileVMProtocol {
    static let logger = Logger.log(DriveConvertFileViewModel.self, category: "DocsSDK.drive.convertSpaceFile")
    // MARK: - fileInfo
    private(set) var fileInfo: DriveFileInfo

    // MARK: - Network
    /// 导入为在线文档
    private var parseFileRequest: DocsRequest<JSON>?

    /// 获取导入结果
    private var getParseResultRequest: DocsRequest<JSON>?

    private let networkManager: DrivePreviewNetManager

    private let permissionHelper: DrivePermissionHelper
    
    private let helper = ConvertFileHelper()

    /// 文件转换结果长链
    private var pushHandler: DriveConvertFilePushHandler?
    private var timer: Timer?
    private let userId = User.current.info?.userID ?? ""

    // MARK: - Utils
    /// 获取导入结果的token
    private var ticket: String?

    let requestGroup: DispatchGroup = DispatchGroup()

    private(set) var performanceLogger: DrivePerformanceRecorder

    var fileID: String {
        return fileInfo.fileToken
    }
    
    var fileType: DriveFileType {
        return fileInfo.fileType
    }
    
    var name: String {
        return fileInfo.name
    }
    
    var fileSize: UInt64 {
        return fileInfo.size
    }
    
    var bindAction: ((DriveConvertFileAction) -> Void)?

    var isReachable: Bool = DocsNetStateMonitor.shared.isReachable {
        didSet {
            self.bindAction?(.networkChanged(isReachable))
        }
    }
    
    private var docxImportEnabled: Bool
    private var docxEnable: Bool
    private let refreshTime: TimeInterval
    private let disposeBag = DisposeBag()

    init(fileInfo: DriveFileInfo,
         performanceLogger: DrivePerformanceRecorder,
         docxImportEnabled: Bool = LKFeatureGating.docxImportEnabled,
         docxEnable: Bool = LKFeatureGating.docxEnabled,
         refreshTime: TimeInterval = 60.0) {
        self.fileInfo = fileInfo
        self.performanceLogger = performanceLogger
        self.networkManager = DrivePreviewNetManager(performanceLogger, fileInfo: fileInfo)
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let service = permissionSDK.userPermissionService(for: .document(token: fileInfo.fileToken, type: .file), withPush: true)
        self.permissionHelper = DrivePermissionHelper(fileToken: fileInfo.fileToken, type: .file, permissionService: service)
        self.docxImportEnabled = docxImportEnabled
        self.docxEnable = docxEnable
        self.refreshTime = refreshTime
        super.init()
        setupNetworkMonitor()
        setupMonitorPermissions()
        updateFileInfo(fileToken: fileInfo.fileToken)

        /// 注册长链
        self.registerPushHandler()
    }

    deinit {
        Self.logger.info("DriveConvertFileViewModel --- deinit")
        stopTimer()
    }

    func isFileSizeOverLimit() -> Bool {
        return DriveConvertFileConfig.isSizeOverLimit(fileInfo.size)
    }
    
    func getCloudDocumentType() -> String {
        let type = fileInfo.fileType
        if type.canImportAsDocs {
            if docxImportEnabled && docxEnable {
                return "docx"
            } else {
                return "doc"
            }
        } else if type.canImportAsSheet {
            return "sheet"
        } else if type.canImportAsMindnote {
            return "mindnote"
        } else {
            Self.logger.info("unsupported conversion type")
            return ""
        }
    }
    // MARK: - Network
    func convertFile() {
        parseFileRequest?.cancel()
        
        var params = [String: Any]()
        var importAPI = ""
        var encodingType: ParamEncodingType
        params = ["file_token": fileInfo.fileToken,
                    "type": getCloudDocumentType(),
                    "file_extension": fileInfo.fileExtension ?? "",
                    "point": ["mount_type": 1, "mount_key": ""],
                    "event_source": "15",
                    "message_tag": StablePushPrefix.convertFile.rawValue + "_" + userId]
        importAPI = OpenAPI.APIPath.importFile
        encodingType = .jsonEncodeDefault
        performanceLogger.stageBegin(stage: .startImportFile, loadingType: .preview)
        requestGroup.enter()
        parseFileRequest = DocsRequest<JSON>(path: importAPI, params: params)
            .set(method: .POST)
            .set(encodeType: encodingType)
            .set(needVerifyData: false)
            .start(result: { [weak self] (json, error) in
                guard let self = self else {
                    Self.logger.error("DriveConvertFileViewModel is nil")
                    return
                }
                defer {
                    self.requestGroup.leave()
                }
                self.performanceLogger.stageEnd(stage: .startImportFile)
                if let error = error {
                    Self.logger.error("DrivePreviewNetManager.parseFile: \(String(describing: error.localizedDescription))")
                    self.handleNetworkError(error: error)
                    return
                }
                guard let json = json,
                      let resultCode = json["code"].int else {
                    Self.logger.error("DrivePreviewNetManager.parseFile：failed to get json data")
                    self.reportFailed()
                    self.bindAction?(.showFailedView(.importFailedRetry))
                    return
                }
                guard resultCode == 0 else {
                    // 联系客服用来兜底
                    let viewType = self.handleErrorCode(code: resultCode) ?? .contactService
                    self.bindAction?(.showFailedView(viewType))
                    return
                }
                var jsonTicket: JSON
                jsonTicket = json["data"]["ticket"]
                guard let ticket = jsonTicket.string else {
                    Self.logger.error("DrivePreviewNetManager.parseFile：failed to ticket")
                    self.reportFailed()
                    self.bindAction?(.showFailedView(.contactService))
                    return
                }
                self.ticket = ticket
            })
    }

    private func registerPushHandler() {
        pushHandler = DriveConvertFilePushHandler(userId: userId)
        pushHandler?.delegate = self
    }

    private func startTimer(ticket: String) {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: refreshTime,
                                     repeats: false,
                                     block: { [weak self] _ in
            self?.getconvertNewResult(ticket: ticket)
        })
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getconvertNewResult(ticket: String) {
        getParseResultRequest?.cancel()
        performanceLogger.stageBegin(stage: .checkImportResult, loadingType: .preview)
        getParseResultRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getImportResult + ticket, params: nil)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .start(result: { [weak self] (json, error) in
                guard let self = self else {
                    Self.logger.error("DriveConvertFileViewModel is nil")
                    return
                }
                self.performanceLogger.stageEnd(stage: .checkImportResult)
                Self.logger.error("getConvertResult failed with error: \(String(describing: error))")
                
                if !self.isReachable {
                    self.reportFailed()
                    self.bindAction?(.showFailedView(.networkInterruption))
                }
                guard let result = json?.dictionaryObject else {
                    Self.logger.error("getConvertResult failed: get code failed")
                    self.reportFailed()
                    self.bindAction?(.showFailedView(.importFailedRetry))
                    return
                }
                self.performanceLogger.importFinished(result: .success, code: .success)
                let viewTypes = self.helper.handleConvertResult(result, fileType: self.fileInfo.type)
                for viewType in viewTypes {
                    self.bindAction?(viewType)
                }
                // 通知我的文档列表刷新
                NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
            })
    }

    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
            Self.logger.info("Current networkType is \(networkType)")
            guard let self = self else {
                Self.logger.error("DriveConvertFileViewModel is nil")
                return
            }
            self.isReachable = isReachable
        }
    }

    private func handleNetworkError(error: Error) {
        guard isReachable else {
            bindAction?(.showFailedView(.networkInterruption))
            return
        }
        let action = self.helper.handleNetworkError(error)
        bindAction?(action)
    }

    // MARK: - FileInfo
    func updateFileInfo(fileToken: String) {
        requestGroup.enter()
        let context = FetchFileInfoContext(showInRecent: false,
                                           version: nil,
                                           optionParams: [],
                                           pollingStrategy: DriveInfoPollingStrategy())
        networkManager.fetchFileInfo(context: context, polling: nil) { [weak self] (result) in
            guard let self = self else {
                Self.logger.info("DriveConvertFileViewModel.updateFileInfo: self is nil")
                return
            }
            defer {
                self.requestGroup.leave()
            }
            switch result {
            case .success(let fileInfo):
                self.fileInfo = fileInfo
            case .failure(let error):
                Self.logger.info("DriveConvertFileViewModel: fetch fileInfo failed", error: error)
            }
        }
        requestGroup.notify(queue: DispatchQueue.main) {
            self.bindAction?(.updateFileSizeText(DriveConvertFileConfig.getFileSizeText(from: self.fileInfo.size)))
            /// 判断fileSize是否超出限制
            if DriveConvertFileConfig.isSizeOverLimit(self.fileInfo.size) {
                self.bindAction?(.showFailedView(.fileSizeOverLimit))
                return
            }
            guard let ticket = self.ticket else {
                Self.logger.warn("ticket is nil")
                return
            }
            /// 开启1分钟超时检测
            self.startTimer(ticket: ticket)
        }
    }
}

// MARK: - DrivePermissionDelegate
extension DriveConvertFileViewModel {
    func permissionChanged(response: DrivePermissionInfo) {
        if !response.canExport {
            Self.logger.info("DriveConvertFileViewModel.permissionChanged: permissions has been changed")
            self.bindAction?(.showFailedView(.noPermission))
        } else {
            Self.logger.info("DriveConvertFileViewModel.permissionChanged: permissions haven't changed")
        }
    }
    func setupMonitorPermissions() {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let service = permissionHelper.permissionService
            service.onPermissionUpdated.subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                let allowExport = self.permissionHelper.permissionService.validate(operation: .importToOnlineDocument).allow
                if !allowExport {
                    Self.logger.info("DriveConvertFileViewModel.permissionChanged: permissions has been changed, export forbidden")
                    self.bindAction?(.showFailedView(.noPermission))
                }
            }).disposed(by: disposeBag)
            service.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            permissionHelper.startMonitorPermission(startFetch: { },
                                                    permissionChanged: {[weak self] (info) in
                self?.permissionChanged(response: info)
            },
                                                    failed: { error in
                Self.logger.error("DriveConvertFileViewModel.permissionChanged: \(error) ")
            })
        }
    }
}

extension DriveConvertFileViewModel {
    private func handleErrorCode(code: Int) -> DriveImportFailedViewType? {
        /// Drive技术埋点
        reportErrorCode(code)
        return helper.handleNewErrorCode(code: code)
    }
}

// MARK: - Drive技术埋点
extension DriveConvertFileViewModel {
    private func reportErrorCode(_ code: Int) {
        performanceLogger.sourceType = .preview
        if let result = helper.errorCodeToResults(code: code) {
            performanceLogger.importFinished(result: result.0, code: result.1)
        } else {
            performanceLogger.importFinished(result: .serverFail)
        }
    }
    
    private func reportFailed() {
        performanceLogger.sourceType = .preview
        performanceLogger.importFinished(result: .serverFail)
    }
}

extension DriveConvertFileViewModel: DriveConvertFilePushHandlerDelegate {
    func fileConvertionDidFinished(code: Int, ticket: String, token: String, type: String?) {
        guard ticket == self.ticket else {
            Self.logger.info("not my ticket")
            return
        }
        guard code == 0 else {
            let viewType = self.handleErrorCode(code: code) ?? .contactService
            self.bindAction?(.showFailedView(viewType))
            stopTimer()
            return
        }
        stopTimer()
        let type = self.helper.convert(from: self.fileInfo.type, specifyType: type)
        self.bindAction?(.routedToExternal(token, type))
    }
}
