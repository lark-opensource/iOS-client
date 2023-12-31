//
//  EventEditArrangeDateView.swift
//  Calendar
//
//  Created by 张威 on 2020/3/9.
//

import UIKit
import SnapKit

protocol EventEditArrangeDateViewDataType {
    var isVisible: Bool { get }
}

final class EventEditArrangeDateView: EventEditCellLikeView, ViewDataConvertible {

    var viewData: EventEditArrangeDateViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)
        }
    }

    var clickHandler: (() -> Void)? {
        didSet { onClick = clickHandler }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = EventEditUIStyle.Color.cellBackground
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        icon = .empty
        let titleContent = ContentTitle(
            text: BundleI18n.Calendar.Calendar_Edit_FindTime,
            color: UIColor.ud.primaryContentDefault
        )
        content = .title(titleContent)
        contentInset = EventEditUIStyle.Layout.contentLeftPadding
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: 30)
    }

}
