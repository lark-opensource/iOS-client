//
//  BannerData.swift
//  UGBanner
//
//  Created by mochangxing on 2021/3/1.
//
import Foundation
import ServerPB

public typealias BannerNormalContent = ServerPB_Ug_reach_material_NormalBannerMaterial
public typealias BannerTemplateContent = ServerPB_Ug_reach_material_TemplateBannerMaterial

public typealias BannerInfo = ServerPB_Ug_reach_material_BannerMaterial

@dynamicMemberLookup
public struct LarkBannerData: Equatable {

    let bannerInfo: BannerInfo

    // Dynamic Member Lookup
    subscript<T>(dynamicMember keyPath: KeyPath<ServerPB.ServerPB_Ug_reach_material_BannerMaterial, T>) -> T {
        return bannerInfo[keyPath: keyPath]
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.bannerInfo == rhs.bannerInfo
    }
}
