//
//  UDDateWheelPickerViewController.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/12/6.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignFont
import UniverseDesignColor

public final class UDDateWheelPickerViewController: UIViewController {

    let titleBar = UIView()
    let customTitle: String?
    var dateWheelPicker: UDDateWheelPickerView
    private lazy var divideLine = UIView()

    var selectedDate: Date?
    public var confirm: ((_ pickedDate: Date) -> Void)?

    public init(customTitle: String,
                date: Date = Date(),
                maximumDate: Date = UDWheelsStyleConfig.defaultMaxDate,
                minimumDate: Date = UDWheelsStyleConfig.defaultMinDate,
                timeZone: TimeZone = TimeZone.current,
                wheelConfig: UDWheelsStyleConfig = UDWheelsStyleConfig(maxDisplayRows: 3)) {
        self.customTitle = customTitle
        self.dateWheelPicker = UDDateWheelPickerView(date: date,
                                                     timeZone: timeZone,
                                                     maximumDate: maximumDate, minimumDate: minimumDate,
                                                     wheelConfig: wheelConfig)
        super.init(nibName: nil, bundle: nil)
        selectedDate = date
        dateWheelPicker.dateChanged = { [weak self] (selectedDate) in
            guard let self = self else { return }
            self.selectedDate = selectedDate
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
        cancelButton.setTitle(BundleI18n.UniverseDesignDatePicker.Calendar_Common_Cancel, for: .normal)
        cancelButton.setTitleColor(UDDatePickerTheme.wheelPickerBtnSeconTextNormalColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelAction(_:)), for: .touchUpInside)

        titleLabel.text = customTitle
        titleLabel.font = UDFont.body0
        titleLabel.textColor = UDDatePickerTheme.wheelPickerTitlePrimaryNormalColor
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)

        completeButton.titleLabel?.font = UIFont.ud.body0
        completeButton.setTitle(BundleI18n.UniverseDesignDatePicker.Calendar_Common_Confirm, for: .normal)
        completeButton.setTitleColor(UDDatePickerTheme.wheelPickerBtnPrimaryTextNormalColor, for: .normal)
        completeButton.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)

        cancelButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.leading.equalTo(cancelButton.snp.trailing).offset(16)
            make.trailing.equalTo(completeButton.snp.leading).offset(-16)
        }
        completeButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
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
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func confirmAction(_ sender: UIButton) {
        guard let selectedDate = selectedDate else { return }
        self.confirm?(selectedDate)
    }
}
