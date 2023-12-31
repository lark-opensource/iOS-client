//
//  DriveWPSPreviewViewModel.swift
//  SKECM
//
//  Created by ZhangYuanping on 2021/4/2.
//
// swiftlint:disable cyclomatic_complexity file_length

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import LarkEnv
import SKUIKit
import SKInfra
import LarkDocsIcon
import Alamofire
import SpaceInterface

struct DriveWPSPreviewInfo {
    let fileToken: String
    let fileType: DriveFileType
    /// 第三方 app_id，如 IM 场景为 1001
    let appId: String?
    /// 额外的鉴权信息
    let authExtra: String?
    /// 编辑权限
    var isEditable: BehaviorRelay<Bool>
    /// 权限信息
    var permissionInfo: BehaviorRelay<DrivePermissionInfo>?
    /// 文档信息
    var docsInfo: BehaviorRelay<DocsInfo>?
    /// 依赖注入的基本信息
    let context: FeatureSettingsContext
    
    struct FeatureSettingsContext {
        var wpsTemplateTimeout = DriveFeatureGate.wpsTemplateTimeout
        var retryCount = DriveFeatureGate.wpsRenderTerminateRetryCount
        var editModeEnable = DriveFeatureGate.driveWPSEditEnable
        var wpsCenterVersionEnable = LKFeatureGating.wpsCenterVersionEnable
        var wpsOptimizeEnable = UserScopeNoChangeFG.ZYP.wpsOptimizeEnable
        var isFeishuPackage = DomainConfig.envInfo.isFeishuPackage
        var language = I18nUtil.currentLanguage
        var wpsUrlCheckEnable = UserScopeNoChangeFG.ZYP.wpsUrlCheckEnable
    }
    
    init(fileToken: String, fileType: DriveFileType, authExtra: String?, isEditable: BehaviorRelay<Bool>,
         context: FeatureSettingsContext = FeatureSettingsContext()) {
        self.fileToken = fileToken
        self.fileType = fileType
        self.appId = nil
        self.authExtra = authExtra
        self.isEditable = isEditable
        self.context = context
    }
    
    /// 供 IM 预览使用
    init(fileId: String, fileType: DriveFileType, appId: String, authExtra: String?,
         context: FeatureSettingsContext = FeatureSettingsContext()) {
        self.fileToken = fileId
        self.fileType = fileType
        self.appId = appId
        self.authExtra = authExtra
        self.isEditable = BehaviorRelay<Bool>(value: false)
        self.context = context
    }
}

class DriveWPSPreviewViewModel {
    typealias Stage = DrivePerformanceRecorder.Stage
    struct BizCode {
        static let succ = 0
        static let overTenantQuota = 11001
        static let overUserQuota = 90001061
        static let mutilGoStopWriting = 900004230
        static let pointKill = 90001500
        static let overEditLimited = 90001081
        static let overSaveLimted = 90001043
        static func needStopWriting(code: Int) -> Bool {
            return code == overTenantQuota ||
            code == overUserQuota ||
            code == overEditLimited ||
            code == overSaveLimted ||
            code == mutilGoStopWriting
        }
    }
    
    enum OfficeOperation: String {
        case NeedPassword
    }
    
    var htmlTemplateURL: URL? { DriveModule.getPreviewResourceURL(name: "wps", extensionType: "html") }
    
    // MARK: - Input
    /// 接收模板的 JS 事件信息
    let receivedMessage = PublishSubject<(method: String, params: String)>()
    /// 切换 PPT 演示模式
    let presentationModeChange = PublishSubject<Bool>()
    private var previewModeChanged = BehaviorRelay<WPSPreviewMode>(value: .readOnly)
    var previewMode: WPSPreviewMode = .readOnly {
        didSet {
            if oldValue != previewMode {
                previewModeChanged.accept(previewMode)
            }
        }
    }
    
    // MARK: - Output
    /// 预览状态
    let wpsPreviewState = PublishSubject<WPSPreviewState>()
    /// 进入/退出 PPT 演示模式状态
    let presentationStatus = PublishSubject<SlidePresentationResult.Status>()
    /// 是否展示 ppt 演示模式按钮
    lazy var showPresentationBarButton: Driver<Bool> = {
        return wpsApplicationReady.asObservable()
            .map {[weak self] in
                guard let self = self else { return false }
                return self.previewInfo.fileType.isPPT && $0
            }
            .asDriver(onErrorJustReturn: false)
    }()
    
    let previewInfo: DriveWPSPreviewInfo
    private var stopWriting = BehaviorRelay<Bool>(value: false)
    // 权限变化提示
    lazy var editPermissionChangedToast: Driver<Bool> = {
        return previewInfo.isEditable.debug("drive.wps.preview - isEditable")
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }()
    
    // 是否展示编辑按钮
    lazy var showEditBtn: Driver<Bool> = {
        return Observable.combineLatest(previewModeChanged,
                                        stopWriting,
                                        previewInfo.isEditable) { (mode, isOverLimited, hasEditPermisson) -> Bool in
            DocsLogger.driveInfo("drive.wps.preview - mode \(mode), isOverLimited: \(isOverLimited), hasEditPermission: \(hasEditPermisson)")
            return mode == .readOnly && !isOverLimited && hasEditPermisson
        }.distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }()
    // 降级到阅读状态
    lazy var downgradeToReadOnly: Driver<()> = {
        return Observable.combineLatest(previewModeChanged,
                                        stopWriting,
                                        previewInfo.isEditable) { (mode, isOverLimited, hasEditPermission) -> Bool in
            return mode == .edit && (isOverLimited || !hasEditPermission)
        }.asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .flatMap { (downgrad) -> Driver<()> in
                if downgrad {
                    return Driver<()>.just(())
                } else {
                    return Driver<()>.empty()
                }
            }
    }()

    private static let thridReqIdLength = 32
    private static let wpsUrlCheckTimeoutMilliSec = 10000

    /// RN长链接口类
    private let tagPrefix = StablePushPrefix.thirdEvent.rawValue
    private let messageTag: String
    private var messageBoxVersion: Int?
    private var messageBoxManager: StablePushManagerProtocol
    private var grayEnv: String = "online" // 灰度策略值，默认 online
    private var grayStrategyRequest: DocsRequest<JSON>?
    private let wpsApplicationReady = BehaviorRelay<Bool>(value: false)
    private let fetchWPSTokenQueue = DispatchQueue(label: "drive.wps.token", attributes: [.concurrent])
    // 判断是否是第一次进入wps
    private var firstOpen: Bool = true
    
    private let disposeBag = DisposeBag()
    
    private var stageDuration = [String: Double]()
    
    private let wpsCenterVersionEnable: Bool
    
    init(info: DriveWPSPreviewInfo,
         pushManagerProvider: (SKPushInfo) -> StablePushManagerProtocol = { pushInfo in
        return StablePushManager(pushInfo: pushInfo)
    }) {
        previewInfo = info
        messageTag = tagPrefix + info.fileToken
        let pushInfo = SKPushInfo(tag: messageTag,
                                  resourceType: StablePushPrefix.thirdEvent.resourceType(),
                                  routeKey: info.fileToken,
                                  routeType: SKPushRouteType.token)
        self.messageBoxManager = pushManagerProvider(pushInfo)
        self.wpsCenterVersionEnable = info.context.wpsCenterVersionEnable
        fetchGrayStrategy()
        setup()
    }
    
    deinit {
        DocsLogger.driveInfo("drive.wps.preview - deinit")
        self.messageBoxManager.unRegister()
    }
    private func setup() {
        // register save notify
        messageBoxManager.register(with: self)

        // 订阅 WPS 模版返回的消息
        receivedMessage.subscribe(onNext: { [weak self] (method, params) in
            guard let self = self else { return }
            guard let jsEvent = ReceivedJSEvent(rawValue: method) else {
                DocsLogger.warning("drive.wps.preview - receive unknown js event")
                return
            }
            DocsLogger.driveInfo("drive.wps.preview - parse JS Messange: method - \(method), params - \(params)")
            switch jsEvent {
            case .getInitialData:
                self.setupInitialData()
            case .wpsLoadStatus:
                guard let jsonData = params.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed) as? [String: Any] else {
                    spaceAssertionFailure("Parse WPSLoadStatus error")
                    return
                }
                if let isSuccess = json["isSuccess"] as? Bool {
                    self.wpsPreviewState.onNext(.loadStatus(isSuccess: isSuccess))
                } else {
                    DocsLogger.driveInfo("WPSLoadStatus not handle \(json)")
                }
            case .getAuthToken:
                DocsLogger.driveInfo("drive.wps.preview - WPS should refresh authToken")
                self.refreshAuthToken()
            case .wpsError:
                guard let jsonData = params.data(using: .utf8),
                      let wpsErrorInfo = try? JSONDecoder().decode(WPSErrorInfo.self, from: jsonData) else {
                    DocsLogger.driveError("can not get JS Object method, params: \(params)")
                    self.wpsPreviewState.onNext(.throwError(info: WPSErrorInfo.unknown))
                    return
                }
                self.wpsPreviewState.onNext(.throwError(info: wpsErrorInfo))
            case .wpsApplicationReady:
                DocsLogger.driveInfo("drive.wps.preview - WPS Application instance Ready")
                self.wpsApplicationReady.accept(true)
            case .wpsApiCallback:
                DocsLogger.driveInfo("drive.wps.preview - WPS API call back, params: \(params)")
            case .slideShowStatusChanged:
                DocsLogger.driveInfo("drive.wps.preview - WPS slideShowStatusChanged, params: \(params)")
                guard let jsonData = params.data(using: .utf8),
                      let presentation = try? JSONDecoder().decode(SlidePresentationResult.self, from: jsonData) else {
                    spaceAssertionFailure("Parse SlidePresentationStatus Failed")
                    return
                }
                self.presentationStatus.onNext(presentation.status)
            case .onHyperLinkOpen:
                DocsLogger.driveInfo("drive.wps.preview - WPS onHyperLinkOpen, params: \(params)")
                guard let jsonData = params.data(using: .utf8),
                      let wpsLink = try? JSONDecoder().decode(WPSLink.self, from: jsonData) else {
                    spaceAssertionFailure("Parse WPSLink Failed")
                    return
                }
                self.wpsPreviewState.onNext(.openLink(urlString: wpsLink.linkUrl))
            case .log:
                DocsLogger.driveInfo("drive.wps.preview - WPS log: \(params)")
            case .wpsFilePasswordStatusChanged:
                DocsLogger.driveInfo("drive.wps.preview - wpsFilePasswordStatusChanged: \(params)")
                
                guard let data = params.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    DocsLogger.driveError("drive.wps.preview - wpsFilePasswordStatusChanged parse params error")
                    return
                }
                self.handleOfficePassword(params: json)
            case .wpsStageChanged:
                DocsLogger.driveInfo("drive.wps.preview - WPS wpsStageChanged: \(params)")
                guard let data = params.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    DocsLogger.driveError("drive.wps.preview - WPS wpsStageChanged parse params error")
                    return
                }
                self.handleStage(params: json)
            case .getWpsIframeUrlHeadData:
                guard let data = params.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any],
                      let iframeUrl = json["iframeUrl"] as? String else {
                    DocsLogger.driveError("drive.wps.preview - getWpsIframeUrlHeadData parse params error")
                    return
                }
                self.checkIframeUrl(iframeUrl)
            }
        }).disposed(by: disposeBag)
        
        // 订阅进入演示模式事件
        presentationModeChange.subscribe(onNext: { [weak self] isPresentation in
            self?.changePresentationMode(isPresentation: isPresentation)
        }).disposed(by: disposeBag)
    }
        
    /// 传递 WPS 预览初始化信息
    private func setupInitialData() {
        fetchWPSAccessToken().observeOn(MainScheduler.instance).subscribe { [weak self] authToken in
            guard let self = self else { return }
            var iframeUrl = ""
            if let url = authToken["url"] as? String {
                iframeUrl = self.getLocal(url: url, authToken: authToken)
                DocsLogger.driveInfo("drive.wps.preview - iframeURL: \(iframeUrl)")
            } else {
                DocsLogger.driveError("drive.wps.preview - need backend return wps url!")
                //对于后端未下发url的情况下，降级兜底预览
                self.wpsPreviewState.onNext(.throwError(info: .unknown))
                return
            }
            let authToken = authToken
            let openIntoEdit: Bool
            switch self.previewMode {
            case .readOnly:
                openIntoEdit = false
            case .edit:
                openIntoEdit = true
            }
            let wordOptions: [String: Any] = ["mobile": ["isOpenIntoEdit": openIntoEdit]]
            var baseInfo: [String: Any] = ["wpsIframeUrl": iframeUrl,
                                           "authToken": authToken,
                                           "shouldWpsUrlCheck": self.previewInfo.context.wpsUrlCheckEnable,
                                           "wpsUrlCheckTimeout": Self.wpsUrlCheckTimeoutMilliSec,
                                           "wpsOptions": ["mode": "normal", "wordOptions": wordOptions]]
            let hiddenCommandBarOptions = [
                "HeaderLeft", // PC头部左侧, 头部一共分左中右三块区域
                "HeaderRight", // PC头部右侧, 头部一共分左中右三块区域
                "FloatQuickHelp", // 右下角帮助(金小豹)
                "CooperationPanelOwnerInfo", // 移动端协作列表中当前文档所有者信息
                "Logo", // 移动端状态栏Logo
                "Cooperation", // 移动端状态栏协作头像
                "More", // 移动端状态栏更多按钮
                "Print", // 打印按钮
                "CheckCellHistory", // PC端-表格-单元格最近的改动
                "HistoryVersion", // PC端-顶部状态栏-历史记录菜单-历史版本
                "HistoryRecord", // PC端-顶部状态栏-历史记录菜单-协作记录
                "HistoryVersionDivider", // PC端-表格-右键菜单-历史版本/协作记录分割线
                "ContextMenuConvene", // 文字右键召唤在线协助者
                "Comment", // pc-评论入口
                "WPPPcCommentButton", // PC端-底部工具栏-评论按钮
                "WPPMobileCommentButton", // 移动端-底部工具栏-评论按钮
                "WPPMobileMarkButton", // 移动端PPT批注显示按钮
                "MobileHeader", // 移动端顶部空白栏
                "WriterHoverToolbars"]
            let excelOptions: [String: Any] = ["isEnableInsertCloudCellPic": false]
            baseInfo["wpsOptions"] = ["mode": "normal",
                                      "wordOptions": wordOptions,
                                      "hiddenCommandBarOptions": hiddenCommandBarOptions,
                                      "excelOptions": excelOptions]
            self.triggerJSEvent(.setInitialData, value: baseInfo)
        } onError: { [weak self] error in
            self?.handleTokenError(error)
        }.disposed(by: disposeBag)
    }
    
    /// 更新 WPS 的 Token
    private func refreshAuthToken() {
        fetchWPSAccessToken().observeOn(MainScheduler.instance).subscribe { [weak self] authToken in
            guard let self = self else { return }
            let tokenInfo = ["authToken": authToken]
            self.triggerJSEvent(.refreshAuthToken, value: tokenInfo)
        } onError: { [weak self] error in
            self?.handleTokenError(error)
        }.disposed(by: disposeBag)
    }
    
    private func handleTokenError(_ error: Error) {
        if let tokenError = error as? FetchTokenError, case FetchTokenError.pointKill = tokenError {
            self.wpsPreviewState.onNext(.pointKill)
        } else {
            // 对于后端返回的未知错误码，统一降级预览
            self.wpsPreviewState.onNext(.throwError(info: .unknown))
        }
        DocsLogger.driveError("drive.wps.preview - failed to get wps token, error: \(error.localizedDescription)")
    }

    private func checkIframeUrl(_ urlStr: String) {
        guard self.previewInfo.context.wpsUrlCheckEnable else { return }
        Alamofire.request(urlStr, method: .head).validate().response { [weak self] response in
            var code = 0
            var msg = "Success"
            if let error = response.error {
                DocsLogger.driveError("drive.wps.preview - checkIframeUrl error: \(error.localizedDescription)")
                code = response.response?.statusCode ?? 1
                msg = "Error"
            }
            DocsLogger.driveInfo("drive.wps.preview - setWpsIframeUrlHeadData: \(code)")
            let info: [String: Any] = ["code": code, "msg": msg]
            self?.triggerJSEvent(.setWpsIframeUrlHeadData, value: info)
        }
    }

    /// 进入/退出 PPT 演示模式
    private func changePresentationMode(isPresentation: Bool) {
        guard previewInfo.fileType.isPPT else { return }
        var command = "ActivePresentation.SlideShowWindow.View.Exit"
        if isPresentation {
            command = "ActivePresentation.SlideShowSettings.Run"
        }
        let value = ["fileType": "ppt", "command": command]
        triggerJSEvent(.triggerWpsApi, value: value)
    }
    
    /// 执行模板 JS 方法
    private func triggerJSEvent(_ event: TriggerJSEvent, value: [String: Any]) {
        let data: [String: Any] = ["key": event.rawValue,
                                  "value": value]
        DocsLogger.driveInfo("drive.wps.preview - TriggerJSEvent: \(event.rawValue)")
        // 需要转换成 Base64
        guard let transformedContent = data.toJSONString()?.toBase64() else {
            spaceAssertionFailure("can not get initalData")
            return
        }
        wpsPreviewState.onNext(.needEvaluateJS(script: "triggerJSEvent('\(transformedContent)')", event: event))
    }
    
    private func handleStage(params: [String: Any]) {
        guard let stage = params["stage"] as? [String: Any] else {
            spaceAssertionFailure("drive.wps.preview - can not parse stage changed parmas")
            return
        }
        guard let stageNameStr = stage["name"] as? String,
              let duration = stage["duration"]  as? Double else {
            spaceAssertionFailure("drive.wps.preview - can not parse stage name and duration")
            return
        }
        guard let stageName = WPSRenderStageName(rawValue: stageNameStr) else {
            DocsLogger.driveInfo("drive.wps.preview - stage not report: \(stageNameStr)")
            return
        }
        if let begin = stageName.performanceStage.begin {
            stageDuration[begin.rawValue] = duration
        }
        if let end = stageName.performanceStage.end, let start = stageDuration[end.rawValue] {
            let cost = duration - start
            DocsLogger.driveInfo("drive.wps.preview - stage \(end.rawValue) cost: \(cost)")
            wpsPreviewState.onNext(.reportStage(stage: end, costTime: cost))
            stageDuration[end.rawValue] = nil
        }
    }
    
    private func handleOfficePassword(params: [String: Any]) {
        guard let status = params["status"] as? [String: Any] else {
            spaceAssertionFailure("drive.wps.preview - can not parse office password changed parmas")
            return
        }
        guard let type = status["type"] as? String,
              type == OfficeOperation.NeedPassword.rawValue else {
            spaceAssertionFailure("drive.wps.preview - invalid type")
            return
        }

        self.wpsPreviewState.onNext(.showPassword)
    }
    
    private func getLocal(url: String, authToken: [String: Any]) -> String {
        let isFeishuPackage = previewInfo.context.isFeishuPackage
        if let brand = authToken["brand"] as? String, brand == "lark", !wpsCenterVersionEnable, !isFeishuPackage {
           return self.assembleIframUrl(baseUrl: url, isInLarkWPS: true)
        } else {
            return self.assembleIframUrl(baseUrl: url)
        }
    }
    
    private func assembleIframUrl(baseUrl: String, isInLarkWPS: Bool = false) -> String {
        var language = previewInfo.context.language // zh-CN 或 en-US
        let isFeishuPackage = previewInfo.context.isFeishuPackage
        if isInLarkWPS {
            switch language {
            case I18nUtil.LanguageType.zh_CN:
                language = "zh-lark"
            case I18nUtil.LanguageType.en_US:
                language = "en-lark"
            default:
                language = "en-lark"
            }
        }
        DocsLogger.driveInfo("drive.wps.preview - assembleIframUrl, isCenterVersion: \(wpsCenterVersionEnable), isInLarkWPS = \(isInLarkWPS), isFeishuPackage = \(isFeishuPackage), language = \(language)")
        let randomStr = String.randomStr(len: Self.thridReqIdLength)
        let requireMode = previewMode.rawValue
        var hideCommandBar = "&hidecmb"
        
        let isWord = previewInfo.fileType.isWord
        let isPPTOrExcel = previewInfo.fileType.isPPT || previewInfo.fileType.isExcel
        if isWord {
            // Word 不隐藏底部工具栏 （缩放功能由工具栏提供）
            hideCommandBar = ""
        } else if isPPTOrExcel && previewMode == .edit {
            hideCommandBar = ""
        }
        if wpsCenterVersionEnable {
            // 中台版
            return baseUrl + "&_w_third_lang=\(language)&_w_third_req_id=\(randomStr)&_w_third_require_mode=\(requireMode)\(hideCommandBar)"
        } else {
            // 珠研版
            return baseUrl + "&lang=\(language)&third_req_id=\(randomStr)&require_mode=\(requireMode)\(hideCommandBar)"
        }
    }

}

extension DriveWPSPreviewViewModel {
    /// wps渲染的阶段细分: https://bytedance.feishu.cn/docx/doxcn7nug6tDq5s0M1ERCPagnWc
    enum WPSRenderStageName: String {
        case parentHtmlStart = "parent.html.start" // 上级页面的requestStart时间戳 (浏览器向服务器发出页面HTTP请求时，或开始读取本地缓存时)    A阶段开始
        case webHtmlStart = "web.html.start" // 当前页面的requestStart时间戳 (浏览器向服务器发出页面HTTP请求时，或开始读取本地缓存时)    A阶段结束，B阶段开始
        case htmlLoaded = "html.loaded" // 浏览器从服务器收到页面最后一个字节时    B阶段结束，C阶段开始
        case xhrStart = "xhr_start" // 开始请求首屏渲染数据    E阶段开始
        case jsLoaded = "js.loaded" // 内核组件加载完成时间    C阶段结束，I阶段开始
        case xhrEnd = "xhr_end" // 请求首屏渲染数据完成    E阶段结束
        case wsStart = "ws.start" // 开始建立连接websocket    G阶段开始
        case initCoreStart = "init.core.start" // 开始初始化内核    I阶段结束，J阶段开始
        case initCoreEnd = "init.core.end" // 内核初始化完成    J阶段结束，K阶段开始
        case renderEnd = "render.end" // 首屏渲染完成    K阶段结束
        case wsOpen = "ws.open" // websocket已连接, G阶段结束，H阶段开始
        case docPermission = "doc.permission" // websocket返回文档权限,H阶段结束
        
        // 对应的性能埋点stage起始点
        // 返回值：
        // begin: 当前stage对应埋点的起点stage
        // end: 当前stage对应埋点事件的结束stage
        // 例如 webHtmlStart是A阶段的结束，B阶段的开始
        var performanceStage: (begin: Stage?, end: Stage?) {
            switch self {
            case .parentHtmlStart: // A阶段开始 wpsRenderParentHtml
                return (.wpsRenderParentHtml, nil)
            case .webHtmlStart: // A阶段结束 wpsRenderParentHtml， B阶段开始 wpsRenderHtml
                return (.wpsRenderHtml, .wpsRenderParentHtml)
            case .htmlLoaded: // B阶段结束 wpsRenderHtml， C阶段开始 wpsRenderLoadJS
                return (.wpsRenderLoadJS, .wpsRenderHtml)
            case .xhrStart: // E阶段开始 wpsRenderXHR
                return (.wpsRenderXHR, nil)
            case .jsLoaded: // C阶段结束 wpsRenderLoadJS，I阶段开始 wpsRenderParseData
                return (.wpsRenderParseData, .wpsRenderLoadJS)
            case .xhrEnd: // E阶段结束 wpsRenderXHR
                return (nil, .wpsRenderXHR)
            case .wsStart: // G阶段开始 wpsRenderWSStart
                return (.wpsRenderWSStart, nil)
            case .initCoreStart:  // I阶段结束 wpsRenderParseData，J阶段开始 wpsRenderInitCore
                return (.wpsRenderInitCore, .wpsRenderParseData)
            case .initCoreEnd: // J阶段结束 wpsRenderInitCore，K阶段开始 wpsRenderContent
                return (.wpsRenderContent, .wpsRenderInitCore)
            case .renderEnd: // K阶段结束 wpsRenderContent
                return (nil, .wpsRenderContent)
            case .wsOpen: // G阶段结束 wpsRenderWSStart，H阶段开始 wpsRenderWSOpen
                return (.wpsRenderWSOpen, .wpsRenderWSStart)
            case .docPermission: // H阶段结束 wpsRenderWSOpen
                return (nil, .wpsRenderWSOpen)
            }
        }
    }
    /// 供 VC 订阅的模板状态
    enum WPSPreviewState {
        case needEvaluateJS(script: String, event: TriggerJSEvent)
        case loadStatus(isSuccess: Bool)
        case throwError(info: WPSErrorInfo)
        case pointKill
        case openLink(urlString: String)
        case quotaAlert(type: Quotatype)
        case reportStage(stage: DrivePerformanceRecorder.Stage, costTime: Double)
        case mutilGoStopWriting
        case toast(tips: String)
        case showPassword
    }
    
    /// 从 WPS 模板里接收的 JS 事件
    enum ReceivedJSEvent: String {
        /// 告诉业务方需要接收初始化数据
        case getInitialData
        /// 告诉业务方需要更新 AuthToken
        case getAuthToken
        /// WPS 模板加载结果
        case wpsLoadStatus
        /// 抛出的原生 WPS 错误信息
        case wpsError
        /// 调用 WPS API 需要获得 WPS 的 Application 实例，在实例加载好后会收到此事件，说明可以调用 triggerWpsApi 了
        case wpsApplicationReady
        /// 对于 WPS API 的调用结果，通过 wpsApiCallback 事件回传给业务方
        case wpsApiCallback
        /// 进入/退出演示模式的状态
        case slideShowStatusChanged
        /// 点击链接抛出的事件
        case onHyperLinkOpen
        case log
        /// 前端wps渲染阶段埋点透传
        case wpsStageChanged
        /// 前端wps 通知需要显示密码输入框（主要用于Office）
        case wpsFilePasswordStatusChanged
        /// 前端让客户端发起 WPS 网页预请求，用于判断 WPS 服务是否正常
        case getWpsIframeUrlHeadData
    }
    
    /// 业务方可以调用的 JS 方法
    enum TriggerJSEvent: String {
        case setInitialData
        case refreshAuthToken
        case triggerWpsApi
        /// 把IframeUrl的连通性结果返回前端
        case setWpsIframeUrlHeadData
    }
    
    enum WPSPreviewMode: Int {
        case readOnly = 1
        case edit = 2
    }
    
    enum Quotatype: Int {
        case tenant = 1
        case user = 2
    }
    
    enum WPSErrorType: String, Codable {
        case unknown = "Unknown"
        /// 对接时的 internal 错误
        case getFileInfoFailed = "GetFileInfoFailed"
        /// 用户未登录
        case userNotLogin
        /// 无效链接
        case invalidLink = "InvalidLink"
        /// 协作成员已满
        case sessionFull = "SessionFull"
        /// 打开失败
        case fail = "Fail"
        /// 您的操作权限不足
        case permissionDenied = "PermissionDenied"
        /// 获取token失败
        case getTokenFailed = "GetTokenFailed"
        /// 会话过期
        case sessionExpired = "SessionExpired"
        /// 文件太大，不支持预览
        case fileTooLarge
        /// WPS 内部自定义错误
        case wpsCustomError = "WPS_CUSTOM_ERROR"
    }
    
    struct WPSErrorInfo: Codable, CustomStringConvertible {
        var errorType: WPSErrorType
        var errorMsg: String
        
        var description: String {
            return "type: \(errorType), message: \(errorMsg)"
        }
        
        static var unknown: WPSErrorInfo {
            return WPSErrorInfo(errorType: .unknown, errorMsg: "unknownError")
        }
    }
    
    struct WPSLink: Codable {
        var linkUrl: String
    }
    
    struct SlidePresentationResult: Codable {
        var status: Status
        
        /// 进入/退出 PPT 演示模式的状态
        enum Status: String, Codable {
            case begin
            case end
        }
    }
    
    enum FetchTokenError: LocalizedError {
        case parseDataFailed
        /// 点杀错误，防止异常文档对服务端稳定性造成影响，收到此错误降级预览
        case pointKill

        var errorDescription: String? {
            switch self {
            case .parseDataFailed:
                return "failed to parse data"
            case .pointKill:
                return "point kill by server"
            }
        }
    }
    
    /// 获取 WPS 灰度策略值
    private func fetchGrayStrategy() {
        let APIPath = OpenAPI.APIPath.thirdPartyGrayStarategy
        let params: [String: Any] = ["third_source": 1]
        grayStrategyRequest = DocsRequest<JSON>(path: APIPath, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeAsQuery)
            .set(needVerifyData: false)
            .start { [weak self] json, error in
                guard let self = self else { return }
                guard error == nil else {
                    DocsLogger.driveError("drive.wps.preview - failed to get gray strategy, error: \(error!.localizedDescription)")
                    return
                }
                guard let json = json, let dataDic = json["data"].dictionaryObject, let env = dataDic["env"] as? String else {
                    DocsLogger.driveError("drive.wps.preview - failed to parse gray strategy")
                    return
                }
                self.grayEnv = env
            }
    }

    
    /// 获取 WPS 的 AccessToken
    /// https://bytedance.feishu.cn/wiki/wikcnnx6X3KMIcKQszifWMyvBkf#i3Fq4v
    func fetchWPSAccessToken() -> Single<[String: Any]> {
        let APIPath = OpenAPI.APIPath.thirdPartyAccessToken
        var params: [String: Any]
        if let appId = previewInfo.appId {
            params = ["app_id": appId,
                      "app_file_id": previewInfo.fileToken,
                      "third_source": 1,
                      "need_url": true]
        } else {
            params = ["file_token": previewInfo.fileToken,
                      "third_source": 1,
                      "need_url": true]
        }
        switch previewMode {
        case .readOnly:
            if firstOpen {
                // need_edit为true后端会判断容量是否超限，确保首次打开在只读状态下预览能够正确判断容量是否超限
                firstOpen = false
                params["need_edit"] = true
            } else {
                params["need_edit"] = false
            }
        case .edit:
            params["need_edit"] = true
        }
        if self.wpsCenterVersionEnable {
            params["third_source"] = 2
        }
        if let authExtra = previewInfo.authExtra {
            params["auth_extra"] = authExtra
        }
        
        let request = DocsRequest<JSON>(path: APIPath, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        
        return request.rxStart()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: fetchWPSTokenQueue))
            .map {[weak self] result -> [String: Any] in
                guard let self = self else { return [:] }
                guard let json = result, let code = json["code"].int else {
                    DocsLogger.driveError("drive.wps.preview - result invalide")
                    throw DriveError.previewDataError
                }
                switch code {
                case BizCode.succ,
                    BizCode.overTenantQuota,
                    BizCode.overUserQuota,
                    BizCode.mutilGoStopWriting,
                    BizCode.overEditLimited:
                    guard let dataDic = json["data"].dictionaryObject else {
                        DocsLogger.driveError("drive.wps.preview - parse data to fileInfo failed")
                        throw FetchTokenError.parseDataFailed
                    }
                    DocsLogger.driveInfo("drive.wps.preview - code: \(code), dataDict: \(dataDic)")
                    if code == BizCode.overTenantQuota {
                        self.wpsPreviewState.onNext(.quotaAlert(type: .tenant))
                    }
                    if code == BizCode.overUserQuota {
                        self.wpsPreviewState.onNext(.quotaAlert(type: .user))
                    }
                    if code == BizCode.mutilGoStopWriting {
                        self.wpsPreviewState.onNext(.mutilGoStopWriting)
                    }
                    if code == BizCode.overEditLimited {
                        self.handleOverEditLimited(data: dataDic)
                    }
                    if let needEdit = params["need_edit"] as? Bool, needEdit {
                        self.stopWriting.accept(BizCode.needStopWriting(code: code))
                    }
                    return dataDic
                case BizCode.pointKill:
                    throw FetchTokenError.pointKill
                default:
                    DocsLogger.driveError("drive.wps.preview - result code: \(code)")
                    throw DriveError.serverError(code: code)
                }
            }
    }
    private func handleOverEditLimited(data: [String: Any]) {
        guard previewInfo.isEditable.value else {
            DocsLogger.driveError("drive.wps.preview - not support edit")
            return
        }
        guard let limited = data["edit_limit"] as? UInt64 else {
            DocsLogger.driveError("drive.wps.preview - no edit_limit")
            return
        }
        self.wpsPreviewState.onNext(.toast(tips: BundleI18n.SKResource.LarkCCM_Docs_Tooltip_FileOversize_mob(limited.sizeInMB)))
    }
}

extension DriveWPSPreviewViewModel: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        DocsLogger.driveInfo("drive.wps.preview - did receive save failed push")
        guard let data = try? JSONSerialization.data(withJSONObject: data),
            let json = try? JSON(data: data),
            let newJsonString = json["body"]["data"].string else {
                DocsLogger.driveInfo("drive.wps.preview - Decode json failed")
                return
        }
        let newJson = JSON(parseJSON: newJsonString)
        guard let fileToken = newJson["file_token"].string,
              let eventType = newJson["event_type"].string,
              let bizCode = newJson["biz_code"].int else {
                DocsLogger.driveInfo("drive.wps.preview - Get fileToken and eventType failed")
                return
        }
        guard eventType == "save", fileToken == previewInfo.fileToken else {
            DocsLogger.driveInfo("drive.wps.preview - no need to handle \(DocsTracker.encrypt(id: fileToken))")
            return
        }
        let editLimited = newJson["edit_limit"].uInt64
        handlePushInfo(bizCode: bizCode, editLimite: editLimited)
    }
    
    private func handlePushInfo(bizCode: Int, editLimite: UInt64?) {
        guard previewInfo.isEditable.value else {
            DocsLogger.driveError("drive.wps.preview - not support edit")
            return
        }
        DocsLogger.driveInfo("drive.wps.preview - bizCode \(bizCode)")
        guard previewMode == .edit else {
            DocsLogger.driveInfo("drive.wps.preview - cur preview mode is readonly not need to show toast")
            return
        }

        if bizCode == BizCode.overEditLimited, let limited = editLimite {
            self.wpsPreviewState.onNext(.toast(tips: BundleI18n.SKResource.LarkCCM_Docs_Tooltip_FileOversize_mob(limited.sizeInMB)))
        }
        
        if bizCode == BizCode.overSaveLimted {
            self.wpsPreviewState.onNext(.toast(tips: BundleI18n.SKResource.LarkCCM_Docs_Tooltip_AutoSaveFailed))
        }
        let overLimited = BizCode.needStopWriting(code: bizCode)
        self.stopWriting.accept(overLimited)
    }
}

extension UInt64 {
    var sizeInMB: UInt64 {
        return self / 1024 / 1024
    }
}
extension DriveFileType {
    var wpsPreviewType: String {
        if isWord {
            return "w"
        }
        if isPPT {
            return "p"
        }
        if isExcel {
            return "s"
        }
        if isPDF {
            return "f"
        }
        return ""
    }
}
