//
//  EventEditDeleteView.swift
//  Calendar
//
//  Created by ByteDance on 2023/8/28.
//

import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignColor

protocol EventEditDeleteViewDataType {
    var isVisible: Bool { get }
    var title: String { get }
}

final class EventEditDeleteView: EventEditCellLikeView, ViewDataConvertible {
    var clickHandler: (() -> Void)? {
        didSet { onClick = clickHandler }
    }

    var viewData: EventEditDeleteViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = !viewData.isVisible
            content = .title(.init(text: viewData.title, color: UIColor.ud.functionDanger500))
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessory = .none
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        icon = .customImageWithoutN3(UDIcon.getIconByKeyNoLimitSize(.deleteTrashOutlined).ud.withTintColor(UIColor.ud.functionDanger500))
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        content = .title(.init(text: BundleI18n.Calendar.Calendar_Common_Delete, color: UIColor.ud.functionDanger500))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }
}
