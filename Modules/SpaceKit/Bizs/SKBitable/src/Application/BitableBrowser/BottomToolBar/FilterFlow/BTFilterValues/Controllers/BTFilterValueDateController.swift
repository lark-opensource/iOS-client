//
//  BTFilterValueDateController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/27.
//  

import UIKit
import UniverseDesignColor

final class BTFilterValueDateController: BTFilterValueBaseController, BTPanelAnimationCustumDurationType {

    var duration: TimeInterval = 0.001
    
    static var contentHeight: CGFloat {
        return 48 + BTFilterDateView.pickerHeight
    }
    
    private var initValue: Date
    
    let filterContentView: BTFilterDateView
    
    init(title: String, date: Date, formatConfig: BTFilterDateView.FormatConfig, isFromNewFilter: Bool = false) {
        filterContentView = BTFilterDateView(date: date, formatConfig: formatConfig, isFromNewFilter: isFromNewFilter)
        initValue = date
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
        filterContentView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        initViewHeight = Self.contentHeight
        super.setupUI()
        self.containerView.backgroundColor = UDColor.bgBody
        setupContentView()
    }
    
    override func getValuesWhenFinish() -> [AnyHashable] {
        return [BTFilterDuration.ExactDate.rawValue,
                filterContentView.selectedDate.timeIntervalSince1970 * 1000]
    }
    
    override func isValueChange() -> Bool {
        return initValue != filterContentView.selectedDate
    }
    
    private func setupContentView() {
        contentView.addSubview(filterContentView)
        filterContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        // 初次进来也需要回调下
        self.valueChanged(date: filterContentView.selectedDate)
    }
}

extension BTFilterValueDateController: BTFilterDateViewDelegate {
    func valueChanged(date: Date) {
        self.delegate?.valueSelected(date.timeIntervalSince1970 * 1000, selected: true)
    }
}
