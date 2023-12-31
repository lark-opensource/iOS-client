//
//  WikiSpaceCoverConfig.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/3.
//  

//TODO:refactor from WikiFeatureGate.swift

import Foundation
import SKCommon

struct WikiSpaceCoverConfig {
    static var placeHolderCount: Int {
        return 4
    }

    static var cellClass: AnyClass {
        return WikiHomePageSpaceViewCell.self
    }

    static var placeHolderShouldShowShadow: Bool {
        return true
    }

    static var layoutConfig: WikiHorizontalPagingLayoutConfig {
        return WikiSpaceCoverLayoutConfig()
    }

    static var allSpacesThreadhold: Int {
        return 3
    }
}
