//
//  DatePickerController.swift
//  LarkDynamic
//
//  Created by Songwen Ding on 2019/7/18.
//

import Foundation
import UIKit
import UniverseDesignPopover
public enum DatePickerType {
    case onlyDate
    case onlyeTime
    case dateTime
}

private final class SwitchBar: UIView {
    public var dateBtnClick: (() -> Void)?
    @objc
    private func dateAction(_ sender: UIButton) {
        dateBtnClick?()
        sender.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        chooseTimeBtn.setTitleColor(UIColor.ud.textTitle, for: .normal)
    }

    public var timeBtnClick: (() -> Void)?
    @objc
    private func timeAction(_ sender: UIButton) {
        timeBtnClick?()
        sender.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        chooseDateBtn.setTitleColor(UIColor.ud.textTitle, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(hSeprater)
        addSubview(vSeprater)
        addSubview(chooseDateBtn)
        addSubview(chooseTimeBtn)
        addSubview(hSeprater2)
    }

    override func updateConstraints() {
        hSeprater.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        vSeprater.snp.remakeConstraints { (make) in
            make.top.bottom.centerX.equalToSuperview()
            make.width.equalTo(0.5)
        }
        chooseDateBtn.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        chooseTimeBtn.snp.remakeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        hSeprater2.snp.remakeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // R模式下不展示日期时间选择器的最下面横线
        var shouldHidden = (self.window?.lkTraitCollection.horizontalSizeClass == .regular)
        hSeprater2.isHidden = shouldHidden
    }

    lazy var chooseDateBtn: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkDatePickerView.Lark_Legacy_ChooseDate, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(dateAction(_:)), for: .touchUpInside)
        return button
    }()

    lazy var chooseTimeBtn: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkDatePickerView.Lark_Legacy_ChooseTime, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.addTarget(self, action: #selector(timeAction(_:)), for: .touchUpInside)
        return button
    }()

    lazy private var hSeprater: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy private var hSeprater2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy private var vSeprater: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

public final class DatePickerController: UIViewController {

    private var type: DatePickerType = .dateTime
    private let transition = DatePickerControllerTransition()
    private var initialDate: String?
    /// 显示popover形式时的视图宽度
    private let popoverWidth: CGFloat
    /// panel容器
    private var panel: UIView?
    public init(initialDate: String?, pickType preferPickType: DatePickerType = .onlyDate, popoverWidth: CGFloat = 375.0) {
        type = preferPickType
        self.initialDate = initialDate
        self.popoverWidth = popoverWidth
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var wraper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private var cancelButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkDatePickerView.Lark_Legacy_MsgCardCancel, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.addTarget(self, action: #selector(cancelAction(_:)), for: .touchUpInside)
        return button
    }()

    private var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: .zero)
        timeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        timeLabel.textColor = UIColor.ud.textTitle
        timeLabel.textAlignment = .center
        return timeLabel
    }()

    private var confirmButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkDatePickerView.Lark_Legacy_MsgCardConfirm, for: .normal)
        button.setTitleColor(UIColor.ud.functionInfoContentDefault, for: .normal)
        button.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)
        return button
    }()

    lazy private var switchBar: SwitchBar = {
        let bar = SwitchBar(frame: .zero)
        bar.dateBtnClick = { [weak self] in
            self?.timePicker.isHidden = true
            self?.datePicker.isHidden = false
        }
        bar.timeBtnClick = { [weak self] in
            self?.timePicker.isHidden = false
            self?.datePicker.isHidden = true
        }
        return bar
    }()

    private var seprater: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private func parseInitDateFormate() -> String {
        if type == .onlyDate {
            return "yyyy-MM-dd"
        } else if type == .onlyeTime {
            return "HH:mm"
        } else {
            return "yyyy-MM-dd HH:mm"
        }
    }

    private lazy var datePicker: DatePickerView = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = parseInitDateFormate()
        dateFormatter.locale = Locale.current
        var date: Date?
        if let dateStr = initialDate {
            date = dateFormatter.date(from: dateStr)
            // 尝试解析添加了时区的时间
            if date == nil {
                dateFormatter.dateFormat = parseInitDateFormate() + " Z"
                date = dateFormatter.date(from: dateStr)
            }
        }
        let picker = DatePickerView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: CGFloat(contentViewHeight)),
                                    selectedDate: date ?? Date())
        picker.delegate = self
        return picker
    }()

    private lazy var timePicker: TimePickerView = {
        var date: Date! = Date()
        if let dateStr = initialDate {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateFormat = parseInitDateFormate()
            date = dateFormatter.date(from: dateStr)
            // 尝试解析添加了时区的时间
            if date == nil {
                dateFormatter.dateFormat = parseInitDateFormate() + " Z"
                date = dateFormatter.date(from: dateStr) ?? Date()
            }
        }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let rect = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: CGFloat(contentViewHeight))
        let picker = TimePickerView(frame: rect, selectedHour: hour, selectedMinute: minute)
        picker.delegate = self
        return picker
    }()

    private var bottomBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private var contentViewHeight: Int {
        switch type {
        case .onlyeTime:
            return 158
        case .onlyDate:
            return 158
        case .dateTime:
            return 158
        }
    }

    private func updateBackgroundColor() {
        var bgColor = UIColor.ud.bgBody
        var config = GradientColorConfig()

        if isInPoperover, UIDevice.current.userInterfaceIdiom == .pad {
            bgColor = UIColor.ud.bgFloat
            config.pickerTopGradient = (bgColor, bgColor.withAlphaComponent(0))
            config.pickerBottomGradient = (bgColor.withAlphaComponent(0), bgColor)
        }
        view.backgroundColor = isInPoperover ? bgColor : .clear
        wraper.backgroundColor = bgColor
        switchBar.backgroundColor = bgColor
        bottomBgView.backgroundColor = bgColor
        datePicker.backgroundColor = bgColor
        timePicker.backgroundColor = bgColor
        datePicker.gradientColorConfig = config
        timePicker.gradientColorConfig = config
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if isInPoperover {
            view.backgroundColor = UIColor.ud.bgBody
        } else {
            view.backgroundColor = .clear
        }
        updateBackgroundColor()
        let panel = UIView()
        view.addSubview(panel)
        panel.addSubview(wraper)
        panel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        /// 记住panel
        self.panel = panel
        wraper.addSubview(cancelButton)
        wraper.addSubview(timeLabel)
        wraper.addSubview(confirmButton)
        wraper.addSubview(seprater)

        let content = UIView(frame: .zero)
        panel.addSubview(content)
        content.addSubview(datePicker)
        content.addSubview(timePicker)
        panel.addSubview(switchBar)
        panel.addSubview(bottomBgView)

        wraper.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(cancelButton)
            make.trailing.equalTo(confirmButton)
            make.top.bottom.equalToSuperview()
        }
        confirmButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        seprater.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        content.snp.makeConstraints { (make) in
            make.top.equalTo(wraper.snp.bottom)
            make.height.equalTo(contentViewHeight)
            make.left.right.equalToSuperview()
        }

        datePicker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        timePicker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        /// 和上面的contentView贴住，和下面的bottomBgView贴住
        switchBar.snp.makeConstraints { (make) in
            make.top.equalTo(content.snp.bottom)
            if type == .dateTime {
                make.height.equalTo(53)
            } else {
                make.height.equalTo(0)
            }
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        /// 刘海屏幕才会有这个view的高度
        bottomBgView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(switchBar.snp.bottom)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelAction(_:)))
        view.addGestureRecognizer(tap)

        if type == .onlyDate {
            timePicker.isHidden = true
            switchBar.isHidden = true
        } else if type == .onlyeTime {
            datePicker.isHidden = true
            switchBar.isHidden = true
        } else {
            timePicker.isHidden = true
            datePicker.isHidden = false
            updateTimeLabel(date: currentDate)
        }

        panel.layoutIfNeeded()
        self.preferredContentSize = CGSize(width: popoverWidth, height: panel.frame.size.height)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.panel?.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
    }

    var dataChanged: ((Date) -> Void)?
    @objc
    private func dateChangedAction(_ datePicker: UIDatePicker) {
        dataChanged?(datePicker.date)
    }

    public var cancel: (() -> Void)?
    @objc
    private func cancelAction(_ sender: UIButton) {
        cancel?()
    }

    public var confirm: ((_ pickType: DatePickerType, _ pickDatetime: Date) -> Void)?
    @objc
    private func confirmAction(_ sender: UIButton) {
        confirm?(type, updateSelectDate())
    }

    public var currentDate: Date {
        return updateSelectDate()
    }
}

// MARK: - same as LarkActionSheet
private final class PresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = UIColor.ud.bgMask
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .dimmed
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = containerView {
            dimmingView.frame = containerView.frame
        }
    }
}

final class DatePickerControllerTransition: NSObject, UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return PresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

extension DatePickerController: DatePickerViewDelegate, TimePickerViewDelegate {

    public func timePickerSelect(_ picker: TimePickerView, didSelectDateTime time: TimePickerDataProtocol) {
        updateTimeLabel(date: updateSelectDate())
    }

    public func datePicker(_ picker: DatePickerView, didSelectDate date: Date) {
        updateTimeLabel(date: updateSelectDate())
    }

    @discardableResult
    func updateSelectDate() -> Date {
        var date: Date?
        date = Date()
        if type == .dateTime {
            date = self.datePicker.currentSelectedDate()
            let time = self.timePicker.currentSelectedTime()
            date = date?.changed(hour: time.hour)?.changed(minute: time.minute)?.changed(second: time.seconds)
        } else if type == .onlyDate {
            date = self.datePicker.currentSelectedDate()
        } else {
            let time = self.timePicker.currentSelectedTime()
            date = date?.changed(hour: time.hour)?.changed(minute: time.minute)?.changed(second: time.seconds)
        }
        return date ?? Date()
    }

    func updateTimeLabel(date: Date) {
        let formatter = DateFormatter()
        if type == .dateTime {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            timeLabel.text = formatter.string(from: date)
        }
    }
}
