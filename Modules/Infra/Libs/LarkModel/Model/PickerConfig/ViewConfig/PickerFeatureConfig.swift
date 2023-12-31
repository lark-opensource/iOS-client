//
//  PickerUIConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/7.
//

import Foundation

public enum PickerScene: String, Codable {
    /// 日历有效会议关联文档场景
    case calendarAgendaAssociate
    /// 日历场景
    case calendarShareMember
    /// CCM AI浮窗选择场景
    case ccmInlineAI
    /// CCM Space 各列表搜索
    case ccmSearchInSpace
    /// CCM Wiki 首页搜索
    case ccmSearchInWiki
    /// CCM Wiki 目录树搜索
    case ccmSearchInWikiTree
    /// CCM "移动/快捷方式/副本"场景的三栏搜索
    case ccmSearchInWikiAndFolder
    /// CCM 文件夹搜索
    case ccmSearchFolder
    /// CCM 搜索 Wiki 空间
    case ccmSearchWikiSpace
    /// CCM 搜索场景过滤文件夹二级搜索
    case ccmFilterByFolder
    /// CCM 搜索场景过滤文件夹二级搜索
    case ccmFilterByWikiSpace
    /// CCM 搜索场景过滤所有者二级搜索
    case ccmFilterByOwner
    /// CCM 搜索场景过滤所在会话二级搜索
    case ccmFilterByChat
    ///  im +号选择面板，选择CCM文档场景
    case imSelectDocs
    /// IM转发组件 创建群组并转发选人场景
    case imCreateAndForward
    ///  mainSearch 开放搜索emailTab 发件人收件人筛选器
    case searchFilterByOpenMail

    case demo
    case unknown
}

/// Picker功能配置
public struct PickerFeatureConfig: Codable {
    /// 多选相关配置
    public struct MultiSelection: Codable {
        /// 是否打开多选
        public var isOpen: Bool
        /// True: 打开多选时, 默认为多选状态,
        /// False: 打开多选时, 默认为单选状态, 需要手动切换到多选状态
        public var isDefaultMulti: Bool
        /// 打开多选时, 能否支持切换至多选
        public var canSwitchToMulti: Bool
        /// 打开多选时, 能否支持切换至单选
        public var canSwitchToSingle: Bool
        /// 预选项, 可以取消选择
        /// 注意: 当设置p2p chat item时, 会预选chatter的item
        public var preselectItems: [PickerItem]?
        /// 多选列表样式, 默认为icon横向列表
        public var selectedViewStyle: PickerSelectedViewStyle = .iconList
        /// 多选列表是否支持展开
        public var supportUnfold: Bool

        public enum PickerSelectedViewStyle {
            case iconList
            case folder
            case label((Int) -> String)
        }

        public init(isOpen: Bool = false,
                    isDefaultMulti: Bool = true,
                    canSwitchToMulti: Bool = true,
                    canSwitchToSingle: Bool = false,
                    preselectItems: [PickerItem]? = nil,
                    selectedViewStyle: PickerSelectedViewStyle = .iconList,
                    supportUnfold: Bool = true) {
            self.isOpen = isOpen
            self.isDefaultMulti = isDefaultMulti
            self.canSwitchToMulti = canSwitchToMulti
            self.canSwitchToSingle = canSwitchToSingle
            self.preselectItems = preselectItems
            self.selectedViewStyle = selectedViewStyle
            self.supportUnfold = supportUnfold
        }
    }

    /// 导航栏配置
    public struct NavigationBar {
        /// 导航栏标题
        public var title: String
        /// 导航栏副标题
        public var subtitle: String?
        /// 隐藏确认按钮
        public var showSure: Bool = true
        /// 确认按钮文案
        public var sureText: String
        /// 关闭按钮颜色
        public var closeColor: UIColor?
        /// 多选模式下,确认按钮是否带有选中个数
        public var isSureWithCount: Bool = true
        /// 多选状态下, 不选择item时能否完成确认
        public var canSelectEmptyResult: Bool
        /// 确认按钮颜色
        public var sureColor: UIColor?

        public init(title: String,
                    subtitle: String? = nil,
                    showSure: Bool = true,
                    sureText: String = "Select", // 下个需求去掉默认值
                    closeColor: UIColor? = nil,
                    isSureWithCount: Bool = true,
                    canSelectEmptyResult: Bool = true,
                    sureColor: UIColor? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.showSure = showSure
            self.sureText = sureText
            self.closeColor = closeColor
            self.isSureWithCount = isSureWithCount
            self.canSelectEmptyResult = canSelectEmptyResult
            self.sureColor = sureColor
        }
    }

    /// 搜索栏配置
    public struct SearchBar: Codable {
        /// 搜索栏提示文案
        public var placeholder: String?
        /// 搜索栏下方是否有12的间距
        public var hasBottomSpace: Bool = true
        /// 进入Picker后, 搜索栏是否进去编辑态
        public var autoFocus: Bool = false
        /// 搜索框autocorrectionType属性
        public var autoCorrect: Bool = false
        /// 搜索栏旁边是否有取消按钮
        public var hasCancelBtn: Bool = true

        public init(placeholder: String? = nil,
                    hasBottomSpace: Bool = true,
                    autoFocus: Bool = false,
                    autoCorrect: Bool = false,
                    hasCancelBtn: Bool = true) {
            self.placeholder = placeholder
            self.hasBottomSpace = hasBottomSpace
            self.autoFocus = autoFocus
            self.autoCorrect = autoCorrect
            self.hasCancelBtn = hasCancelBtn
        }
    }

    /// 目标预览
    public struct TargetPreview: Codable {
        /// 是否打开目标预览
        public var isOpen: Bool = false

        public init(isOpen: Bool = false) {
            self.isOpen = isOpen
        }
    }

    public var scene: PickerScene = .unknown
    public var multiSelection = MultiSelection()
    public var navigationBar = NavigationBar(title: "", sureText: "")
    public var searchBar = SearchBar()
    public var targetPreview = TargetPreview()

    public init(scene: PickerScene = .unknown,
                multiSelection: PickerFeatureConfig.MultiSelection? = nil,
                navigationBar: PickerFeatureConfig.NavigationBar? = nil,
                searchBar: PickerFeatureConfig.SearchBar? = nil,
                targetPreview: PickerFeatureConfig.TargetPreview? = nil) {
        self.scene = scene
        self.multiSelection = multiSelection ?? MultiSelection()
        self.navigationBar = navigationBar ?? NavigationBar(title: "", sureText: "")
        self.searchBar = searchBar ?? SearchBar()
        self.targetPreview = targetPreview ?? TargetPreview()
    }
}

extension PickerFeatureConfig.NavigationBar: Codable {
    enum CodingKeys: CodingKey {
        case title
        case subtitle
        case sureText
        case isSureWithCount
        case canSelectEmptyResult
        case sureColor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.subtitle = try? container.decode(String?.self, forKey: .subtitle)
        self.sureText = try container.decode(String.self, forKey: .sureText)
        self.isSureWithCount = try container.decode(Bool.self, forKey: .isSureWithCount)
        self.canSelectEmptyResult = try container.decode(Bool.self, forKey: .canSelectEmptyResult)
        if let sureColorHex = try container.decode(String?.self, forKey: .sureColor) {
            self.sureColor = UIColor(hexString: sureColorHex)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.subtitle, forKey: .subtitle)
        try container.encode(self.sureText, forKey: .sureText)
        try container.encode(self.isSureWithCount, forKey: .isSureWithCount)
        try container.encode(self.canSelectEmptyResult, forKey: .canSelectEmptyResult)
        try container.encode(self.sureColor?.toHexString(), forKey: .sureColor)
    }
}

extension PickerFeatureConfig.MultiSelection.PickerSelectedViewStyle: Codable {
    enum CodingKeys: CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        switch value {
        case "folder": self = .folder
        case "label": self = .label({ _ in "" })
        default: self = .iconList
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var value = "iconList"
        switch self {
        case .label(_): value = "label"
        case .folder: value = "folder"
        default: break
        }
        try container.encode(value, forKey: .value)
    }
}
