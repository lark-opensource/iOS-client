//
//  ReminderDatePicker.swift
//  SpaceKit
//
//  Created by nine on 2019/4/9.
//

import Foundation
import SKCommon
import RxSwift
import RxRelay
import UniverseDesignFont
import UniverseDesignDatePicker

class ReminderDatePicker: UIView {

    let pickerView: UDDateWheelPickerView
        
    let dateObserver = BehaviorRelay<Date>(value: Date())
    
    var date: Date {
        get {
            return dateObserver.value
        }
        set {
            let value = min(max(newValue, UDWheelsStyleConfig.defaultMinDate), UDWheelsStyleConfig.defaultMaxDate)
            pickerView.select(date: value)
            dateObserver.accept(value)
        }
    }
    
    init(mode: UDWheelsStyleConfig.WheelModel, minuteInterval: Int) {
        let pickerConfig = UDWheelsStyleConfig(mode: mode,
                                               pickerHeight: 155.5,
                                               is12Hour: false,
                                               showSepeLine: false,
                                               minInterval: minuteInterval,
                                               textFont: .systemFont(ofSize: 17))
        pickerView = UDDateWheelPickerView(wheelConfig: pickerConfig)
        super.init(frame: .zero)

        let itemLine = DocsItemLine()
        addSubview(itemLine)
        itemLine.snp.makeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        pickerView.dateChanged = { [weak self] newValue in
            self?.dateObserver.accept(newValue)
        }
        addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(155.5)
            make.bottom.equalTo(itemLine.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ReminderPickerView: UIPickerView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let itemLine = DocsItemLine()
        addSubview(itemLine)
        itemLine.snp.makeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
