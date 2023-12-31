//
//  FeedViewModelFactory.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/23.
//

import Foundation
typealias FeedSubViewModelBuilder = (Feed_V1_FeedFilter.TypeEnum, _ context: Any) throws -> FeedListViewModel

import RustPB
import LarkOpenFeed

final class FeedViewModelFactory {

    private static var viewModelBuilders: [FeedListViewModelType: FeedSubViewModelBuilder] = [:]

    static func register(type: FeedListViewModelType, viewModelBuilder: @escaping FeedSubViewModelBuilder) {
        FeedViewModelFactory.viewModelBuilders[type] = viewModelBuilder
    }

    // 构造 viewModel
    static func viewModel(for type: Feed_V1_FeedFilter.TypeEnum, context: Any) throws -> FeedListViewModel {
        guard let filterType = FeedListViewModelType.feedListVMTypes[type],
              let builder = FeedViewModelFactory.viewModelBuilders[filterType] else {
            fatalError("Should never go here")
        }
        return try builder(type, context)
    }
}
