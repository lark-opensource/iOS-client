//
//  BTFilterDateView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/2.
//  


import SKFoundation
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignDatePicker

protocol BTFilterDateViewDelegate: AnyObject {
    func valueChanged(date: Date)
}

public final class BTFilterDateView: UIView {
    
    static let pickerHeight: CGFloat = 256.0
    
    struct FormatConfig {
        var dateFormat: String = "yyyy/MM/dd"
        var timeFormat: String = ""
        var timeZone: TimeZone = .current
    }
   
    /// 记录当前选中时间
    private(set) var selectedDate: Date
    /// 初始值
    private var dateValue: Date
    
    private let formatConfig: FormatConfig

    private var isFromNewFilter: Bool = false
    
    weak var delegate: BTFilterDateViewDelegate?
    
    var pickerMode: UDWheelsStyleConfig.WheelModel {
        if formatConfig.dateFormat.isEmpty { // 纯时间
            return .hourMinuteCenter
        } else if formatConfig.timeFormat.isEmpty { // 纯日期
            return .yearMonthDayWeek
        } else { // 日期+时间
            return .dayHourMinute()
        }
    }
    
    private lazy var pickerConfig = UDWheelsStyleConfig(mode: pickerMode,
                                                        pickerHeight: Self.pickerHeight,
                                                        is12Hour: false,
                                                        minInterval: 1,
                                                        textFont: .systemFont(ofSize: 18))
    
    private lazy var pickerView = UDDateWheelPickerView(date: dateValue, timeZone: formatConfig.timeZone, wheelConfig: pickerConfig)
    
    init(date: Date, formatConfig: FormatConfig, isFromNewFilter: Bool = false) {
        dateValue = min(max(date, UDWheelsStyleConfig.defaultMinDate), UDWheelsStyleConfig.defaultMaxDate)
        selectedDate = dateValue
        self.formatConfig = formatConfig
        self.isFromNewFilter = isFromNewFilter
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        pickerView.dateChanged = { [weak self] selectedDate in
            guard let self = self else { return }
            self.selectedDate = selectedDate.docs.convert(toTimeZone: self.formatConfig.timeZone) ?? selectedDate
            self.delegate?.valueChanged(date: self.selectedDate)
        }
        self.addSubview(pickerView)
        if isFromNewFilter {
            pickerView.snp.remakeConstraints { it in
                it.edges.equalToSuperview()
            }
        } else {
            pickerView.snp.remakeConstraints { it in
                it.left.right.bottom.equalToSuperview()
                it.height.equalTo(Self.pickerHeight)
            }
        }
    }
}
