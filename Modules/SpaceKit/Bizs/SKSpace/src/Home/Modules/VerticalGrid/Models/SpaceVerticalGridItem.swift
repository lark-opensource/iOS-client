//
//  SpaceVerticalGridItem.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource

public struct SpaceVerticalGridItem {
    let enable: Bool
    let title: String?
    let needRedPoint: Bool

    let iconType: SpaceList.IconType
    let entry: SpaceEntry
}

extension SpaceVerticalGridItem: Equatable {
    public static func == (lhs: SpaceVerticalGridItem, rhs: SpaceVerticalGridItem) -> Bool {
        return lhs.enable == rhs.enable
            && lhs.title == rhs.title
            && lhs.needRedPoint == rhs.needRedPoint
            && lhs.iconType == rhs.iconType
            && lhs.entry.objToken == rhs.entry.objToken
    }
}
