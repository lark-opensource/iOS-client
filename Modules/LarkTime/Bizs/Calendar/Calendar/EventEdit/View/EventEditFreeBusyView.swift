//
//  EventEditFreeBusyView.swift
//  Calendar
//
//  Created by 张威 on 2020/3/9.
//

import UniverseDesignIcon
import UIKit
import SnapKit

protocol EventEditFreeBusyViewDataType {
    var title: String { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
}

final class EventEditFreeBusyView: EventEditCellLikeView, ViewDataConvertible {

    var clickHandler: (() -> Void)? {
        didSet {
            onClick = clickHandler
        }
    }
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.statusTripOutlined)
    private lazy var iconImageDisbaled = UDIcon.getIconByKeyNoLimitSize(.statusTripOutlined).renderColor(with: .n4)

    var viewData: EventEditFreeBusyViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)
            let isEditable = viewData?.isEditable ?? false
            isUserInteractionEnabled = isEditable
            
            accessory = .type(.next(isEditable ? .n3 : .n4))
            icon = isEditable ? .customImage(iconImage) : .customImageWithoutN3(iconImageDisbaled)
            if let text = viewData?.title {
                content = .title(.init(text: text, color: isEditable ? UIColor.ud.textTitle : UIColor.ud.textDisabled))
            } else {
                content = .none
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .customImage(iconImage)
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        accessory = .type(.next())
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

}
