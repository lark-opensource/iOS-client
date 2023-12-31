//
//  BTContainerAddRecordPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/10/19.
//

import SKFoundation
import SKInfra
import SKCommon
import SKBrowser
import UniverseDesignEmpty
import SwiftyJSON
import EENavigator
import UniverseDesignColor
import SKResource
import UniverseDesignDialog
import SpaceInterface
import LarkSetting

private enum AddRecordState {
    
    enum FailedType {
        
        enum Code: Int {
            case networkError = -330
            case bizError = -331
            case timeout = -332
            case blockedByPermission = -333
        }
        
        case fgDisable
        case invalidToken
        case noPermission(code: Int, msg: String?)
        case others(code: Int, msg: String?)
        
        var codeAndMsg: (code: Int?, msg: String?) {
            switch self {
            case .fgDisable:
                return (nil, "fgDisable")
            case .invalidToken:
                return (nil, "invalidToken")
            case .noPermission(let code, let msg):
                return (code, msg)
            case .others(let code, let msg):
                return (code, msg)
            }
        }
    }
    
    case none
    case loading
    case failed(type: FailedType)
    case loaded
}

class BTContainerAddRecordPlugin: BTContainerBasePlugin {
    
    weak var addRecordCardVC: BTController?
    
    private var request: DocsRequest<Any>? // 必须持有住，不然还没请求就自己释放了
    private var metaPrefecthTime: Date?
    private var metaPrefecthCallbackTime: Date?
    private var metaPrefecthCallbackParams: [String: Any]?
    private var getAddRecordContentTime: Date?
    private var metaCallback: ((_ params: [String: Any]) -> Void)?
    
    private static var metaTimeout: TimeInterval = 20
    private static var jsTimeout: TimeInterval = 10
    private var metaTimeoutTimer: Timer?
    
    private var hasReportedLoaded: Bool = false
    private var retryCount: Int = 0 // 重试加载的次数
    private var metaRetryCount: Int = -1 // meta 重试请求的次数
    
    private var addRecordState: AddRecordState = .none {
        didSet {
            DocsLogger.btInfo("[BTContainerAddRecordPlugin] addRecordState changed \(addRecordState)")
            if case .failed(let type) = addRecordState {
                BTOpenFileReportMonitor.reportOpenBaseAddRecordFail(traceId: openFileTraceId, retryCount: retryCount, code: type.codeAndMsg.code, msg: type.codeAndMsg.msg)
            } else if case .loaded = addRecordState, !hasReportedLoaded {
                hasReportedLoaded = true
                let fieldCount = addRecordCardVC?.viewModel.tableMeta.fields.count
                BTOpenFileReportMonitor.reportOpenBaseAddRecordTTV(traceId: openFileTraceId, fieldCount: fieldCount)
                BTOpenFileReportMonitor.reportOpenBaseAddRecordTTU(traceId: openFileTraceId, fieldCount: fieldCount)
            }
        }
    }
    
    deinit {
        self.request?.cancel()
        self.metaTimeoutTimer?.invalidate()
        self.request = nil
        self.metaTimeoutTimer = nil
    }
    
    override func load(service: BTContainerService) {
        super.load(service: service)
        
        if service.isAddRecord {
            if let browserViewController = service.browserViewController, let fileConfig = browserViewController.fileConfig {
                BTOpenFileReportMonitor.handleOpenBrowserView(vc: browserViewController, fileConfig: fileConfig)
            }
            
            // 容器开始加载就立即请求 meta，减少 meta 请求时间
            prefecthMeta()
        }
    }
    
    override func setupView(hostView: UIView) {
        super.setupView(hostView: hostView)
        
        guard let browser = service?.browserViewController else {
            return
        }
        browser.browserViewDidUpdateDocName(browser.editor, docName: BundleI18n.SKResource.Bitable_QuickAdd_AddNewRecord_Title)
    }
    
    // nolint: duplicated_code
    func showAddRecord(cardVC: BTController) {
        DocsLogger.info("BTContainerFormViewPlugin.showIndRecord")
        if case .failed(let type) = addRecordState, case .noPermission(_, _) = type {
            DocsLogger.error("showIndRecord noPermission")
            return
        }
        guard let service = service else {
            DocsLogger.error("showIndRecord invalid service")
            return
        }
        guard let parentVC = service.browserViewController else {
            DocsLogger.error("showIndRecord invalid parentVC")
            return
        }
        guard cardVC.parent == nil else {
            DocsLogger.error("cardVC has parent")
            return
        }
        self.addRecordCardVC = cardVC
        
        cardVC.view.removeFromSuperview()
        
        parentVC.addChild(cardVC)
        parentVC.view.addSubview(cardVC.view)
        cardVC.didMove(toParent: parentVC)
        cardVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        service.setIndRecordShow(indRecordShow: true)
        addRecordState = .loaded
    }
    
    func closeAddRecord() {
        DocsLogger.btInfo("[BTContainerAddRecordPlugin] closeAddRecord")
        guard let addRecordCardVC = addRecordCardVC else {
            DocsLogger.btInfo("[BTContainerAddRecordPlugin] closeAddRecord but nil")
            return
        }
        addRecordCardVC.willMove(toParent: nil)
        addRecordCardVC.removeSelfFromParentVC()
        addRecordCardVC.view.removeFromSuperview()
        addRecordCardVC.didMove(toParent: nil)
        self.addRecordCardVC = nil
        
        service?.setIndRecordShow(indRecordShow: false)
    }
    
    
    func addRecordResult(actionTask: BTCardActionTask, baseContext: BaseContext) {
        DocsLogger.info("addRecordResult")
        guard let addRecordCardVC = addRecordCardVC else {
            DocsLogger.error("addRecordCardVC is nil")
            return
        }
        guard let result = actionTask.actionParams.data.addRecordResult else {
            DocsLogger.error("addRecordData is nil")
            return
        }
        DocsLogger.btInfo("[BTContainerAddRecordPlugin] addRecordResult \(actionTask.actionParams.data.addRecordResult?.description ?? "nil")")
        addRecordCardVC.handleBaseAddSubmitResult(result)
        
    }
    
    private func prefecthMeta() {
        DocsLogger.btInfo("prefecthMeta")
        guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
            let empty = UDEmpty(config: .init(description: .init(descriptionText: BundleI18n.SKResource.Bitable_QuickAdd_FunctionOnItsWay_Desc), type: .upgraded))
            
            service?.loadingPlugin.hideAllSkeleton(from: "base-add-fg-disbale")
            service?.loadingPlugin.showEmptyView(empty: empty)
            addRecordState = .failed(type: .fgDisable)
            return
        }
        guard let token = service?.browserViewController?.docsInfo?.token else {
            DocsLogger.error("invalid token")
            // TODO: zhangyushang 这里要显示报错页
            addRecordState = .failed(type: .invalidToken)
            return
        }
        metaRetryCount += 1
        DocsLogger.info("fetch bitable add record meta start. metaRetryCount:\(metaRetryCount)")
        addRecordState = .loading
        self.metaPrefecthTime = Date()
        BTOpenFileReportMonitor.reportBaseAddRecordMetaStart(traceId: openFileTraceId, retryCount: metaRetryCount)
        let path = OpenAPI.APIPath.getBaseAddRecordMeta(token)
        let request = DocsRequest<Any>(path: path, params: nil)
            .set(method: .GET)
            .set(timeout: BTContainerAddRecordPlugin.metaTimeout)
        self.request = request
        request.start { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            self.metaTimeoutTimer?.invalidate()
            self.metaTimeoutTimer = nil
            self.request = nil
            var params: [String: Any] = [:]
            if let data = data, let result = String(data: data, encoding: .utf8) {
                params["data"] = result
                DocsLogger.info("fetch bitable add record meta success")
                self.prefecthMetaResponse(params: params)
            } else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.error("fetch bitable add record meta failed: \(error)")
                params["error"] = error.localizedDescription
                self.prefecthMetaResponse(params: params, response: response, error: error)
            }
        }
        
        // DocsRequest 的超时有问题，这里自己做个超时
        let timer = Timer(
            timeInterval: BTContainerAddRecordPlugin.metaTimeout,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else {
                    return
                }
                DocsLogger.btError("prefecthMeta timeout")
                self.request?.cancel()
                self.request = nil
                self.metaTimeoutTimer = nil
                self.prefecthMetaResponse(params: [
                    "error": "timeout",
                    "code": AddRecordState.FailedType.Code.timeout.rawValue
                ])
            })
        RunLoop.main.add(timer, forMode: .common)
        metaTimeoutTimer = timer
    }
    
    /// 检查文件访问控制权限
    private func checkPermission(baseToken: String?) -> Bool {
        guard let baseToken = baseToken else {
            return true
        }
        if let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) {
            let request = PermissionRequest(token: baseToken, type: .bitable, operation: .view, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            DocsLogger.btInfo("PermissionRequest response \(response)")
            if case .forbidden(let denyType, _) = response.result {
                self.showNoPermission(baseToken: baseToken, code: AddRecordState.FailedType.Code.blockedByPermission.rawValue, msg: "blocked by Permission \(denyType)")
                return false
            }
        }
        return true
    }
    
    private func showNoPermission(baseToken: String?, code: Int, msg: String?) {
        // record meta 接口成功，用户没有添加权限，拦截掉数据端上处理
        DocsLogger.error("fetch bitable add record meta failed, no perm")
        var handler: (String, (UIButton) -> Void)?
        if let baseToken = baseToken, !baseToken.isEmpty, let browser = service?.browserViewController {
            handler = (BundleI18n.SKResource.Bitable_ShareSingleRecord_ViewTable_Button, { [weak browser] _ in
                guard let browser = browser else {
                    return
                }
                DocsLogger.btInfo("[BTContainerAddRecordPlugin] view table")
                let url = DocsUrlUtil
                    .url(type: .bitable, token: baseToken)
                    .docs
                    .addOrChangeEncodeQuery(
                        parameters: [
                            CCMOpenTypeKey: "record_upgrade_warning"
                        ]
                    )
                Navigator.shared.push(url, from: browser)
                
                var trackParams: [String: String] = [:]
                if let docsInfo = browser.docsInfo {
                    trackParams = DocsParametersUtil.createCommonParams(by: docsInfo)
                }
                trackParams["click"] = "open_table"
                trackParams["target"] = "none"
                DocsTracker.newLog(enumEvent: .bitableNoPermissionAddRecordClick, parameters: trackParams)
            })
        }
        metaPrefecthCallbackParams = nil
        let empty = UDEmpty(
            config: .init(
                description: .init(descriptionText: BundleI18n.SKResource.Bitable_QuickAdd_NoRecordAccess_Desc),
                type: .noAccess,
                primaryButtonConfig: handler
            )
        )
        service?.loadingPlugin.hideAllSkeleton(from: "base-add-record-no-perm")
        service?.loadingPlugin.showEmptyView(empty: empty)
        addRecordState = .failed(type: .noPermission(code: code, msg: msg))
        
        var trackParams: [String: String] = [:]
        if let docsInfo = self.service?.browserViewController?.docsInfo {
            trackParams = DocsParametersUtil.createCommonParams(by: docsInfo)
        }
        DocsTracker.newLog(enumEvent: .bitableNoPermissionAddRecordView, parameters: trackParams)
    }
    
    private func getLoadFailedTipsFromSettings(code: Int) -> String? {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            guard let base_add = settings["base_add"] as? [String: Any] else {
                return nil
            }
            guard let config = base_add["load_failed_tips"] as? [String: String] else {
                return nil
            }
            return config[String(code)]
        } catch {
            DocsLogger.btError("getSubmitFailedTipsFromSettings faild: \(error)")
        }
        return nil
    }
    
    private func prefecthMetaResponse(params: [String: Any], response: URLResponse? = nil, error: Error? = nil) {
        let responseStr = params["data"] as? String
        let responseJson = JSON(parseJSON: responseStr ?? "")
        let code = responseJson["code"].int
        let msg = responseJson["msg"].string
        let metaStr = responseJson["data"]["meta"].stringValue
        let metaJson = JSON(parseJSON: metaStr)
        let addable = metaJson["recordPerm"]["addable"].bool
        var costTime: Int?
        if let metaPrefecthTime = metaPrefecthTime {
            costTime = Int(Date().timeIntervalSince(metaPrefecthTime) * 1000)
        }
        let finalCode: Int
        if let errorMsg = params["error"] {
            finalCode = response?.statusCode ?? (params["code"] as? Int) ?? AddRecordState.FailedType.Code.networkError.rawValue
            BTOpenFileReportMonitor.reportBaseAddRecordMetaFail(
                traceId: openFileTraceId,
                costTime: costTime,
                retryCount: metaRetryCount,
                code: finalCode,
                msg: errorMsg as? String
            )
        } else {
            finalCode = code ?? AddRecordState.FailedType.Code.bizError.rawValue
            BTOpenFileReportMonitor.reportBaseAddRecordMetaSuccess(
                traceId: openFileTraceId,
                costTime: costTime,
                dataSize: responseStr?.count,
                retryCount: metaRetryCount,
                code: finalCode,
                msg: msg
            )
        }
        DocsLogger.btInfo("[BTContainerAddRecordPlugin] prefecthMetaResponse code:\(finalCode) msg:\(String(describing: msg)) addable:\(String(describing: addable))")
        guard let code = code, code == 0, let addable = addable else {
            // record meta 接口失败了，直接 Native 报错
            let msg = msg ?? error?.localizedDescription
            DocsLogger.error("fetch bitable add record meta failed, code: \(finalCode)")
            let tableNotFoundCode = 800004000
            let isTableNotFount = (code == tableNotFoundCode)
            let descText: String
            let emptyType: UDEmptyType
            if let code = code, let tips = getLoadFailedTipsFromSettings(code: code) {
                emptyType = .loadingFailure
                descText = tips
            } else if isTableNotFount {
                emptyType = .noContent
                descText = BundleI18n.SKResource.Bitable_QuickAdd_TableDeleted_Toast
            } else {
                emptyType = .loadingFailure
                descText = BundleI18n.SKResource.Bitable_ShareSingleRecord_FailedToLoadData_Desc
            }
            let primaryButtonConfig: (String, (UIButton) -> Void)? = (BundleI18n.SKResource.Bitable_Common_ButtonRetry, { [weak self] _ in
                guard let self = self else { return }
                DocsLogger.btInfo("[BTContainerAddRecordPlugin] retry")
                self.service?.loadingPlugin.showSkeletonLoading(from: "base-add-record-error-retry", loadingType: .main)
                self.service?.loadingPlugin.hideEmptyView()
                retryCount += 1
                self.prefecthMeta()
                self.service?.browserViewController?.editor.docsLoader?.reload()
            })
            let empty = UDEmpty(
                config: .init(
                    description: .init(descriptionText: descText),
                    type: emptyType,
                    primaryButtonConfig: isTableNotFount ? nil : primaryButtonConfig
                )
            )
            service?.loadingPlugin.hideAllSkeleton(from: "base-add-record-error")
            service?.loadingPlugin.showEmptyView(empty: empty)
            addRecordState = .failed(type: .others(code: finalCode, msg: msg))
            return
        }
        let baseToken = metaJson["baseToken"].string
        guard addable else {
            showNoPermission(baseToken: baseToken, code: finalCode, msg: msg)
            return
        }
        guard checkPermission(baseToken: baseToken) else {
            return
        }
        // record meta 接口成功，用户有添加权限，透传数据给前端
        handlePrefetchMetaData(params: params)
        // 数据已经下发，开始等待前端执行完成
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.jsTimeout) { [weak self] in
            guard let self = self else {
                return
            }
            if case .loaded = self.addRecordState {
                // 加载完成
            } else {
                DocsLogger.btError("js load timeout")
            }
        }
    }
    
    func handleBack() {
        if case .failed(let type) = addRecordState {
            if case .noPermission = type {
                var trackParams: [String: String] = [:]
                if let docsInfo = self.service?.browserViewController?.docsInfo {
                    trackParams = DocsParametersUtil.createCommonParams(by: docsInfo)
                }
                trackParams["click"] = "back"
                trackParams["target"] = "none"
                DocsTracker.newLog(enumEvent: .bitableNoPermissionAddRecordClick, parameters: trackParams)
            }
        }
    }
    
    private func handlePrefetchMetaData(params: [String: Any]) {
        self.metaPrefecthCallbackParams = params
        self.metaPrefecthCallbackTime = Date()
        if let metaCallback = self.metaCallback {
            // 已经有绑定的 callback，直接返回
            DocsLogger.btInfo("[BTContainerAddRecordPlugin] metaCallback")
            metaCallback(params)
            BTOpenFileReportMonitor.reportBaseAddRecordReturnMeta(traceId: openFileTraceId)
            stastic()
            return
        } else {
            DocsLogger.btInfo("[BTContainerAddRecordPlugin] metaCallback nil")
        }
    }
    
    func getAddRecordContent(callback: @escaping (_ params: [String: Any]) -> Void) {
        BTOpenFileReportMonitor.reportBaseAddRecordGetMeta(traceId: openFileTraceId)
        self.getAddRecordContentTime = Date()
        if let metaPrefecthCallbackParams = self.metaPrefecthCallbackParams {
            // 已经有预加载的数据，直接返回
            DocsLogger.btInfo("[BTContainerAddRecordPlugin] metaCallback")
            callback(metaPrefecthCallbackParams)
            BTOpenFileReportMonitor.reportBaseAddRecordReturnMeta(traceId: openFileTraceId)
            stastic()
            return
        }
        DocsLogger.btInfo("[BTContainerAddRecordPlugin] waiting meta")
        // 数据尚未返回，先等等
        self.metaCallback = callback
    }
    
    private func stastic() {
        guard let metaPrefecthTime = self.metaPrefecthTime else {
            return
        }
        guard let getAddRecordContentTime = self.getAddRecordContentTime else {
            return
        }
        guard let metaPrefecthCallbackTime = self.metaPrefecthCallbackTime else {
            return
        }
        let now = Date()
        let getAddRecordContentCost = Int(now.timeIntervalSince(getAddRecordContentTime) * 1000)
        let metaPrefecthCost = Int(metaPrefecthCallbackTime.timeIntervalSince(metaPrefecthTime) * 1000)
        DocsLogger.info("getAddRecordContentCost:\(getAddRecordContentCost)ms, metaPrefecthCost:\(metaPrefecthCost)ms")
    }
}
