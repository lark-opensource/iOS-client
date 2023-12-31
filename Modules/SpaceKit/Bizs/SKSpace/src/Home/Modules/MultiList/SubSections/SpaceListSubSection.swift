//
//  SpaceListSubSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import UniverseDesignEmpty
import SKFoundation

public protocol SpaceListSubSectionConvertible {
    func asSections() -> [SpaceListSubSection]
}

public extension SpaceListSubSection {
    func asSections() -> [SpaceListSubSection] { [self] }
}

extension Array: SpaceListSubSectionConvertible where Element == SpaceListSubSectionConvertible {
    public func asSections() -> [SpaceListSubSection] { flatMap { $0.asSections() } }
}

@resultBuilder
public struct SpaceMultiListBuilder {
    public static func buildBlock() -> [SpaceListSubSection] { [] }
    public static func buildBlock(_ sections: SpaceListSubSectionConvertible...) -> [SpaceListSubSection] { sections.flatMap { $0.asSections() } }
    public static func buildIf(_ value: SpaceListSubSectionConvertible?) -> SpaceListSubSectionConvertible { value ?? [] }
    public static func buildEither(first: SpaceListSubSectionConvertible) -> SpaceListSubSectionConvertible { first }
    public static func buildEither(second: SpaceListSubSectionConvertible) -> SpaceListSubSectionConvertible { second }
}

struct SpaceSortFilterConfig {
    let sortItems: [SortItem]
    let defaultSortItems: [SortItem]
    // 与默认排序是否匹配
    var sortChanged: Bool {
        sortItems != defaultSortItems
    }
    let filterItems: [FilterItem]
    let defaultFilterItems: [FilterItem]
}

struct SpaceSortFilterConfigV2 {
    typealias FilterOption = SpaceFilterHelper.FilterOption
    typealias SortOption = SpaceSortHelper.SortOption

    let filterIndex: Int
    let filterOptions: [FilterOption]
    let defaultFilterOption: FilterOption
    let sortIndex: Int
    let sortOptions: [SortOption]
    let defaultSortOption: SortOption
}

public protocol SpaceListSubSection: SpaceSection, SpaceListSubSectionConvertible {
    var listTools: [SpaceListTool] { get }
    // ipad列表表头排序信息config
    var iPadListHeaderSortConfig: IpadListHeaderSortConfig? { get }
    // docs_tab_click 埋点上报用
    var subSectionIdentifier: String { get }
    var subSectionTitle: String { get }
    // 列表创建文档上下文
    var createIntent: SpaceCreateIntent { get }

    func didShowSubSection()
    func willHideSubSection()

    func reportClick(fromSubSectionId previousSubSectionId: String)
}

extension SpaceListSubSection {
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? { nil }

    // TODO(chenwenjun.cn): handling duplicate code
    public func reportClick(fromSubSectionId previousSubSectionId: String) {
        DocsLogger.info("No need to report click event")
    }
}

extension SpaceListSubSection {
    typealias ListState = SpaceListSubSectionListState
}

enum SpaceListSubSectionPlaceHolderType {
    case loading
    case networkUnavailable
    case emptyList(description: String, emptyType: UDEmptyType, createEnable: Observable<Bool>, createButtonTitle: String, createHandler: (UIView) -> Void)
    case failure(description: String, clickHandler: () -> Void)
}

enum SpaceListSubSectionListState {
    case loading
    case normal(itemTypes: [SpaceListItemType])
    case networkUnavailable
    case empty(description: String, emptyType: UDEmptyType, createEnable: Observable<Bool>, createButtonTitle: String, createHandler: (UIView) -> Void)
    case failure(description: String, clickHandler: () -> Void)
    case none

    var asPlaceHolderType: SpaceListSubSectionPlaceHolderType? {
        switch self {
        case .loading:
            return .loading
        case .normal, .none:
            return nil
        case .networkUnavailable:
            return .networkUnavailable
        case let .empty(description, emptyType, createEnable, createButtonTitle, createHandler):
            return .emptyList(description: description,
                              emptyType: emptyType,
                              createEnable: createEnable,
                              createButtonTitle: createButtonTitle,
                              createHandler: createHandler)
        case let .failure(description, clickHandler):
            return .failure(description: description, clickHandler: clickHandler)
        }
    }
}
