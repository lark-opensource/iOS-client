//
//  FeedFilterListInterface.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/15.
//

import UIKit
import Foundation
import RxSwift
import RustPB

public typealias FeedFilterListItemsProvider = (_ context: Any, _ subTabId: String?) throws -> [FeedFilterListItemInterface]
public typealias FeedFilterListItemObservableProvider = (_ context: Any) throws -> Observable<Void>

// Entity
public protocol FeedFilterListItemInterface {
    var selectState: Bool { get }
    var filterType: Feed_V1_FeedFilter.TypeEnum { get }
    var unread: Int { get }
    var unreadContent: String { get }
    var title: String { get }
    var avatarInfo: (avatarId: String, avatarKey: String)? { get }
    var avatarImage: UIImage? { get }
    var subTabId: String? { get }
}

// Register
public struct FeedFilterListSource {
    public let itemsProvider: FeedFilterListItemsProvider
    public var observableProvider: FeedFilterListItemObservableProvider

    public init(itemsProvider: @escaping FeedFilterListItemsProvider,
                observableProvider: @escaping FeedFilterListItemObservableProvider) {
        self.itemsProvider = itemsProvider
        self.observableProvider = observableProvider
    }
}

final public class FeedFilterListSourceFactory {

    private static var sourceMap: [Feed_V1_FeedFilter.TypeEnum: FeedFilterListSource] = [:]

    public static func register(type: Feed_V1_FeedFilter.TypeEnum,
                                itemsProvider: @escaping FeedFilterListItemsProvider,
                                observableProvider: @escaping FeedFilterListItemObservableProvider) {
        let source = FeedFilterListSource(itemsProvider: itemsProvider,
                                          observableProvider: observableProvider)
        FeedFilterListSourceFactory.sourceMap[type] = source
    }

    // 构造 source (Feed_V1_FeedFilter -> source)
    public static func source(for type: Feed_V1_FeedFilter.TypeEnum) -> FeedFilterListSource? {
        if let source = FeedFilterListSourceFactory.sourceMap[type] {
            return source
        }
        return nil
    }
}
