//
//  File.swift
//  LarkWorkplace
//
//  Created by SolaWing on 2019/10/12.
//

import Foundation
import RustPB
import LarkWorkplaceModel

typealias AppType = RustPB.Openplatform_V1_AppType
typealias FeedbackRecentAppRequest = RustPB.Openplatform_V1_FeedbackRecentAppRequest
typealias DomainSettings = RustPB.Basic_V1_DomainSettings

enum Rust {
    typealias NetStatus = RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus
    typealias OpenAppBadgeNode = RustPB.Openplatform_V1_OpenAppBadgeNode
    typealias LoadStrategy = RustPB.Openplatform_V1_CommonEnum.LoadStrategy
    typealias OpenAppFeatureType = RustPB.Openplatform_V1_CommonEnum.OpenAppFeatureType
    typealias SaveOpenAppBadgeNodesRequest = Openplatform_V1_SaveOpenAppBadgeNodesRequest
    typealias PushOpenAppBadgeNodesRequest = RustPB.Openplatform_V1_PushOpenAppBadgeNodesRequest
    typealias PullOpenAppBadgeNodesRequest = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest
    typealias PullOpenAppBadgeNodesResponse = RustPB.Openplatform_V1_PullOpenAppBadgeNodesResponse
    typealias IdFeaturePair = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest.IdFeaturePair
}

typealias FavoriteModule = WPTemplateModule.ComponentDetail.Favorite
typealias FavoriteSubModule = WPTemplateModule.ComponentDetail.Favorite.Config.SubModule
typealias FavoriteAppTag = WPTemplateModule.ComponentDetail.Favorite.AppTag
typealias FavoriteAppDisplaySize = WPTemplateModule.ComponentDetail.Favorite.DisplaySize
