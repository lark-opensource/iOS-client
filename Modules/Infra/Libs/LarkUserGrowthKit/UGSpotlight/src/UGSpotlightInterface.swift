//
//  UGSpotlightInterface.swift
//  UGSpotlight
//
//  Created by zhenning on 2021/3/25.
//

import UIKit
import Foundation
import ServerPB
import LarkGuideUI

public typealias SpotlightMaterial = ServerPB_Ug_reach_material_SpotlightMaterialItem
public typealias SpotlightMaterials = ServerPB_Ug_reach_material_SpotlightMaterial

@dynamicMemberLookup
public struct UGSpotlightData: Equatable {

    let spotlightData: SpotlightData

    // Dynamic Member Lookup
    subscript<T>(dynamicMember keyPath: KeyPath<SpotlightData, T>) -> T {
        return spotlightData[keyPath: keyPath]
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.spotlightData == rhs.spotlightData
    }
}

// 气泡业务依赖信息
public struct SpotlightBizProvider {
    // 气泡展示的页面
    let hostProvider: () -> UIViewController
    // 锚点的类型，rect / view
    let targetSourceTypes: () -> [TargetSourceType]
    public init(hostProvider: @escaping () -> UIViewController,
                targetSourceTypes: @escaping () -> [TargetSourceType]) {
        self.hostProvider = hostProvider
        self.targetSourceTypes = targetSourceTypes
    }
}

public struct SpotlightData: Equatable {
    let spotlightMaterials: SpotlightMaterials
    var isMult: Bool {
        return spotlightMaterials.spotlights.count > 1
    }
    public init(spotlightMaterials: SpotlightMaterials) {
        self.spotlightMaterials = spotlightMaterials
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.spotlightMaterials == rhs.spotlightMaterials
    }
}
