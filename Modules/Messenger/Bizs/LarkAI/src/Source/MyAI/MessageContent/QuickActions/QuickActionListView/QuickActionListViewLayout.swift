//
//  QuickActionListViewLayout.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import LarkAIInfra

class QuickActionListViewLayout {

    var isLoading: Bool = false
    var quickActionList: [AIQuickActionModel] = []

    /// 布局大小
    var size: CGSize = .zero

    static func layout(props: QuickActionListViewComponentProps, size: CGSize) -> QuickActionListViewLayout {
        let layout = QuickActionListViewLayout()
        layout.isLoading = props.isLoading
        if props.isLoading {
            layout.size = CGSize(width: size.width, height: QuickActionListView.Cons.listHeightForLoading)
        } else {
            layout.quickActionList = props.quickActionList
            layout.size = CGSize(width: size.width, height: QuickActionListView.Cons.listHeight(with: props.quickActionList, constraintWidth: size.width))
        }
        return layout
    }
}
