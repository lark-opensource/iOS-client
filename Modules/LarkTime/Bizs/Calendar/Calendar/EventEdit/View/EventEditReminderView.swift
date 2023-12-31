//
//  EventEditReminderView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UIKit
import SnapKit
import UniverseDesignIcon

protocol EventEditReminderViewDataType {
    var title: String { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
    var outOfRangeText: String { get }
}

final class EventEditReminderView: EventEditCellLikeView, ViewDataConvertible {

    var clickHandler: (() -> Void)? {
        didSet {
            onClick = clickHandler
        }
    }
    var nextHandler: (() -> Void)? {
        didSet {
            onAccessoryClick = nextHandler
        }
    }

    private lazy var iconImage: UIImage = UDIcon.getIconByKeyNoLimitSize(.bellOutlined).renderColor(with: .n3)
    private lazy var iconDisabledImage: UIImage = UDIcon.getIconByKeyNoLimitSize(.bellOutlined).renderColor(with: .n4)

    var viewData: EventEditReminderViewDataType? {
        didSet {
            if let isEditable = viewData?.isEditable, isEditable {
                content = .richTitle(.init(text: viewData?.title ?? "",
                                           numberOfLines: 2,
                                           outOfRangeText: viewData?.outOfRangeText ?? "",
                                           preferMaxWidth: self.frame.width - 85))
                accessory = .type(.next())
                isUserInteractionEnabled = true
                icon = .customImage(iconImage)
            } else {
                content = .richTitle(.init(text: viewData?.title ?? "",
                                           color: UIColor.ud.textDisable,
                                           numberOfLines: 2,
                                           outOfRangeText: viewData?.outOfRangeText ?? "",
                                           preferMaxWidth: self.frame.width - 85))
                accessory = .type(.next(.n4))
                icon = .customImageWithoutN3(iconDisabledImage)
                isUserInteractionEnabled = false
            }

            isHidden = !(viewData?.isVisible ?? false)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .customImage(iconImage)
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

}
