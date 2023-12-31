//
//  EventEditCheckInfoView.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/8.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

protocol EventEditCheckInViewDataType {
    var title: String { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
    var isValid: Bool { get }
    var errorText: String { get }
}

final class EventEditCheckInView: EventEditCellLikeView, ViewDataConvertible {

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

    var viewData: EventEditCheckInViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)
            titleLabel.text = "\(viewData?.title ?? "")"

            if let isEditable = viewData?.isEditable, isEditable {
                accessory = .type(.next())
                titleLabel.textColor = UDColor.textTitle
                isUserInteractionEnabled = true
                icon = .customImage(iconImage)
            } else {
                accessory = .type(.next(.n4))
                icon = .customImageWithoutN3(iconImageDisabled)
                titleLabel.textColor = UDColor.textDisabled
                isUserInteractionEnabled = false
            }

            if let isValid = viewData?.isValid,
               let error = viewData?.errorText,
               !error.isEmpty && !isValid {
                errorView.isHidden = false
                errorView.text = error
            } else {
                errorView.isHidden = true
            }
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body0
        label.textColor = UDColor.textTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let errorView: UILabel = {
        let label = UILabel()
        label.font = UDFont.body0
        label.textColor = UDColor.functionDangerContentDefault
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.checkInOutlined).renderColor(with: .n3)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.checkInOutlined).renderColor(with: .n4)


    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .customImage(iconImage)
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize

        let stackView = UIStackView(arrangedSubviews: [titleLabel, errorView])
        stackView.axis = .vertical
        stackView.spacing = 12

        let containerView = UIView()
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.right.equalToSuperview()
        }

        content = .customView(containerView)
        iconAlignment = .centerYEqualTo(refView: titleLabel)
        accessoryAlignment = .centerYEqualTo(refView: titleLabel)
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }
}
