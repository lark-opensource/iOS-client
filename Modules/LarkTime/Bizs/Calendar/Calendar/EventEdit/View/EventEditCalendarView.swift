//
//  EventEditCalendarView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import CalendarFoundation
import UIKit

enum EventEditCalendarFlagType {
    case resigned // 离职日历
    case external // 外部租户日历
    case threeParty(UIImage) // exchange、google
}

protocol EventEditCalendarViewDataType {
    var title: String { get }
    var subtitle: String? { get }
    var flag: [EventEditCalendarFlagType]? { get }
    var color: UIColor { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
}

final class EventEditCalendarView: EventEditCellLikeView, ViewDataConvertible {

    var clickHandler: (() -> Void)? {
        didSet {
            onClick = clickHandler
        }
    }

    var viewData: EventEditCalendarViewDataType? {
        didSet {
            // icon
            let color = viewData?.color ?? UIColor.ud.iconN3
            let image = calendarIcon.ud.withTintColor(color)

            icon = .customImageWithoutN3(image)
            iconSize = EventEditUIStyle.Layout.cellLeftIconSize
            // title
            titleLabel.text = viewData?.title
            // subtitle
            subtitleLabel.text = viewData?.subtitle
            let hideSubtitle = subtitleLabel.text?.isEmpty ?? true
            let subtitleHiddenChanged = hideSubtitle != subtitleLabel.isHidden
            subtitleLabel.isHidden = hideSubtitle

            flagView.isHidden = true
            resignedView.isHidden = true
            externalView.isHidden = true

            viewData?.flag?.forEach({ item in
                switch item {
                case .threeParty(let image):
                    flagView.image = image.withRenderingMode(.alwaysOriginal)
                    flagView.isHidden = false
                case .external:
                    externalView.isHidden = false
                case .resigned:
                    resignedView.isHidden = false
                }
            })

            isHidden = !(viewData?.isVisible ?? false)
            titleLabel.snp.updateConstraints {
                $0.width.lessThanOrEqualToSuperview().offset(flagView.isHidden ? 0 : -18)
                $0.top.equalToSuperview().offset(!subtitleLabel.isHidden ? 13 : 15)
            }
            if subtitleHiddenChanged {
                invalidateIntrinsicContentSize()
            }
            if let isEditable = viewData?.isEditable, isEditable {
                titleLabel.textColor = UIColor.ud.textTitle
                subtitleLabel.textColor = UIColor.ud.textTitle
                accessory = .type(.next())
                isUserInteractionEnabled = true
            } else {
                titleLabel.textColor = UIColor.ud.textDisable
                subtitleLabel.textColor = UIColor.ud.textDisable
                accessory = .type(.next(.n4))
                isUserInteractionEnabled = false
            }
        }
    }

    private let calendarIcon = UDIcon.getIconByKeyNoLimitSize(.calendarOutlined)
    private let contentWrapperView = UIView()
    private let titleLabel = UILabel()
    private let flagView = UIImageView()
    private let subtitleLabel = UILabel()
    private let externalView = TagViewProvider.externalNormal
    private let resignedView = TagViewProvider.resignedTagView

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessory = .type(.next())
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        contentWrapperView.isUserInteractionEnabled = false
        content = .customView(contentWrapperView)

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        contentWrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.height.equalTo(22)
            $0.top.equalToSuperview().offset(15)
            $0.width.lessThanOrEqualToSuperview()
        }

        let tagStackView = UIStackView(arrangedSubviews: [externalView, resignedView])
        tagStackView.axis = .horizontal
        tagStackView.spacing = 6
        contentWrapperView.addSubview(tagStackView)
        tagStackView.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.left.equalTo(titleLabel.snp.right).offset(6)
            $0.right.lessThanOrEqualToSuperview().offset(-6)
        }
        externalView.isHidden = true
        resignedView.isHidden = true

        flagView.isHidden = true
        contentWrapperView.addSubview(flagView)
        flagView.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.left.equalTo(titleLabel.snp.right).offset(6)
            $0.width.height.equalTo(12)
        }

        subtitleLabel.isHidden = true
        subtitleLabel.textColor = UIColor.ud.textPlaceholder
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        contentWrapperView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.left.equalTo(titleLabel)
            $0.height.equalTo(20)
            $0.bottom.equalToSuperview().offset(-13)
            $0.width.lessThanOrEqualToSuperview()
        }

        iconAlignment = .centerYEqualTo(refView: titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: subtitleLabel.isHidden ? EventEditUIStyle.Layout.singleLineCellHeight : 68)
    }

}
