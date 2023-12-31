//
//  UDTabsTitleItemModel.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

open class UDTabsTitleItemModel: UDTabsBaseItemModel {
    public var title: String?
    public var titleCurrentColor: UIColor = UDTabsColorTheme.tabsFixedTitleNormalColor
    public var titleCurrentZoomScale: CGFloat = 0
    public var titleCurrentStrokeWidth: CGFloat = 0
    public var textWidth: CGFloat = 0
}
