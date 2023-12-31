//
//  CalendarHeaderBgComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/31.
//

import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable

final class CalendarHeaderBgComponentProps: ASComponentProps {
    // 未来可能多种颜色type支持，先占位
    var colorType: String?
}

/// ASComponent  嵌入自定义 View
final class CalendarHeaderBgComponent<C: Context>: ASComponent<CalendarHeaderBgComponentProps, EmptyState, StripBackgroundView, C> {

    override func update(view: StripBackgroundView) {
        super.update(view: view)
        view.layoutIfNeeded()
    }
    
    override func create(_ rect: CGRect) -> StripBackgroundView {
        return StripBackgroundView(rect: rect)
    }

    override var isComplex: Bool {
        return true
    }

    override var isSelfSizing: Bool {
        return true
    }
}
