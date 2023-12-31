//
//  ArrangementNavigationBar.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/25.
//
import UniverseDesignIcon
import UIKit
import SnapKit
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils
import LarkUIKit
import LarkInteraction
import UniverseDesignDatePicker

final class ArrangementNavigationBar: UIView {

    private var date: Date {
        didSet {
            setTitleLabel(date: date)
            didSelectDate?(date)
        }
    }
    private let leftButton: UIButton

    private lazy var chooseGroupMemberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.personAdmitOutlined).scaleNaviSize().renderColor(with: .n1).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(chooseTap), for: .touchUpInside)
        return button
    }()

    private let wrapper = UIView()
    private let titleLabel = UILabel.cd.titleLabel(fontSize: 17)
    private let iconView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.expandDownFilled).renderColor(with: .n1))
    private var arrangementDatePicker: UDDateCalendarPickerView
    // 固定高度
    private static let DatePickerHeight: CGFloat = 272
    private var topConstraint: NSLayoutConstraint?
    var closeHandle: (() -> Void)?
    var didSelectDate: ((Date) -> Void)?
    var choosenGroupMemberHandle: (() -> Void)?
    var stateChangeHandle: ((_ isExpand: Bool) -> Void)?
    private var uiCurrentDate = Date()
    private let firstWeekday: DaysOfWeek
    private var timeZone: TimeZone = .current

    // showCancelLeft: 左边按钮文案为「取消」- true；「X」- false
    init(date: Date, firstWeekday: DaysOfWeek, showChooseButton: Bool = false, showCancelLeft: Bool = false) {
        self.date = date
        self.firstWeekday = firstWeekday
        self.arrangementDatePicker = UDDateCalendarPickerView(
            date: date,
            calendarConfig: .init(firstWeekday: .from(daysOfweek: firstWeekday))
        )
        let buttonItem: LKBarButtonItem
        if showCancelLeft {
            buttonItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
            buttonItem.setBtnColor(color: UIColor.ud.textTitle)
        } else {
            buttonItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeOutlined)
                                            .scaleNaviSize()
                                            .renderColor(with: .n1)
                                            .withRenderingMode(.alwaysOriginal))
        }
        leftButton = buttonItem.button
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        wrapper.backgroundColor = UIColor.ud.bgBody
        addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        let titleViewWrapper = UIView()
        layoutTitleView(wrapper: titleViewWrapper,
                        superView: wrapper,
                        titleLabel: titleLabel,
                        imageView: iconView)
        if Display.pad {
            layoutCloseButton(leftButton, superView: wrapper, centerYView: titleLabel)
        } else {
            layoutCloseButton(leftButton, superView: wrapper, centerYView: titleViewWrapper)
        }

        if showChooseButton {
            if Display.pad {
                layoutChooseButton(chooseGroupMemberButton, superView: wrapper, centerYView: titleLabel)
            } else {
                layoutChooseButton(chooseGroupMemberButton, superView: wrapper, centerYView: titleViewWrapper)
            }
        }
        setupTapGesture(tapView: UIView(), leftView: leftButton, upView: titleViewWrapper)
        setTitleLabel(date: date)
        setupDatePicker(arrangementDatePicker, upView: wrapper)
    }

    func setupTapGesture(tapView: UIView, leftView: UIView, upView: UIView) {
        addSubview(tapView)
        tapView.snp.makeConstraints { (make) in
            make.left.equalTo(leftView.snp.right).offset(20)
            make.height.top.equalTo(upView)
            make.right.equalToSuperview().offset(-40)
        }
        addTapGesture(wrapper: tapView)
    }

    func changeDate(date: Date) {
        arrangementDatePicker.select(date: date)
    }
    // 时区变更 刷新 picker 及 title
    func updateCurrentUiDate(uiDate: Date, timeZone: TimeZone) {
        guard timeZone != self.timeZone else { return }
        let sameDayWhenTZChanged = TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: self.timeZone.identifier, destTzId: timeZone.identifier)
        uiCurrentDate = uiDate
        self.timeZone = timeZone
        self.date = sameDayWhenTZChanged
        arrangementDatePicker = UDDateCalendarPickerView(
            date: sameDayWhenTZChanged,
            calendarConfig: .init(firstWeekday: .from(daysOfweek: firstWeekday))
        )
        setupDatePicker(arrangementDatePicker, upView: wrapper)
    }

    private func setupDatePicker(_ datePick: UDDateCalendarPickerView, upView: UIView) {
        insertSubview(datePick, at: 0)
        topConstraint = datePick.topAnchor.constraint(equalTo: upView.bottomAnchor, constant: -Self.DatePickerHeight)
        topConstraint?.isActive = true
        datePick.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        datePick.isHidden = true
        datePick.delegate = self
        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(panGesture(sender:)))
        datePick.addGestureRecognizer(pan)
    }

    @objc
    private func panGesture(sender: UIPanGestureRecognizer) {
        superview?.layoutIfNeeded()
        superview?.setNeedsLayout()

        let velocity = sender.velocity(in: arrangementDatePicker)
        let point = sender.translation(in: arrangementDatePicker)
        sender.setTranslation(CGPoint.zero, in: arrangementDatePicker)
        if sender.state == .changed {
            if topConstraint?.constant ?? 0 + point.y >= 0 && velocity.y > 0 {
                topConstraint?.constant = 0
                return
            }
            topConstraint?.constant += point.y
        }

        if sender.state == .ended {
            if velocity.y < 0 {
                hideDatePicker()
                self.setIconExpand(isExpand: false)
                CalendarTracer.shareInstance.calCalWidgetOperation(actionSource: .profile,
                                                                   actionTargetStatus: .close)
            } else {
                showDatePicker()
                CalendarTracer.shareInstance.calCalWidgetOperation(actionSource: .profile,
                                                                   actionTargetStatus: .open)
                self.setIconExpand(isExpand: true)
            }
        }
    }

    private func addTapGesture(wrapper: UIView) {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(titleTaped))
        wrapper.addGestureRecognizer(tap)
    }

    @objc
    private func titleTaped() {
        if !isExpand() {
            showDatePicker()
        } else {
            hideDatePicker()
        }
        setIconExpand(isExpand: !isExpand())
    }

    private func setIconExpand(isExpand: Bool) {
        UIView.animate(withDuration: 0.15) {
            if isExpand {
                self.iconView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                self.iconView.transform = CGAffineTransform.identity
            }
        }
    }

    func closeDatePicker() {
        hideDatePicker()
        setIconExpand(isExpand: false)
    }

    private func hideDatePicker() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.topConstraint?.constant = -Self.DatePickerHeight
                self.superview?.layoutIfNeeded()
            }) { _ in
                self.arrangementDatePicker.isHidden = true
                self.stateChangeHandle?(false)
        }
    }

    private func showDatePicker() {
        arrangementDatePicker.isHidden = false
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.topConstraint?.constant = 0
                self.superview?.layoutIfNeeded()
            }) { (_) in
                self.stateChangeHandle?(true)
        }
    }

    private func isExpand() -> Bool {
        return !iconView.transform.isIdentity
    }

    private func setTitleLabel(date: Date, with timeZone: TimeZone = .current) {
        titleLabel.text = getTimeText(date: date, with: timeZone)
    }

    private func getTimeText(date: Date, with timeZone: TimeZone) -> String {
        // 使用设备时区
        let customOptions = Options(
            timeZone: timeZone,
            is12HourStyle: false,
            datePrecisionType: .day,
            dateStatusType: .absolute
        )

        return CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: date,
            endAt: date.dayEnd(),
            accordingTo: uiCurrentDate,
            isAllDayEvent: true,
            with: customOptions
        )
    }

    private func layoutTitleView(wrapper: UIView,
                                 superView: UIView,
                                 titleLabel: UILabel,
                                 imageView: UIImageView) {
        superView.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(44)
            make.bottom.centerX.equalToSuperview()
        }
        wrapper.addSubview(titleLabel)
        wrapper.addSubview(imageView)

        if Display.pad {
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.top.equalToSuperview().offset(16)
            }
            imageView.snp.makeConstraints { (make) in
                make.left.equalTo(titleLabel.snp.right).offset(4)
                make.centerY.equalTo(titleLabel.snp.centerY)
                make.right.equalToSuperview()
                make.width.height.equalTo(12)
            }
        } else {
            titleLabel.snp.makeConstraints { (make) in
                make.left.centerY.equalToSuperview()
            }
            imageView.snp.makeConstraints { (make) in
                make.left.equalTo(titleLabel.snp.right).offset(4)
                make.right.centerY.equalToSuperview()
                make.width.height.equalTo(12)
            }
        }
    }

    private func layoutCloseButton(_ closeButton: UIButton,
                                   superView: UIView,
                                   centerYView: UIView) {
        superView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(centerYView)
            make.left.equalToSuperview().offset(12)
        }
        closeButton.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
        // iPad button highlight
        if #available(iOS 13.4, *) {
            closeButton.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 36), 8)
                }))
        }
    }

    private func layoutChooseButton(_ chooseButton: UIButton,
                                    superView: UIView,
                                    centerYView: UIView) {

        superView.addSubview(chooseButton)
        chooseButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(centerYView)
            make.right.equalToSuperview().offset(-12)
            make.height.width.equalTo(24)
        }
        // iPad button highlight
        if #available(iOS 13.4, *) {
            chooseButton.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 36), 8)
                }))
        }
    }

    @objc
    private func closeTap() {
        closeHandle?()
    }

    @objc
    private func chooseTap() {
        choosenGroupMemberHandle?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ArrangementNavigationBar: UDDatePickerViewDelegate {
    func dateChanged(_ date: Date, _ sender: UDDateCalendarPickerView) {
        self.date = date
        closeDatePicker()
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("select_date")
            $0.mergeEventCommonParams(commonParam: CommonParamData())
        }
    }
}
