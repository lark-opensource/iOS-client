//
//  OpenPluginNetwork+Monitor.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation
import OPPluginManagerAdapter
import ECOProbe
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPFoundation
import LarkContainer
import TTMicroApp

// MARK: - Monitor
extension OpenPluginNetwork {
    struct MonitorKey {
        // MARK: common
        static let Method = "method";
        static let Domain = "domain";
        static let Path = "path";
        static let RequestID = "request_id";
        static let FileSize = "file_size";
        static let Duration = "from_request_start_duration";
        static let NQEStatus = "nqe_status";
        static let NQEHttpRtt = "nqe_http_rtt";
        static let NQETransportRtt = "nqe_transport_rtt";
        static let NQEDownstreamThroughput = "nqe_downstream_throughput";
        static let IsBackground = "is_background";
        static let NetStatus = "net_status";
        static let RustStatus = "rust_status";
        static let Channel = "channel";
        static let HttpCode = "http_code"
        static let PatchSystemCookies = "patch_system_cookies";
        static let SetCookie = "response_set_cookie";
        static let RequestVersion = "request_version"

        // MARK: tt.request

        static let IsPrefetch = "is_prefetch";
        static let PrefetchResultDetail = "prefetch_result_detail";
        static let UsePrefetch = "use_prefetch";
        static let RequestHeader = "request_header";
        static let ResponseHeader = "response_header";
        static let RequestBodyLength = "request_body_length";
        static let ResponseBodyLength = "response_body_length";
        static let PrefetchErrno = "prefetch_errno"
        static let PrefetchVersion = "prefetch_version"
        
        // MARK: tt.download
        static let FilePath = "file_path"
        static let SuggestedFileName = "suggested_file_name"
        static let DownloadedTempPath = "downloaded_temp_file_path"
        
        // MARK: tt.upload
        static let FiledName = "name"

        // Podfile
        static let pluginDurationMS = "plugin_duration_ms"
        static let pluginEndMS = "plugin_end_ms"
        static let isBackground = "is_background"
        static let backgroundDuration = "background_duration"
    }
    
    struct MonitorEventName {
        static let RequestStart = kEventName_mp_request_start
        static let RequestResult = kEventName_mp_request_result
        static let UploadStart = kEventName_mp_request_upload_start
        static let UploadResult = kEventName_mp_request_upload_result
        static let DownloadStart = kEventName_mp_request_download_start
        static let DownloadResult = kEventName_mp_request_download_result
    }
}


extension OPMonitor {
    private typealias MonitorKey = OpenPluginNetwork.MonitorKey
    
    func flushFail(withAPIError error: OpenAPIError) {
        var errorCode: String? = nil
        if let outerCode = error.outerCode {
            errorCode = String(outerCode)
        }
        addMap(["errno": error.errnoError?.errnoValue ?? 0, "errString": error.errnoError?.errString ?? ""])
        setResultTypeFail().setError(error).setErrorCode(errorCode).timing().flush()
    }
    
    func flushSuccess() {
        setResultTypeSuccess().timing()
        // 旧数据兼容逻辑, 网络埋点用 from_request_start_duration 字段记录时长, 而非通用 duration
        if let duration = metrics?[OPMonitorEventKey.duration] {
            addMap([MonitorKey.Duration: duration])
        }
        flush()
    }
    
}

// MARK: - 网络 API 结束埋点
extension OPMonitor {
    private static var netStatusService: OPNetStatusHelper? {
        InjectedOptional<OPNetStatusHelper>().wrappedValue
    }
    
    /// 创建请求开始点
    /// 返回一个 Monitor 并设置上下文
    static func startMonitor(withContext context: OpenAPIContext, name: String) -> OPMonitor {
        return OPMonitor(name)
            .tracing(context.apiTrace)
            .setUniqueID(context.uniqueID)
            .setPlatform([.slardar])
            .timing()
    }
    
    /// 创建请求结束点
    /// 返回一个 Monitor 并设置上下文
    static func resultMonitor(withContext context: OpenAPIContext, name: String) -> OPMonitor {
        return OPMonitor(name)
            .tracing(context.apiTrace)
            .setUniqueID(context.uniqueID)
            .setPlatform([.slardar, .tea])
            .timing()
    }
    
    /// 设置开始点通用的信息
    /// - Parameters:
    ///   - url: url
    ///   - payload: 三个网络 API 的通用 request 结构
    @discardableResult func setStartInfo(fromURL url: URL?, payload: OpenPluginNetworkParamsPayloadProtocol) -> OPMonitor {
        return addMap([
            MonitorKey.RequestVersion: "v2",
            MonitorKey.Domain: url?.host ?? "",
            MonitorKey.Path: url?.path ?? "",
            MonitorKey.RequestID: payload.taskID,
            MonitorKey.Method: payload.method ?? ""
        ])
    }
    
    /// 设置结束点 tt.request request 信息
    @discardableResult func setRequestInfo(
        fromUniqueID uniqueID: OPAppUniqueID,
        url: URL?,
        payload: OpenPluginNetworkRequestParamsPayload) -> OPMonitor {
            addMap([
                MonitorKey.UsePrefetch: false,
            ])._setRequestCommonInfo(fromUniqueID: uniqueID, url: url, payload: payload)
    }
    
    /// 设置结束点 tt.upload request 信息
    @discardableResult func setUploadInfo(
        fromUniqueID uniqueID: OPAppUniqueID,
        url: URL?,
        payload: OpenPluginNetworkUploadParamsPayload) -> OPMonitor {
            addMap([
                MonitorKey.FilePath: payload.filePath,
                MonitorKey.FiledName: payload.name
            ])._setRequestCommonInfo(fromUniqueID: uniqueID, url: url, payload: payload)
    }
    
    /// 设置结束点 tt.download request 信息
    @discardableResult func setDownloadInfo(
        fromUniqueID uniqueID: OPAppUniqueID,
        url: URL?,
        payload: OpenPluginNetworkDownloadParamsPayload) -> OPMonitor {
            addMap([MonitorKey.FilePath: payload.filePath ?? ""])
                ._setRequestCommonInfo(fromUniqueID: uniqueID, url: url, payload: payload)
    }
    
    /// 设置从本地 cookieStorage 中取出的当前 url cookie
    @discardableResult func setStorageCookie(cookies: [String]?) -> OPMonitor {
        let cookieString = cookies?.joined(separator: ";") ?? ""
        let maskString = TMAPluginNetworkTools.cookieMaskValue(forOrigin:cookieString)
        return addMap([OpenPluginNetwork.MonitorKey.PatchSystemCookies: maskString])
    }
    
    /// 设置结束点 tt.request response 信息
    /// - Parameter extra: tt.request 的 response 的数据
    @discardableResult func setRequestResponseInfo(from extra: OpenPluginNetworkRequestResultExtra) -> OPMonitor {
        return addMap([
            MonitorKey.IsPrefetch: false
        ])._setResponseCommonInfo(from: extra)
    }
    
    /// 设置结束点 tt.download response 信息
    /// - Parameter extra: tt.download 的 response 的数据
    @discardableResult func setDownloadResponseInfo(from extra: OpenPluginNetworkDownloadResultExtra) -> OPMonitor {
        return addMap([
            MonitorKey.SuggestedFileName: extra.suggestedFileName,
            MonitorKey.DownloadedTempPath: extra.downloadFilePath,
        ])._setResponseCommonInfo(from: extra)
    }
    
    /// 设置结束点 tt.upload response 信息
    /// - Parameter extra: tt.upload 的 response 的数据
    @discardableResult func setUploadResponseInfo(from extra: OpenPluginNetworkUploadResultExtra) -> OPMonitor {
        return _setResponseCommonInfo(from: extra)
    }
    
    /// 设置结束点 request 通用信息
    @discardableResult private func _setRequestCommonInfo(
        fromUniqueID uniqueID: OPAppUniqueID,
        url: URL?,
        payload: OpenPluginNetworkParamsPayloadProtocol
    ) -> OPMonitor {
        if let service = Self.netStatusService {
            addMap([
                MonitorKey.NetStatus: service.status.rawValue,
                MonitorKey.RustStatus: service.rustNetStatus.rawValue,
                MonitorKey.NQEStatus: service.ttNetStatus.rawValue,
            ])
        }
        let networkQuality = TTNetworkManager.shareInstance().getNetworkQuality()
        addMap([
            MonitorKey.NQEHttpRtt: networkQuality.httpRttMs,
            MonitorKey.NQETransportRtt: networkQuality.transportRttMs,
            MonitorKey.NQEDownstreamThroughput: networkQuality.downstreamThroughputKbps]
        )
        return addMap([
            MonitorKey.RequestID: payload.taskID,
            MonitorKey.RequestVersion: "v2",
            MonitorKey.Domain: url?.host ?? "",
            MonitorKey.Path: url?.path ?? "",
            MonitorKey.Method: payload.method ?? "",
            MonitorKey.Channel: "rust",
            MonitorKey.IsBackground: BDPAPIInterruptionManager.shared().shouldInterruptionV2(for: uniqueID)
        ])
    }
    
    /// 设置结束点 response 信息
    /// - Parameter extra:
    @discardableResult private func _setResponseCommonInfo(from extra: OpenPluginNetworkResultExtraProtocol) -> OPMonitor {
        var info: [String: Any] = [:]
        if let cookies = extra.cookie {
            let maskcookies = cookies.map {TMAPluginNetworkTools.cookieMaskValue(forOrigin: $0)}
            info[MonitorKey.SetCookie] = maskcookies
        }
        if let statusCode = extra.statusCode {
            info[MonitorKey.HttpCode] = statusCode
        }
        return addMap(info)
    }
}
