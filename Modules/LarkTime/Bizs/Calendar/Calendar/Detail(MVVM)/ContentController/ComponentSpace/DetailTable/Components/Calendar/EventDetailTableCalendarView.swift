//
//  EventDetailTableCalendarView.swift
//  Calendar
//
//  Created by Rico on 2021/3/27.
//

import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

protocol EventDetailTableCalendarViewDataType {
    var calendarName: String { get }
    var isResigned: Bool { get }
}

final class EventDetailTableCalendarView: UIView, ViewDataConvertible {
    var viewData: EventDetailTableCalendarViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            titleLabel.text = viewData.calendarName
            titleLabel.tryFitFoFigmaLineHeight()
            resignedTag.isHidden = !viewData.isResigned
        }
    }

    private let resignedTag = TagViewProvider.resignedTagView

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
        }

        addSubview(titleStackView)
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(resignedTag)

        titleStackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(10)
            make.left.equalToSuperview().offset(48)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

    }

    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = UDIcon.getIconByKeyNoLimitSize(.calendarLineOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal)
        return icon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UDColor.textTitle
        label.font = UDFont.body0(.fixed)
        return label
    }()

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()
}
