//
//  SpaceMoreItem.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/10/29.
//

import Foundation
import SKFoundation

// Space 对 MoreItem 的封装，支持多维度的 hidden、disable 状态控制
public final class SpaceMoreItem {
    // forbiddenReason 不为 nil 表示 enable，否则表示被禁用
    public typealias ActionHandler = (_ isSwitch: Bool, _ forbiddenReason: String?) -> Void
    public var hiddenCheckers: [HiddenChecker]
    public var enableCheckers: [EnableChecker]
    public let type: MoreItemType
    public let style: MoreStyle
    public let newTagInfo: MoreItemNewTagInfo?
    public var handler: ActionHandler

    public init(type: MoreItemType, style: MoreStyle = .normal, newTagInfo: MoreItemNewTagInfo? = nil,
         @HiddenCheckerBuilder hiddenCheckers: () -> [HiddenChecker],
         @EnableCheckerBuilder enableCheckers: () -> [EnableChecker],
         handler: @escaping ActionHandler) {
        self.type = type
        self.style = style
        self.newTagInfo = newTagInfo
        self.hiddenCheckers = hiddenCheckers()
        self.enableCheckers = enableCheckers()
        self.handler = handler
    }

    public var moreItem: MoreItem? {
        let forbiddenReason: String?
        var customHandler: ((UIViewController?) -> Bool)?
        let itemEnable: Bool
        let preventDismissal: Bool
        if let forbiddenChecker = enableCheckers.first(where: { !$0.isEnabled }) {
            forbiddenReason = forbiddenChecker.disableReason
            customHandler = forbiddenChecker.customHandler
            itemEnable = forbiddenChecker.forceEnableStyle
            preventDismissal = forbiddenChecker.forceEnableStyle
        } else {
            forbiddenReason = nil
            customHandler = nil
            itemEnable = true
            preventDismissal = false
        }
        let handler = self.handler
        return MoreItem(type: type,
                        style: style,
                        preventDismissal: preventDismissal,
                        newTagInfo: newTagInfo) {
            hiddenCheckers.allSatisfy { !$0.isHidden }
        } prepareEnable: {
            itemEnable
        } handlerV2: { _, isSwitch, hostController, _  in
            if let customHandler {
                let shouldContinue = customHandler(hostController)
                if !shouldContinue { return }
            }
            handler(isSwitch, forbiddenReason)
        }

    }
}

public protocol SpaceMoreItemType {
    func asSpaceMoreItems() -> [SpaceMoreItem]
}
extension SpaceMoreItem: SpaceMoreItemType {
    public func asSpaceMoreItems() -> [SpaceMoreItem] { [self] }
}
extension Array: SpaceMoreItemType where Element == SpaceMoreItem {
    public func asSpaceMoreItems() -> [SpaceMoreItem] { self }
}

extension SpaceMoreItem: MoreItemConvertible {
    public func asMoreItems() -> [MoreItem] {
        guard let moreItem = moreItem else {
            return []
        }
        return [moreItem]
    }
}

// 为了实现 SpaceMoreItem 初始化一次后，可以持续更新 MoreItem，做一层 Space More 封装
public struct SpaceMoreSection {
    @resultBuilder
    public struct SpaceMoreSectionBuilder {
        public static func buildBlock(_ values: SpaceMoreItemType...) -> [SpaceMoreItem] { values.flatMap { $0.asSpaceMoreItems() } }
        public static func buildIf(_ value: [SpaceMoreItem]?) -> [SpaceMoreItem] { value ?? [] }
        public static func buildEither(first: [SpaceMoreItem]) -> [SpaceMoreItem] { first }
        public static func buildEither(second: [SpaceMoreItem]) -> [SpaceMoreItem] { second }
    }

    public let sectionType: MoreSectionType
    let items: [SpaceMoreItem]

    var moreSection: MoreSection? {
        MoreSection(type: sectionType, items: items.compactMap(\.moreItem))
    }

    public init(type: MoreSectionType, @SpaceMoreSectionBuilder items: () -> [SpaceMoreItem]) {
        self.sectionType = type
        self.items = items()
    }
}

public protocol SpaceMoreSectionConvertible {
    func asSections() -> [SpaceMoreSection]
}

extension SpaceMoreSection: SpaceMoreSectionConvertible {
    public func asSections() -> [SpaceMoreSection] { [self] }
}

extension Array: SpaceMoreSectionConvertible where Element == SpaceMoreSection {
    public func asSections() -> [SpaceMoreSection] { flatMap { $0.asSections() } }
}

public final class SpaceMoreItemBuilder {
    @resultBuilder
    public struct SpaceMoreBuilder {
        public static func buildBlock(_ sections: SpaceMoreSectionConvertible...) -> [SpaceMoreSection] { sections.flatMap { $0.asSections() } }

        public static func buildOptional(_ component: SpaceMoreSectionConvertible?) -> SpaceMoreSectionConvertible {
            component?.asSections() ?? [SpaceMoreSection]()
        }
    }

    let sections: [SpaceMoreSection]

    public init(@SpaceMoreBuilder sections: () -> [SpaceMoreSection]) {
        self.sections = sections()
    }

    public var moreBuilder: MoreItemsBuilder {
        MoreItemsBuilder(sections: sections.compactMap(\.moreSection))
    }
}
