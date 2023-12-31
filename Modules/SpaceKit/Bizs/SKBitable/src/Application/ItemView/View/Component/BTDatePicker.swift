// 
// Created by duanxiaochen.7 on 2020/3/13.
// Affiliated with DocsSDK.
// 
// Description:

import SKFoundation
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignDatePicker

protocol BTDatePickerDelegate: AnyObject {
    func didFinishPickingDate(result: String, trackInfo: BTTrackInfo)
    func dismissPicker(_ picker: BTDatePicker, trackInfo: BTTrackInfo)
    var dateField: BTFieldDateCellProtocol? { get }
}

final class BTDatePicker: UIView {
    private var field: BTFieldDateCellProtocol? {
        return delegate?.dateField
    }
    private weak var delegate: BTDatePickerDelegate?

    var internalHeight: CGFloat { datePickerHeight + accessoryViewHeight }

    private let datePickerHeight: CGFloat = 250.0
    private let accessoryViewHeight: CGFloat = 40.0

    var dateValues: [BTDateModel] = []

    var dateFormat: String = "yyyy/MM/dd"

    var timeFormat: String = "HH:mm"
    
    var timeZone: TimeZone = .current

    var pickerMode: UDWheelsStyleConfig.WheelModel {
        if dateFormat.isEmpty { // 纯时间
            return .hourMinuteCenter
        } else if timeFormat.isEmpty { // 纯日期
            return .yearMonthDayWeek
        } else { // 日期+时间
            return .dayHourMinute()
        }
    }

    func dateValueInRegular() -> [Date] {
        return dateValues.map {
            Date(timeIntervalSince1970: $0.value)
        }
    }

    /// 初始值
    private var dateValue: Date {
        let date = dateValueInRegular().first ?? Date()
        return min(max(date, UDWheelsStyleConfig.defaultMinDate), UDWheelsStyleConfig.defaultMaxDate)
    }
    
    private var trackInfo = BTTrackInfo()
    
    /// 当前滚轮值
    var currentDate = Date()
    
    lazy var clearBtn = UIButton().construct { it in
        it.setTitle(
            BundleI18n.SKResource.Doc_Block_Clear,
            withFontSize: 17,
            fontWeight: .regular,
            colorForNormalState: UDColor.primaryContentDefault,
            colorForPressedState: UDColor.primaryContentPressed
        )
        it.titleLabel?.textAlignment = .left
        it.addTarget(self, action: #selector(didClearContent), for: .touchUpInside)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
    }

    lazy var confirmBtn = UIButton().construct { it in
        it.setTitle(
            BundleI18n.SKResource.Bitable_BTModule_Done,
            withFontSize: 17,
            fontWeight: .regular,
            colorForNormalState: UDColor.primaryContentDefault,
            colorForPressedState: UDColor.primaryContentPressed
        )
        it.titleLabel?.textAlignment = .right
        it.addTarget(self, action: #selector(didConfirmPicking), for: .touchUpInside)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
    }

    lazy var accessoryView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.addSubview(clearBtn)
        clearBtn.snp.makeConstraints { it in
            it.centerY.height.equalToSuperview()
            it.left.equalToSuperview().offset(16)
        }
        it.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { it in
            it.centerY.height.equalToSuperview()
            it.right.equalToSuperview().offset(-16)
        }
    }
    
    lazy var wrapperView = UIView().construct { (it) in
        it.layer.ud.setShadow(type: .s4Up)
    }

    lazy var pickerConfig = UDWheelsStyleConfig(mode: pickerMode,
                                                pickerHeight: datePickerHeight,
                                                is12Hour: false,
                                                minInterval: 1,
                                                textFont: .systemFont(ofSize: 17))
    
    lazy var pickerView = UDDateWheelPickerView(date: dateValue, timeZone: timeZone, wheelConfig: pickerConfig)

    init(delegate: BTDatePickerDelegate?, fieldModel: BTFieldModel) {
        self.delegate = delegate
        trackInfo.didClickDone = true
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(internalHeight)
        }
        
        wrapperView.addSubview(accessoryView)
        accessoryView.snp.makeConstraints { it in
            it.height.equalTo(accessoryViewHeight)
            it.top.left.right.equalToSuperview()
        }
        
        updatePickerView(fieldModel: fieldModel)
    }
    
    private func updatePickerView(fieldModel: BTFieldModel) {
        dateValues = fieldModel.dateValue
        dateFormat = fieldModel.property.dateFormat
        timeFormat = fieldModel.property.timeFormat
        timeZone = TimeZone(identifier: fieldModel.timeZone) ?? .current
        currentDate = dateValue
        // pickerView 里面是根据 dateValue 和 timeZone 结合来进行显示，但是返回的 selectedDate 却以 currentTimeZone 计算时间戳。所以有下面的计算
        self.pickerView = UDDateWheelPickerView(date: dateValue, timeZone: timeZone, wheelConfig: pickerConfig)
        pickerView.dateChanged = { [weak self] selectedDate in
            guard let self = self else { return }
            self.currentDate = selectedDate.docs.convert(toTimeZone: self.timeZone) ?? selectedDate
            DocsLogger.btInfo("datapicker dateChanged: \(self.currentDate)")
        }
        wrapperView.addSubview(pickerView)
        pickerView.snp.remakeConstraints { it in
            it.left.right.bottom.equalToSuperview()
            it.height.equalTo(datePickerHeight)
        }
    }

    @objc
    private func didClearContent() {
        delegate?.didFinishPickingDate(result: "", trackInfo: trackInfo)
    }

    @objc
    private func didConfirmPicking() {
        delegate?.didFinishPickingDate(result: "1", trackInfo: trackInfo)
    }

    func updatePicker(fieldModel: BTFieldModel) {
        if timeZone.identifier != fieldModel.timeZone {
            DocsLogger.btInfo("updatePicker timeZone: \(self.timeZone.identifier) changeTo: \(fieldModel.timeZone)")
            updatePickerView(fieldModel: fieldModel)
        } else {
            dateValues = fieldModel.dateValue
            dateFormat = fieldModel.property.dateFormat
            timeFormat = fieldModel.property.timeFormat
            /// 这里要处理时间戳不一致的问题。
            pickerView.switchTo(mode: pickerMode, with: dateValue)
            currentDate = dateValue
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        trackInfo.didClickDone = false
        didConfirmPicking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
