//
//  CardView.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/6.
//

import UIKit
import Lynx
import SnapKit

/// tt.xxx封装的js文件名
private let ttSyntax = "bd_core"
/// js文件后缀
private let jsType = "js"
/// 未设置监听的msg
private let developHasNotSetListener = "develop has not set listener"
/// 卡片组ID
private var cardGroupID: UInt64 = 0

// MARK: Card Container
class CardView: UIView, CardViewProtocol {

    /// 渲染使用的LynxView
    private let lynxView: LynxView

    /// 生命周期中转对象( Lynx 1.4 改为弱引用，因此这里改为强引用，否则会被释放)
    private var lifecycleAdapter: CardLifecycleAdapter?

    /// Lynx使用的网络图片请求器（Lynx 弱引用这个对象）
    private let imageFetcher: CardImageFetcher

    /// 卡片JSBridge 引擎
    private var engine: CardEngine

    /// 应用的唯一复合ID
    private let uniqueID: BDPUniqueID

    /// 获取卡片应用对应的容器（不会自动进行下载渲染，请调用loadTemplate方法渲染在线卡片或者本地卡片，用于卡片测试或者渲染非应用纯卡片）
    /// - Parameter cardframe: frame
    init(cardframe: CGRect, uniqueID: BDPUniqueID) {
        setupLynxLog()
        self.uniqueID = uniqueID
        let cardEngine = CardEngine(uniqueID: uniqueID)
        engine = cardEngine
        lynxView = LynxView { (builder) in
            builder.isUIRunningMode = true
            let config = LynxConfig(provider: CardTemplateProvider())
            //  配置Lynx JSBridge
            config.register(CardAPIBridge.self, param: cardEngine)
            //  Tips: 目前必须要加上config（Lynx目前非常特化，不加这个就稳定crash，并且Lynx保证这几个版本修复这个问题）
            builder.config = config
            //  注册tt.相关语法，支持小程序开发者使用tt.xxx调用API（目前注入bd_core.js失效）
            let bdcorePath = (BDPBundle.mainBundle()?.path(forResource: ttSyntax, ofType: jsType) ?? "")
            if bdcorePath.isEmpty {
                //  异常情况，没找到ttSyntax对应的js文件
                BDPLogError(tag: .cardContainer, "not found \(ttSyntax).\(jsType)")
                assertionFailure("ttSyntax js is not founded, please contact gadget team")
            }
            //  卡片id，标注是否共享卡片jsruntime（Lynx强行规定必须要加上）"file://"前缀，否则无法调通js
            let group = LynxGroup(name: String(cardGroupID), withPreloadScript: ["file://"+bdcorePath])
            cardGroupID += 1
            builder.group = group
        }
        let imageFetcher = CardImageFetcher()
        self.imageFetcher = imageFetcher
        //  Lynx弱引用这个imageFetcher
        lynxView.imageFetcher = imageFetcher
        super.init(frame: cardframe)
        //  生成生命周期中转对象
        let lifecycleObj = CardLifecycleAdapter()
        lifecycleObj.cardView = self
        //  LynxView会强持有delegate，小心内存泄漏
        lynxView.addLifecycleClient(lifecycleObj)
        /// 配置lynx的尺寸约束信息
        lynxView.layoutWidthMode = .exact
        lynxView.preferredLayoutWidth = cardframe.width
        lifecycleAdapter = lifecycleObj
        addSubview(lynxView)
        lynxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        BDPLogInfo(tag: .cardRenderEngine, "card init with uniqueID: \(uniqueID)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        BDPLogInfo(tag: .cardRenderEngine, "card deinit with uniqueID: \(uniqueID)")
    }

    /// 布局刷新时，触发 Lynx 重新 Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        self.lynxView.preferredLayoutWidth = self.bounds.size.width
        self.lynxView.preferredLayoutHeight = self.bounds.size.height
        self.lynxView.triggerLayout()
    }

    /// 添加卡片生命周期监听（请业务方自己处理对象生命周期）
    /// - Parameter listener: 监听对象
    func setLifeCycleListener(_ listener: CardLifeCycleProtocol) {
        lifecycleAdapter?.lifeCycleListener = listener
    }

    /// 直接从 url 中下载卡片并加载
    /// - Parameter url: 在线template.js url
    func loadTemplate(from url: String) {
        lynxView.loadTemplate(fromURL: url)
    }

    /// 从 url 中下载卡片，并附带初始化数据
    /// - Parameters:
    ///   - url: 在线template.js url
    ///   - initData: 初始化数据 json
    func loadTemplate(
        with url: String,
        initData: String?
    ) {
        var lynxTemData: LynxTemplateData?
        if let initData = initData {
            lynxTemData = LynxTemplateData(json: initData)
        }
        lynxView.loadTemplate(fromURL: url, initData: lynxTemData)
    }

    /// 加载指定的本地卡片，并附上具有标识性的 url
    /// - Parameters:
    ///   - templateData: 本地template.js
    ///   - url: 具有标识性的 url
    func loadTemplate(
        with templateData: Data,
        url: String
    ) {
        lynxView.loadTemplate(templateData, withURL: url)
    }

    /// 加载指定的卡片并附带初始化数据和具有标示性的 url
    /// - Parameters:
    ///   - templateData: 本地template.js
    ///   - url: 具有标识性的 url
    ///   - initData: 初始化数据 json
    func loadTemplate(
        with templateData: Data,
        url: String,
        initData: String?
    ) {
        var lynxTemData: LynxTemplateData?
        if let initData = initData {
            lynxTemData = LynxTemplateData(json: initData)
        }
        lynxView.loadTemplate(templateData, withURL: url, initData: lynxTemData)
    }

    /// 更新卡片数据
    /// - Parameter data: 需要更新的数据，并且数据不需要预处理,数据格式为json
    func updateCard(with data: String?) {
        lynxView.updateData(with: data)
    }

    /// 更新卡片数据
    /// - Parameter data: map结构的数据
    func updateCard(with data: [String: Any]?) {
        lynxView.updateData(with: data)
    }

    /// 触发布局
    func triggerLayout() {
        lynxView.triggerLayout()
    }
    
    fileprivate func reportPerformance(perfData: [AnyHashable: Any]?, type: String) {
        // 增加统一性能监控
        OPMonitor("op_app_card_performance")
            .addMap(perfData as? [String: Any])
            .setUniqueID(uniqueID)
            .addCategoryValue("performance_type", type)
            .flush()
    }
}

// MARK: Card LifecycleAdapter
/// LynxView CardView 生命周期中转，接受LynxView的回调，回调卡片生命周期
@objcMembers
class CardLifecycleAdapter: NSObject {
    /// 卡片生命周期监听对象
    weak var lifeCycleListener: CardLifeCycleProtocol?
    /// 对应的卡片
    weak var cardView: CardView?

    /// 进行卡片和Lynx生命周期中转
    /// - Parameters:
    ///   - delegate: 卡片生命周期监听
    ///   - cardView: 卡片
    init(
        with delegate: CardLifeCycleProtocol? = nil,
        cardView: CardView? = nil
    ) {
        lifeCycleListener = delegate
        self.cardView = cardView
        super.init()
    }
}

// MARK: Lynx Lifecycle
extension CardLifecycleAdapter: LynxViewLifecycle {
    func lynxViewDidStartLoading(_ view: LynxView!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidStartLoading(cardView)
    }
    func lynxView(_ view: LynxView!, didLoadFinishedWithUrl url: String!) {
        if url == nil {
            BDPLogError(tag: .cardContainer, "lynxView didLoadFinishe but url is nil")
        }
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidFinishLoading(cardView, with: URL(string: url ?? ""))
    }
    func lynxViewDidFirstScreen(_ view: LynxView!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidLayoutFirstScreen(cardView)
    }
    func lynxViewDidConstructJSRuntime(_ view: LynxView!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidConstructJSRuntime(cardView)
    }
    func lynxViewDidUpdate(_ view: LynxView!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidUpdateData(cardView)
    }
    func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidChangeIntrinsicContentSize(cardView,
                                                                cardContentSize: view.intrinsicContentSize)
    }
    func lynxView(_ view: LynxView!, didLoadFailedWithUrl url: String!, error: Error!) {
        if url == nil {
            BDPLogError(tag: .cardContainer, "lynxView didLoadFailed but url is nil")
        }
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidLoadFailed(cardView, with: url ?? "", error: error)
    }
    func lynxView(_ view: LynxView!, didRecieveError error: Error!) {
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidRecieve(cardView, error: error)
    }
    func lynxView(_ view: LynxView!, didReceiveFirstLoadPerf perf: LynxPerformance!) {
        if perf == nil {
            BDPLogError(tag: .cardContainer, "lynxView didReceiveFirstLoadPerf but perf is nil")
        }
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidReceiveFirstLoadPerf(cardView, perf: perf?.toDictionary())
        
        // 统一性能监控埋点
        cardView.reportPerformance(perfData: perf?.toDictionary(), type: "first_load")
    }
    func lynxView(_ view: LynxView!, didReceiveUpdatePerf perf: LynxPerformance!) {
       if perf == nil {
            BDPLogError(tag: .cardContainer, "lynxView didReceiveUpdatePerf but perf is nil")
        }
        guard let (lifeCycleListener, cardView) = getLifeCycleObject(lifeCycleListener, cardView) else { return }
        lifeCycleListener.cardViewDidReceiveUpdatePerf(cardView, perf: perf?.toDictionary())
        
        // 统一性能监控埋点
        cardView.reportPerformance(perfData: perf?.toDictionary(), type: "update")
    }
    //  封装获取回调参数的方法，无参数打Log
    private func getLifeCycleObject(
        _ lifeCycleListener: CardLifeCycleProtocol?,
        _ cardView: CardView?
    ) -> (CardLifeCycleProtocol, CardView)? {
        guard let lifeCycleListener = lifeCycleListener,
            let cardView = cardView else {
                BDPLogInfo(tag: .cardLifeCycle, developHasNotSetListener)
                return nil
        }
        return (lifeCycleListener, cardView)
    }
}

/// 是否初始化Lynx Log系统
private var hasInjectLynxLog = false

/// 初始化Lynx Log系统
private func setupLynxLog() {
    if hasInjectLynxLog {
        return
    }
    LynxSetLogFunction { (level, msg) in
        let message = msg ?? ""
        switch level {
        case .error, .fatal, .report:
            BDPLogError(tag: .cardContainer, message)
        case .info:
            BDPLogDebug(tag: .cardContainer, message)
        case .warning:
            BDPLogWarn(tag: .cardContainer, message)
        @unknown default:
            assert(false, "unsupport，default use error level.")
            BDPLogError(tag: .cardContainer, message)
        }
    }
    hasInjectLynxLog = true
}
