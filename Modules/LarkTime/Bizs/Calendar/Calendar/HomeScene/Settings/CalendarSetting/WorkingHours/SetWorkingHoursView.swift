//
//  SetWorkingHoursView.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/16.
//
import UIKit
import RxSwift
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils

protocol SetWorkingHoursViewContent {
    var workHourItems: [DaysOfWeek: SettingModel.WorkHourSpan] { get }
}

final class SetWorkingHoursView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_NewSettings_SetWorkingHoursMobile
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: 16)
        return label
    }()

    private lazy var weekButtons: [WeekButton] = {
        var daysOfWeek = firstWeekday
        var buttons: [WeekButton] = []
        (0..<7).forEach { (_) in
            let button = WeekButton(daysOfWeek: daysOfWeek)
            button.taped = { [unowned self] (isSelected, weekday) in
                self.enableDaysOfWeek?(isSelected, weekday)
            }
            buttons.append(button)
            daysOfWeek = daysOfWeek.next()
        }
        return buttons
    }()

    private lazy var workingHoursItems: [WorkingHoursItem] = {
        var items: [WorkingHoursItem] = []
        var weekday = firstWeekday
        (0..<7).forEach({ (_) in
            let item = WorkingHoursItem(daysOfWeek: weekday)
            item.didSelected = { [weak self] (weekday, span) in
                guard let `self` = self, let span = span else { return }
                self.spanTimeTaped?(weekday, span)
            }
            items.append(item)
            weekday = weekday.next()

        })
        return items
    }()

    var enableDaysOfWeek: ((_ enable: Bool, _ daysOfWeek: DaysOfWeek) -> Void)?
    var spanTimeTaped: ((DaysOfWeek, SettingModel.WorkHourSpan) -> Void)?
    private let firstWeekday: DaysOfWeek
    init(firstWeekday: DaysOfWeek) {
        self.firstWeekday = firstWeekday
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgFloat
        layoutTitleLabel(titleLabel)
        let buttonStackView = UIStackView()
        layoutWeekButtons(weekButtons, stackView: buttonStackView, topView: titleLabel)
        let itemsStackView = UIStackView()
        layoutWorkHourItems(workingHoursItems,
                            stackView: itemsStackView,
                            topView: buttonStackView)
    }

    private func layoutTitleLabel(_ titleLabel: UILabel) {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(16)
        }
    }

    func setContent(_ content: SetWorkingHoursViewContent, is12HourStyle: Bool) {
        weekButtons.forEach({ (button) in
            if content.workHourItems[button.daysOfWeek] != nil {
                button.isSelected = true
            } else {
                button.isSelected = false
            }
        })

        workingHoursItems.forEach { (item) in
            if let span = content.workHourItems[item.daysOfWeek] {
                item.isHidden = false
                item.setupContent(content: WorkingHoursItemContent(span: span, is12HourStyle: is12HourStyle))
            } else {
                item.isHidden = true
            }
        }
    }

    private func layoutWeekButtons(_ weekButtons: [WeekButton],
                                   stackView: UIStackView,
                                   topView: UIView) {
        addSubview(stackView)
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        weekButtons.forEach { (button) in
            button.snp.makeConstraints({ (make) in
                make.width.height.equalTo(40)
            })
            stackView.addArrangedSubview(button)
        }
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(topView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        stackView.addBottomBorder()
    }

    private func layoutWorkHourItems(_ workingHoursItems: [WorkingHoursItem],
                                     stackView: UIStackView,
                                     topView: UIView) {
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topView.snp.bottom)
        }
        workingHoursItems.forEach { (item) in
            stackView.addArrangedSubview(item)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class WeekButton: UIButton {
    let daysOfWeek: DaysOfWeek
    var taped: ((Bool, DaysOfWeek) -> Void)?
    init(daysOfWeek: DaysOfWeek) {
        self.daysOfWeek = daysOfWeek
        super.init(frame: .zero)
        titleLabel?.font = UIFont.cd.regularFont(ofSize: 12)
        setTitle(TimeFormatUtils.weekdayShortString(weekday: daysOfWeek.rawValue), for: .normal)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .selected)
        addTarget(self, action: #selector(buttonTaped), for: .touchUpInside)
    }

    @objc
    private func buttonTaped() {
        self.isSelected = !self.isSelected
        taped?(isSelected, daysOfWeek)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2.0
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = 0.0
                backgroundColor = UIColor.ud.primaryContentDefault
            } else {
                layer.borderWidth = 1.0
                backgroundColor = UIColor.ud.bgBody
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            super.isHighlighted = false
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WorkingHoursItemContent {
    let span: SettingModel.WorkHourSpan
    var text: String {
        let startDate = Date(timeIntervalSince1970: TimeInterval(span.startMinute * 60))
        let endDate = Date(timeIntervalSince1970: TimeInterval(span.endMinute * 60))

        // 使用 UTC 时区，默认用当前时区兜底
        let customOptions = Options(
            timeZone: TimeZone(abbreviation: "UTC") ?? TimeZone.current,
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute
        )

        return TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: customOptions)
    }
    private let is12HourStyle: Bool
    init(span: SettingModel.WorkHourSpan, is12HourStyle: Bool) {
        self.span = span
        self.is12HourStyle = is12HourStyle
    }
}

private final class WorkingHoursItem: HighlightableView {
    let daysOfWeek: DaysOfWeek
    private var span: SettingModel.WorkHourSpan?
    private let weekLabel: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 16)
        label.textColor = UIColor.ud.primaryContentDefault
        return label
    }()

    var didSelected: ((DaysOfWeek, SettingModel.WorkHourSpan?) -> Void)?
    init(daysOfWeek: DaysOfWeek) {
        self.daysOfWeek = daysOfWeek
        super.init(frame: .zero)
        addSubview(weekLabel)
        weekLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        weekLabel.text = TimeFormatUtils.weekdayFullString(weekday: daysOfWeek.rawValue)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(taped))
        addGestureRecognizer(tapGesture)
    }

    @objc
    private func taped() {
        didSelected?(daysOfWeek, span)
    }

    func setupContent(content: WorkingHoursItemContent) {
        self.span = content.span
        timeLabel.text = content.text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 46
        return size
    }
}
