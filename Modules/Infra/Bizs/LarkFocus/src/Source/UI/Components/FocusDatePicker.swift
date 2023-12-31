//
//  FocusDatePicker.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/6.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction
import UniverseDesignToast
import UniverseDesignPopover
import UniverseDesignDatePicker
import UniverseDesignActionPanel
import LarkContainer
import LarkSDKInterface

final class FocusDatePickerController: UIViewController, UserResolverWrapper {

    let userResolver: UserResolver
    @ScopedInjectedLazy private var focusManager: FocusManager?


    @ScopedInjectedLazy
    var userSettings: UserGeneralSettings?
    /// 当前是否为 24 小时制
    var is24Hour: Bool {
        return userSettings?.is24HourTime.value ?? false
    }

    var onConfirm: ((Date) -> Void)?
    var onCancel: (() -> Void)?
    var selectedDate: Date = Date().futureHour

    @objc
    private func didTapConfirmButton(_ sender: UIButton) {
        guard selectedDate > Date() else {
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_LastTimeDesc, on: self.view)
            return
        }
        onConfirm?(selectedDate)
        dismiss(animated: true)
    }

    @objc
    private func didTapCancelButton(_ sender: UIButton) {
        onCancel?()
        dismiss(animated: true)
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if contentView.frame.contains(location) {
            return
        }
        onCancel?()
        dismiss(animated: true)
    }

    private var popoverTransition = UDPopoverTransition(sourceView: nil)

    private lazy var pickerView: UDDateWheelPickerView = {
        let config = UDWheelsStyleConfig(
            mode: .dayHourMinute(),
            maxDisplayRows: 5,
            is12Hour: !(focusManager?.is24Hour ?? false),
            showSepeLine: true,
            minInterval: 5
        )
        let picker = UDDateWheelPickerView(
            date: selectedDate,
            minimumDate: Date(),
            wheelConfig: config
        )
        picker.select(date: selectedDate)
        return picker
    }()

    private lazy var dividingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineBorderCard
        return line
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var titleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkFocus.Lark_Profile_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(didTapCancelButton(_:)), for: .touchUpInside)
        return button
    }()

    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkFocus.Lark_Profile_Enable, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(didTapConfirmButton(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.text = BundleI18n.LarkFocus.Lark_Profile_SetTime_EndingTime
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    init(userResolver: UserResolver, sourceView: UIView) {
        self.userResolver = userResolver
        popoverTransition = UDPopoverTransition(
            sourceView: sourceView,
            sourceRect: sourceView.frame.inset(by: UIEdgeInsets(edges: -10)),
            permittedArrowDirections: [.left, .right]
        )
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = popoverTransition
        self.preferredContentSize = CGSize(width: 375, height: 310)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        detailLabel.text = selectedDate.pickerTime(is24Hour: is24Hour)
        pickerView.dateChanged = { [weak self] date in
            guard let self else { return }
            self.detailLabel.text = date.pickerTime(is24Hour: self.is24Hour)
            self.detailLabel.textColor = date > Date() ? UIColor.ud.textPlaceholder : UIColor.ud.functionDangerContentDefault
            self.selectedDate = date
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(_:))))
        popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
    }

    private func setupSubviews() {
        view.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(pickerView)
        headerView.addSubview(dividingLine)
        headerView.addSubview(titleStack)
        headerView.addSubview(cancelButton)
        headerView.addSubview(confirmButton)
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(detailLabel)
        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(256)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(contentView.safeAreaLayoutGuide)
        }
        dividingLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        confirmButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        titleStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(cancelButton.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualTo(confirmButton.snp.leading).offset(-6)
        }
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
        detailLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        addPointerAction()
    }

    private func addPointerAction() {
        if #available(iOS 13.4, *) {
            let cancelAction = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            cancelButton.addLKInteraction(cancelAction)
            let confirmAction = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            confirmButton.addLKInteraction(confirmAction)
        }
    }
}

fileprivate extension Date {

    func pickerTime(is24Hour: Bool) -> String {
        if self.isInToday {
            return BundleI18n.LarkFocus.Lark_Profile_SetTime_Today_Text(readableString(is24Hour: is24Hour))
        } else {
            return self.readableString(is24Hour: is24Hour)
        }
    }
}
