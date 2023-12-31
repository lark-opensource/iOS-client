//
//  MoreViewControllerV2Interface.swift
//  SKCommon
//
//  Created by lizechuang on 2021/2/25.
//

import Foundation
import SKResource
import SKFoundation
import SpaceInterface

public struct MoreReadingDataInfo {
    // ReadData
    var readingCount: String?
    var wordCount: String?
}

// MARK: MoreSection
public enum MoreSectionType {
    case horizontal
    // typetitle 表示shortcut的上下分栏的title("对快捷方式"&"对本体"), 非shortcut为nil
    case verticalSection(VerticalMoreSecitonType?)
    public static let vertical: MoreSectionType = .verticalSection(nil)
}

public enum VerticalMoreSecitonType {
    case origin
    case shortcut
    case originNotExist
    
    public var sectionText: String {
        switch self {
        case .origin:
            return BundleI18n.SKResource.LarkCCM_Workspace_Menu_OriginalDoc_Header
        case .shortcut:
            return BundleI18n.SKResource.LarkCCM_Workspace_Menu_Shortcut_Header
        case .originNotExist:
            return BundleI18n.SKResource.LarkCCM_Workspace_Menu_OriginalDocumentDeleted_Tooltip
        }
    }
}

public struct MoreSection {
    @resultBuilder
    public struct InnerMoreItemBuilder {
        public static func buildBlock(_ values: MoreItem?...) -> [MoreItem] {
            values.compactMap({ $0 })
        }
        public static func buildBlock(_ values: MoreItemConvertible?...) -> [MoreItem] {
            let values: [MoreItemConvertible] = values.compactMap({ $0 })
            return values.flatMap { value -> [MoreItem] in
                return value.asMoreItems()
            }
        }
        public static func buildIf(_ value: MoreItemConvertible?) -> MoreItemConvertible { value ?? [MoreItem]() }
        public static func buildEither(first: MoreItemConvertible) -> MoreItemConvertible { first }
        public static func buildEither(second: MoreItemConvertible) -> MoreItemConvertible { second }
    }

    let sectionType: MoreSectionType
    let items: [ItemsProtocol]

    public init?(type: MoreSectionType,
                 outsideControlItems: MoreDataOutsideControlItems? = nil,
                 @InnerMoreItemBuilder items: () -> [ItemsProtocol]) {
        self.init(type: type, outsideControlItems: outsideControlItems, items: items())
    }

    public init?(type: MoreSectionType,
                 outsideControlItems: MoreDataOutsideControlItems? = nil,
                 items: [ItemsProtocol]) {
        var processedItems = items
        if let outsideControlItems = outsideControlItems {
            // hidden & disable
            let hiddens = outsideControlItems[.hidden]
            let disables = outsideControlItems[.disable]
            processedItems = processedItems.compactMap({ (item) -> ItemsProtocol? in
                var item = item
                if hiddens?.contains(item.type) ?? false {
                    return nil
                }
                if disables?.contains(item.type) ?? false {
                    item.state = .disable
                }
                return item
            })
        }
        if processedItems.count == 0 {
            return nil
        }
        self.sectionType = type
        self.items = processedItems
    }
}

public typealias MoreItemNewTagInfo = (shouldShow: Bool, docsType: DocsType, isOwner: Bool, controlByFrontendItems: [String]?)

// MARK: MoreItem
public struct MoreItem: ItemsProtocol {
    
    public var state: State = .enable

    public var shouldPreventDismissal: Bool = false

    public var type: MoreItemType

    public var style: MoreStyle = .normal

    public var handler: ItemActionHandlerV2

    public var title: String {
        type.imageAndTitle.1
    }
    public var image: UIImage {
        type.imageAndTitle.0
    }

    public var iconEnableColor: UIColor {
        type.enableColor
    }

    public var iconDisableColor: UIColor {
        type.disableColor
    }

    public private(set) var needNewTag: Bool = false
    
    //点击按钮是否会进入二级页
    public var hasSubPage: Bool = false

    public func removeNewTagMarkWith(_ docsType: DocsType) {
        if self.type.newTagIdentifiler != nil {
            MoreVCGuideConfig.updateNewTapDataIfNeed(docsType: docsType, type: self.type)
        } else {
            MoreVCGuideConfig.markHasFinishGuide(docsType: docsType, itemType: self.type)
        }
    }

    /// 创建 ItemsProtocol，返回值可以为空，表示不需要显示
    /// - Parameters:
    ///   - type: Item 类型
    ///   - style: Item 风格
    ///   - prepareCheck: 判断是否需要显示，不需要则return nil
    ///   - prepareEnable: 判断是否可点击
    ///   - needNewTag: 是否需要红点逻辑，持久化交付内部进行判断
    ///   - handler: 点击事件响应
    public init?(type: MoreItemType,
                 style: MoreStyle = .normal,
                 preventDismissal: Bool = false,
                 newTagInfo: MoreItemNewTagInfo? = nil,
                 hasSubPage: Bool = false,
                 prepareCheck: () -> Bool,
                 prepareEnable: (() -> Bool)? = nil,
                 handler: @escaping ItemActionHandler) {
        self.init(type: type,
                  style: style,
                  preventDismissal: preventDismissal,
                  newTagInfo: newTagInfo,
                  hasSubPage: hasSubPage,
                  prepareCheck: prepareCheck,
                  prepareEnable: prepareEnable,
                  handlerV2: { item, isOn, _ , _ in
            handler(item, isOn)
        })
    }
    
    /// 创建 ItemsProtocol，返回值可以为空，表示不需要显示
    /// - Parameters:
    ///   - type: Item 类型
    ///   - style: Item 风格
    ///   - prepareCheck: 判断是否需要显示，不需要则return nil
    ///   - prepareEnable: 判断是否可点击
    ///   - needNewTag: 是否需要红点逻辑，持久化交付内部进行判断
    ///   - handler: 点击事件响应
    public init?(type: MoreItemType,
                 style: MoreStyle = .normal,
                 preventDismissal: Bool = false,
                 newTagInfo: MoreItemNewTagInfo? = nil,
                 hasSubPage: Bool = false,
                 prepareCheck: () -> Bool,
                 prepareEnable: (() -> Bool)? = nil,
                 handler: @escaping ItemActionHandlerV3) {
        self.init(type: type,
                  style: style,
                  preventDismissal: preventDismissal,
                  newTagInfo: newTagInfo,
                  hasSubPage: hasSubPage,
                  prepareCheck: prepareCheck,
                  prepareEnable: prepareEnable,
                  handlerV2: { item, isOn, _ , style in
            handler(item, isOn, style)
        })
    }

    /// 创建 ItemsProtocol，返回值可以为空，表示不需要显示
    /// - Parameters:
    ///   - type: Item 类型
    ///   - style: Item 风格
    ///   - prepareCheck: 判断是否需要显示，不需要则return nil
    ///   - prepareEnable: 判断是否可点击
    ///   - needNewTag: 是否需要红点逻辑，持久化交付内部进行判断
    ///   - handler: 点击事件响应
    public init?(type: MoreItemType,
                 style: MoreStyle = .normal,
                 preventDismissal: Bool = false,
                 newTagInfo: MoreItemNewTagInfo? = nil,
                 hasSubPage: Bool = false,
                 prepareCheck: () -> Bool,
                 prepareEnable: (() -> Bool)? = nil,
                 handlerV2: @escaping ItemActionHandlerV2) {
        guard prepareCheck() else {
            return nil
        }
        self.type = type
        self.style = style
        self.handler = handlerV2
        self.hasSubPage = hasSubPage
        if let enable = prepareEnable?() {
            self.state = enable ? .enable : .disable
        }
        self.shouldPreventDismissal = preventDismissal
        if let newTagInfo = newTagInfo, newTagInfo.shouldShow, self.state == .enable {
            self.needNewTag = self.moreItemShouldShowNewTagWith(newTagInfo, type: type)
        }
    }

    
    /// 创建 ItemsProtocol，返回值不可以为空
    /// - Parameters:
    ///   - type: Item 类型
    ///   - style: Item 风格
    ///   - prepareEnable: 判断是否可点击
    ///   - needNewTag: 判断是否需要红点逻辑，本地持久化More模块统一判断
    ///   - handler: 点击事件响应
    public init(type: MoreItemType,
                style: MoreStyle = .normal,
                preventDismissal: Bool = false,
                newTagInfo: MoreItemNewTagInfo? = nil,
                hasSubPage: Bool = false,
                prepareEnable: (() -> Bool)? = nil,
                handler: @escaping ItemActionHandler) {
        self.init(type: type,
                  style: style,
                  preventDismissal: preventDismissal,
                  newTagInfo: newTagInfo,
                  prepareEnable: prepareEnable,
                  handlerV2: { item, isOn, _, _  in
            handler(item, isOn)
        })
    }

    /// 创建 ItemsProtocol，返回值不可以为空
    /// - Parameters:
    ///   - type: Item 类型
    ///   - style: Item 风格
    ///   - prepareEnable: 判断是否可点击
    ///   - needNewTag: 判断是否需要红点逻辑，本地持久化More模块统一判断
    ///   - handler: 点击事件响应
    public init(type: MoreItemType,
                style: MoreStyle = .normal,
                preventDismissal: Bool = false,
                newTagInfo: MoreItemNewTagInfo? = nil,
                hasSubPage: Bool = false,
                prepareEnable: (() -> Bool)? = nil,
                handlerV2: @escaping ItemActionHandlerV2) {
        self.type = type
        self.style = style
        self.shouldPreventDismissal = preventDismissal
        self.handler = handlerV2
        self.hasSubPage = hasSubPage
        if let enable = prepareEnable?() {
            self.state = enable ? .enable : .disable
        }
        if let newTagInfo = newTagInfo, newTagInfo.shouldShow, self.state == .enable {
            self.needNewTag = self.moreItemShouldShowNewTagWith(newTagInfo, type: type)
        }
    }
}

// NewTag
extension MoreItem {
    func moreItemShouldShowNewTagWith(_ info: MoreItemNewTagInfo, type: MoreItemType) -> Bool {
        if type.newTagIdentifiler != nil {
            return MoreVCGuideConfig.shouldDisplaySpecialGuide(docsType: info.docsType,
                                                               itemType: type,
                                                               controlByFrontend: info.controlByFrontendItems)
        }
        return MoreVCGuideConfig.shouldDisplayGuide(docsType: info.docsType,
                                                             itemType: type,
                                                             isOwner: info.isOwner)
    }
}

extension MoreItem: MoreItemConvertible {
    public func asMoreItems() -> [MoreItem] { [self] }
}

public protocol MoreItemConvertible {
    func asMoreItems() -> [MoreItem]
}

extension Array: MoreItemConvertible where Element: MoreItemConvertible {
    public func asMoreItems() -> [MoreItem] { flatMap { $0.asMoreItems() } }
}

// swiftlint:disable static_operator
public func - (l: MoreItemConvertible?, r: MoreItemConvertible?) -> [MoreItem] {
    let lItems: [MoreItem] = (l ?? [MoreItem]()).asMoreItems().compactMap({ $0 })
    let rItems: [MoreItem] = (r ?? [MoreItem]()).asMoreItems().compactMap({ $0 })
    return lItems + rItems
}

//postfix operator *
//public postfix func * (item: MoreItemConvertible) -> MoreItemConvertible? {
//    guard LayoutManager.shared.isGrid else {
//        return nil
//    }
//    return item
//}
