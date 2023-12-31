//
//  DCWheelPickerViewController.swift
//  Todo
//
//  Created by baiyantao on 2023/5/17.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignDatePicker

// copy 自 UDDateWheelPickerViewController
// 看这个组件的代码行数不多，直接 copy 了一份出来改造；后面等他们设计出更合适的 API 以后，任务再接入
// 主要需求点为，左上按钮的定制，以及标题的限宽
// nolint: duplicated code
final class DCWheelPickerViewController: UIViewController {

    let titleBar = UIView()
    let customTitle: String?
    var dateWheelPicker: UDDateWheelPickerView
    private lazy var divideLine = UIView()

    var selectedDate: Date?
    public var confirm: ((_ pickedDate: Date) -> Void)?
    public var onClear: (() -> Void)?

    public init(customTitle: String,
                date: Date = Date(),
                timeZone: TimeZone = TimeZone.current,
                wheelConfig: UDWheelsStyleConfig = UDWheelsStyleConfig(maxDisplayRows: 3)) {
        self.customTitle = customTitle
        self.dateWheelPicker = UDDateWheelPickerView(
            date: date,
            timeZone: timeZone,
            maximumDate: UDWheelsStyleConfig.defaultMaxDate,
            minimumDate: UDWheelsStyleConfig.defaultMinDate,
            wheelConfig: wheelConfig
        )
        super.init(nibName: nil, bundle: nil)
        selectedDate = date
        dateWheelPicker.dateChanged = { [weak self] (selectedDate) in
            self?.selectedDate = selectedDate
        }
        titleBar.backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        titleBar.layer.cornerRadius = 6
        titleBar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        divideLine.backgroundColor = UDDatePickerTheme.calendarPickerCurrentMonthBgColor
        dateWheelPicker.layer.cornerRadius = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 实际高度
    public var intrinsicHeight: CGFloat {
        Cons.titleBarHeight + dateWheelPicker.intrinsicHeight
    }

    /// 选中参数 date 所对应时刻
    public func select(date: Date = Date()) {
        dateWheelPicker.select(date: date)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        layoutTitleBar()
    }

    private func layoutTitleBar() {
        let cancelButton = UIButton()
        let titleLabel = UILabel()
        let completeButton = UIButton()

        titleBar.addSubview(cancelButton)
        titleBar.addSubview(titleLabel)
        titleBar.addSubview(completeButton)
        titleBar.addSubview(divideLine)
        view.addSubview(dateWheelPicker)
        view.addSubview(titleBar)

        cancelButton.titleLabel?.font = UDFont.body0
        cancelButton.setTitle(I18N.Todo_TimePicker_Clear_Button, for: .normal)
        cancelButton.setTitleColor(UDDatePickerTheme.wheelPickerBtnPrimaryTextNormalColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelAction(_:)), for: .touchUpInside)

        titleLabel.text = customTitle
        titleLabel.font = UDFont.body0
        titleLabel.textColor = UDDatePickerTheme.wheelPickerTitlePrimaryNormalColor
        titleLabel.textAlignment = .center

        completeButton.titleLabel?.font = UIFont.ud.body0
        completeButton.setTitle(I18N.Todo_Task_Confirm, for: .normal)
        completeButton.setTitleColor(UDDatePickerTheme.wheelPickerBtnPrimaryTextNormalColor, for: .normal)
        completeButton.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)

        let cancelButtonWidth = cancelButton.titleLabel?.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        ).width ?? 0
        cancelButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(cancelButtonWidth + 1)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(cancelButton.snp.trailing).offset(16)
            make.trailing.equalTo(completeButton.snp.leading).offset(-16)
        }
        let completeButtonWidth = completeButton.titleLabel?.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        ).width ?? 0
        completeButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(completeButtonWidth + 1)
        }

        dateWheelPicker.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
        }

        titleBar.snp.makeConstraints { (make) in
            make.height.equalTo(Cons.titleBarHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(dateWheelPicker.snp.top)
        }

        divideLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    private enum Cons {
        static let titleBarHeight: CGFloat = 54
    }

    @objc
    private func cancelAction(_ sender: UIButton) {
        onClear?()
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func confirmAction(_ sender: UIButton) {
        guard let selectedDate = selectedDate else { return }
        self.confirm?(selectedDate)
    }
}
