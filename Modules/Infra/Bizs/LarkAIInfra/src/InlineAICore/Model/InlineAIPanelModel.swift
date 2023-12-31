//
//  InlineAIPanelModel.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
import UniverseDesignIcon
import LarkBaseKeyboard

public struct InlineAIPanelModel: Codable {
    
    public var show: Bool
    public var dragBar: DragBar?
    public var content: String?
    public var contentExtra: [String: AIAnyCodable]?
    public var images: Images?
    public var prompts: Prompts?
    public var operates: Operates?
    public var input: Input?
    public var tips: Tips?
    public var feedback: Feedback?
    public var history: History?
    /// sheet单元格范围操作
    public var range: SheetOperate?
    /// 当前的亮/暗主题，用于内置webview展示，如果为自定义容器，不需要传入
    public var theme: String?
    /// 蒙层样式: fullScreen: 底部都是灰色、 aroundPanel：面板周围渐变色、none: 透明
    public var maskType: String?
    public var conversationId: String
    public var taskId: String
    /// false: 事件可以穿透到父容器，比如展示AI浮窗的同时可以滚动文档。true：手势事件完全由AI浮窗处理
    public var lock: Bool?
    
    public init(show: Bool, dragBar: InlineAIPanelModel.DragBar? = nil,
                content: String? = nil,
                contentExtra: [String: AIAnyCodable]? = nil,
                images: InlineAIPanelModel.Images? = nil,
                prompts: InlineAIPanelModel.Prompts? = nil,
                operates: InlineAIPanelModel.Operates? = nil,
                input: InlineAIPanelModel.Input? = nil,
                tips: InlineAIPanelModel.Tips? = nil,
                feedback: InlineAIPanelModel.Feedback? = nil,
                history: InlineAIPanelModel.History? = nil,
                range: InlineAIPanelModel.SheetOperate? = nil,
                theme: String? = InlineAIPanelModel.getCurrentTheme(),
                maskType: String? = nil,
                conversationId: String,
                taskId: String,
                lock: Bool? = nil) {
        self.show = show
        self.dragBar = dragBar
        self.content = content
        self.contentExtra = contentExtra
        self.images = images
        self.prompts = prompts
        self.operates = operates
        self.input = input
        self.tips = tips
        self.feedback = feedback
        self.history = history
        self.theme = theme
        self.maskType = maskType
        self.conversationId = conversationId
        self.taskId = taskId
        self.lock = lock
        self.range = range
    }
    
    var extraParams: [String: Any]? {
        guard let contentExtra = self.contentExtra else { return [:] }
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(contentExtra)
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            return jsonObj
        } catch {
            LarkInlineAILogger.error("extra convert fail error: \(error)")
            return nil
        }
    }
    
    public mutating func updateContentExtra(_ extra: [String: AIAnyCodable]?) {
        self.contentExtra = extra
    }
}

public struct InlineAISubPromptsModel: Codable {
    public var data: [InlineAIPanelModel.PromptGroups]?
    public var dragBar: InlineAIPanelModel.DragBar
    
    /// 默认为false，true表示本次为更新不是谈一个
    public var update: Bool?

    public init(data: [InlineAIPanelModel.PromptGroups],
                dragBar: InlineAIPanelModel.DragBar) {
        self.data = data
        self.dragBar = dragBar
    }
}

extension InlineAIPanelModel {
    enum MaskType: String {
        case fullScreen
        case aroundPanel
        case none
    }
    
    // 不能直接用枚举去解析json，枚举只要不匹配就会整体解析失败，不管是不是optional
    var maskTypeEnum: MaskType? {
        MaskType(rawValue: maskType ?? "")
    }
    
    public struct DragBar: Codable {
        
        public var show: Bool
        /// 下滑时是否需要二次确认
        public var doubleConfirm: Bool
        
        public init(show: Bool, doubleConfirm: Bool) {
            self.show = show
            self.doubleConfirm = doubleConfirm
        }
    }

    public struct Tips: Codable {
        
        public var show: Bool
        /// 提示文字
        public var text: String
        
        public init(show: Bool, text: String) {
            self.show = show
            self.text = text
        }
    }

    public struct Feedback: Codable {
        enum Position: String {
            case history
            case tips
        }
        
        public var show: Bool
        /// 0 不高亮  1高亮
        public var like: Bool
        /// 0 不高亮  1高亮
        public var unlike: Bool
        /// 'history' | 'tips'
        public var position: String?
        
        public init(show: Bool, like: Bool, unlike: Bool, position: String? = nil) {
            self.show = show
            self.like = like
            self.unlike = unlike
            self.position = position
        }
        
        var enumPosition: Position {
            return Position(rawValue: self.position ?? "") ?? .history
        }
        
        mutating func update(like: Bool) {
            self.like = like
        }
    
        mutating func update(unlike: Bool) {
            self.unlike = unlike
        }
    }

    // 历史记录参数
    public struct History: Codable {
        
        public var show: Bool
        /// 5/8 的8
        public var total: Int
        /// 5/8 的5
        public var curNum: Int
        /// 左侧箭头 1=可用  0=禁用
        public var leftArrowEnabled: Bool
        /// 右侧箭头 1=可用  0=禁用
        public var rightArrowEnabled: Bool
        
        public init(show: Bool,
                    total: Int,
                    curNum: Int,
                    leftArrowEnabled: Bool,
                    rightArrowEnabled: Bool) {
            self.show = show
            self.total = total
            self.curNum = curNum
            self.leftArrowEnabled = leftArrowEnabled
            self.rightArrowEnabled = rightArrowEnabled
        }
    }

    public struct Input: Codable {
        
        public var show: Bool
        /// 0 = 普通输入状态   1 = 正在输入状态
        public var status: Int
        /// 文字
        public var text: String
        /// 带参快捷指令
        public var textContentList: QuickAction?
        /// 普通输入状态的文案
        public var placeholder: String
        /// 正在输入状态的文案
        public var writingText: String
        /// 是否展示暂停按钮  1=展示 0=隐藏
        public var showStopBtn: Bool
        /// 是否需要激活输入框。非空才会响应
        public var showKeyboard: Bool?
        
        /// 自定义字段
        var attributedString: AIAttributedStringWrapper?
        
        //  === 支持历史指令需要的字段 ===
                
        /// 是否可选中placehoder，当为多参指令/自由指令时传true，其他场景传false
        /// 多参指令textContentList不为空，将textContentList变为实体文本显示
        /// 多参指令textContentList为空时，将placeholder变为实体文本显示
        public var placehoderSelected: Bool?

        /// 普通历史快捷指令，不支持展示历史指令场景/或者非普通快捷指令 不需要返回。
        /// 当返回不为空时，在未输入文字情况下可点击按钮/键盘发送上次指令
        public var recentPrompt: Prompt?
        
        public init(show: Bool,
                    status: Int,
                    text: String,
                    placeholder: String,
                    writingText: String,
                    showStopBtn: Bool,
                    showKeyboard: Bool? = nil,
                    textContentList: QuickAction? = nil,
                    placehoderSelected: Bool? = nil,
                    recentPrompt: Prompt? = nil) {
            self.show = show
            self.status = status
            self.text = text
            self.placeholder = placeholder
            self.writingText = writingText
            self.showStopBtn = showStopBtn
            self.showKeyboard = showKeyboard
            self.textContentList = textContentList
            self.placehoderSelected = placehoderSelected
            self.recentPrompt = recentPrompt
        }
        
        mutating func update(_ attributedString: AIAttributedStringWrapper) {
            self.attributedString = attributedString
        }

    }
    
    public struct QuickAction: Codable {
        
        public var displayName: String
        
        public var displayContent: String?
        
        public var paramDetails: [ParamDetail]
        
        public init(displayName: String, displayContent: String? = nil, paramDetails:[ParamDetail]) {
            self.displayName = displayName
            self.displayContent = displayContent
            self.paramDetails = paramDetails
        }
        
        static func convert(templates: PromptTemplates) -> QuickAction {
            return QuickAction(displayName: templates.templatePrefix, paramDetails: ParamDetail.convert(templates: templates.templateList))
        }
    }
    
    public enum ParamContentComponent: Codable {
        case plainText(String) // 纯文本
        case mention(InlineAIMentionEntity) // @实体
        // 不参与序列化
        public init(from decoder: Decoder) throws {
            self = .plainText("")
        }
        public func encode(to encoder: Encoder) throws {
        }
    }
    
    public struct ParamDetail: Codable {
        public var name: String
        public var key: String
        public var placeHolder: String?
        public var content: String?
        // 保存 `@实体` 和 `纯文本` 数组，不序列化
        public private(set) var contentComponents: [ParamContentComponent]?
        
        var richContent: AIAttributedStringWrapper?
    
        public init(name: String, key: String, placeHolder: String? = nil, content: String? = nil) {
            self.name = name
            self.key = key
            self.placeHolder = placeHolder
            self.content = content
        }
        
        static func convert(templates: [PromptTemplate]) -> [ParamDetail] {
            return templates.map {
                return ParamDetail(name: $0.templateName, key: $0.key, placeHolder: $0.placeHolder, content: $0.defaultUserInput)
            }
        }
    
        mutating func updateComponents(_ components: [ParamContentComponent]) {
            self.contentComponents = components
        }
        
        mutating func updateRichContent(_ richContent: AIAttributedStringWrapper?) {
            self.richContent = richContent
        }
    }

    public struct Operate: Codable {
        
        public enum ButtonType: String, Codable {
            case `default`
            case primary
        }
        public var text: String
        public var type: String?
        public var btnType: String
        // 不能直接用枚举去解析json，枚举只要不匹配就会整体解析失败，不管是不是optional
        var btnTypeEnum: ButtonType {
            ButtonType(rawValue: btnType) ?? .default
        }

        /// UI不需要，点击后要透传
        public var template: String?
        
        public var disabled: Bool?
        
        public init(text: String,
                    type: String? = nil,
                    btnType: String,
                    template: String? = nil,
                    disabled: Bool = false) {
            self.text = text
            self.type = type
            self.btnType = btnType
            self.template = template
            self.disabled = disabled
        }
    }

    public struct Operates: Codable {
        
        public var show: Bool
        public var data: [Operate]
        
        public init(show: Bool, data: [InlineAIPanelModel.Operate]) {
            self.show = show
            self.data = data
        }
    }


    enum PromptType: String {
        case historyPrompt = "history_prompt"
    }

    public struct Prompt: Codable {

        /// 指令id，id可能不唯一
        public var id: String
        
        public var localId: String?

        public var icon: String
        // 指令名称，形式可能会是:
        // 1. 指令名称
        // 2. <span style="color: #ffffff">指令</span>名称
        public var text: String
        
        public var rightArrow: Bool

        // 自定义字段
        public var attributedString: AIAttributedStringWrapper?
        
        var iconImage: UIImage? {
            if let image = PromptIcon(rawValue: icon)?.image {
                return image
            } else {
                LarkInlineAILogger.error("iconImage nil key:\(icon)")
                if icon.isEmpty {
                    return nil
                } else {
                    return UDIcon.getIconByKey(.editContinueOutlined, size: CGSize(width: 16, height: 16))
                }
            }
        }
        
        /// UI不需要，点击后要透传给业务方
        public var type: String?
        public var template: String?
        public var originText: String?
        public var key: String?
        public var params: [String]?
        public var extras: String?
        
        public init(id: String,
                    localId: String? = nil,
                    icon: String,
                    text: String,
                    rightArrow: Bool = false,
                    type: String? = nil,
                    template: String? = nil,
                    originText: String? = nil,
                    key: String? = nil,
                    params: [String]? = nil,
                    attributedString: AIAttributedStringWrapper? = nil,
                    extras: String? = nil) {
            self.id = id
            self.localId = localId
            self.icon = icon
            self.text = text
            self.rightArrow = rightArrow
            self.type = type
            self.template = template
            self.originText = originText
            self.key = key
            self.params = params
            self.extras = extras
            self.attributedString = attributedString
        }
        
        mutating func update(attributedString: AIAttributedStringWrapper) {
            self.attributedString = attributedString
        }
    }

    public struct PromptGroups: Codable {
        // 没有title是会是 '' 空字符串
        public var title: String?
        public var prompts: [Prompt]
        
        public init(title: String? = nil,
                    prompts: [InlineAIPanelModel.Prompt]) {
            self.title = title
            self.prompts = prompts
        }
    }

    public struct Prompts: Codable {
        
        public var show: Bool
        /// true表示覆盖在结果页展示指令和结果页共存, false为互斥显示
        public var overlap: Bool
        public var data: [PromptGroups]
        
        public init(show: Bool,
                    overlap: Bool,
                    data: [InlineAIPanelModel.PromptGroups]) {
            self.show = show
            self.overlap = overlap
            self.data = data
        }
        
        mutating func update(data: [PromptGroups]) {
            self.data = data
        }
    }
    
    public struct ImageData: Codable {

        public var url: String
        public var id: String
        /// 被tns拦截时服务端会返回兜底图，这时不能选中改图片
        public var checkable: Bool?
    }

    public struct Images: Codable {
        public var show: Bool
        /// 0 loading态  1 数据展示态
        public var status: Int
        /// url数据
        public var data: [ImageData]?
        
        /// 选中的图片id
        public var checkList: [String]
        
        var canShow: Bool {
            return status == 1
        }
    }

    public struct SheetOperate: Codable {
        public var show: Bool
        public var text: String
        public var enable: Bool
        public var suffixIcon: String?
        
        public init(show: Bool,
                    text: String,
                    enable: Bool,
                    suffixIcon: String?) {
            self.show = show
            self.text = text
            self.enable = enable
            self.suffixIcon = suffixIcon
        }
    }
}


enum UIType: Int, CaseIterable {
    case dragBar = 0
    case history
    case content
    case tips
    case feedback
    case operate
    case prompt
    case input
    case images
}

public struct InlineAIImageDownloadResult{
    public var id: String
    public var success: Bool
}

struct InlineAIModelWrapper {
    
    var panelModel: InlineAIPanelModel
    
    var imageModels: [InlineAICheckableModel]
}


public enum PromptIcon: String {
    case edit = "CcmEditContinueOutlined"
    case maybe = "MaybeOutlined"
    case todo = "TodoOutlined"
    case slidesAnimation = "SlidesAnimationOutlined"
    case expand = "ExpandOutlined"
    case abbreviation = "AbbreviationOutlined"
    case editDiscription = "EditDiscriptionOutlined"
    case nopicture = "NopictureFilled"
    case translate = "TranslateOutlined"
    case effects = "EffectsOutlined"
    case settingInter = "SettingInterOutlined"
    case fileLinkFormOutlined = "FileLinkFormOutlined"
    case addexpandOutlined = "AddexpandOutlined"
    case ccmEditOutlined = "CcmEditOutlined"
    case taskAddOutlined = "TaskAddOutlined"
    case addOutlined = "AddOutlined"
    case adminMutiStage =  "AdminMultistageOutlined"
    case efficiency = "EfficiencyOutlined"
    case more = "MoreOutlined"
    case imChatNewOutlined = "IconChatNewOutlined"
    case imEditDescriptionOutlined = "IconEditDescriptionOutlined"
    case imListCheckBoldOutlined = "IconListCheckBoldOutlined"
    case imTodoOutlined = "IconTodoOutlined"
    case imMaybeOutlined = "IconMaybeOutlined"
    case imDefault = "IconIMDefault"
    case calendarOutlined = "IconCalendarOutlined"
    case calendarEditOutlined = "IconCalendarEditOutlined"
    case timeOutlined = "IconTimeOutlined"
    case roomOutlined = "IconRoomOutlined"
    case fileLinkDocxOutlined = "IconFileLinkDocxOutlined"
    case historyOutlined = "HistoryOutlined"
    
    public var image: UIImage? {
        let size = CGSize(width: 16, height: 16)
        switch self {
        case .edit:
            return UDIcon.getIconByKey(.editContinueOutlined, size: size)
        case .maybe, .imMaybeOutlined:
            return UDIcon.getIconByKey(.maybeOutlined, size: size)
        case .todo, .imTodoOutlined:
            return UDIcon.getIconByKey(.todoOutlined, size: size)
        case .slidesAnimation, .imDefault:
            return UDIcon.getIconByKey(.slidesAnimationOutlined, size: size)
        case .expand:
            return UDIcon.getIconByKey(.expandOutlined, size: size)
        case .abbreviation:
            return UDIcon.getIconByKey(.abbreviationOutlined, size: size)
        case .editDiscription, .imEditDescriptionOutlined:
            return UDIcon.getIconByKey(.editDiscriptionOutlined, size: size)
        case .nopicture:
            return UDIcon.getIconByKey(.nopictureFilled, size: size)
        case .translate:
            return UDIcon.getIconByKey(.translateOutlined, size: size)
        case .effects:
            return UDIcon.getIconByKey(.effectsOutlined, size: size)
        case .settingInter:
            return UDIcon.getIconByKey(.settingInterOutlined, size: size)
        case .fileLinkFormOutlined:
            return UDIcon.getIconByKey(.fileLinkFormOutlined, size: size)
        case .addexpandOutlined:
            return UDIcon.getIconByKey(.addexpandOutlined, size: size)
        case .ccmEditOutlined:
            return UDIcon.getIconByKey(.editOutlined, size: size)
        case .taskAddOutlined:
            return UDIcon.getIconByKey(.taskAddOutlined, size: size)
        case .addOutlined:
            return UDIcon.getIconByKey(.addOutlined, size: size)
        case .adminMutiStage:
            return UDIcon.getIconByKey(.adminMultistageOutlined, size: size)
        case .efficiency:
            return UDIcon.getIconByKey(.efficiencyOutlined, size: size)
        case .more:
            return UDIcon.getIconByKey(.moreOutlined, size: size)
        case .imChatNewOutlined:
            return UDIcon.getIconByKey(.replyCnOutlined, size: size)
        case .imListCheckBoldOutlined:
            return UDIcon.getIconByKey(.listCheckBoldOutlined, size: size)
        case .calendarOutlined:
            return UDIcon.getIconByKey(.calendarLineOutlined, size: size)
        case .calendarEditOutlined:
            return UDIcon.getIconByKey(.calendarEditOutlined, size: size)
        case .timeOutlined:
            return UDIcon.getIconByKey(.timeOutlined, size: size)
        case .roomOutlined:
            return UDIcon.getIconByKey(.roomOutlined, size: size)
        case .fileLinkDocxOutlined:
            return UDIcon.getIconByKey(.fileLinkWordOutlined, size: size)
        case .historyOutlined:
            return UDIcon.getIconByKey(.historyOutlined, size: size)
        }
    }
}


public typealias InlineInputContent = (text: String, quickAction: InlineAIPanelModel.QuickAction?)

public struct AIAttributedStringWrapper: Codable {

    var value: NSAttributedString?
    
    public init(_ wrappedValue: NSAttributedString?) {
        self.value = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.value = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
}
