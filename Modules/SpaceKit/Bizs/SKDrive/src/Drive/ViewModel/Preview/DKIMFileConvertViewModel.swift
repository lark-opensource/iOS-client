//
//  DKIMFileConvertViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/5/19.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import LKCommonsLogging
import SKResource
import SpaceInterface
import LarkDocsIcon

protocol DKIMFileConvertVMDependency {
    func getChatToken(msgID: String) -> Observable<SpaceRustRouter.ConvertInfo>
    // msgID: messageID
    // chat_token: getChatToken返回的鉴权信息
    // type: 云文档类型：doc 文档， sheet 电子表格， docx doc2.0
    func createTask(msgID: String, chatToken: String, type: String?) -> Observable<[String: Any]>
    func startPolling(ticket: String, timeOut: Int) -> Observable<[String: Any]>
}

class DKIMFileConvertViewModel: NSObject, DKConvertFileVMProtocol {
    static let logger = Logger.log(DKIMFileConvertViewModel.self, category: "DocsSDK.drive.convertIMFile")
    typealias CreateResult = (ticket: String, timeout: Int)
    private let fileInfo: DKFileInfo
    private let msgID: String
    private let dependency: DKIMFileConvertVMDependency
    private let performanceLogger: DrivePerformanceRecorder
    private let helper = ConvertFileHelper()
    private let networkMonitor: SKNetStatusService
    private var isReachable: Bool {
        didSet {
            self.bindAction?(.networkChanged(isReachable))
        }
    }
    private var disposeBag = DisposeBag()
    init(fileInfo: DKFileInfo, msgID: String,
         dependency: DKIMFileConvertVMDependency,
         performanceLogger: DrivePerformanceRecorder,
         networkMonitor: SKNetStatusService = DocsNetStateMonitor.shared) {
        self.fileInfo = fileInfo
        self.msgID = msgID
        self.dependency = dependency
        self.performanceLogger = performanceLogger
        self.networkMonitor = networkMonitor
        self.isReachable = networkMonitor.isReachable
        super.init()
        self.setupNetworkMonitor()
    }
    
    // DKConvertFileVMProtocol
    var fileID: String {
        return fileInfo.fileID
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
    
    func isFileSizeOverLimit() -> Bool {
        return DriveConvertFileConfig.isSizeOverLimit(fileInfo.size)
    }
    
    func convertFile() {
        dependency.getChatToken(msgID: msgID).flatMap {[weak self] info -> Observable<[String: Any]> in
            guard let self = self else { return Observable<[String: Any]>.never() }
            Self.logger.info("get chat token success \(self.msgID.encryptToken)")
            self.performanceLogger.stageBegin(stage: .startImportFile, loadingType: .preview)
            return self.dependency.createTask(msgID: self.msgID, chatToken: info.chatToken, type: nil)
        }.flatMap {[weak self] json -> Observable<CreateResult> in
            guard let self = self else { return Observable<CreateResult>.never() }
            self.performanceLogger.stageEnd(stage: .startImportFile)
            guard let ticket = json["ticket"] as? String, let time = json["job_timeout"] as? Int else {
                Self.logger.info("createTask failed with invalid data  \(self.msgID.encryptToken)")
                return Observable.error(DriveConvertFileError.invalidDataError)
            }
            Self.logger.info("createTask success \(self.msgID.encryptToken), timout: \(time)")
            return Observable.just(CreateResult(ticket: ticket, timeout: time))
        }.flatMap {[weak self] result -> Observable<[String: Any]> in
            guard let self = self else { return Observable<[String: Any]>.never() }
            Self.logger.info("start polling  \(self.msgID.encryptToken), timout: \(result.timeout)")
            self.performanceLogger.stageBegin(stage: .checkImportResult, loadingType: .preview)
            return self.dependency.startPolling(ticket: result.ticket, timeOut: result.timeout)
        }.subscribe(onNext: {[weak self] result in
            guard let self = self else { return }
            self.performanceLogger.stageEnd(stage: .checkImportResult)
            Self.logger.info("handle result")
            self.handleResult(result)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            Self.logger.info("handle error")
            self.performanceLogger.stageEnd(stage: .startImportFile)
            self.performanceLogger.stageEnd(stage: .checkImportResult)
            self.handleError(error)
        }).disposed(by: disposeBag)
    }
    
    private func handleResult(_ result: [String: Any]) {
        self.performanceLogger.importFinished(result: .success, code: .success)
        if !self.isReachable {
            Self.logger.info("handle result network not reachable")
            self.bindAction?(.showFailedView(.networkInterruption))
            return
        }
        let viewTypes = helper.handleConvertResult(result, fileType: fileInfo.type)
        for viewType in viewTypes {
            Self.logger.info("handle result show type: \(viewType)")
            self.bindAction?(viewType)
        }
    }
    
    private func handleError(_ error: Error) {
        Self.logger.error("convert file failed: \(error)")
        reportFailed()
        if !self.isReachable {
            Self.logger.info("network not reachable")
            performanceLogger.importFinished(result: .nativeFail, code: .noNetwork)
            self.bindAction?(.showFailedView(.networkInterruption))
            return
        } else {
            if let convertError = error as? DriveConvertFileError { // 业务错误
                switch convertError {
                case .invalidDataError:
                    self.bindAction?(.showFailedView(.importFailedRetry))
                case .serverError(let code):
                    let viewType: DriveImportFailedViewType
                    if code == DriveConvertFileNewErrorCode.dlpCheckedFailed.rawValue {
                        if fileType.canImportAsDocs {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithDocsNew_Toast)
                        } else if fileType.canImportAsSheet {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithSheetsNew_Toast)
                        } else if fileType.canImportAsMindnote {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_FileSensitiveUnableToOpenWithMindnote_Toast)
                        } else {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithDocsNew_Toast)
                        }
                    } else if code == DriveConvertFileNewErrorCode.dlpChecking.rawValue {
                        if fileType.canImportAsDocs {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithDocs_Toast)
                        } else if fileType.canImportAsSheet {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithSheets_Toast)
                        } else if fileType.canImportAsMindnote {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithMindnoteTryLater_Toast)
                        } else {
                            viewType = helper.handleNewErrorCode(code: code, text: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToOpenWithDocs_Toast)
                        }
                    } else {
                        viewType = helper.handleNewErrorCode(code: code)
                    }
                    self.bindAction?(.showFailedView(viewType))
                }
            } else {
                let viewType = helper.handleNetworkError(error)
                Self.logger.info("handle error show type: \(viewType)")
                self.bindAction?(viewType)
            }
        }
    }
    
    private func setupNetworkMonitor() {
        networkMonitor.addObserver(self) { [weak self] (networkType, isReachable) in
            Self.logger.debug("Current networkType is \(networkType)")
            guard let self = self else {
                Self.logger.error("DriveConvertFileViewModel is nil")
                return
            }
            self.isReachable = isReachable
        }
    }
    
    private func reportFailed() {
        performanceLogger.sourceType = .preview
        performanceLogger.importFinished(result: .serverFail)
    }
}

class ConvertFileHelper {
    static let logger = Logger.log(ConvertFileHelper.self, category: "DocsSDK.drive.convertIMFile")

    // result: get convert result
    // fileType: drive文件后缀
    func handleConvertResult(_ result: [String: Any], fileType: String) -> [DriveConvertFileAction] {
        guard let resultCode = result["code"] as? Int else {
            Self.logger.error("getConvertResult failed: get code failed")
            return [.showFailedView(.importFailedRetry)]
        }
        guard resultCode == 0 else {
            Self.logger.error("getConvertResult failed result code \(resultCode)")
            // 联系客服用来兜底
            let viewType = self.handleNewErrorCode(code: resultCode)
            return [.showFailedView(viewType)]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: result, options: []),
            let parseReuslt = try? JSONDecoder().decode(DriveConvertNewResult.self, from: data) else {
                Self.logger.error("getConvertResult parse data failed")
                return [.showFailedView(.importFailedRetry)]
        }
        let statusCode = parseReuslt.data.result.jobStatus
        guard statusCode == 0 else {
            Self.logger.error("getConvertResult status code \(statusCode)")
            // 联系客服用来兜底
            let viewType = self.handleNewErrorCode(code: statusCode)
            return [.showFailedView(viewType)]
        }
        guard let token = parseReuslt.data.result.token, !token.isEmpty,
                let type = parseReuslt.data.result.type else {
            Self.logger.error("getConvertResult failed: tokens is nil")
            // 联系客服用来兜底
            let viewType = self.handleNewErrorCode(code: resultCode)
            return [.showFailedView(viewType)]
        }
        var actions = [DriveConvertFileAction]()
        if let data = result["data"] as? [String: Any],
           let result = data["result"] as? [String: Any],
            let extra = result["extra"] as? [String: String],
           let tips = extraCodeTips(extra: extra) {
            Self.logger.error("getConvertResult success extra no nil")
            actions.append(.showToast(tips))
        }
        Self.logger.error("getConvertResult success routed to external")
        let convertType = self.convert(from: fileType, specifyType: type)
        actions.append(.routedToExternal(token, convertType))
        return actions
    }
    // 旧接口错误码处理
    func handleOldErrorCode(code: Int) -> DriveImportFailedViewType? {
        guard let parseFileErrorCode = DriveConvertFileErrorCode(rawValue: code) else {
            Self.logger.error("Create DriveParseFileErrorCode failed")
            return nil
        }
        switch parseFileErrorCode {
        case .failed:
            return DriveImportFailedViewType.contactService
        case .xmlVersionNotSupport:
            return DriveImportFailedViewType.unsupportType
        case .fileEncrypt:
            return DriveImportFailedViewType.unsupportEncryptFile
        case .tosFailed:
            return DriveImportFailedViewType.importFailedRetry
        case .mysqlFaild:
            return DriveImportFailedViewType.importFailedRetry
        case .rpcFailed:
            return DriveImportFailedViewType.importFailedRetry
        case .needCharge:
            return DriveImportFailedViewType.numberOfFileExceedsTheLimit
        case .amountExceedLimit:
            return DriveImportFailedViewType.amountExceedLimit
        case .hierarchyExceedLimit:
            return DriveImportFailedViewType.hierarchyExceedLimit
        case .sizeExceedLimit:
            return DriveImportFailedViewType.sizeExceedLimit
        case .dataLockedForMigration:
            return .dataLockedForMigration
        case .unavailableForCrossTenantGeo:
            return .unavailableForCrossTenantGeo
        case .unavailableForCrossBrand:
            return .unavailableForCrossBrand
        }
    }
    // swiftlint:disable cyclomatic_complexity
    func handleNewErrorCode(code: Int, text: String = "") -> DriveImportFailedViewType {
        Self.logger.info("handle new error code \(code)")
        guard let parseFileErrorCode = DriveConvertFileNewErrorCode(rawValue: code) else {
            Self.logger.error("Create DriveParseFileErrorCode failed")
            return .contactService
        }
        switch parseFileErrorCode {
        case .creatNewMission, .convertProcessing:
            return .contactService
        case .xmlVersionNotSupport, .spaceOutOfLimit, .importFileExtensionNotMatch, .importFileTypeNotMatch, .importFileExpired,
             .fileFormatNotSupported, .fileContentParserFailed, .convertFileTokenNotFound, .convertImportFileExtenNotMatch, .convertImportFiletypeNotMatch, .convertFileTokenExpired:
            return .contactService
        case .convertImportFileSizeOverLimit, .importSizeLimit:
            return DriveImportFailedViewType.importTooLarge
        case .noPermission, .mountNoPermission, .convertNoPermission, .convertMountNoPermission:
            return .noPermission
        case .spaceBillingUnavailable:
            return .spaceBillingUnavailable
        case .mountNotExist, .mountDeleted, .convertMountPointNotExist:
            return .mountNotExist
        case .encryptFile:
            return .unsupportEncryptFile
        case .importFileSizeZero, .convertImportFileSizeZero:
            return .importFileSizeZero
        case .failed, .tosFailed, .mysqlFailed, .rpcFailed, .jobTimeout, .importDownloadFileFailed, .docJavaSdkParserFailed, .convertMysqlError, .convertRpcError, .convertInternalError:
            return .importFailedRetry
        case .amountExceedLimit:
            return .amountExceedLimit
        case .hierarchyExceedLimit:
            return .hierarchyExceedLimit
        case .sizeExceedLimit:
            return .sizeExceedLimit
        case .dataLockedForMigration:
            return .dataLockedForMigration
        case .unavailableForCrossTenantGeo:
            return .unavailableForCrossTenantGeo
        case .unavailableForCrossBrand:
            return .unavailableForCrossBrand
        case .dlpCheckedFailed:
            return .dlpCheckedFailed(text)
        case .dlpChecking:
            return .dlpChecking(text)
        case .dlpExternalDetcting:
            return .dlpExternalDetcting
        case .dlpExternalSensitive:
            return .dlpExternalSensitive
        }
    }
    
    func handleNetworkError(_ error: Error) -> DriveConvertFileAction {
        guard let code = (error as? DocsNetworkError)?.code else {
            return .showFailedView(.importFailedRetry)
        }
        switch code {
        case .dataLockedForMigration:
            return .showFailedView(.dataLockedForMigration)
        case .unavailableForCrossBrand:
            return .showFailedView(.unavailableForCrossBrand)
        case .unavailableForCrossTenantGeo:
            return .showFailedView(.unavailableForCrossTenantGeo)
        default:
            return .showFailedView(.importFailedRetry)
        }
    }
    
    /// 将文件类型转换成 DocsType
    /// - Parameters:
    ///   - fileType: 文件类型
    ///   - specifyType: 指定转换成的类型，目前仅用于 docX 场景
    /// - Returns: DocsType
    func convert(from fileType: String, specifyType: String?) -> DocsType {
        let fileType = DriveFileType(fileExtension: fileType)
        if fileType.canImportAsDocs {
            return specifyType == "docx" ? .docX: .doc
        } else if fileType.canImportAsSheet {
            return .sheet
        } else if fileType.canImportAsMindnote {
            return .mindnote
        } else {
            return .unknownDefaultType
        }
    }
    
    // error code to drive tech stastics
    func errorCodeToResults(code: Int) -> (DriveResultKey, DriveResultCode)? {
        guard let parseFileErrorCode = DriveConvertFileErrorCode(rawValue: code) else {
            Self.logger.error("Create DriveParseFileErrorCode failed in reportErrorCode()")
            return nil
        }
        Self.logger.error("OpenFinish DriveFile failed in preview")
        switch parseFileErrorCode {
        case .failed:
            return (.serverFail, .startConvertFailed)
        case .fileEncrypt:
            return (.serverFail, .unsupportPreviewFileType)
        case .xmlVersionNotSupport:
            return (.serverFail, .xmlVersionNotSupport)
        case .mysqlFaild:
            return (.serverFail, .mysqlFailed)
        case .needCharge:
            return (.serverFail, .needCharge)
        case .rpcFailed:
            return (.serverFail, .rpcFailed)
        case .tosFailed:
            return (.serverFail, .tosFailed)
        default:
            return nil
        }
    }
    
    private func extraCodeTips(extra: [String: String]) -> String? {
        let keys = extra.keys.compactMap { Int($0) }
        guard let code = keys.first else {
            Self.logger.error("extra code keys count is 0")
            return nil
        }
        guard let extraCode = DriveConvertExtraCode(rawValue: code) else {
            Self.logger.error("extra code not define: \(code)")
            return nil
        }
        return extraCode.errorTips
    }
}
