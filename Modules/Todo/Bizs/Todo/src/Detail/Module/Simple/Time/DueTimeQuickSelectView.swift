//
//  DueTimeQuickSelectView.swift
//  Todo
//
//  Created by baiyantao on 2022/12/15.
//

import Foundation
import LarkContainer
import UniverseDesignIcon
import UniverseDesignFont

final class DueTimeQuickSelectView: UIView {
    var quickTodayHandler: (() -> Void)?
    var quickTomorrowHandler: (() -> Void)?
    var otherTimeHandler: (() -> Void)?

    private lazy var scrollView = initScrollView()
    private lazy var stackView = initStackView()

    private lazy var todayCell = initTodayCell()
    private lazy var tomorrowCell = initTomorrowCell()
    private lazy var otherTimeCell = initOtherTimeCell()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.left.right.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.centerY.equalToSuperview()
        }

        stackView.addArrangedSubview(todayCell)
        stackView.addArrangedSubview(tomorrowCell)
        stackView.addArrangedSubview(otherTimeCell)
        // 加一个空 view，让 stackView 滑动到最右边的时候能有个 spacing
        stackView.addArrangedSubview(UIView())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }

    private func initStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.backgroundColor = UIColor.ud.bgBody
        return stackView
    }

    private func initTodayCell() -> QuickSelectCell {
        let icon = UDIcon.getIconByKey(
            UDIconType.calendarDateOutlined(timeZone: .current),
            iconColor: UIColor.ud.primaryContentDefault,
            size: CGSize(width: 20, height: 20)
        )
        let cell = QuickSelectCell(icon: icon, title: I18N.Todo_Common_Today)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTodayClick))
        cell.addGestureRecognizer(tap)
        return cell
    }

    private func initTomorrowCell() -> QuickSelectCell {
        let icon = UDIcon.calendarTomorrowOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.colorfulTurquoise)
        let cell = QuickSelectCell(icon: icon, title: I18N.Todo_Common_Tomorrow)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTomorrowClick))
        cell.addGestureRecognizer(tap)
        return cell
    }

    private func initOtherTimeCell() -> QuickSelectCell {
        let icon = UDIcon.calendarDateOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.iconN2)
        let cell = QuickSelectCell(icon: icon, title: I18N.Todo_Common_OtherTime)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOtherTimeClick))
        cell.addGestureRecognizer(tap)
        return cell
    }

    @objc private func onTodayClick() {
        quickTodayHandler?()
    }

    @objc private func onTomorrowClick() {
        quickTomorrowHandler?()
    }

    @objc private func onOtherTimeClick() {
        otherTimeHandler?()
    }
}

private class QuickSelectCell: UIView {
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = initTitleLabel()

    init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 8
        layer.masksToBounds = true
        iconView.image = icon
        titleLabel.text = title

        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
                .inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 0))
            $0.width.height.equalTo(20)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.left.equalTo(iconView.snp.right).offset(4)
            $0.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }
}
