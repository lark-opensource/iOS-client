//
//  LinkItemOpened.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2023/4/13.
//

import Foundation

/// ['lark/workplace/api/recent/LinkItemOpened'] - request parameters
public struct WPCustomLinkOpenedRequestParams: Codable {
    /// item identifier
    public let itemId: String

    public init(itemId: String) {
        self.itemId = itemId
    }
}
