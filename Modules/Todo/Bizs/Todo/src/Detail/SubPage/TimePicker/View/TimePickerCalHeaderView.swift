//
//  TimePickerCalHeaderView.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/12.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

final class TimePickerCalHeaderView: UIView {

    var previousHandler: (() -> Void)?

    var nextHandler: (() -> Void)?

    var date: Date {
        didSet {
            yearMonthLabel.text = formatter.string(from: date)
        }
    }

    private lazy var previousBtn: UIButton = {
        let btn = UIButton()
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.setImage(UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        btn.addTarget(self, action: #selector(onPreviousClick), for: .touchUpInside)
        return btn
    }()

    private lazy var nextBtn: UIButton = {
        let btn = UIButton()
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.setImage(UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        btn.addTarget(self, action: #selector(onNextClick), for: .touchUpInside)
        return btn
    }()

    private lazy var yearMonthLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.monospacedDigitSystemFont(ofSize: 26, weight: .medium)
        label.numberOfLines = 1
        label.text = formatter.string(from: date)
        return label
    }()

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy.MM"
        return formatter
    }()

    private let calendar: Calendar

    init(date: Date, calendar: Calendar) {
        self.calendar = calendar
        self.date = date
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(yearMonthLabel)
        addSubview(previousBtn)
        addSubview(nextBtn)

        nextBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-21)
            $0.width.height.equalTo(18)
        }

        previousBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalTo(nextBtn.snp.left).offset(-44)
            $0.width.height.equalTo(18)
        }

        yearMonthLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.lessThanOrEqualTo(previousBtn.snp.left).offset(-16)
            $0.left.equalToSuperview().offset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onPreviousClick() {
        previousHandler?()
    }

    @objc
    private func onNextClick() {
        nextHandler?()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 60)
    }
}
