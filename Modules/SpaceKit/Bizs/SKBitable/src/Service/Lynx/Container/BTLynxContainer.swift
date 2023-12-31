//
//  BTLynxContainerProvider.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import LarkModel
import Lynx
import LarkLynxKit
import UniverseDesignTheme
import LarkContainer
import LarkSetting
import LarkStorage
import SKFoundation
import SKResource

let ImageFetcherErrorDomain = "BTLynxImageFetcher"
let ImageFetcherErrorcode = -1

/// Lynx Image加载注入对象
@objcMembers
final class BTLynxImageFetcher: NSObject, LynxImageFetcher {

    /// Load image asynchronously.
    /// - Parameters:
    ///   - url: ui that fires the request.
    ///   - targetSize: the target screen size for showing the image. It is more efficient that UIImage with the same size is returned.
    ///   - contextInfo: extra info needed for image request.
    ///   - completionBlock: the block to provide image fetcher result.
    /// - Returns: A block which can cancel the image request if it is not finished. nil if cancel action is not supported.
    func loadImage(
        with url: URL,
        size targetSize: CGSize,
        contextInfo: [AnyHashable : Any]?,
        completion completionBlock: @escaping LynxImageLoadCompletionBlock
    ) -> () -> Void {
        let absString = url.absoluteString
        if let image = UIImage.docs.image(base64: absString, scale: 1) {
            DispatchQueue.main.async {
                completionBlock(image, nil, url)
            }
        } else {
            DispatchQueue.main.async {
                let msg = "image create error with string:\(absString)"
                DispatchQueue.main.async {
                    completionBlock(nil, imageFetcherError(with: msg), nil)
                }
                DocsLogger.btError(msg)
            }
        }
        return {}
    }
}

/// 下载Lynx UIImage
/// - Parameter msg: 错误信息
private func imageFetcherError(with msg: String) -> Error {
    NSError(
        domain: ImageFetcherErrorDomain,
        code: ImageFetcherErrorcode,
        userInfo: [
            NSLocalizedDescriptionKey: msg
        ]
    )
}

extension LarkLynxContainerProtocol {
    func reload(data: [AnyHashable: Any]) {
        if let lynxView = self.getLynxView() as? LynxView,
            let lynxTemData = LynxTemplateData(dictionary: data){
            lynxView.reloadTemplate(with: lynxTemData)
        } else {
            update(data: data)
        }
    }
}


public final class BTLynxContainer: NSObject {
    
    static let Tag = "LarkBitableForChart"
    static let imageFetcher = BTLynxImageFetcher()
    
    // template.js 封装结构, 数据 + 版号
    typealias SDKTemplate = (data: Data, version: String)
    typealias SDKTemplateStandalone = (data: LynxTemplateBundle, version: String)
    static private var _template: SDKTemplate?
    
    static private var template: SDKTemplate? = {
        if _template == nil {
            registerAll()
            loadTemplate()
        }
        return _template
    }()
    
    static private func loadTemplate(){
        
        let path = I18n.resourceBundle.path(forResource: "template", ofType: "js") ?? ""
        let jsPathAbs = AbsPath(path)
        
        guard let data = try? Data.read(from: jsPathAbs)  else {
            assertionFailure("BTLynxContainer load template data fail")
            return
        }
//        let version = BDPVersionManagerV2.localLibVersionString(.sdkMsgCard)
        let version = "?.?.?"
        _template = (data, version)
    }

    var containerData: BTLynxContainer.ContainerData
    var lifeCycleClient: BTLynxContainerLifeCycle?
    private var lynxContainer: LarkLynxContainerProtocol?
    
    public var view: LynxView? { lynxContainer?.getLynxView() as? LynxView }

    @Injected private var containerEnvService: BTLynxContainerEnvService

    init(
        containerData: ContainerData,
        lifeCycleClient: BTLynxContainerLifeCycle?
    ) {
        self.containerData = containerData
        self.lifeCycleClient = lifeCycleClient
        super.init()
        setup()
    }
    
    private func setup() {
        didStartSetup()
        
        //注册是否主题色变更，主动通知重新绘制
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(envUpdate), name: UDThemeManager.didChangeNotification, object: nil)
        }
        
        LarkLynxInitializer.shared.registerGlobalData(
            tag: Self.Tag,
            globalData: containerEnvService.env.toDictionary()
        )
        didFinishSetup()
    }

    //更新env数据，避免外部变化感知不到（字体大小，时区等）
    public func updateEnvData() {
        self.view?.updateGlobalProps(with:containerEnvService.env.toDictionary())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func envUpdate() {
        LarkLynxInitializer.shared.registerGlobalData(
            tag: Self.Tag,
            globalData: containerEnvService.env.toDictionary()
        )
        DispatchQueue.main.async { self.render() }
    }

    // 创建view
    public func createView() -> LynxView {
        if lynxContainer == nil {
            guard let _ = Self.template else {
                didReceiveError(error: .internalError("render fail: wrong template"))
                assertionFailure("BTLynxContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                return LynxView()
            }
            lynxContainer = createOPLynxBuilder().build()
        }

        guard let view = lynxContainer?.getLynxView() as? LynxView else {
            DocsLogger.btError("container create view failed")
            return LynxView()
        }
        return view
    }

    //绘制刷新
    public func renderView(_ containerData: BTLynxContainer.ContainerData) {
        updateData(containerData)
        didStartRender()
    
        let initData = containerData.contextData.bizContext
        if let lynxContainer = self.lynxContainer {
            if !lynxContainer.hasRendered() {
                guard let template = Self.template else {
                    didReceiveError(error: .internalError("render fail: wrong template"))
                    assertionFailure("BTLynxContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                    return
                }
#if ALPHA || DEBUG
                if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                    lynxContainer.render(templateUrl: debugUrl, initData: initData)
                } else {
                    lynxContainer.render(
                        template: template.data,
                        initData: initData
                    )
                }
#else
                lynxContainer.render(
                    template: template.data,
                    initData: initData
                )
#endif
            } else if lynxContainer.hasLayout() && !lynxContainer.hasRendered() {
                lynxContainer.processRender()
            } else {
                let layout = Self.opLynxLayoutConfig(fromConfig: containerData.config)
                lynxContainer.updateLayoutIfNeeded(sizeConfig: layout)
                lynxContainer.reload(data: initData)
                view?.setNeedsLayout()
            }
        }
    }
    
    //绘制刷新
    public func updateRenderWithScene(scene: String) {
        var initData = containerData.contextData.bizContext
        initData["scene"] = scene
        self.lynxContainer?.update(data: initData)
    }
    
    private  func render() {
        let initData = containerData.contextData.bizContext
        if lynxContainer == nil {
            guard let template = Self.template else {
                didReceiveError(error: .internalError("render fail: wrong template"))
                assertionFailure("BTLynxContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                return
            }
            didStartRender()
            lynxContainer = createOPLynxBuilder().build()
            #if ALPHA || DEBUG
            if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                lynxContainer?.render(templateUrl: debugUrl, initData: initData)
            } else {
                lynxContainer?.render(
                    template: template.data,
                    initData: initData
                )
            }
            #else
            lynxContainer?.render(
                template: template.data,
                initData: initData
            )
            #endif
        } else {
            let layout = Self.opLynxLayoutConfig(fromConfig: containerData.config)
            lynxContainer?.updateLayoutIfNeeded(sizeConfig: layout)
            lynxContainer?.reload(data: initData)
            view?.setNeedsLayout()
        }
    }
    
    public func updateLayoutIfNeeded(config: Config) {
        let layout = Self.opLynxLayoutConfig(fromConfig: config)
        lynxContainer?.updateLayoutIfNeeded(sizeConfig: layout)
    }

    public func updateData(_ containerData: BTLynxContainer.ContainerData) {
        self.containerData = containerData
        (self.lynxContainer?.getLynxView() as? LynxView)?.bitableChartToken = containerData.contextData.bizContext["chartToken"] as? String
    }

    private func createOPLynxBuilder() -> LarkLynxContainerBuilder {
        let layout = Self.opLynxLayoutConfig(fromConfig: containerData.config)
        let context = Self.opLynxContext(containerCata: containerData)
        return LarkLynxContainerBuilder()
            .setupContext(context: context)
            .tagForCustomComponent(tag: Self.Tag)
            .tagForBridgeMethodDispatcher(tag: Self.Tag)
            .tagForGlobalData(tag: Self.Tag)
            .tagForLynxGroup(tag: Self.Tag)
            .lynxViewSizeConfig(sizeConfig: layout)
            .lynxViewLifeCycle(lynxViewLifeCycle: self)
            .lynxViewImageLoader(imageFetcher: Self.imageFetcher)
    }
    
    // 构造 OPLynxContainer 需要的上下文
    static func opLynxContext(
        containerCata: ContainerData
    ) -> LynxContainerContext {
        return LynxContainerContext(
            containerType: Self.Tag,
            bizExtra: ["bizContext": containerCata.contextData.bizContext]
        )
    }
}



public enum BTLynxContainerError: Error {
    // Lynx 在渲染过程中发生错误
    case lynxRenderFail(Error?)
    // Lynx 在加载过程中发生错误
    case lynxLoadFail(Error?)
    // 内部意外异常
    case internalError(String?)
        
    public var errorCode: Int {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError else { return -1 }
            return error.code
        case .internalError(_):
            return -1
        }
    }
    
    public var errorType: String {
        switch(self) {
        case .lynxRenderFail(_):
            return "LynxRenderFail"
        case .lynxLoadFail(_):
            return "LynxLoadFail"
        case .internalError(_):
            return "InternalError"
        }
    }
    
    public var domain: String {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError else { return "" }
            return error.domain
        case .internalError(_):
            return "com.ccm.base"
        }
    }
    
    public var errorMessage: String {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError,
                  let messageInfo = error.userInfo["message"] else {
                return "\(self)"
            }
            return "\(messageInfo)"
        case .internalError(let msg):
            return "internal error: \(msg ?? "unknown")"
        }
       
    }
}

private var dataProviderKey: Void?
private var downloadTaskKey: Void?

extension BTLynxContainer {
    
    // 数据更新
    var dataProvider: BitableSliceDataProvider? {
        get {
            return objc_getAssociatedObject(self, &dataProviderKey) as? BitableSliceDataProvider
        }
        set {
            objc_setAssociatedObject(self, &dataProviderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var downloadTask: BitableSliceDownloadTask? {
        get {
            return objc_getAssociatedObject(self, &downloadTaskKey) as? BitableSliceDownloadTask
        }
        set {
            objc_setAssociatedObject(self, &downloadTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func asyncLoadWithChart(_ chart: Chart, size:CGSize) -> Bool {
        if let currentTask = downloadTask {
            currentTask.canceled = true
        }
        guard let lynxView = self.lynxContainer?.getLynxView() as? LynxView else {
            DocsLogger.btError("can't find lynxView, render fail")
            return false
        }
        guard let chartToken = chart.token,
                let baseToken = chart.baseToken,
              let dashboardToken = chart.dashboardToken else {
            lynxView.isHidden = true
            lynxView.bitableChartStatusView?.updateViewWithStatus(.fail, detail: "token is nil")
            DocsLogger.btError("token exception with chart: \(chart)")
            return false
        }
        guard let dataProvider = self.dataProvider else {
            lynxView.isHidden = true
            lynxView.bitableChartStatusView?.updateViewWithStatus(.fail, detail: "data provider is nil")
            DocsLogger.btError("dataProvider is nil")
            return false
        }
        
//        //一进来先尝试render一份空数据，让 lynx 前端用缓存数据更新页面，提升体验
//        let bizContext = [
//            "chartToken": chartToken,
//            "baseToken": baseToken,
//            "dashboardToken": dashboardToken,
//            "isTemplate": chart.isTemplate,
//            "status": chart.status ?? 0,
//            "scene": chart.scene.rawValue,
//            "chartData": ""
//        ] as [String : Any]
//        let contextData = BTLynxContainer.ContextData(bizContext: bizContext)
//        let config = BTLynxContainer.Config(perferWidth: size.width, perferHeight:size.height, maxHeight: size.height)
//        let containerData = BTLynxContainer.ContainerData(contextData: contextData,
//                                                          config:config)
//        self.renderView(containerData)
        
        downloadTask = dataProvider.retrieveSliceData(token: chartToken, with: {[weak self] slice, _ in
            if let slice = slice {
                let bizContext = [
                    "chartToken": chartToken,
                    "baseToken": baseToken,
                    "dashboardToken": dashboardToken,
                    "isTemplate": chart.isTemplate,
                    "status": chart.status ?? 0,
                    "scene": chart.scene.rawValue,
                    "chartData": slice.toJSONString() ?? ""
                ]
                let contextData = BTLynxContainer.ContextData(bizContext: bizContext)
                let config = BTLynxContainer.Config(perferWidth: size.width, perferHeight:size.height, maxHeight: size.height)
                let containerData = BTLynxContainer.ContainerData(contextData: contextData,
                                                                  config:config)
                //lynxView 在 hideLoading 的时候能更新lynxView 和 status的状态。因此不需要在这里操作
                self?.renderView(containerData)
            } else {
                lynxView.isHidden = true
                lynxView.bitableChartStatusView?.updateViewWithStatus(.fail, detail: "retrieve return unexcepted result")
                // slice数据未能成功获取
                DocsLogger.btError("lynx container failed to fetch data of chart \(chartToken.encryptToShort)")
            }
        })
        return downloadTask == nil
    }
    
    func cancelAsyncLoad() {
        downloadTask?.canceled = true
    }
}

protocol BitableSliceDataProvider: AnyObject {
    func retrieveSliceData(token: String, with completion: @escaping (chartLynxData?, Error?) -> Void) -> BitableSliceDownloadTask?
    func retrieveSliceDataFromCache(_ token: String) -> chartLynxData?
}

final class BitableSliceDownloadTask {
    // flag
    var canceled: Bool = false
    
    // initial property
    let token: String
    
    let downloadFinished: (chartLynxData?, Error?)->Void
    
    let completion: (chartLynxData?, Error?)->Void
    
    init(token: String, downloadFinished: @escaping (chartLynxData?, Error?)->Void, completion: @escaping (chartLynxData?, Error?)->Void) {
        self.token = token
        self.downloadFinished = downloadFinished
        self.completion = completion
    }
    
    func resume() {
        ChartRequest.requestChartSlice(ChartSliceRequestParam(chartToken: token)) { slice, err in
            self.downloadFinished(slice, err)
        }
    }
}

final class BitableSliceManager: BitableSliceDataProvider {
    private let cache = MemoryCache()
    private var tasks: [String: [BitableSliceDownloadTask] ] = [:]
    private let lock: NSLock = NSLock()
    
    func retrieveSliceData(token: String, with completion: @escaping (chartLynxData?, Error?) -> Void) -> BitableSliceDownloadTask? {
        if let cacheValue = cache.retrieveValue(forKey: token) {
            completion(cacheValue, nil)
        }
        
        let task = BitableSliceDownloadTask(token: token) { slice, err in
            self.lock.lock()
            if let taskArray = self.tasks[token], taskArray.count > 0 {
                taskArray.forEach { task in
                    if !task.canceled {
                        task.completion(slice, err)
                    }
                }
                self.tasks[token] = []
            }
            
            if err == nil, let slice = slice {
                self.cache.store(value: slice, forKey: token)
            }
            self.lock.unlock()
        } completion: { slice, err in
            //判断返回的 slice 是不是和缓存的一样，如果是一样的就不需要callback
            guard let slice = slice else {
                completion(slice, err)
                return
            }
            if let cachedValue = self.cache.retrieveValue(forKey: token) {
                if (slice as NSDictionary).isEqual(cachedValue) {
                    DocsLogger.btInfo("slice data is equal to cachedValue, don't update UI")
                } else {
                    completion(slice, err)
                }
            } else {
                completion(slice, err)
            }
        }

        lock.lock()
        if var taskArray = tasks[token], taskArray.count > 0 {
            taskArray.append(task)
        } else {
            tasks[token] = [task]
            task.resume()
        }
        lock.unlock()
        return task
    }
    
    func retrieveSliceDataFromCache(_ token: String) -> chartLynxData? {
        if let cacheValue = cache.retrieveValue(forKey: token) {
            return cacheValue
        }
        return nil
    }
}

class MemoryCache {
    // 不涉及回收 不使用NSCache类型
    private var cache: [String: chartLynxData] = [:]
    
    func store(value: chartLynxData, forKey key: String) {
        cache[key] = value
    }
    
    func retrieveValue(forKey key: String) -> chartLynxData? {
        return cache[key]
    }
    
    func removeValue(forKey key: String) {
        cache[key] = nil
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
