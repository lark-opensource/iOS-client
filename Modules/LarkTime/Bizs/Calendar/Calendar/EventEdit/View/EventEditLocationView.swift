//
//  EventEditLocationView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor

protocol EventEditLocationViewDataType {
    var title: String { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
}

final class EventEditLocationView: EventEditCellLikeView, ViewDataConvertible {

    var clickHandler: (() -> Void)? {
        didSet { onClick = clickHandler }
    }

    var deleteHandler: (() -> Void)? {
        didSet { onAccessoryClick = deleteHandler }
    }

    var viewData: EventEditLocationViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)

            var titleContent = ContentTitle(text: viewData?.title ?? "")
            if let isEditable = viewData?.isEditable, isEditable {
                isUserInteractionEnabled = true
                accessory = .type(.close)
                titleContent.color = UIColor.ud.textTitle
                icon = .customImage(iconImage)
            } else {
                isUserInteractionEnabled = false
                accessory = .none
                icon = .customImageWithoutN3(iconImageDisabled)
                titleContent.color = UIColor.ud.textDisable
            }
            if titleContent.text.isEmpty {
                titleContent.text = BundleI18n.Calendar.Calendar_Detail_AddLocation
                titleContent.color = EventEditUIStyle.Color.dynamicGrayText
                accessory = .none
            }
            content = .title(titleContent)
        }
    }
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n3)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .customImage(iconImage)
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        accessory = .type(.close)
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

}
