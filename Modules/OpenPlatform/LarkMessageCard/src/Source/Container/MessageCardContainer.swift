//
//  MessageCardContainer.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/11/20.
//

import Foundation
import LarkModel
import Lynx
import ECOProbe
import LarkLynxKit
import UniverseDesignTheme
import LKCommonsLogging
// FIXME: 下一期改造
// 不应该引用
import TTMicroApp
import LarkContainer
import LarkSetting
import LarkStorage
import UniversalCard

public final class MessageCardContainer: NSObject {
    // template.js 封装结构, 数据 + 版号
    typealias SDKTemplate = (data: Data, version: String, extraTiming: [AnyHashable: Any])
    typealias SDKTemplateStandalone = (data: LynxTemplateBundle, version: String, extraTiming: [AnyHashable: Any])
    static private var _template: SDKTemplate?
    static private var _templateStandalone: SDKTemplateStandalone?
    
    static private var template: SDKTemplate? = {
        if _template == nil || BDPVersionManagerV2.compareVersion(BDPVersionManagerV2.localLibVersionString(.sdkMsgCard), with: _template?.version) == 1 {
            registerLynxExtension()
            loadTemplate()
        }
        return _template
    }()
    
    static private var templateStandalone: SDKTemplateStandalone? = {
        if _templateStandalone == nil {
            registerLynxExtension()
            loadTemplate()
        }
        return _templateStandalone
    }()
    
    static private func loadTemplate(){
        var extraTiming: [AnyHashable: Any] = [:]
        extraTiming["prepare_template_start"] = Int64(Date().timeIntervalSince1970 * 1000)
        // FIXME: 下一期改造
        // 改成依赖注入, 不直接引用 BDPVersionManagerV2
        var jsPath = BDPVersionManagerV2.latestVersionMsgCardSDKPath()
        let jsPathAbs = AbsPath(BDPVersionManagerV2.latestVersionMsgCardSDKPath())

        //debug和内测包都强制使用新解压的templateJS
        #if ALPHA || DEBUG
        let messageCardDebugIsOn = EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigMessageCardDebugTool)?.boolValue ?? false
        if messageCardDebugIsOn {
            try? LSFileSystem.main.removeItem(atPath: jsPath)
            jsPath = BDPVersionManagerV2.latestVersionMsgCardSDKPath()
        }
        #endif


        let version = BDPVersionManagerV2.localLibVersionString(.sdkMsgCard)
        
        guard let data = try? Data.read(from: jsPathAbs) else {
            assertionFailure("MessageCardContainer load template data fail")
            return
        }
        let bundle: LynxTemplateBundle? = LynxTemplateBundle(template: data)
        extraTiming["prepare_template_end"] = Int64(Date().timeIntervalSince1970 * 1000)
        _template = (data, version, extraTiming)
        if let bundle = bundle {
            _templateStandalone = (bundle, version, extraTiming)
        }
    }

    @FeatureGatingValue(key: "messagecard.renderoptimization.enable")
    var enableRenderOptimization: Bool
    
    @FeatureGatingValue(key: "openplatform.smartcard.decode_standalone")
    var decodeStandaloneEnable: Bool

    @FeatureGatingValue(key: "universalcard.forcetriggerlayout.enable")
    var forceTriggerLayout: Bool

    let logger = Logger.log(MessageCardContainer.self, category: "MessageCardContainer")
    public var identify: EquatableIdentify? = nil
    private var theme: String? = nil

    var cardID: String
    var version: String
    var localStatus: String
    var content: CardContent
    var config: Config
    var translateInfo: TranslateInfo
    var targetElement: [String: Any]?
    var trace: OPTrace { context.trace }
    var renderingTrace: OPTrace?
    public weak var lifeCycleClient: MessageCardContainerLifeCycle?

    private var cardData: CardData?
    private var translatedCardData: CardData?
    private var lynxContainer: LarkLynxContainerProtocol?
    
    public var view: LynxView? { lynxContainer?.getLynxView() as? LynxView }
    public var preferSize: CGSize?
    public var context: Context
    public var dependency: MessageCardContainerDependency? { context.dependency }

    private var resourceProvider = UniversalCardLynxResourceProvider()

    // FIXME: 发布前改造
    // Context 更新逻辑
    @Injected private var messageCardEnvService: MessageCardEnvService
    
    @Injected private var cardContextManager: MessageCardContextManagerProtocol

    init(
        cardID: String,
        version: String,
        content: CardContent,
        localStatus: String,
        config: Config,
        context: Context,
        lifeCycleClient: MessageCardContainerLifeCycle?,
        translateInfo: TranslateInfo,
        targetElement: [String: Any]? = nil
    ) {
        self.cardID = cardID
        self.version = version
        self.content = content
        self.localStatus = localStatus
        self.config = config
        self.context = context
        self.lifeCycleClient = lifeCycleClient
        self.translateInfo = translateInfo
        self.targetElement = targetElement
        super.init()
        setup()
    }
    
    private func setup() {
        setupCardData()
        registerContext()
        
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(envUpdate), name: UDThemeManager.didChangeNotification, object: nil)
        }
        
        // FIXME: 发布前改造
        // Context 更新逻辑
        LarkLynxInitializer.shared.registerGlobalData(
            tag: Self.Tag,
            globalData: messageCardEnvService.env.toDictionary()
        )
    }

    //更新env数据，避免外部变化感知不到（字体大小，时区等）
    public func updateEnvData() {
        self.view?.setGlobalPropsWith(messageCardEnvService.env.toDictionary())
    }

    private func registerContext() {
        cardContextManager.setContext(key: context.key, context: context)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cardContextManager.removeContext(key: context.key)
    }
    
    @objc func envUpdate() {
        // FIXME: 下一期改造
        // Context 更新逻辑
        if enableRenderOptimization {
            updateEnvData()
        } else {
            LarkLynxInitializer.shared.registerGlobalData(
                tag: "MessageCard",
                globalData: messageCardEnvService.env.toDictionary()
            )
        }
        DispatchQueue.main.async { self.render() }
    }

    // 创建view
    public func createView() -> LynxView {
        if lynxContainer == nil {
            guard let template = Self.template else {
                didReceiveError(error: .internalError("render fail: wrong template"))
                assertionFailure("MessageCardContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                return LynxView()
            }
            context.updateSDKVersion(template.version)
            lynxContainer = createOPLynxBuilder().build()
        }

        guard let view = lynxContainer?.getLynxView() as? LynxView else {
            logger.error("container create view failed")
            return LynxView()
        }
        return view
    }

    //绘制刷新
    public func renderView(_ cardContainerData: MessageCardContainer.ContainerData,
                           identify: EquatableIdentify?,
                           forceRender: Bool = false) {
        let needRenderFlag = needRender(identify)
        guard needRenderFlag || forceRender else { return }
        updateData(cardContainerData)
        guard let cardDataOrignal = cardData else {
            didReceiveError(error: .internalError("render fail: wrong card data"))
            assertionFailure("MessageCardContainer render with wrong data ")
            return
        }
        didStartRender()
        logger.info("render translateInfo: \(cardDataOrignal.translateInfo))", additionalData: [
            "MessageID": (context.getBizContext(key: "message") as? Message)?.id ?? "",
            "traceId": trace.traceId
        ])
        var cardData = cardDataOrignal.toDict()

        if let lynxContainer = self.lynxContainer,
           !lynxContainer.hasRendered() {
            if self.decodeStandaloneEnable {
                guard let templateStandalone = Self.templateStandalone else {
                    didReceiveError(error: .internalError("render fail: wrong template standalone"))
                    assertionFailure("MessageCardContainer render with error templateData")
                    return
                }
                #if ALPHA || DEBUG
                if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                    lynxContainer.render(templateUrl: debugUrl, initData: cardData)
                } else {
                    lynxContainer.render(bundle: templateStandalone.data, initData: cardData)
                }
                #else
                lynxContainer.render(bundle: templateStandalone.data,initData: cardData)
                #endif
            } else {
                guard let template = Self.template else {
                    didReceiveError(error: .internalError("render fail: wrong template"))
                    assertionFailure("MessageCardContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                    return
                }
                #if ALPHA || DEBUG
                if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                    lynxContainer.render(templateUrl: debugUrl, initData: cardData)
                } else {
                    lynxContainer.render(
                        template: template.data,
                        initData: cardData
                    )
                }
                #else
                lynxContainer.render(
                    template: template.data,
                    initData: cardData
                )
                #endif
            }
        } else {
            let traceid = context.renderTrace.traceId
            //lynxView 每次更新需要添加如下不同的flag，保证触发updateTiming回调
            cardData["__lynx_timing_flag"] = "__lynx_timing_actual_fmp_" + traceid
            let layout = Self.opLynxLayoutConfig(fromConfig: config)
            lynxContainer?.updateLayoutIfNeeded(sizeConfig: layout)
            lynxContainer?.update(data: cardData)
            if forceTriggerLayout,
               let lynxView = lynxContainer?.getLynxView() as? LynxView {
                lynxView.triggerLayout()
            }
            view?.setNeedsLayout()
        }
    }

    public func render() {

        guard let cardDataOrignal = cardData else {
            didReceiveError(error: .internalError("render fail: wrong card data"))
            assertionFailure("MessageCardContainer render with wrong data ")
            return
        }

        logger.info("render translateInfo: \(cardDataOrignal.translateInfo))", additionalData: [
            "MessageID": (context.getBizContext(key: "message") as? Message)?.id ?? "",
            "traceId": trace.traceId
        ])

        let cardData = cardDataOrignal.toDict()
        if lynxContainer == nil {
            if self.decodeStandaloneEnable {
                guard let templateStandalone = Self.templateStandalone else {
                    didReceiveError(error: .internalError("render fail: wrong template standalone"))
                    assertionFailure("MessageCardContainer render with error templateData")
                    return
                }
                context.updateSDKVersion(templateStandalone.version)
                didStartRender()
                lynxContainer = createOPLynxBuilder().build()
                lynxContainer?.setExtraTiming(extraTimingDic: templateStandalone.extraTiming)
                #if ALPHA || DEBUG
                if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                    lynxContainer?.render(templateUrl: debugUrl, initData: cardData)
                } else {
                    lynxContainer?.render(bundle: templateStandalone.data, initData: cardData)
                }
                #else
                lynxContainer?.render(bundle: templateStandalone.data,initData: cardData)
                #endif

            } else {
                guard let template = Self.template else {
                    didReceiveError(error: .internalError("render fail: wrong template"))
                    assertionFailure("MessageCardContainer render with error templateData: \(Self.template?.data.count ?? 0)")
                    return
                }
                context.updateSDKVersion(template.version)
                didStartRender()
                lynxContainer = createOPLynxBuilder().build()
                lynxContainer?.setExtraTiming(extraTimingDic: template.extraTiming)
                #if ALPHA || DEBUG
                if let debugUrl = LarkLynxDebugger.shared.debugUrl {
                    lynxContainer?.render(templateUrl: debugUrl, initData: cardData)
                } else {
                    lynxContainer?.render(
                        template: template.data,
                        initData: cardData
                    )
                }
                #else
                lynxContainer?.render(
                    template: template.data,
                    initData: cardData
                )
                #endif
            }
        } else {
            let layout = Self.opLynxLayoutConfig(fromConfig: config)
            lynxContainer?.updateLayoutIfNeeded(sizeConfig: layout)
            lynxContainer?.update(data: cardData)
            if forceTriggerLayout,
               let lynxView = lynxContainer?.getLynxView() as? LynxView {
                lynxView.triggerLayout()
            }
            view?.setNeedsLayout()
        }
    }
    
    public func update(content: CardContent, translateInfo: TranslateInfo, config: Config) {
        self.translateInfo = translateInfo
        self.content = content
        self.config = config
        setupCardData()
    }
    
    public func updateLayoutIfNeeded(config: Config) {
        let layout = Self.opLynxLayoutConfig(fromConfig: config)
        lynxContainer?.updateLayoutIfNeeded(sizeConfig: layout)
    }

    public func updateData(_ cardContainerData: MessageCardContainer.ContainerData) {
        cardContextManager.removeContext(key: context.key)
        self.cardID = cardContainerData.cardID
        self.localStatus = cardContainerData.localStatus
        self.version = cardContainerData.version
        self.content = cardContainerData.content
        self.context.update(cardContainerData.contextData)
        self.config = cardContainerData.config
        self.translateInfo = cardContainerData.translateInfo
        cardContextManager.setContext(key: context.key, context: context)
        setupCardData()
    }

    private func checkThemeChanged() -> Bool {
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        let currentTheme = isDarkModeTheme ? "dark" : "light"
        var themeChanged = false
        if let theme = self.theme {
            themeChanged = theme != currentTheme
        }
        self.theme = currentTheme
        return themeChanged
    }
    private func needRender(_ identify: EquatableIdentify?) -> Bool {
        var needRenderFlag = true
        if let isEqual = self.identify?.isEqual(identify: identify) {
            needRenderFlag = !isEqual
        }
        if checkThemeChanged() {
            updateEnvData()
            needRenderFlag = true
        }
        self.identify = identify
        return needRenderFlag
    }

    private func setupCardData() {
        guard let data = Self.data(fromCardContent: content) else {
            didReceiveError(error: .internalError("setupCardData fail: wrong content"))
            assertionFailure("MessageCardContainer setup with wrong data, jsonBody or jsonAttachment is nil")
            return
        }
        context.updateRnederTrace()
        let cardContext = Self.cardContext(fromContext: context, config: config)
        let cardConfig = Self.cardConfig(fromConfig: config)
        let cardSettings = Self.getSettings(translateInfo: translateInfo)
        let cardFGs = Self.getFeatureGatings()
        cardData = CardData(
            cardID: cardID,
            version: version,
            status: localStatus,
            original: data.original,
            translation: data.translation,
            context: cardContext,
            translateInfo: translateInfo,
            config: cardConfig,
            settings: cardSettings,
            fg: cardFGs,
            i18nText: config.i18nText,
            targetElement: self.targetElement
        )
    }
    
    private func createOPLynxBuilder() -> LarkLynxContainerBuilder {
        let layout = Self.opLynxLayoutConfig(fromConfig: config)
        let context = Self.opLynxContext(context: self.context)
        return LarkLynxContainerBuilder()
            .setupContext(context: context)
            .tagForCustomComponent(tag: Self.Tag)
            .tagForBridgeMethodDispatcher(tag: Self.Tag)
            .tagForGlobalData(tag: Self.Tag)
            .tagForLynxGroup(tag: Self.Tag)
            .lynxViewSizeConfig(sizeConfig: layout)
            .lynxViewLifeCycle(lynxViewLifeCycle: self)
            .addLynxResourceProvider(lynxResourceProvider: self.resourceProvider)
    }
}

public protocol EquatableIdentify {
    func isEqual(identify : EquatableIdentify?) -> Bool
}
