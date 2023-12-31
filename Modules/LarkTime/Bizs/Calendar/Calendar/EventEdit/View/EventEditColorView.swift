//
//  EventEditColorView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UIKit
import SnapKit

protocol EventEditColorViewDataType {
    var color: UIColor { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
}

final class EventEditColorView: EventEditCellLikeView, ViewDataConvertible {

    private let title = BundleI18n.Calendar.Calendar_Edit_EventColor
    var clickHandler: (() -> Void)? {
        didSet { onClick = clickHandler }
    }

    var viewData: EventEditColorViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)

            let colorImage = UIImage.cd.image(
                withColor: viewData?.color ?? .clear,
                size: CGSize(width: 16, height: 16),
                cornerRadius: 4
            )
            icon = .customImageWithoutN3(colorImage)
            var titleContent = ContentTitle(text: title)
            if let isEditable = viewData?.isEditable, isEditable {
                isUserInteractionEnabled = true
                accessory = .type(.next())
                titleContent.color = UIColor.ud.textTitle
            } else {
                accessory = .type(.next(.n4))
                titleContent.color = UIColor.ud.textDisabled
            }
            content = .title(titleContent)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        iconSize = CGSize(width: 16, height: 16)
        contentInset = EventEditUIStyle.Layout.contentLeftPadding
        iconLeftOffset = 17
        iconAlignment = .centerVertically
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

}
