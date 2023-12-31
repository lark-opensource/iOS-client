//
//  AppOpened.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2023/4/13.
//

import Foundation

/// ['lark/workplace/api/recent/AppOpened'] - request parameters
public struct WPAppOpenedRequestParams: Codable {
    /// application identifier
    public let appId: String
    /// application ability, different open strategy
    public let abilityType: WPAppItem.AppAbility
    /// path of "Approval" template, eg: "Purchase" app
    public let path: String

    enum CodingKeys: String, CodingKey {
        case appId = "appID"
        case abilityType
        case path
    }

    public init(appId: String, abilityType: WPAppItem.AppAbility, path: String) {
        self.appId = appId
        self.abilityType = abilityType
        self.path = path
    }
}
