//
//  DrivePreviewNetManager.swift
//  SpaceKit-DocsSDK
//
//  Created by zenghao on 2019/6/30.
//

import Foundation
import SwiftyJSON
import RxSwift
import SKCommon
import SKFoundation
import Alamofire
import SKInfra

typealias DriveGetReadingDataCallback = (_ data: [ReadingPanelInfo]?, _ avatarUrl: String?, _ succeed: Bool) -> Void

protocol DrivePreviewNetManagerProtocol {
    func fetchDocsInfo(docsInfo: DocsInfo, completion: @escaping (Error?) -> Void)
    func fetchFileInfo(context: FetchFileInfoContext,
                       polling: (() -> Void)?,
                       completion: @escaping (DriveResult<DriveFileInfo>) -> Void)
    func fetchPreviewURL(regenerate: Bool, mountPoint: String, mountToken: String, completion: @escaping (DriveResult<DriveFilePreview>) -> Void)
    func updateFileInfo(name: String, completion: @escaping (DriveResult<Bool>) -> Void)
    func saveToSpace(fileInfo: DriveFileInfo, completion: @escaping (DriveResult<Bool>) -> Void)
    func getReadingData(docsInfo: DocsInfo, callback: @escaping DriveGetReadingDataCallback)
    func cancelFileInfo()
}

struct FetchFileInfoContext {
    let showInRecent: Bool
    let version: String?
    let optionParams: [String]
    let pollingStrategy: DrivePollingStrategy
}

public enum PollingInterval {
    case interval(Int)
    case end
}

public protocol DrivePollingStrategy {
    func nextInterval() -> PollingInterval
    func shouldPolling(data: JSON?, error: Error?) -> Bool
}

class DrivePreviewNetManager {

    // MARK: - DocsRequest
    /// 文档信息请求 - space kit通用信息，用于More模块
    private let docsInfoUpdater: DocsInfoDetailUpdater

    /// 文件信息请求 - 基本文件元数据信息
    private var fetchFileInfoRequest: DocsRequest<JSON>?

    /// 后台预览PDF下载地址请求 - 本地不支持类型 后台支持转换成PDF
    private var fetchPreviewURLRequest: DocsRequest<JSON>?

    /// 更新文件信息请求 - 重命名
    private var updateFileInfoRequest: DocsRequest<JSON>?

    /// 保存到云空间
    private var saveToSpaceRequest: DocsRequest<JSON>?

    /// 文档统计信息请求
    private var readingDataRequest: ReadingDataRequest?
    private var readingDataCallback: DriveGetReadingDataCallback?

    private(set) var fileInfo: DriveFileInfo
    private let performanceLogger: DrivePerformanceRecorder
    private var disposeBag = DisposeBag()

    /// FileInfo 重试逻辑（网络层错误重试一次）
    private var retryAction: RetryAction = { (request: URLRequest?, currentRetryCount: UInt, error: Error) in
        guard let urlError = error as? URLError else { return (false, 0) }
        if currentRetryCount < 1 {
            let extraInfo: [String: Any] = ["error": error.localizedDescription.toBase64(), "retryCount": currentRetryCount ]
            DocsLogger.driveInfo("FileInfo Network Retry", extraInfo: extraInfo, error: nil)
            return (true, 1)
        } else {
            return (false, 0)
        }
    }
    
    init(_ performanceLogger: DrivePerformanceRecorder, fileInfo: DriveFileInfo) {
        self.performanceLogger = performanceLogger
        self.fileInfo = fileInfo
        docsInfoUpdater = DefaultDocsInfoDetailUpdater()
    }
}

extension DrivePreviewNetManager: DrivePreviewNetManagerProtocol {

    // MARK: - DocsInfo
    func fetchDocsInfo(docsInfo: DocsInfo, completion: @escaping (Error?) -> Void) {
        disposeBag = DisposeBag()
        let shareUrl = docsInfo.shareUrl
        performanceLogger.stageBegin(stage: .requestDocInfo)
        docsInfoUpdater.updateDetail(for: docsInfo)
            .subscribe(onSuccess: { [weak self] in
                self?.performanceLogger.stageEnd(stage: .requestDocInfo)
                /// doscInfo requestDetail内部会覆盖shareUrl，请求回来的shareUrl为空
                if let url = shareUrl {
                    docsInfo.shareUrl = url
                }
                completion(nil)
            }, onError: { [weak self] error in
                self?.performanceLogger.stageEnd(stage: .requestDocInfo)
                DocsLogger.driveInfo("fetch docsInfo failed", extraInfo: ["error": "\(error.underlyingError)"])
                completion(error)
            })
            .disposed(by: disposeBag)
    }

    func cancelFileInfo() {
        fetchFileInfoRequest?.cancel()
    }
    
    // MARK: - FileInfo
    func fetchFileInfo(context: FetchFileInfoContext,
                       polling: (() -> Void)?,
                       completion: @escaping (DriveResult<DriveFileInfo>) -> Void) {
        self.performanceLogger.stageBegin(stage: .requestFileInfo)
        self._fetchFileInfo(context: context,
                            polling: polling,
                            completion: completion)
    }
    
    private func _fetchFileInfo(context: FetchFileInfoContext,
                                polling: (() -> Void)?,
                                completion: @escaping (DriveResult<DriveFileInfo>) -> Void) {
        fetchFileInfoRequest?.cancel()
        var optionParams = context.optionParams
        // 确保带上 preview_meta 参数信息
        if !optionParams.contains("preview_meta") {
            optionParams.append("preview_meta")
        }
        if !optionParams.contains("check_cipher") {
            optionParams.append("check_cipher")
        }
        let param = fetchFileInfoParams(showInRecent: context.showInRecent,
                                        version: context.version,
                                        optionParams: optionParams)
        fetchFileInfoRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo,
                                                 params: param)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .set(retryAction: retryAction)
        
        fetchFileInfoRequest?.start(result: { [weak self] (result, error) in
            guard let `self` = self else { return }
            if context.pollingStrategy.shouldPolling(data: result, error: error),
                case let .interval(interval) = context.pollingStrategy.nextInterval() {
                DocsLogger.driveInfo("start polling after: \(interval)s")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(interval)) {
                    self._fetchFileInfo(context: context,
                                        polling: polling,
                                        completion: completion)
                }
                polling?()
                return
            }
            if let error = error {
                completion(DriveResult.failure(error))
                self.performanceLogger.stageEnd(stage: .requestFileInfo)
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    completion(DriveResult.failure(DriveError.fileInfoDataError))
                    self.performanceLogger.stageEnd(stage: .requestFileInfo)
                    return
            }
            if code != 0 { // 解析错误码
                if code == DocsNetworkError.Code.tnsCrossBrandBlocked.rawValue,
                   let url = json["url"].url {
                    completion(DriveResult.failure(DriveError.blockByTNS(redirectURL: url)))
                } else {
                    completion(DriveResult.failure(DriveError.serverError(code: code)))
                }
                self.performanceLogger.stageEnd(stage: .requestFileInfo)
                return
            }
            guard let dataDic = json["data"].dictionaryObject else {
                completion(DriveResult.failure(DriveError.fileInfoParserError))
                self.performanceLogger.stageEnd(stage: .requestFileInfo)
                return
            }
            self.transformData(data: dataDic, completion: { (result) in
                self.performanceLogger.stageEnd(stage: .requestFileInfo)
                completion(result)
            })
        })
    }

    func fetchPreviewURL(regenerate: Bool, mountPoint: String, mountToken: String, completion: @escaping (DriveResult<DriveFilePreview>) -> Void) {
        fetchPreviewURLRequest?.cancel()

        performanceLogger.stageBegin(stage: .requestPreviewUrl)
        let params = fetchPreiviewFileDownloadURLParams(regenerate: regenerate, mountPoint: mountPoint, mountToken: mountToken)
        fetchPreviewURLRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.driveGetServerPreviewURL,
                                                   params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        fetchPreviewURLRequest?.start(result: {[weak self] (result, error) in
            guard let `self` = self else { return }
            self.performanceLogger.stageEnd(stage: .requestPreviewUrl)

            if let error = error {
                completion(DriveResult.failure(error))
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    completion(DriveResult.failure(DriveError.previewDataError))
                    return
            }
            if code != 0 { // 解析错误码
                completion(DriveResult.failure(DriveError.serverError(code: code)))
                return
            }
            guard let dataDic = json["data"].dictionaryObject,
                let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []),
                let filePreview = try? JSONDecoder().decode(DriveFilePreview.self, from: data) else {
                    completion(DriveResult.failure(DriveError.previewDataError))
                    return
            }
            guard let originPreviewType = self.fileInfo.previewType else {
                DocsLogger.driveError("no previewFileType to get preview url")
                completion(DriveResult.failure(DriveError.previewDataError))
                return
            }
            var newFilePreview = filePreview
            newFilePreview.previewURL = self.fileInfo.getPreviewDownloadURLString(previewType: originPreviewType)
            completion(DriveResult.success(newFilePreview))
        })
    }

    func updateFileInfo(name: String, completion: @escaping (DriveResult<Bool>) -> Void) {
        var params = baseParams
        params.merge(other: ["name": name])
        if let version = fileInfo.version {
            params["source_version"] = version
        }

        updateFileInfoRequest?.cancel()
        updateFileInfoRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.updateFileInfo, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        updateFileInfoRequest?.start(result: {(json, error) in
            guard error == nil else {
                completion(DriveResult.failure(error!))
                return
            }
            guard let json = json,
                let resultCode = json["code"].int else {
                    completion(.failure(DriveError.fileInfoParserError))
                    return
            }
            guard resultCode == 0 else {
                completion(.failure(DriveError.serverError(code: resultCode)))
                return
            }
            completion(DriveResult.success(true))
        })
    }

    // save to space
    func saveToSpace(fileInfo: DriveFileInfo, completion: @escaping (DriveResult<Bool>) -> Void) {
        saveToSpaceRequest?.cancel()
        var params: [String: Any] = ["file_token": fileInfo.fileToken,
                      "mount_node_token": fileInfo.mountNodeToken,
                      "name": fileInfo.name,
                      "size_checker": SettingConfig.sizeLimitEnable]
        if let extra = fileInfo.authExtra {
            params["extra"] = extra
        }
        saveToSpaceRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.saveToSpace, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("save file to space failed: \(String(describing: error?.localizedDescription))")
                    completion(DriveResult.failure(error!))
                    return
                }
                guard let json = json,
                    let resultCode = json["code"].int else {
                        DocsLogger.error("save file to space failed: parse error")
                        completion(.failure(DriveError.fileInfoParserError))
                        return
                }
                guard resultCode == 0 else {
                    completion(.failure(DriveError.serverError(code: resultCode)))
                    return
                }
                completion(DriveResult.success(true))
            })
    }

    func getReadingData(docsInfo: DocsInfo, callback: @escaping DriveGetReadingDataCallback) {
        readingDataRequest = ReadingDataRequest(docsInfo)
        readingDataRequest?.dataSource = self
        readingDataRequest?.request()

        readingDataCallback = callback
    }
}

private extension DrivePreviewNetManager {

    func transformData(data: [String: Any], completion: (DriveResult<DriveFileInfo>) -> Void) {
        guard let info = DriveFileInfo(data: data,
                                       fileToken: fileInfo.fileToken,
                                       mountNodeToken: fileInfo.mountNodeToken,
                                       mountPoint: fileInfo.mountPoint,
                                       authExtra: fileInfo.authExtra) else {
                                        completion(DriveResult.failure(DriveError.fileInfoParserError))
                                        return
        }
        // 更新fileInfo信息
        self.fileInfo = info
        completion(DriveResult.success(info))
    }

    var baseParams: [String: Any] {
        return ["file_token": fileInfo.fileToken,
                "mount_point": fileInfo.mountPoint]
    }

    /// version为nil获取最新版本文件信息，修改文件名version应该传nil
    func fetchFileInfoParams(showInRecent: Bool, version: String?, optionParams: [String]) -> [String: Any] {
        var params = baseParams
        if let v = version, v.count > 0 {
            params["version"] = version
        }
        if showInRecent {
            params["caller"] = DriveConstants.driveMountPoint
        }
        if let extra = fileInfo.authExtra {
            params["extra"] = extra
        }
        if optionParams.count > 0 {
            params["option_params"] = optionParams
        }
        return params
    }

    /// regenerate: 是否手动触发,重新请求生成预览PDF接口
    func fetchPreiviewFileDownloadURLParams(regenerate: Bool, mountPoint: String, mountToken: String) -> [String: Any] {
        var params = baseParams
        let regenerteValue = regenerate ?
            DrivePreviewFileGeneratedType.manual.rawValue :
            DrivePreviewFileGeneratedType.normal.rawValue
        params.merge(other: ["preview_type": fileInfo.previewType?.rawValue ?? DrivePreviewFileType.linerizedPDF.rawValue,
                             "regenerate": regenerteValue,
                             "mount_point": mountPoint,
                             "mount_node_token": mountToken])
        if let version = fileInfo.dataVersion {
            params["version"] = version
        }
        if let extra = fileInfo.authExtra {
            params["extra"] = extra
        }
        return params
    }
}

// MARK: - ReadingDataFrontDataSource
extension DrivePreviewNetManager: ReadingDataFrontDataSource {
    func requestData(request: ReadingDataRequest, docs: DocsInfo, finish: @escaping (ReadingInfo) -> Void) {
        DocsLogger.driveInfo("request reading data finish")
    }

    func requestRefresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, error: Bool) {
        if error {
            DocsLogger.warning("request reading data fail")
            readingDataCallback?(nil, nil, false)
            readingDataCallback = nil
            return
        }
        let panelData = data

        guard let avatarUrl = avatarUrl else {
            spaceAssertionFailure("missing url")
            readingDataCallback?(nil, nil, false)
            readingDataCallback = nil
            return
        }

        readingDataCallback?(panelData, avatarUrl, true)
        readingDataCallback = nil
    }
}


class DriveInfoPollingStrategy: DrivePollingStrategy {
    // nolint-next-line: magic number
    private let intervals: [Int] = [1, 1, 1, 3, 5, 10, 15, 30]
    private var index: Int = 0
    public func nextInterval() -> PollingInterval {
        let pre = index
        index += 1
        if pre < intervals.count {
            return .interval(intervals[pre])
        } else {
            return .end
        }
    }
    
    public func shouldPolling(data: JSON?, error: Error?) -> Bool {
        guard let json = data,
              let code = json["code"].int,
              code == DriveFileInfoErrorCode.fileCopying.rawValue else {
                return false
        }
        return true
    }
}
