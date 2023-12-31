//
//  MoreDataProvider.swift
//  SKCommon
//
//  Created by lizechuang on 2021/2/25.
//

import Foundation

public typealias MoreDataSourceUpdater = ((MoreItemsBuilder) -> Void)
public typealias MoreDataOutsideControlItems = [State: [MoreItemType]]

// 数据源，负责当前业务逻辑的Item配置，以及Action响应
public protocol MoreDataProvider {
    // 数据源构造器
    var builder: MoreItemsBuilder { get }
    // 数据源更新
    var updater: MoreDataSourceUpdater? { get set }
    // 外部控制hidden Or disable
    var outsideControlItems: MoreDataOutsideControlItems? { get set }
    // 当前用户的最新 user permission
    var userPermissions: UserPermissionAbility? { get }
}

public extension MoreDataProvider {
    var userPermissions: UserPermissionAbility? { nil } // 只有 InsideMoreDataProvider 和 SpaceListMoreDataProvider 才会提供 userPermissions，其他类型都返回 nil
}

//   通过builder建造器来告知MoreVC需要展示什么
//   item可以是option类型的，通过prepareCheck来判断是否需要这个item，
//   item也可以是disable的，通过prepareEnable来判断是否需要置灰
//
//   e.g.
//   private var docs: MoreItemBuilder {
//       MoreItemBuilder {
//           share* - addTo - star - subscribe - pin - offline - delete*
//       } column: {
//           copyUrl
//           copyFile
//           exportDocument
//       }
//   }

public protocol MoreSectionConvertible {
    func asSections() -> [MoreSection]
}

extension MoreSection: MoreSectionConvertible {
    public func asSections() -> [MoreSection] { [self] }
}

extension Array: MoreSectionConvertible where Element == MoreSectionConvertible {
    public func asSections() -> [MoreSection] { flatMap { $0.asSections() } }
}

public final class MoreItemsBuilder {
    @resultBuilder
    public struct InnerMoreSectionBuilder {
        public static func buildBlock(_ sections: MoreSectionConvertible?...) -> [MoreSection] {
            sections.flatMap { $0?.asSections() ?? [] }
        }

        public static func buildOptional(_ component: MoreSectionConvertible?) -> MoreSectionConvertible {
            component?.asSections() ?? [MoreSection]()
        }
    }

    private let sections: [MoreSection]
    
    public init(@InnerMoreSectionBuilder sections: () -> [MoreSection]) {
        self.sections = sections()
    }

    public init(sections: [MoreSection]) {
        self.sections = sections
    }

    public static var empty: MoreItemsBuilder {
        MoreItemsBuilder {}
    }

    // 按顺序布局
    public func build() -> [MoreSection] {
        return sections
    }
}
