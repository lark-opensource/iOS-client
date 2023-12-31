//
//  ExportDocumentDownload.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/23.
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import RxSwift
import SpaceInterface
import SKInfra

protocol ExportDocumentDownloadDelegate: AnyObject {
    func exportDocumentDownload(_ download: ExportDocumentDownload, getTicketFinish result: Result<String, Error>) // 获取Ticket
    func exportDocumentDownload(_ download: ExportDocumentDownload, continuePollExportResult: Bool) //是否继续轮询获取导出结果
    func exportDocumentDownload(_ download: ExportDocumentDownload, downloadFile result: Result<URL, Error>) //下载结果
    func exportDocumentDownload(_ download: ExportDocumentDownload, downloadProgress: Float) //下载进度
}

class ExportDocumentDownload {
    private var pollingTimeout: TimeInterval = 0
    private let firstPollingInterval: TimeInterval = 1
    private let pollingInterval: TimeInterval = 3
    private var shouldContinuePoll: Bool {
        guard pollingTimeout > 0 else { return false }
        guard exportResultPollingCount > 0 else { return true }
        let curCostTime = firstPollingInterval + Double((exportResultPollingCount - 1)) * pollingInterval
        return curCostTime < pollingTimeout
    }

    private var exportRequest: DocsRequest<JSON>?
    private var getExportResultRequest: DocsRequest<JSON>?
    private var downloader: DocumentDownloader?

    private let format: ExportDocumentType
    private let token: String
    private let fileName: String
    private var needComment: Bool?
    private var isCancel: Bool = false
    private var docsType: DocsType

    private let exportTimeOut: Double = 30
    private let pollingMaxCount: Int = 20
    private var exportResultPollingCount: Int = 0

    private let disposeBag = DisposeBag()
    
    private var destinationPath: SKFilePath {
        let tmpDir = SKFilePath.globalSandboxWithTemporary
        var suffix: String
        switch self.format {
        case .slide2pdf, .pdf:
            suffix = "\(fileName).pdf"
        case .slide2png:
            suffix = "\(fileName).zip"
        case .docx:
            suffix = "\(fileName).docx"
        case .xlsx:
            suffix = "\(fileName).xlsx"
        default:
            suffix = "unkown"
        }
        let handleSuffix = _handleLocPathSuffix(suffix)
        return tmpDir.appendingRelativePath(handleSuffix)
    }

    private var destinationURL: URL {
        return destinationPath.pathURL
    }
    
    //文档导出传给drive的临时path，如果传文档标题path过长会导致导出失败，统一传脱敏token
    private var tempPath: SKFilePath {
        var lastPath = destinationURL.lastPathComponent
        if let range = lastPath.range(of: fileName, options: [.backwards]) {
            lastPath = lastPath.replacingCharacters(in: range, with: token.encryptToken)
        }
        return SKFilePath.globalSandboxWithTemporary.appendingRelativePath(lastPath)
    }

    private weak var delegate: ExportDocumentDownloadDelegate?


    init(format: ExportDocumentType, token: String, docsType: DocsType, fileName: String, needComment: Bool?, delegate: ExportDocumentDownloadDelegate? = nil) {
        self.format = format
        self.token = token
        self.fileName = fileName
        self.docsType = docsType
        self.needComment = needComment
        self.delegate = delegate
    }

    func start() {
        newGetTicket(token: token, type: docsType, format: format.rawValue, needComment: needComment) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let ticket):
                self.newGetExportResultRequest(token: self.token, ticket: ticket, type: self.docsType) { [weak self] (result) in
                    guard let self = self else { return }
                    switch result {
                    case .success(let fileToken):
                        self.newStartDownloadFile(fileToken: fileToken, type: self.docsType) { [weak self] (result) in
                            guard let self = self else { return }
                            switch result {
                            case .success(let url):
                                self.delegate?.exportDocumentDownload(self, downloadFile: .success(url))
                            case .failure(let error):
                                self.delegate?.exportDocumentDownload(self, downloadFile: .failure(error))
                            }
                        }
                    case .failure(let error):
                        self.delegate?.exportDocumentDownload(self, downloadFile: .failure(error))
                    }
                }
            case .failure(let error):
                self.delegate?.exportDocumentDownload(self, downloadFile: .failure(error))
            }
        }
    }

    func cancel() {
        isCancel = true
        exportRequest?.cancel()
        getExportResultRequest?.cancel()
        downloader?.cancelDownload()
    }

    private func newGetTicket(token: String, type: DocsType, format: String, needComment: Bool?,
                              complete: @escaping (Result<String, NewExportDownloadError>) -> Void) {
        var params: [String: Any] = ["token": token,
                                        "type": type.name,
                                        "file_extension": format,
                                        "event_source": "15"]
        if let need = needComment {
            params["need_comment"] = need
        }
        DocsLogger.info("\(format) new request export - 开始请求后台生成导出文件")
        exportRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.requestExportNew, params: params)
            .set(method: .POST)
            .set(needVerifyData: false)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: exportTimeOut)
            .set(headers: ["env": "ccm_oldgw"])
            .start(result: {[weak self] (result, error) in
                guard let self = self else { return }
                guard !self.isCancel else { return }
                guard let json = result, error == nil else {
                    DocsLogger.error("\(self.format) new request export - failed: \(String(describing: error?.localizedDescription))")
                    complete(.failure(.requestExportError))
                    return
                }
                guard let code = json["code"].int else {
                    complete(.failure(.requestExportError))
                    return
                }
                if code == 0, let response = json["data"].dictionary, let ticket = response["ticket"]?.string {
                    let jobTimeout = response["job_timeout"]?.int ?? Int(60.0)
                    self.pollingTimeout = TimeInterval(jobTimeout)
                    complete(.success(ticket))
                    self.delegate?.exportDocumentDownload(self, getTicketFinish: .success(ticket))
                } else {
                    let msg = json["msg"].string ?? ""
                    let error = NewExportDownloadError.exportResultErrorWithCode(code)
                    DocsLogger.error("\(self.format) new request export - code error failed: \(msg), code: \(code)")
                    complete(.failure(error))
                }
            })
    }

    private func newGetExportResultRequest(token: String, ticket: String, type: DocsType,
                                           complete: @escaping (Result<String, NewExportDownloadError>) -> Void) {
        let params: [String: String] = ["token": token,
                                        "type": type.name]
        DocsLogger.info("\(self.format) new get export Result - 开始轮询请求结果")
        getExportResultRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getExportResultNew + ticket, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .set(headers: ["env": "ccm_oldgw"])
            .start(result: {[weak self] (result, error) in
                guard let `self` = self else { return }
                guard !self.isCancel else { return }
                guard let json = result, error == nil else {
                    DocsLogger.error("\(self.format) new get export Result - failed: \(String(describing: error?.localizedDescription))")
                    complete(.failure(.requestExportError))
                    return
                }
                guard let code = json["code"].int else {
                    complete(.failure(.requestExportError))
                    return
                }
                if code == 0, let data = json["data"].dictionary, let response = data["result"]?.dictionary, let jobStatus = response["job_status"]?.int {
                    // request success
                    if jobStatus == 0, let fileToken = response["file_token"]?.string {
                        complete(.success(fileToken))
                        self.delegate?.exportDocumentDownload(self, continuePollExportResult: false)
                    } else if jobStatus == 1 || jobStatus == 2 {
                        guard self.shouldContinuePoll else {
                            DocsLogger.info("\(self.format) new get export Result - retry cost time more than pollingTimeout: \(self.exportResultPollingCount)")
                            complete(.failure(.requestExportError))
                            return
                        }
                        // continue
                        DocsLogger.info("\(self.format) new get export Result - retry status: \(self.exportResultPollingCount)")
                        // 第一次1s，后面3s
                        if self.exportResultPollingCount == 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.firstPollingInterval) {
                                self.newGetExportResultRequest(token: token, ticket: ticket, type: type, complete: complete)
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.pollingInterval) {
                                self.newGetExportResultRequest(token: token, ticket: ticket, type: type, complete: complete)
                            }
                        }
                        self.exportResultPollingCount += 1
                        self.delegate?.exportDocumentDownload(self, continuePollExportResult: true)
                    } else {
                        let msg = response["job_error_msg"]?.string ?? ""
                        let error = NewExportDownloadError.exportResultErrorWithJobStatus(jobStatus)
                        DocsLogger.error("\(self.format) new get export Result - code error failed: \(msg), jobStatus: \(jobStatus)")
                        complete(.failure(error))
                    }
                } else {
                    let msg = json["message"].string ?? ""
                    let error = NewExportDownloadError.exportResultErrorWithCode(code)
                    DocsLogger.error("\(self.format) new get export Result - code error failed: \(msg), code: \(code)")
                    complete(.failure(error))
                }
            })
    }

    private func newStartDownloadFile(fileToken: String, type: DocsType,
                                      complete: @escaping (Result<URL, NewExportDownloadError>) -> Void) {
        downloader = DocumentDownloader(docsType: type)
        downloader?.progressObserver.subscribe(onNext: { [weak self] (progress) in
            guard let self = self else { return }
            self.delegate?.exportDocumentDownload(self, downloadProgress: progress)
        }).disposed(by: disposeBag)
        downloader?.completedObserver.subscribe(onNext: { [weak self] (success, errorCode) in
            guard let self = self else { return }
            guard !self.isCancel else { return }
            if let errorCode = errorCode {
                DocsLogger.info("\(self.format) new download - endDownloadFile failed: \(errorCode)")
                complete(.failure(.requestExportError))
                return
            }
            DocsLogger.info("\(self.format) new download - endDownloadFile")
            if self.tempPath.moveItem(to: self.destinationPath) {
                complete(.success(self.destinationURL))
            } else {
                DocsLogger.info("\(self.format) new download - move fail, download to \(self.tempPath)")
                complete(.success(URL(fileURLWithPath: self.tempPath.pathString)))
            }
        }).disposed(by: disposeBag)
        DocsLogger.info("\(self.format) new download - startDownloadFile")
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            self.downloader?.startDownload(localPath: self.tempPath.pathString, fileToken: fileToken)
        }
    }
}

extension ExportDocumentDownload {
    /// handle localPath suffix
    private func _handleLocPathSuffix(_ suffix: String) -> String {
        let regex = "/"
        do {
            let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let modified = RE.stringByReplacingMatches(in: suffix, options: .reportProgress, range: NSRange(location: 0, length: suffix.count), withTemplate: "_")
            return modified
        } catch {
            return suffix
        }
    }
}

public protocol DocumentDownloadAble: AnyObject {
    var progressObserver: PublishSubject<Float> { get }
    var completedObserver: PublishSubject<(success: Bool, errorCode: Int?)> { get }
    var readyObserver: PublishSubject<Bool> { get }
    func startDownload(remoteUrl: String, localPath: String, slice: Bool, fileSize: String?)
    func cancelDownload()
}

class DocumentDownloader: DocumentDownloadAble {
    private var requestKey: String?
    private let docsType: DocsType
    private var bag: DisposeBag = DisposeBag()
    public var readyObserver: PublishSubject<Bool> = PublishSubject<Bool>()
    public var progressObserver: PublishSubject<Float> = PublishSubject<Float>()
    public var completedObserver: PublishSubject<(success: Bool, errorCode: Int?)> = PublishSubject<(success: Bool, errorCode: Int?)>()
    public init(docsType: DocsType) {
        self.docsType = docsType
        DocsContainer.shared.resolve(DriveDownloadCallbackServiceBase.self)?.addObserver(self)
    }
    
    deinit {
        DocsLogger.info("DocumentDownloader deinit")
    }

    public func startDownload(remoteUrl: String, localPath: String, slice: Bool, fileSize: String?) {
        DocsContainer.shared.resolve(DriveRustRouterBase.self)?.downloadNormal(remoteUrl: remoteUrl,
                                                                                  localPath: localPath,
                                                                                  fileSize: fileSize,
                                                                                  slice: slice,
                                                                                  priority: .userInteraction).subscribe(onNext: {[weak self] (key) in
                                                                                    self?.requestKey = key
                                                                                    self?.reportStartDownload(downloadKey: key, filePath: localPath)
                                                                                  }).disposed(by: bag)
        
    }

    public func startDownload(localPath: String, fileToken: String) {
        DocsContainer.shared.resolve(DriveRustRouterBase.self)?.downloadfile(localPath: localPath,
                                                                             fileToken: fileToken,
                                                                             mountNodePoint: "",
                                                                             mountPoint: "ccm_export").subscribe(onNext: {[weak self] (key) in
                                                                                self?.requestKey = key
                                                                                self?.reportStartDownload(downloadKey: key, filePath: localPath)
                                                                              }).disposed(by: bag)
    }

    public func cancelDownload() {
        guard let cancelKey = requestKey else {
            return
        }
        DocsContainer.shared
            .resolve(DriveRustRouterBase.self)?
            .cancelDownload(key: cancelKey).subscribe(onNext: { (result) in
                DocsLogger.info("document download-暂停: \(result)")
            }).disposed(by: bag)
        completedObserver.onNext((false, nil))
    }
    
    private func reportStartDownload(downloadKey: String, filePath: String) {
        let module = docsType.statisticModule.rawValue
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent

        DocsContainer.shared.resolve(UploadAndDownloadStastis.self)?.recordDownloadInfo(module: module,
                                                                                         downloadKey: downloadKey,
                                                                                         fileID: "",
                                                                                         fileSubType: SKFilePath.getFileExtension(from: fileName),
                                                                                         isExport: true,
                                                                                         isDriveSDK: false)
    }
}

extension DocumentDownloader: DriveDownloadCallback {
    public func updateProgress(context: DriveDownloadContext) {
        guard context.key == requestKey else { return }
        // 错误码: https://bytedance.feishu.cn/space/doc/doccn0VCcK1jUqaKlk1oFb#
        switch context.status {
        case .ready:
            DocsLogger.debug("document download-准备下载")
            readyObserver.onNext(true)
        case .cancel://在onFailed方法中处理回调
            DocsLogger.debug("document download-取消下载")
        case .failed://在onFailed方法中处理回调
            DocsLogger.debug("document download-下载失败")
        case .success:
            completedObserver.onNext((true, nil))
            DocsLogger.info("document download-成功")
        case .inflight, .queue:
            if context.bytesTotal > 0 {
                progressObserver.onNext(Float(context.bytesTransferred) / Float(context.bytesTotal))
                DocsLogger.debug("document download-progress：\(Float(context.bytesTransferred) / Float(context.bytesTotal))")
            }
        case .pending:
            completedObserver.onNext((false, nil))//下载中断
            DocsLogger.info("document download-下载中断")
        case .rangeFinish:
            // ApiType 为 Range 时才有的状态
            DocsLogger.debug("document download-Range下载结束")
        @unknown default:
            break
        }
    }

    public func onFailed(key: String,
                  errorCode: Int) {
        guard key == requestKey else { return }
        DocsLogger.info("document download- onFailed -key=\(key),errorcode=\(errorCode)")
        completedObserver.onNext((false, errorCode))
    }
}
