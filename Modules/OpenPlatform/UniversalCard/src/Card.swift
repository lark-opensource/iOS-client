//
//  Card.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/8.
//

import Foundation
import Swinject
import Lynx
import LarkLynxKit
import LarkContainer
import LKCommonsLogging
import UniversalCardInterface
import UniversalCardBase
import EEAtomic

public final class UniversalCard: UniversalCardProtocol {
    var resourceProvider = UniversalCardLynxResourceProvider()
    public static let Tag = UniversalCardTag
    public static let SetupContextKey = "UniversalCardSetupContextKey"
    public static let logger = Logger.log(UniversalCard.self, category: "UniversalCard")
    let tasmFinishSemaphore = DispatchSemaphore(value: 0)
    let layoutLock = NSLock()
    var isLayoutFinished = false
    // MARK: property: 常量

    fileprivate var cardEnvService: UniversalCardEnvironmentServiceProtocol?
    fileprivate var contextManager: UniversalCardContextManagerProtocol?
    fileprivate var moduleDependency: UniversalCardModuleDependencyProtocol?
    // lynx 容器
    private(set) var container: LarkLynxContainerProtocol
    // 卡片 view
    private var view: UIView { container.getLynxView() }
    // lynx 生命周期的处理器(用于处理 lynx 的生命周期)
    private let lynxLifeCycleClient: LynxLifeCycleClient = LynxLifeCycleClient()
    // lynx Bridge 包装类, 用于包装当前 context
    private let lynxBridgeContextWrapper: UniversalCardLynxBridgeContextWrapper = UniversalCardLynxBridgeContextWrapper()

    // MARK: property: 变量

    // 卡片布局配置
    private(set) var layout: UniversalCardLayoutConfig? = nil
    // 卡片源数据
    private(set) var cardSource: (
        data: UniversalCardData,
        context: UniversalCardContext,
        config: UniversalCardConfig
    )? = nil
    private(set) var env: UniversalCardEnvironment?

    // 卡片生命周期代理(外部处理卡片的生命值后期)
    private(set) weak var lifeCycleDelegate: UniversalCardLifeCycleDelegate? = nil
    
    @AtomicObject
    private var cacheRenderContextForTrace: [String: UniversalCardContext] = [:]

    private let resolver: UserResolver

    public init(resolver: UserResolver, renderThreadMode: UniversalCardRenderThreadMode) {
        self.resolver = resolver
        cardEnvService = try? resolver.resolve(assert: UniversalCardEnvironmentServiceProtocol.self)
        contextManager = try? resolver.resolve(assert: UniversalCardContextManagerProtocol.self)
        moduleDependency = try? resolver.resolve(assert: UniversalCardModuleDependencyProtocol.self)
        container = Self.createLynxBuilder(
            resolver: resolver,
            // 需要在构造前就设置好模式, 构造后更新没用, 会导致渲染尺寸不对. 目前固定为 exact, 不对外开放
            layout: LynxViewSizeConfig(layoutWidthMode: .exact, layoutHeightMode: .max, preferredMaxLayoutHeight: CGFloat.greatestFiniteMagnitude),
            wrapper: lynxBridgeContextWrapper,
            lifeCycleClient: lynxLifeCycleClient,
            renderThreadMode: renderThreadMode
        )
        .addLynxResourceProvider(lynxResourceProvider: self.resourceProvider)
        .build()
        lynxLifeCycleClient.card = self
    }

    // MARK: function: Public

    public static func create(resolver: UserResolver, renderMode: UniversalCardRenderThreadMode = .sync) -> UniversalCard { UniversalCard(resolver: resolver, renderThreadMode: renderMode) }

    public func getView() -> UIView { container.getLynxView() }

    public func getContentSize() -> CGSize { container.getContentSize() }

    public func updateLayout(layoutConfig: UniversalCardLayoutConfig) {
        container.updateLayoutIfNeeded(sizeConfig: Self.createLynxLayoutConfig(fromConfig: layoutConfig))
        cardSource?.config.displayConfig.preferWidth = layoutConfig.preferWidth
        cardSource?.config.displayConfig.preferHeight = layoutConfig.preferHeight
        (container.getLynxView() as? LynxView)?.triggerLayout()
    }
    
    public func updateMode(layoutConfig: UniversalCardLayoutConfig) {
        container.updateModeIfNeeded(sizeConfig: Self.createLynxLayoutConfig(fromConfig: layoutConfig))
    }

    public func render(
        layout: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        lifeCycle: UniversalCardLifeCycleDelegate?,
        force: Bool = false
    ) {

        // 全部数据相同, 不做更新
        if let current = cardSource, !force && self.layout == layout &&
            Self.isSameSource(left: current, right: source) && self.env == cardEnvService?.env {
            return
        }
        refreshCardEnv()
        updateCard(layout: layout, source: source, lifeCycle: lifeCycle)
        container.updateLayoutIfNeeded(sizeConfig: Self.createLynxLayoutConfig(fromConfig: layout))
        _render()
    }

    public func render() {
        refreshCardEnv()
        _render()
    }
    
    public func updateTraceContext(_ context: UniversalCardContext, forKey key: String?) {
        guard let key = key else {
            return
        }
        cacheRenderContextForTrace[key] = context
    }
    
    public func getTraceContext(forKey key: String) -> UniversalCardContext? {
        return cacheRenderContextForTrace[key]
    }
    
    public func removeTraceContext(forKey key: String) {
        cacheRenderContextForTrace.removeValue(forKey: key)
    }

    // MARK: function: Private

    private func refreshCardEnv() {
        guard self.env != cardEnvService?.env else { return }
        self.env = cardEnvService?.env
        guard let globalData = try? self.env.toDictionary() else {
            Self.logger.error("updateEnv fail: \(String(describing: cardEnvService?.env)) conver to dictionary fail")
            return
        }
        container.updateGlobalData(data: globalData)
    }

    private func updateCard(
        layout: UniversalCardLayoutConfig,
        source newSource: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        lifeCycle: UniversalCardLifeCycleDelegate?
    ) {
        if let key = cardSource?.context.key { contextManager?.removeContext(key: key) }
        contextManager?.setContext(key: newSource.context.key, context: newSource.context)
        self.cardSource = newSource
        self.cardSource?.context.updateSDKVersion(moduleDependency?.loadTemplate()?.version)
        self.layout = layout
        self.cardSource?.context.updateRenderingTrace()
        self.lifeCycleDelegate = lifeCycle
        self.lynxBridgeContextWrapper.cardContext = newSource.context
    }

    deinit {
        if let key = cardSource?.context.key { contextManager?.removeContext(key: key) }
    }
}
//TODO: 三个生命周期没放
//lifeCycleDelegate?.didStartSetup(context: context)
//lifeCycleDelegate?.didFinishSetup(context: context)

extension UniversalCard {

    public static func isSameSource(
        left: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        right: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)
    ) -> Bool {
        left.context.key == right.context.key &&
        left.data == right.data &&
        left.config == right.config
    }

    private func _render() {
        guard let template = moduleDependency?.loadTemplate() else {
            Self.logger.error("_render fail: loadTemplate fail")
            lifeCycleDelegate?.didReceiveError(context: cardSource?.context, error: .internalError("_render fail: loadTemplate fail"))
            return
        }
        guard let data = self.cardSource?.data, let config = self.cardSource?.config, let context = self.cardSource?.context,
              let lynxData = try? LynxData(cardData: data, cardConfig: config, cardContext: context).toDictionary() else {
            Self.logger.error("_render fail: cardSource invalid")
            lifeCycleDelegate?.didReceiveError(context: cardSource?.context, error: .internalError("_render fail: cardSource invalid"))
            return
        }

        lifeCycleDelegate?.didStartRender(context: context)
        updateTraceContext(
            context,
            forKey: (container.hasRendered() || container.hasLayout()) ? context.renderingTrace?.traceId : UniversalCard.SetupContextKey
        )
        // 判断 LynxView 是否第一次加载, 第一次的话执行 render
        if !container.hasLayout() && !container.hasRendered() {
            #if ALPHA || DEBUG
            if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                container.render(templateUrl: debugUrl, initData: lynxData)
            } else {
                container.render(template: template.data, initData: lynxData)
            }
            #else
            Self.logger.info("Universal card render", additionalData: ["traceID" : context.renderingTrace?.traceId ?? ""])
            container.render(template: template.data, initData: lynxData)
            #endif
            updateTraceContext(context, forKey: UniversalCard.SetupContextKey)
        } else if container.hasLayout() && !container.hasRendered() {
            Self.logger.info("Universal card processRender", additionalData: ["traceID" : context.renderingTrace?.traceId ?? ""])
            container.processRender()
        } else {
            Self.logger.info("Universal card render update", additionalData: ["traceID" : context.renderingTrace?.traceId ?? ""])
            container.update(data: lynxData)
            (container.getLynxView() as? LynxView)?.triggerLayout()
        }
        view.setNeedsLayout()
    }
}

extension UniversalCard {
    public func layout(
        layout: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        lifeCycle: UniversalCardLifeCycleDelegate?,
        force: Bool = false
    ) {
        layoutLock.lock(); defer { layoutLock.unlock() }
        // 全部数据相同, 不做更新
        if let current = cardSource, !force && self.layout == layout &&
            Self.isSameSource(left: current, right: source) && self.env == cardEnvService?.env {
            return
        }
        refreshCardEnv()
        updateCard(layout: layout, source: source, lifeCycle: lifeCycle)
        container.updateLayoutIfNeeded(sizeConfig: Self.createLynxLayoutConfig(fromConfig: layout))
        _layout()
    }

    public func _layout() {
        guard let template = moduleDependency?.loadTemplate() else {
            Self.logger.error("_render fail: loadTemplate fail")
            lifeCycleDelegate?.didReceiveError(context: cardSource?.context, error: .internalError("_render fail: loadTemplate fail"))
            return
        }
        guard let data = self.cardSource?.data, let config = self.cardSource?.config, let context = self.cardSource?.context,
              let lynxData = try? LynxData(cardData: data, cardConfig: config, cardContext: context).toDictionary() else {
            Self.logger.error("_render fail: cardSource invalid")
            lifeCycleDelegate?.didReceiveError(context: cardSource?.context, error: .internalError("_render fail: cardSource invalid"))
            return
        }
        lifeCycleDelegate?.didStartRender(context: context)
        updateTraceContext(
            context,
            forKey: (container.hasRendered() || container.hasLayout()) ? context.renderingTrace?.traceId : UniversalCard.SetupContextKey
        )
        // 主线程直接将算高标志位设为 true
        isLayoutFinished = Thread.isMainThread
        // 判断 LynxView 是否第一次加载, 第一次的话执行 render
        if !container.hasLayout() && !container.hasRendered() {
            #if ALPHA || DEBUG
            if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                container.processLayout(template: template.data, withURL: debugUrl, initData: lynxData)
            } else {
                container.processLayout(template: template.data, withURL: "", initData: lynxData)
            }
            #else
            Self.logger.info("Universal card processLayout", additionalData: ["traceID" : context.renderingTrace?.traceId ?? ""])
            container.processLayout(template: template.data, withURL: "", initData: lynxData)
            #endif// 非主线程才需要等待算高, 其他场景不用
            if !Thread.isMainThread { tasmFinishSemaphore.wait() }
        } else {
            Self.logger.info("Universal card layout update", additionalData: ["traceID" : context.renderingTrace?.traceId ?? ""])
            container.update(data: lynxData)
            // 非主线程才需要等待算高, 其他场景不用
            if !Thread.isMainThread { tasmFinishSemaphore.wait() }
            (container.getLynxView() as? LynxView)?.triggerLayout()
        }
    }
}
