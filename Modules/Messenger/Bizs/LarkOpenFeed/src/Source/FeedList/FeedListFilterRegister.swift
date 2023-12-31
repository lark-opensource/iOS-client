//
//  FeedListFilterRegister.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/6/10.
//

import UIKit
import Foundation
import RustPB

public typealias FeedTitleProvider = () -> (String)
// context透传给factory，一般应该实现UserResolverWrapper协议
public typealias FeedModuleVCBuilder = (Feed_V1_FeedFilter.TypeEnum, _ context: Any) throws -> FeedModuleVCInterface
public typealias FeedTapHandler = (Feed_V1_FeedFilter.TypeEnum, _ context: Any) throws -> Void

public struct FeedFilterTabSource {
    public enum Responder {
        case subVC(FeedModuleVCBuilder)
        case tapHandler(FeedTapHandler)
    }

    public enum FeedCardRemoveMode {
        case immediate // 立马移除，默认模式
        case delay // 稍后移除/切分组移除
    }

    public let normalIcon: UIImage?
    public let selectedIcon: UIImage?
    public let removeMode: FeedCardRemoveMode
    public let supportTempTop: Bool // AppInFeed 卡片是否支持置顶底色显示
    public let titleProvider: FeedTitleProvider
    public let responder: Responder
    public let trackFilterName: String // 埋点用

    public init(normalIcon: UIImage?,
                selectedIcon: UIImage?,
                removeMode: FeedCardRemoveMode,
                supportTempTop: Bool,
                trackFilterName: String,
                titleProvider: @escaping FeedTitleProvider,
                responder: Responder) {
        self.titleProvider = titleProvider
        self.normalIcon = normalIcon
        self.removeMode = removeMode
        self.supportTempTop = supportTempTop
        self.trackFilterName = trackFilterName
        self.selectedIcon = selectedIcon
        self.responder = responder
    }
}

final public class FeedFilterTabSourceFactory {

    private static var sourceMap: [Feed_V1_FeedFilter.TypeEnum: FeedFilterTabSource] = [:]

    public static func register(type: Feed_V1_FeedFilter.TypeEnum,
                                normalIcon: UIImage? = nil,
                                selectedIcon: UIImage? = nil,
                                removeMode: FeedFilterTabSource.FeedCardRemoveMode = .immediate,
                                supportTempTop: Bool = true,
                                titleProvider: @escaping FeedTitleProvider,
                                responder: FeedFilterTabSource.Responder) {
        let source = FeedFilterTabSource(normalIcon: normalIcon,
                                         selectedIcon: selectedIcon,
                                         removeMode: removeMode,
                                         supportTempTop: supportTempTop,
                                         trackFilterName: "", // 先留个口子，之后待filter优化之后，需要加上
                                         titleProvider: titleProvider,
                                         responder: responder)
        FeedFilterTabSourceFactory.sourceMap[type] = source
    }

    // 构造 source (Feed_V1_FeedFilter -> source)
    public static func source(for type: Feed_V1_FeedFilter.TypeEnum) -> FeedFilterTabSource? {
        if let source = FeedFilterTabSourceFactory.sourceMap[type] {
            return source
        }
        return nil
    }
}
