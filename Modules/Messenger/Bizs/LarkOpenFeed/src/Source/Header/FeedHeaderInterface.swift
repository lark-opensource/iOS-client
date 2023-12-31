//
//  FeedHeaderFactory.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/30.
//

import UIKit
import Foundation
import LarkContainer

public typealias FeedHeaderItemViewModelBuilder = (UserResolver) throws -> FeedHeaderItemViewModelProtocol?
public typealias FeedHeaderItemViewBuilder = (FeedHeaderItemViewModelProtocol) -> UIView?

final public class FeedHeaderFactory {

    private static var typesOrder: [FeedHeaderItemType] = [.topBar, .banner, .event, .shortcut]

    private static var viewModelBuilders: [FeedHeaderItemType: FeedHeaderItemViewModelBuilder] = [:]
    private static var viewBuilders = [FeedHeaderItemType: FeedHeaderItemViewBuilder]()

    // 注册Header所需要的ViewModel/View构造器
    public static func register(type: FeedHeaderItemType, viewModelBuilder: @escaping FeedHeaderItemViewModelBuilder, viewBuilder: @escaping FeedHeaderItemViewBuilder) {
        FeedHeaderFactory.viewModelBuilders[type] = viewModelBuilder
        FeedHeaderFactory.viewBuilders[type] = viewBuilder
    }

    // 构造 viewModel
    public static func allViewModel(context: UserResolver) -> [FeedHeaderItemViewModelProtocol] {
        typesOrder.compactMap { try? FeedHeaderFactory.viewModelBuilders[$0]?(context) }
    }

    // 构造 views
    public static func view(for viewModel: FeedHeaderItemViewModelProtocol) -> UIView? {
        FeedHeaderFactory.viewBuilders[viewModel.type]?(viewModel)
    }
}
