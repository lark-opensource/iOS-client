//
//  EventEditGuestPermissionView.swift
//  Calendar
//
//  Created by ByteDance on 2023/3/1.
//

import UIKit
import Foundation

protocol EventEditGuestPermissionViewDataType {
    var title: String { get }
    var subtitle: String { get }
    var isVisible: Bool { get }
}

final class EventEditGuestPermissionView: EventEditCellLikeView, ViewDataConvertible {
    let titleLabel = UILabel()
    let tailLabel = UILabel()

    var viewData: EventEditGuestPermissionViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)
            guard let viewData = viewData else {
                return
            }
            titleLabel.text = viewData.title
            tailLabel.text = viewData.subtitle
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessory = .type(.next())
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        content = .customView(titleContentView())
        contentInset = EventEditUIStyle.Layout.contentLeftPadding
        icon = .empty
    }

    private func titleContentView() -> UIView {
        let titleContentView = UIView()
        titleLabel.font = UIFont.cd.regularFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .byTruncatingTail

        tailLabel.font = UIFont.cd.regularFont(ofSize: 14)
        tailLabel.textColor = EventEditUIStyle.Color.dynamicGrayText
        tailLabel.textAlignment = .right
        tailLabel.numberOfLines = 3
        tailLabel.lineBreakMode = .byTruncatingTail

        titleContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.left.equalToSuperview()
        }
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        titleContentView.addSubview(tailLabel)
        tailLabel.snp.makeConstraints {
            $0.centerY.right.equalToSuperview()
            $0.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(12)
            $0.width.greaterThanOrEqualTo(86)
            $0.height.lessThanOrEqualTo(titleLabel.snp.height)
        }

        titleContentView.isUserInteractionEnabled = false
        return titleContentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }
}
