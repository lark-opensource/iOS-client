//
//  DrivePerformanceRecorder.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/3.
//
// swiftlint:disable file_length

import Foundation
import SKCommon
import SKFoundation
import LarkReleaseConfig
import SKInfra

//--------------------------------------------------------------------------------------------
enum DriveResultKey: String {
    case success
    case cancel
    case overtime
    case nativeFail
    case rustFail
    case serverFail
}

enum DriveOpenType: String {
    case quicklook // 使用quickLookViewController打开
    case avplayer_local = "av_player_fullCache"  // DriveVideoPlayerViewController avplayer播放本地视频
    case ttplayer_local = "tt_video_fullCache" // DriveVideoPlayerViewController ttplayer播放本地视频
    case ttplayer_online = "tt_video_previewUrl"// DriveVideoPlayerViewController ttplayer播放转码后视频
    case ttplayer_sourceURL = "tt_video_sourceUrl"// DriveVideoPlayerViewController ttplayer源地址播放
    case webView // DriveWebViewController
    case textView // DriveTextViewController
    case gifView // DriveGIFPreviewController
    case imageView // DriveImageViewController
    case lineImageView // DriveImageViewController 渐进式图片打开
    case pdfView // 使用pdfkit打开
    case archiveView // 使用ArchiveViewController打开
    case htmlView // 使用DriveHtmlPreviewViewController打开
    case wps // 使用 WPS 在线预览方式打开
    case sheet // 使用 Sheet 预览编辑 Excel
    case videoCover
    case unknown
}

// Drive 下载功能错误码：https://bytedance.feishu.cn/space/doc/doccnkwOT5tBcZVVqVOBf0#
enum DriveResultCode: String {
    case success                    = "DEC0"
    case cancel                     = "DEC1"
    case noNetwork                  = "DEC3"
    case noPermission               = "DEC4"
    case fetchFileInfoFail          = "DEC5"
    case fetchPreviewUrlFail        = "DEC6"
    case fetchPermissionFail        = "DEC7"
    case rustDownloadFail           = "DEC8"
    case fileInfoDataError          = "DEC9"
    case perviewUrlDataError        = "DEC10"
    // MARK: - begin: 后端返回的错误码，需要上报
    // https://bytedance.feishu.cn/space/doc/doccnESEwiTYHEKOOWSjXB#DH2TKW
    case unsupportPreviewFileType   = "DEC11"
    case previewFileSizeTooBig      = "DEC12"
    case previewFileIsEmpty         = "DEC13"
    case cancelledOnCellularNetwork = "DEC14"
    case illegalFile                = "DEC15"
    case fileDeleted                = "DEC16"
    case startConvertFailed         = "DEC17"
    case tosFailed                  = "DEC18"
    case mysqlFailed                = "DEC19"
    case rpcFailed                  = "DEC20"
    case xmlVersionNotSupport       = "DEC21"
    case fileEncrypt                = "DEC22"
    case needCharge                 = "DEC23"
    case importStatusFailed         = "DEC24"
    // MARK: 本地文件预览错误
    case localFileNotFound          = "DEC25"
    case localUnsupportFileType     = "DEC26"
    case fileNotFound               = "DEC27"
    /// 文件类型受支持，但是打开失败了（后缀被修改或文件损坏）
    case localFileRenderFailed      = "DEC28"
    case fileCopyFailed             = "DEC31"
    case fileCopyTimeout            = "DEC32"
    // MARK: - end: 后端返回的错误码
    case operationsTooFrequentError = "429"
}

enum DriveSourceType: Int {
    /// 其他情况（如打开中途用户取消）
    case other     = -1
    /// 缓存文件打开
    case cache = 1
    /// 原始文件打开
    case source = 2
    /// 预览文件打开
    case preview = 3
    /// 预加载打开
    case preload = 4
    /// 本地文件打开
    case localFile = 5
}

extension DriveOpenType {
    /// 打开的方式是否为视频
    var isVideo: Bool {
        switch self {
        case .avplayer_local, .ttplayer_local, .ttplayer_online, .ttplayer_sourceURL:
            return true
        default:
            return false
        }
    }

    /// 打开的方式是否可以降级预览
    var isDowngradable: Bool {
        switch self {
        case .wps:
            return true
        case .quicklook, .avplayer_local, .ttplayer_local, .ttplayer_online, .ttplayer_sourceURL,
                .webView, .textView,
             .gifView, .imageView, .lineImageView,
             .pdfView, .archiveView, .htmlView, .sheet, .videoCover, .unknown:
            return false
        }
    }
}

final class DrivePerformanceRecorder {

    /// 打开过程中的各个阶段
    enum Stage: String {
        /// 标记文档打开
        case vcCreate           = "vc_create"
        /// 获取文档信息耗时
        case requestDocInfo     = "request_doc_info"
        /// 请求权限
        case requestPermission  = "request_permission"
        /// 请求文件信息
        case requestFileInfo    = "request_file_info"
        /// 请求服务端预览 url
        case requestPreviewUrl  = "request_preview_url"
        /// Rust下载文件
        case downloadFile       = "rust_download_file"
        /// 本地缓存文件
        case localCacheFile     = "local_cache_file"
        /// 文件已经打开或者显示不支持页面
        case fileIsOpen         = "file_open_succeed"
        /// 获取是否开启转换文档入口的请求总耗时：fileInfo + fg + permission
        case canImport          = "can_import"
        /// 发起转换文档请求的耗时
        case startImportFile    = "start_import_file"
        /// 查询转换结果请求的耗时
        case checkImportResult  = "check_import_Result"
        /// wps加载过程
        case wpsLoadTemplate = "wps_load_template"
        case wpsGetInitailData = "wps_getInitial_data"
        case wpsRender = "wps_render"
        /// wps 内部渲染阶段细分： https://bytedance.feishu.cn/docx/doxcn7nug6tDq5s0M1ERCPagnWc
        /// 结论1：整个websocket耗时(G+H)
        /// 结论2：整个xhr耗时(E)
        /// 结论3：整个文档打开耗时(A+B+C+I+J+K)
        // A阶段 从上级html开始请求到WebOffice的html开始请求耗时
        case wpsRenderParentHtml = "wps_render_parent_html"
        // B阶段 WebOffice的html加载耗时
        case wpsRenderHtml = "wps_render_html"
        // C阶段 从html加载完到内核js加载完成耗时
        case wpsRenderLoadJS = "wps_render_load_js"
        // E阶段 从xhr.start到xhr.end耗时
        case wpsRenderXHR = "wps_render_xhr"
        // G阶段 从websocket.start到websocket.open耗时
        case wpsRenderWSStart = "wps_render_websocket_start"
        // H阶段 从websocket.open到doc.permission
        case wpsRenderWSOpen = "wps_render_websocket_open"
        // I阶段 从内核js加载完成到xhr完成并解析数据耗时
        case wpsRenderParseData = "wps_render_parse_data"
        // J阶段 初始化内核耗时
        case wpsRenderInitCore = "wps_render_init_core"
        // K阶段 前端渲染文档内容耗时
        case wpsRenderContent = "wps_render_content"
        
        // 加载缩略图耗时
        // 关联需求 https://bytedance.feishu.cn/wiki/wikcnwrvfTyKqJXsb0qNW0wfXpA
        case loadThumb = "load_thumb"
    }

    /// 上报到后台时的字段
    enum ReportKey: String {
        case stage      = "stage"
        case resultKey  = "result_key"
        case resultCode = "result_code"
        case costTime   = "cost_time"
        case fileToken  = "file_token"
        case fileType   = "file_type"
        case fileSize   = "file_size"
        case loadingType   = "loading_type"
        case sourceType = "source_type"
        case previewFrom = "preview_from"
        case key        = "key"
        case code       = "code"
        case sdkAppID   = "sdkAppId"
        case previewType = "preview_type" // 采用的服务器转换类型
        case previewExt = "preview_ext" // 转换类型对应的文件后缀
        case previewSize = "preview_size" // 预览文件的大小, streaming类型不上报
        case hitCache = "doc_has_cache" // 是否命中缓存 （0否1是）
        case openType = "open_type" // 使用哪种方式打开
        case errorMsg = "error_message" // 错误信息（目前用于上报 WPS 的错误信息）
        case mimeType = "mime_type" // fileinfo 返回的 mimeType 信息，对应文件后缀
        case realMimeType = "real_mime_type" // 后端返回的 mimeType 信息
        case isRealType = "isRealType" // 是否为真实类型
        case loadFrom = "load_from" // 预览加载方式
        case thumbType = "thumbnail_type" // 缩略图预览
        case brand = "brand" //飞书 brand或Lark brand
        case package = "package" //飞书 package或Lark package
        case unit = "unit" //
        case domain = "domain"
        case isPrivatePkg = "is_private_ka_pkg"
        case isChinaGeo = "user_geo"
        case networkType = "doc_network_level" // 网络类型，详见https://bytedance.feishu.cn/wiki/wikcnzzpOsJ0AeGi0Qw6O3Pd8Vf#kQe86N
    }

    enum LoadingType: Int {
        case preview = 0
        case preload = 1
    }

    enum Key: String {
        /// 请求服务端预览 url轮询统计
        case serverTransform = "server_transform"
    }

    enum Code: Int {
        case start = 1 // 开始请求转码状态
        case cancel = 2 // 用户中途退出
        case finish = 3 // 转码成功
        case failed = 4 // 转码失败
    }
    
    /// 预览加载方式
    /// https://bytedance.feishu.cn/docs/doccn435eh7sqhOTEJefZTS71ae#GcuPRI
    enum LoadFrom: String {
        case normal = "1"
        case retry = "2"
    }

    /// 文件token
    let fileToken: String
    
    /// 文件加密id，做单一文档保护的作用的
    var encryptId: String?

    /// 文件类型, 保证为小写
    var fileType: String {
        get {
            return lowercasedFileType
        }
        set {
            lowercasedFileType = newValue.lowercased()
        }
    }

    private var lowercasedFileType = ""

    /// 文件大小
    var fileSize: UInt64?
    /// 是否应该上报
    var shouldReport: Bool = true
    /// 预览来源
    var previewFrom: DrivePreviewFrom
    /// 文件来源
    var sourceType: DriveSourceType
    /// 预览文件的大小
    var previewFileSize: UInt64?
    /// 是否命中缓存
    var hitCache: Bool = false
    /// 转换类型对应的文件后缀
    var previewExt: String?
    /// 采用的服务器转换类型
    var previewType: Int?
    /// 文件 MIMETyp(对标文件后缀)
    var mimeType: String?
    /// 后端识别的 MIMEType
    var realMimeType: String?
    /// 预览是正常打开还是失败后点击重试打开
    var loadFrom: LoadFrom = .normal
    /// 缩略图加载成功: true
    /// 缩略图加载失败: false
    /// 不走缩略图流程: nil
    var thumbType: Bool?
    
    var networkType: Int?
    /// 各种时刻
    @ThreadSafe private var costTime: Dictionary = [String: Date]()
    /// key为stage 字典为对应的参数数据
    @ThreadSafe private var uploadParameters: Dictionary = [String: [String: Any]]()
    let lock = NSLock()
    // open finish回调，目前只用于drive性能测试
    var finishedCallback: (() -> Void)?
    // 额外的上报参数
    var additionalStatisticParameters: [String: String]?

    /// previewFrom：预览界面使用时传预览来源，其他地方不需要传
    init(fileToken: String, fileType: String, previewFrom: DrivePreviewFrom = .unknown, sourceType: DriveSourceType, additionalStatisticParameters: [String: String]?) {
        self.fileToken = DocsTracker.encrypt(id: fileToken)
        self.lowercasedFileType = fileType.lowercased()
        self.previewFrom = previewFrom
        self.sourceType = sourceType
        self.additionalStatisticParameters = additionalStatisticParameters
    }

    // MARK: - 函数定义
    func stageBegin(stage: Stage, loadingType: LoadingType = .preview, parameters: [String: Any]? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if !shouldReport {
            return
        }
        costTime[stage.rawValue] = Date()
        var tmpParamers = [String: Any]()
        tmpParamers.merge(other: parameters)
        tmpParamers.merge(other: [ReportKey.loadingType.rawValue: loadingType.rawValue,
                                  ReportKey.previewFrom.rawValue: previewFrom.stasticsValue])
        uploadParameters[stage.rawValue] = tmpParamers
        #if DEBUG || BETA
        DocsLogger.verbose("😁 -- DocsTracker.log  Start \(stage) \(String(describing: parameters))")
        #else
        #endif
    }

    func stageEnd(stage: Stage, parameters: [String: Any]? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if !shouldReport {
            return
        }
        let stageRawValue = stage.rawValue
        // stage 需要有开始才结束
        guard let previousTime = self.costTime[stageRawValue] else {
            return
        }
        let costTime = round(Date().timeIntervalSince(previousTime) * 1000)
        var allParames: [String: Any] = [ReportKey.stage.rawValue: stageRawValue,
                                         ReportKey.costTime.rawValue: costTime,
                                         ReportKey.fileToken.rawValue: fileToken,
                                         ReportKey.fileType.rawValue: fileType,
                                         ReportKey.previewFrom.rawValue: previewFrom.stasticsValue]
        allParames.merge(other: uploadParameters[stageRawValue])
        allParames.merge(other: parameters)
        allParames.merge(other: additionalStatisticParameters)
        if let fileSize = fileSize {
            allParames[ReportKey.fileSize.rawValue] = fileSize
        }
        #if DEBUG || BETA
        DocsLogger.verbose("😁 -- DocsTracker.log  End \(stage) \(allParames)")
        #else
        #endif

        DocsTracker.log(enumEvent: .driveStageEvent, parameters: allParames)
        self.uploadParameters[stageRawValue] = nil
        self.costTime[stageRawValue] = nil
    }
    
    func reportStageCostTime(stage: Stage, costTime: Double) {
        let stageRawValue = stage.rawValue
        var allParames: [String: Any] = [ReportKey.stage.rawValue: stageRawValue,
                                         ReportKey.costTime.rawValue: costTime,
                                         ReportKey.fileToken.rawValue: fileToken,
                                         ReportKey.fileType.rawValue: fileType,
                                         ReportKey.previewFrom.rawValue: previewFrom.stasticsValue]
        allParames.merge(other: additionalStatisticParameters)
        if let fileSize = fileSize {
            allParames[ReportKey.fileSize.rawValue] = fileSize
        }
        #if DEBUG || BETA
        DocsLogger.verbose("😁 -- DocsTracker.log  End \(stage) \(allParames)")
        #else
        #endif
        DocsTracker.log(enumEvent: .driveStageEvent, parameters: allParames)
    }
    /// 预览请求轮询统计
    func dataCollectionBegin(key: Key, code: Code, parameters: [String: Any]? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if !shouldReport {
            return
        }
        costTime[key.rawValue] = Date()
        var tmpParamers = [String: Any]()
        tmpParamers.merge(other: parameters)
        tmpParamers.merge(other: [ReportKey.key.rawValue: key.rawValue,
                                  ReportKey.code.rawValue: code.rawValue,
                                  ReportKey.previewFrom.rawValue: previewFrom.stasticsValue,
                                  ReportKey.fileType.rawValue: fileType])
        tmpParamers.merge(other: additionalStatisticParameters)
        DocsTracker.log(enumEvent: .dataCollectionEvent, parameters: tmpParamers)
        tmpParamers.removeValue(forKey: ReportKey.code.rawValue)
        tmpParamers.removeValue(forKey: ReportKey.fileType.rawValue)
        uploadParameters[key.rawValue] = tmpParamers
        #if DEBUG || BETA
        DocsLogger.verbose("😁 -- DocsTracker.log  dataCollectionBegin \(key) \(code) \(String(describing: tmpParamers))")
        #else
        #endif
    }

    func dataCollectionEnd(key: Key, code: Code, parameters: [String: Any]? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if !shouldReport {
            return
        }
        let keyRawValue = key.rawValue
        let codeRawValue = code.rawValue
        // stage 需要有开始才结束
        guard let previousTime = self.costTime[keyRawValue] else {
            return
        }
        let costTime = round(Date().timeIntervalSince(previousTime) * 1000)
        var allParames: [String: Any] = [ReportKey.code.rawValue: codeRawValue,
                                         ReportKey.costTime.rawValue: costTime,
                                         ReportKey.fileToken.rawValue: fileToken,
                                         ReportKey.fileType.rawValue: fileType]
        allParames.merge(other: uploadParameters[keyRawValue])
        allParames.merge(other: parameters)
        allParames.merge(other: additionalStatisticParameters)
        if let fileSize = fileSize {
            allParames[ReportKey.fileSize.rawValue] = fileSize
        }
        #if DEBUG || BETA
        DocsLogger.verbose("😁 -- DocsTracker.log  dataCollectionEnd \(key) \(code) \(allParames)")
        #else
        #endif
        DocsTracker.log(enumEvent: .dataCollectionEvent, parameters: allParames)
        if code == .finish {
            self.uploadParameters[keyRawValue] = nil
            self.costTime[keyRawValue] = nil
        }
    }

    ///  打开Drive文件开始
    func openStart(isInVC: Bool = false, contextVC: UIViewController?) {
        var parames: [String: Any] = [ReportKey.fileToken.rawValue: fileToken,
                                      ReportKey.previewFrom.rawValue: previewFrom.stasticsValue]
        parames.merge(other: additionalStatisticParameters)
        DocsTracker.startRecordTimeConsuming(eventType: .openDrive,
                                             parameters: parames)
        if let vc = contextVC {
            let viewId = "\(ObjectIdentifier(vc))"
            PowerConsumptionStatistic.markStart(token: fileToken, scene: .driveView(contextViewId: viewId))
            let inVCKey = PowerConsumptionStatisticParamKey.isInVC
            PowerConsumptionStatistic.updateParams(isInVC, forKey: inVCKey, token: fileToken, scene: .driveView(contextViewId: viewId))
            
            let key = PowerConsumptionStatisticParamKey.startNetLevel
            let netLevel = PowerConsumptionExtendedStatistic.ttNetworkQualityRawValue
            PowerConsumptionStatistic.updateParams(netLevel, forKey: key, token: fileToken, scene: .driveView(contextViewId: viewId))
        }
    }

    ///  关闭Drive文件
    func close(contextVC: UIViewController?) {
        guard let vc = contextVC else { return }
        let viewId = "\(ObjectIdentifier(vc))"
        
        if let fileSize = fileSize {
            let sizeKey = PowerConsumptionStatisticParamKey.fileSize
            PowerConsumptionStatistic.updateParams(fileSize, forKey: sizeKey, token: fileToken, scene: .driveView(contextViewId: viewId))
        }
        if let realMimeType = realMimeType {
            let typeKey = PowerConsumptionStatisticParamKey.fileType
            PowerConsumptionStatistic.updateParams(realMimeType, forKey: typeKey, token: fileToken, scene: .driveView(contextViewId: viewId))
        }
        if let sdkAppID = additionalStatisticParameters?[DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue] {
            let key = PowerConsumptionStatisticParamKey.appId
            PowerConsumptionStatistic.updateParams(sdkAppID, forKey: key, token: fileToken, scene: .driveView(contextViewId: viewId))
        }
        
        let key = PowerConsumptionStatisticParamKey.endNetLevel
        let netLevel = PowerConsumptionExtendedStatistic.ttNetworkQualityRawValue
        PowerConsumptionStatistic.updateParams(netLevel, forKey: key, token: fileToken, scene: .driveView(contextViewId: viewId))
        
        PowerConsumptionStatistic.markEnd(token: fileToken, scene: .driveView(contextViewId: viewId))
    }

    /// 开始转换在线文档
    func importStart() {
        var parames: [String: Any] = [ReportKey.fileToken.rawValue: fileToken,
                                      ReportKey.previewFrom.rawValue: previewFrom.stasticsValue]
        parames.merge(other: additionalStatisticParameters)
        DocsTracker.startRecordTimeConsuming(eventType: .convertDrive,
                                             parameters: parames)
    }
    
    func importFinished(result: DriveResultKey, code: DriveResultCode? = nil) {
        var params: [String: Any] = [ReportKey.fileToken.rawValue: fileToken,
                                     ReportKey.previewFrom.rawValue: previewFrom.stasticsValue,
                                     ReportKey.resultKey.rawValue: result.rawValue]
        if let code = code {
            params[ReportKey.resultCode.rawValue] = code.rawValue
        }
        params.merge(other: additionalStatisticParameters)
        DocsTracker.endRecordTimeConsuming(eventType: .convertDrive, parameters: params)
        #if DEBUG
        DocsLogger.driveInfo("import finish Params: \(params)")
        #endif
    }
    
    /// 可降级的预览方式的事件上报
    func openDowngradable(success: Bool, openType: DriveOpenType, extraInfo: [String: Any]? = nil) {
        var params: [String: Any] = [ReportKey.resultKey.rawValue: success ? "success" : "fail",
                                     ReportKey.openType.rawValue: openType.rawValue]
        let commonParams = commonReportParams(extraInfo: extraInfo)
        params.merge(other: commonParams)
        DocsTracker.log(event: DocsTracker.EventType.openDriveDowngrade.rawValue, parameters: params)
    }

    ///  完成打开文件
    ///
    /// - Parameters:
    ///   - result: 结果
    ///   - code: code值
    func openFinish(result: DriveResultKey, code: DriveResultCode, openType: DriveOpenType, extraInfo: [String: Any]? = nil) {
        var params: [String: Any] = [ReportKey.resultKey.rawValue: result.rawValue,
                                     ReportKey.resultCode.rawValue: code.rawValue,
                                     ReportKey.openType.rawValue: openType.rawValue,
                                     ReportKey.brand.rawValue: DomainConfig.envInfo.isFeishuBrand,
                                     ReportKey.package.rawValue: DomainConfig.envInfo.isFeishuPackage,
                                     ReportKey.isPrivatePkg.rawValue: ReleaseConfig.isPrivateKA,
                                     ReportKey.isChinaGeo.rawValue: DomainConfig.envInfo.isChinaMainland]
        if let thumbType = thumbType {
            params[ReportKey.thumbType.rawValue] = thumbType
        }
        
        if let networkType = networkType {
            params[ReportKey.networkType.rawValue] = networkType
        }
        
        let commonParams = commonReportParams(extraInfo: extraInfo)
        params.merge(other: commonParams)
        DocsTracker.endRecordTimeConsuming(eventType: .openDrive, parameters: params)
        DocsLogger.driveInfo("openFinish Params: \(params)")
        #if DEBUG
        if !(result == .cancel && sourceType == .other) {
            finishedCallback?()
        }
        #endif
    }
    
    private func commonReportParams(extraInfo: [String: Any]? = nil) -> [String: Any] {
        var params: [String: Any] = [ReportKey.fileType.rawValue: fileType,
                                      ReportKey.sourceType.rawValue: sourceType.rawValue,
                                      ReportKey.previewFrom.rawValue: previewFrom.stasticsValue,
                                      ReportKey.hitCache.rawValue: hitCache ? 1 : 0,
                                      ReportKey.loadFrom.rawValue: loadFrom.rawValue]
        if let fileSize = fileSize {
            params[ReportKey.fileSize.rawValue] = fileSize
        }
        
        if let previewSize = previewFileSize {
            params[ReportKey.previewSize.rawValue] = previewSize
        }
        
        if let previewType = previewType {
            params[ReportKey.previewType.rawValue] = previewType
        }
        
        if let previewExt = previewExt {
            params[ReportKey.previewExt.rawValue] = previewExt
        }
        
        if let mimeType = mimeType {
            params[ReportKey.mimeType.rawValue] = mimeType
        }
        
        if let realMimeType = realMimeType {
            params[ReportKey.realMimeType.rawValue] = realMimeType
        }
        
        if let isRealType = isRealFileType() {
            params[ReportKey.isRealType.rawValue] = isRealType ? 1 : 0
        }
        
        if let extraInfo = extraInfo {
            params.merge(other: extraInfo)
        }
        
        params.merge(other: additionalStatisticParameters)
        
        return params
    }
    
    /// 根据 MIMEType 等信息判断文件是否为真实类型
    private func isRealFileType() -> Bool? {
        guard let mimeType = self.mimeType,
              let realMimeType = self.realMimeType else { return nil }
        // 先判断后端返回的两个 mimeType 信息是否一致，若不一致则转换为文件后缀名进行二次判断
        if mimeType == realMimeType {
            return true
        } else {
            let originFileExt = DriveUtils.fileExtensionFromMIMEType(realMimeType)
            return originFileExt == fileType
        }
    }
}
