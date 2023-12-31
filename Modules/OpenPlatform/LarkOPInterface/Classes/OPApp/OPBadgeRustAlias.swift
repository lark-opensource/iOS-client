//
//  OPBadgeRustAlias.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import RustPB

public enum OPBadgeRustAlias {
    public typealias OpenAppBadgeNode = RustPB.Openplatform_V1_OpenAppBadgeNode
    public typealias LoadStrategy = RustPB.Openplatform_V1_CommonEnum.LoadStrategy
    public typealias OpenAppFeatureType = RustPB.Openplatform_V1_CommonEnum.OpenAppFeatureType
    public typealias PushOpenAppBadgeNodesRequest = RustPB.Openplatform_V1_PushOpenAppBadgeNodesRequest
    public typealias PullOpenAppBadgeNodesRequest = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest
    public typealias PullOpenAppBadgeNodesResponse = RustPB.Openplatform_V1_PullOpenAppBadgeNodesResponse
    public typealias IdFeaturePair = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest.IdFeaturePair
}
