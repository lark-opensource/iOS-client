//
//  LarkInlineAIModuleGenerator.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/25.
//


import Foundation
import TangramService
import LarkContainer

/// @ 的类型
public enum InlineAIMentionType {
    
    case doc
    
    case user
}
/// @ 的实体
public enum InlineAIMentionEntity {
    
    case doc(title: String, url: URL)
    
    case user(name: String, userID: String)
}

public struct InlineAIConfig {
    public enum ScenarioType: Int {
        case none = -1
        case im = 0
        case docX = 1
        case sheet = 2
        case base = 3
        case vc = 4
        case calendar = 5
        case email = 6
        case meego = 7
        case openWebContainer = 8
        case search = 9
        case slides = 10
        case groupChat = 11
        case p2pChat = 12
        case board = 13
        case pdfView = 14
        case wikiSpace = 15
        case voiceInput = 16
    }
    
    public enum MaskTye: String {
        case `default` // 默认遮罩，强确认全屏遮罩，弱确认边框遮罩
        case fullScreen  // 全屏遮罩
        case aroundPanel // 边框遮罩
    }
    
    public enum LockType {
        case `default` // 强确认lock，弱确认unLock
        case lock // 事件不穿透
        case unLock // 事件穿透
    }
    
    public struct PanelMargin {
        /// 有键盘时面板距离底部的距离
        public var bottomWithKeyboard: CGFloat
        /// 没有键盘时面板距离底部的距离
        public var bottomWithoutKeyboard: CGFloat
        /// 左右间距
        public var leftAndRight: CGFloat

        public init(bottomWithKeyboard: CGFloat, bottomWithoutKeyboard: CGFloat, leftAndRight: CGFloat) {
            self.bottomWithKeyboard = bottomWithKeyboard
            self.bottomWithoutKeyboard = bottomWithoutKeyboard
            self.leftAndRight = leftAndRight
        }
    }

    // 文案为空则使用默认值
    public struct DialogConfig {
        public var title: String?
        public var content: String?
        public var cancelButton: String?
        public var confirmButton: String?
        
        public init(title: String? = nil,
                    content: String? = nil,
                    cancelButton: String? = nil,
                    confirmButton: String? = nil) {
            self.title = title
            self.content = content
            self.cancelButton = cancelButton
            self.confirmButton = confirmButton
        }
    }

    /// 是否可以录屏/截屏
    public var captureAllowed: Bool
    
    /// 支持@ 的类型
    public var mentionTypes: [InlineAIMentionType]

    /// 使用完整SDK时必传
    public var scenario: ScenarioType
    
    public var userResolver: LarkContainer.UserResolver
    
    private var fullSDK: Bool = false

    /// AI输入框文案
    public var placeHolder: PlaceHolder
    
    /// 面板遮罩类型
    public var maskType: MaskTye = .default
    
    /// 面板外事件透传类型
    public var lock: LockType = .default
    
    public var panelMargin: PanelMargin?
    
    public weak var quitConfirmDialogConfigProvider: QuitConfirmDialogConfigProvider?
    
    /// 退出是否需要二次确认弹窗
    public var needQuitConfirm: Bool = false
    
    /// 业务方传true，则结果页会多一个"复制调试信息"的按钮，点击后可复制当前AI指令和输入输出信息到剪切板
    public var debug: Bool = false

    /// 是否支持最近指令和编辑上次指令
    public var supportLastPrompt: Bool = false

    /// AI浮窗初始化配置（*表示数据层字段）
    /// - Parameters:
    ///   - captureAllowed: 是否可以录屏/截屏
    ///   - mentionTypes: 支持@ 的类型，目前只支持单类型
    ///   - scenario: 使用完整SDK时必传 *
    ///   - placeHolder: AI输入框文案 *
    ///   - maskType: 面板遮罩类型 *
    ///   - lock: 面板外事件透传类型 *
    ///   - panelMargin: 自定义面板间距，nil表示使用默认间距
    ///   - quitConfirmDialogConfigProvider: 提供弹窗文案，nil表示使用默认文案。只有needQuitConfirm为true时会生效 *
    ///   - userResolver: 用户态Container容器，提供面板获取其他sdk能力
    public init(captureAllowed: Bool = false,
                mentionTypes: [InlineAIMentionType] = [],
                scenario: ScenarioType = .none,
                placeHolder: PlaceHolder = PlaceHolder.defaultPlaceHolder,
                maskType: MaskTye = .default,
                lock: LockType = .default,
                panelMargin: PanelMargin? = nil,
                quitConfirmDialogConfigProvider: QuitConfirmDialogConfigProvider? = nil,
                userResolver: LarkContainer.UserResolver) {
        self.captureAllowed = captureAllowed
        self.mentionTypes = mentionTypes
        self.scenario = scenario
        self.userResolver = userResolver
        self.placeHolder = placeHolder
        self.maskType = maskType
        self.lock = lock
        self.panelMargin = panelMargin
        self.quitConfirmDialogConfigProvider = quitConfirmDialogConfigProvider
    }
    
    mutating func updateCaptureAllowed(allow: Bool) {
        self.captureAllowed = allow
    }
    
    mutating func updateFullSDK(fullSDK: Bool) {
        self.fullSDK = fullSDK
    }
    
    internal var isFullSDK: Bool { self.fullSDK }
    
    @discardableResult
    public mutating func update(needQuitConfirm: Bool) -> InlineAIConfig {
        self.needQuitConfirm = needQuitConfirm
        return self
    }
    
    @discardableResult
    public mutating func update(debug: Bool) -> InlineAIConfig {
        self.debug = debug
        return self
    }
    
    @discardableResult
    public mutating func update(supportLastPrompt: Bool) -> InlineAIConfig {
        self.supportLastPrompt = supportLastPrompt
        return self
    }
}

public struct PlaceHolder {
    /// 指令选择页面
    var waitingPlaceHolder: String
    /// AI生成中
    var writingPlaceHolder: String
    /// AI结果页
    var finishedPlaceHolder: String
    
    public static var defaultPlaceHolder: PlaceHolder {
        return PlaceHolder(BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_WhatToDo_Placeholder,
                           BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_Writing_Placeholder,
                           BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_WhatNext_Placeholder)
    }
    
    public init(_ waitingPlaceHolder: String, _ writingPlaceHolder: String, _ finishedPlaceHolder: String) {
        self.waitingPlaceHolder = waitingPlaceHolder
        self.writingPlaceHolder = writingPlaceHolder
        self.finishedPlaceHolder = finishedPlaceHolder
    }
    
    public mutating func update(waitingPlaceHolder: String) {
        self.waitingPlaceHolder = waitingPlaceHolder
    }
    
    public mutating func update(writingPlaceHolder: String) {
        self.writingPlaceHolder = writingPlaceHolder
    }
    
    public mutating func update(finishedPlaceHolder: String) {
        self.finishedPlaceHolder = finishedPlaceHolder
    }
}

public protocol QuitConfirmDialogConfigProvider: AnyObject {
    func provideDialogConfig() -> InlineAIConfig.DialogConfig
}


public class LarkInlineAIModuleGenerator {
    
    /// 只接入UI层
    public class func createUISDK(config: InlineAIConfig, customView: UIView?, delegate: LarkInlineAIUIDelegate) -> LarkInlineAIUISDK {
        InlineAIResourceManager.shared.unzipResToSandboxIfNeed()
        let module = LarkInlineAIModule(viewPresentation: .panelViewController(customView: customView),
                                        aiDelegate: delegate,
                                        aiFullDelegate: nil,
                                        config: config)
        module.aiOnboardingService = self.getOnboardingService(userResolver: config.userResolver)
        return module
    }
    
    /// 接入UI层+数据层
    public class func createAISDK(config: InlineAIConfig, customView: UIView?, delegate: LarkInlineAISDKDelegate) -> LarkInlineAISDK {
        InlineAIResourceManager.shared.unzipResToSandboxIfNeed()
        var innerConfig = config
        innerConfig.updateFullSDK(fullSDK: true)
        let module = LarkInlineAIModule(viewPresentation: .panelViewController(customView: customView),
                                        aiDelegate: nil,
                                        aiFullDelegate: delegate,
                                        config: innerConfig)
        module.aiOnboardingService = self.getOnboardingService(userResolver: config.userResolver)
        return module
    }
    
    /// 接入语音AI sdk，传入初始配置，返回IInlineAIAsrSdk接口实例
    public class func createAsrSDK(config: InlineAIConfig, customView: UIView?, delegate: LarkInlineAISDKDelegate?) -> InlineAIAsrSDK {
        InlineAIResourceManager.shared.unzipResToSandboxIfNeed()
        
        var innerConfig = config
        innerConfig.scenario = .voiceInput
        
        var placeHolder = PlaceHolder.defaultPlaceHolder
        placeHolder.writingPlaceHolder = BundleI18n.LarkAIInfra.MyAI_IM_VoiceMessage_PolishTextWorkingOnIt_AI_Text
        innerConfig.placeHolder = placeHolder
        
        innerConfig.updateFullSDK(fullSDK: true)
        let module = LarkInlineAIModule(viewPresentation: .customView,
                                        aiDelegate: nil,
                                        aiFullDelegate: nil,
                                        config: innerConfig)
        module.aiOnboardingService = self.getOnboardingService(userResolver: config.userResolver)
        let sdkImpl = InlineAIAsrSDKImpl(aiModule: module, delegate: delegate)
        sdkImpl.asrContainerView = customView
        sdkImpl.fetchPrompts(result: nil) // 创建时请求一次，便于后续使用缓存
        return sdkImpl
    }

    private static func getOnboardingService(userResolver: LarkContainer.UserResolver?) -> MyAIOnboardingService? {
        let service = try? userResolver?.resolve(type: MyAIOnboardingService.self)
        return service
    }
}
