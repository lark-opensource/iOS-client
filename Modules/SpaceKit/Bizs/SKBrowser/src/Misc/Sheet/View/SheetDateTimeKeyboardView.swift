//
// Created by duanxiaochen.7 on 2019/8/8.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - Custom Date/Time Keyboard

import Foundation
import UIKit
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignDatePicker

public protocol SheetDateTimeKeyboardDelegate: AnyObject {
    var sheetInputView: SheetInputView? { get }
    var jsEngine: BrowserJSEngine? { get }
    var cachedValue: Date? { get set }
    var cachedSubtype: SheetDateTimeKeyboardSubtype { get set }
    func didSwitchDatetimeInputSubtype(to: SheetDateTimeKeyboardSubtype)
    func logCompletion(type: SheetDateTimeKeyboardSubtype)
}

public final class SheetDateTimeKeyboardView: UIView {

    public var isInFullScreenInputMode = false

    public weak var delegate: SheetDateTimeKeyboardDelegate?
    
    private var pickerView: UDDateWheelPickerView
    
    private var pickerConfig: UDWheelsStyleConfig
    
    private var currentSelection: Date = Date()

    private var currentPickingMode: UDWheelsStyleConfig.WheelModel {
        get {
            return pickerConfig.mode
        }
        set {
            pickerConfig.mode = newValue
            pickerView.switchTo(mode: newValue, with: currentSelection)
            updateButtonHighlight(for: newValue)
            delegate?.cachedSubtype = currentInputSubtype
        }
    }

    private var currentInputSubtype: SheetDateTimeKeyboardSubtype {
        switch currentPickingMode {
        case .yearMonthDayWeek: return .date
        case .hourMinuteCenter: return .time
        default: return .dateTime
        }
    }

    private lazy var toolbar = UIView()

    private lazy var dateButton = CheckBoxView(title: BundleI18n.SKResource.Doc_Sheet_DateKeyboardDate) { [weak self] in
        self?.didRequestToDatePicker()
    }

    private lazy var timeButton = CheckBoxView(title: BundleI18n.SKResource.Doc_Sheet_DateKeyboardTime) { [weak self] in
        self?.didRequestToTimePicker()
    }

    private lazy var confirmButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Doc_Sheet_DateKeyboardConfirm, for: .normal)
        it.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.addTarget(self, action: #selector(didConfirmPicking), for: .touchUpInside)
    }

    private lazy var clearButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Doc_Doc_ColorSelectClear, for: .normal)
        it.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.addTarget(self, action: #selector(clearAction), for: .touchUpInside)
    }

    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    public init(subtype: SheetDateTimeKeyboardSubtype, date: Date) {
        pickerConfig = UDWheelsStyleConfig(
            mode: subtype.datePickerMode,
            maxDisplayRows: 21,
            is12Hour: false,
            showSepeLine: true,
            minInterval: 1,
            textFont: UIFont.systemFont(ofSize: 20),
            backgroundColor: UDColor.N100
        )
        let reformedDate = min(max(date, UDWheelsStyleConfig.defaultMinDate), UDWheelsStyleConfig.defaultMaxDate)
        pickerView = UDDateWheelPickerView(date: reformedDate, wheelConfig: pickerConfig)
        super.init(frame: .zero)
        backgroundColor = UDColor.N100

        pickerView.dateChanged = { [weak self] currentDate in
            self?.currentSelection = currentDate
            self?.delegate?.cachedValue = currentDate
        }
        currentSelection = reformedDate
        currentPickingMode = subtype.datePickerMode

        addSubview(toolbar)
        toolbar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }

        let separator = UIView()
        separator.backgroundColor = UDColor.lineDividerDefault
        addSubview(separator)
        separator.snp.makeConstraints { (make) in
            make.bottom.equalTo(toolbar.snp.top)
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
        }

        addSubview(pickerView)
        pickerView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(separator.snp.top)
        }

        toolbar.addSubview(dateButton)
        dateButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        dateButton.docs.addHighlight(with: UIEdgeInsets(top: 8, left: -10, bottom: 8, right: -10), radius: 8)

        toolbar.addSubview(timeButton)
        timeButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(dateButton.snp.right).offset(30)
        }
        timeButton.docs.addHighlight(with: UIEdgeInsets(top: 8, left: -10, bottom: 8, right: -10), radius: 8)

        toolbar.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        confirmButton.docs.addHighlight(with: UIEdgeInsets(top: 8, left: -10, bottom: 8, right: -10), radius: 8)
        
        toolbar.addSubview(clearButton)
        clearButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.centerY.equalTo(confirmButton)
            make.right.equalTo(confirmButton.snp.left).offset(-20)
        }
        clearButton.docs.addHighlight(with: UIEdgeInsets(top: 8, left: -10, bottom: 8, right: -10), radius: 8)

        selectionFeedbackGenerator.prepare()
    }
    
    public func updatePicker(subtype: SheetDateTimeKeyboardSubtype, date: Date) {
        let reformedDate = min(max(date, UDWheelsStyleConfig.defaultMinDate), UDWheelsStyleConfig.defaultMaxDate)
        if currentInputSubtype != subtype {
            currentSelection = reformedDate
            currentPickingMode = subtype.datePickerMode
        } else if currentSelection != reformedDate {
            //切换模式会触发闪动动画，所以模式没变，就只更新日期即可
            currentSelection = reformedDate
            pickerView.select(date: currentSelection, animated: false)
        } else {
            DocsLogger.info("no need to update")
        }
        
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { // 在移动到键盘 window 后主动刷新布局，避免滚轮对不齐
            pickerView.switchTo(mode: pickerConfig.mode, with: currentSelection)
        }
    }

    @objc
    private func didConfirmPicking() {
        let formatter = DateFormatter()
        switch currentPickingMode {
        case .hourMinuteCenter:
            formatter.dateFormat = "HH:mm:00"
        case .yearMonthDayWeek:
            formatter.dateFormat = "yyyy-MM-dd"
        default:
            formatter.dateFormat = "yyyy-MM-dd HH:mm:00"
        }
        let value = formatter.string(from: currentSelection)
        delegate?.sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: .customDate, subType: currentInputSubtype)
        if isInFullScreenInputMode {
            delegate?.sheetInputView?.replaceCurrentAttText(with: value, editState: .editing)
        } else {
            delegate?.sheetInputView?.replaceCurrentAttText(with: value, editState: .endCellEdit)
        }
        selectionFeedbackGenerator.selectionChanged()
        delegate?.cachedSubtype = currentInputSubtype
        delegate?.logCompletion(type: currentInputSubtype)
        delegate?.logCompletion(type: .none) // 不管什么类型的都要上报一次，用于计算总数，无语
    }
    
    @objc
    private func clearAction() {
        delegate?.sheetInputView?.replaceCurrentAttText(with: "", editState: .editing)
        delegate?.logCompletion(type: .clear)
        delegate?.logCompletion(type: .none) // 不管什么类型的都要上报一次，用于计算总数，无语
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SheetDateTimeKeyboardView {
    
    private func updateButtonHighlight(for mode: UDWheelsStyleConfig.WheelModel) {
        switch mode {
        case .yearMonthDayWeek: // .date
            dateButton.isSelected = true
            timeButton.isSelected = false
        case .hourMinuteCenter: // .time
            dateButton.isSelected = false
            timeButton.isSelected = true
        default:
            dateButton.isSelected = true
            timeButton.isSelected = true
        }
    }

    private func didRequestToDatePicker() {
        switch currentPickingMode {
        case .hourMinuteCenter:
            currentPickingMode = .dayHourMinute()
            selectionFeedbackGenerator.selectionChanged()
            delegate?.didSwitchDatetimeInputSubtype(to: .dateTime)
        case .dayHourMinute(_, _):
            currentPickingMode = .hourMinuteCenter
            selectionFeedbackGenerator.selectionChanged()
            delegate?.didSwitchDatetimeInputSubtype(to: .time)
        default: ()
        }
    }
    
    private func didRequestToTimePicker() {
        switch currentPickingMode {
        case .yearMonthDayWeek:
            currentPickingMode = .dayHourMinute()
            selectionFeedbackGenerator.selectionChanged()
            delegate?.didSwitchDatetimeInputSubtype(to: .dateTime)
        case .dayHourMinute(_, _):
            currentPickingMode = .yearMonthDayWeek
            selectionFeedbackGenerator.selectionChanged()
            delegate?.didSwitchDatetimeInputSubtype(to: .date)
        default: ()
        }
    }
}

class CheckBoxView: UIView {
    
    typealias Callback = (() -> Void)
    var callback: Callback?
    
    var checkBox = UDCheckBox()
    var textButton = UIButton()
    
    var isSelected: Bool = false {
        didSet {
            checkBox.isSelected = isSelected
        }
    }
    
    required init(title: String, callback: @escaping Callback) {
        super.init(frame: .zero)
        self.callback = callback
        setupInit()
        setupLayout()
        textButton.setTitle(title, for: .normal)
    }
    
    func setupInit() {
        checkBox = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(style: .circle)) { [weak self] (_) in
            self?.callback?()
        }
        textButton.construct({
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.setTitleColor(UIColor.ud.textTitle, for: .normal)
        })
        textButton.addTarget(self, action: #selector(textClick), for: .touchUpInside)
        addSubview(checkBox)
        addSubview(textButton)
    }
    
    @objc
    func textClick() {
        callback?()
    }
    
    func setupLayout() {
        checkBox.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        textButton.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(checkBox.snp.right).offset(6)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
