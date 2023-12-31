//
//  SearhInChatEmptyDataView.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/31.
//

import Foundation
import LarkUIKit
import UniverseDesignEmpty

typealias SearhInChatEmptyDataView = UDEmptyView
typealias SearhInChatEmptyDataViewType = UDEmptyType

extension SearhInChatEmptyDataView {
    static func searchImageStyle() -> SearhInChatEmptyDataView {
        SearhInChatEmptyDataView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult),
            imageSize: 100,
            spaceBelowImage: 12,
            type: .noImage))
    }
    static func searchStyle(title: String, type: SearhInChatEmptyDataViewType) -> SearhInChatEmptyDataView {
        SearhInChatEmptyDataView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: title),
            imageSize: 100,
            spaceBelowImage: 12,
            type: type))
    }
}
