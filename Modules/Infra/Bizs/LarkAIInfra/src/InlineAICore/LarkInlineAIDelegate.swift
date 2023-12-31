//
//  LarkInlineAIDelegate.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import Foundation
import RxSwift
import RxCocoa
import LarkModel


// MARK: - 数据层接口

/// 接入数据层需要实现
public protocol LarkInlineAISDKDelegate: AnyObject {

    func getShowAIPanelViewController() -> UIViewController

    /// 横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { get }
    
    /// 历史记录切换回调，在弱确认场景时业务方可能需要挪动选区等操作
    /// - Parameter text: 切换目标历史记录AI生成文本
    func onHistoryChange(text: String)
    
    /// 面板高度变化时通知业务方
    func onHeightChange(height: CGFloat)
    
    /// 用于发送自由指令时，需要业务方返回Prompt对象用于监听后续事件回调
    /// 只需要设置callback参数，其他参数传空
    func getUserPrompt() -> AIPrompt
    
    // 获取业务方的埋点公参
    func getBizReportCommonParams() -> [AnyHashable: Any]
    
    /// 复制浮窗中文本时, 业务方传入的加密id
    func getEncryptId() -> String?
}

public extension LarkInlineAISDKDelegate {
    
    func getEncryptId() -> String? { nil }
}

public class AIPromptGroup {
    /// 指令组的title
    public var title: String

    /// 该组的指令列表
    public var prompts: [AIPrompt]
    
    public init(title: String, prompts: [AIPrompt]) {
        self.title = title
        self.prompts = prompts
    }
}

extension AIPromptGroup {
    
    var ai_description: String {
        var dict = [String: Any]()
        dict["title"] = title
        dict["prompts"] = prompts.map { $0.ai_description }
        return dict.description
    }
}

public class AIPrompt {

    public struct PromptConfirmOptions {
        /// 预览模式，强（true）/ 弱（false）确认
        public var isPreviewMode: Bool

        /// 业务方执行指令时需要携带的额外参数
        public var param: [String: String]
        
        /// 业务方自定义指令执行中的文案
        public var writingPlaceholder: String?
        
        public init(isPreviewMode: Bool, param: [String : String], writingPlaceholder: String? = nil) {
            self.isPreviewMode = isPreviewMode
            self.param = param
            self.writingPlaceholder = writingPlaceholder
        }
        
        mutating func update(param: [String: String]) {
            self.param.merge(param) { (_, new) in new }
        }
    }

    public class AIPromptCallback {
        /// 指令准备请求之前，业务方返回该指令所需要的额外信息，不同场景同一指令对应的信息不一样，所以需要以get方式获取
        var onStart: (() -> PromptConfirmOptions)
        /// AI内容输入中，msg是markdown数据
        var onMessage: ((String) -> Void)
        /// AI输出中error/
        var onError: ((Error) -> Void)

        /// 参数为状态码，0代表成功，业务方根据状态成功/失败返回对应的操作按钮，
        var onFinish: ((Int) -> [OperateButton])

        public init(onStart: @escaping (() -> AIPrompt.PromptConfirmOptions), onMessage: @escaping ((String) -> Void), onError: @escaping ((Error) -> Void), onFinish: @escaping ((Int) -> [OperateButton])) {
            self.onStart = onStart
            self.onMessage = onMessage
            self.onError = onError
            self.onFinish = onFinish
        }
    }

    /// 指令id。用户输入自由指令传nil
    public var id: String?
    
    /// 唯一指令id，用于本地构建二级指令。
    /// 本地构建的二级指令id和父指令id相同，因此内部需要localId来识别
    /// 业务如果通过指令平台配置的二级指令可以忽略这个字段，默认id和localId相等
    public var localId: String?

    /// 指令icon，参考PromptIcon定义
    public var icon: String

    /// 指令文本
    public var text: String
    
    /// 目前用于埋点上报，区分不同指令
    public var type: String

    /// 指令模板
    public var templates: PromptTemplates?

    /// 指令的extra_map
    public var extraMap: [String: Any] = [:]
    
    /// 如果该指令有二级页面，则需要传此参数
    public var children: [AIPrompt] = []

    /// 点击指令callback
    public var callback: AIPromptCallback
    
    public init(id: String?,
                localId: String? = nil,
                icon: String,
                text: String,
                type: String = "",
                templates: PromptTemplates? = nil,
                children: [AIPrompt] = [],
                callback: AIPrompt.AIPromptCallback) {
        self.id = id
        self.icon = icon
        self.text = text
        self.type = type
        self.templates = templates
        self.children = children
        self.callback = callback
        self.localId = localId
        if let lId = localId  {
            self.localId = lId
        } else {
            self.localId = id
        }
    }

    var enumType: InlineAIPanelModel.PromptType? {
        return .init(rawValue: self.type)
    }
}

extension AIPrompt {
    
    var ai_description: String {
        var dict = [String: Any]()
        dict["id"] = id ?? ""
        dict["icon"] = icon
        dict["text"] = text
        dict["type"] = type
        return dict.description
    }
}

/**
 * 模版快捷指令的参数
 * @param templatePrefix 模板前缀
 * @param templateList 模板列表
 * 例如："帮我写一篇作文，字数是：请输入字数，主题是：请输入主题"
 * 其中"帮我写一篇作文，"是templatePrefix，"字数是：请输入字数"和"，主题是：请输入主题"是templateList
 */
public struct PromptTemplates {
    var templatePrefix: String
    var templateList: [PromptTemplate]

    public init(templatePrefix: String, templateList: [PromptTemplate]) {
        self.templatePrefix = templatePrefix
        self.templateList = templateList
    }
}

public struct PromptTemplate {
    
    /// 模版
    var templateName: String

    /// 用户输入的key
    var key: String

    /// 模版对应的placeHolder，单参指令时可为空
    var placeHolder: String?
    
    // 用户输入的默认值（替换placeHolder的内容）
    var defaultUserInput: String?
    
    public init(templateName: String, key: String, placeHolder: String? = nil, defaultUserInput: String? = nil) {
        self.templateName = templateName
        self.placeHolder = placeHolder
        self.key = key
        self.defaultUserInput = defaultUserInput
    }
}

public class OperateButton {
    
    typealias Callback = ((_ key: String, _ content: String) -> Void)
    /// 按钮key
    var key: String
    /// 按钮文案
    var text: String
    /// 如果该操作按钮有二级页面，则需要传此参数
    var promptGroups: [AIPromptGroup]?
    
    /// 按钮是否为高亮样式，正常情况下需要设置第一个按钮为true
    var isPrimary: Bool
    
    private var callback: Callback
    
    
    /// 初始化
    /// - Parameters:
    ///   - key: 按钮key
    ///   - text: 按钮文案
    ///   - promptGroups: 如果该操作按钮有二级页面，则需要传此参数
    ///   - isPrimary: 按钮是否为高亮样式，正常情况下需要设置第一个按钮为true
    ///   - callback: 点击回调，content为当前AI输出内容。
    public init(key: String,
                text: String,
                isPrimary: Bool = false,
                promptGroups: [AIPromptGroup]? = nil,
                callback: @escaping ((_ key: String, _ content: String) -> Void)) {
        self.key = key
        self.text = text
        self.promptGroups = promptGroups
        self.isPrimary = isPrimary
        self.callback = callback
    }
    
    func perform(content: String) {
        callback(self.key, content)
    }
}

extension OperateButton {
    
    var ai_description: String {
        var dict = [String: Any]()
        dict["key"] = key
        dict["text"] = text
        dict["promptGroups"] = promptGroups?.map { $0.ai_description } ?? []
        return dict.description
    }
}

// MARK: - UI层接口


/// 接入UI 层需要实现
public protocol LarkInlineAIUIDelegate: AnyObject {
    
    func getShowAIPanelViewController() -> UIViewController
    
    // 横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { get }
    
    // 输入框文本变化
    func onInputTextChange(text: String)
        
    // 点击键盘的发送按键（有快捷指令 or mention url功能）
    func onClickSend(content: RichTextContent)
    
    // 点击键盘的发送按键 （无快捷指令）
    func onClickSend(text: String)
        
    // 点击指令
    func onClickPrompt(prompt: InlineAIPanelModel.Prompt)
    
    // 点击二级面板指令
    func onClickSubPrompt(prompt: InlineAIPanelModel.Prompt)
        
    // 点击操作
    func onClickOperation(operate: InlineAIPanelModel.Operate)
    
    // 点击sheet操作
    func onClickSheetOperation()
        
    // 点击停止（AI内容生成过程中）
    func onClickStop()
    
    // 输入、点击'@'弹出picker选择框
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void)
        
    // 点击反馈按钮
    // true：点赞；false：点踩
    // callback: 反馈回调, 业务方保存后续调用时传入config
    func onClickFeedback(like: Bool, callback: ((LarkInlineAIFeedbackConfig) -> Void)?)
    
    // 点击历史记录
    // true：上一页；false：下一页
    func onClickHistory(pre: Bool)
    
    // 点击遮罩区域
    func onClickMaskArea(keyboardShow: Bool)
    
    func keyboardChange(show: Bool)

    // 滑动达到阈值，关闭面板
    func onSwipHidePanel(keyboardShow: Bool)

    func onHeightChange(height: CGFloat)
    
    func panelDidDismiss()
    
    // 通知业务方AI onBoarding是否设置完成的状态
    func onNeedOnBoarding(needOnBoarding: Bool)
    
    // Onboarding流程中途退出的回调
    // code = 0 表示用户主动退出，其他表示异常退出
    func onUserQuitOnboarding(code: Int, error: Swift.Error?)

    // 其他事件，用于后续拓展
    func onExtraOperation(type: String, data: Any?)
    
    func onClickImageCheckbox(imageData: InlineAIPanelModel.ImageData, checked: Bool)
    
    func imagesDownloadResult(results: [InlineAIImageDownloadResult])
    
    func imagesInsert(models: [InlineAICheckableModel])
    
    /// 复制浮窗中文本时, 业务方传入的加密id
    func getEncryptId() -> String?
    
    // 删除历史指令
    func onDeleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt)

    // 点击结果页面板文档链接
    func onOpenLink(url: String)
}

// MARK: - 可选实现
public extension LarkInlineAIUIDelegate {
    
    func onClickImageCheckbox(imageData: InlineAIPanelModel.ImageData, checked: Bool) {}
    func imagesDownloadResult(results: [InlineAIImageDownloadResult]) {}
    func imagesInsert(models: [InlineAICheckableModel]) {}
    
    /// InlineAIConfig.supportAt为true时需要实现此协议
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void) {}
    
    /// 支持快捷指令需要实现此协议
    func onClickSend(content: RichTextContent) {
        switch content.data {
        case .quickAction:
            break
        case .freeInput:
            onClickSend(text: content.attributedString.string)
        }
    }
    
    ///不支持快捷指令实现此协议
    func onClickSend(text: String) {}
    
    func onNeedOnBoarding(needOnBoarding: Bool) {}
    
    func onUserQuitOnboarding(code: Int, error: Swift.Error?) {}
    
    func onExtraOperation(type: String, data: Any?) {}
    
    func getEncryptId() -> String? { nil }

    func onDeleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt) {}

    func onOpenLink(url: String) {}
}
