//
//  BTFilterValueOptionsController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/27.
//  

import UIKit
import SKBrowser

final class BTFilterValueOptionsController: BTFilterValueBaseController {
    
    private var initValue: [BTCapsuleModel]
    
    let filterContentView: BTFilterOptionsView
    var isFromNewFilter = false
    
    init(title: String, options: [BTCapsuleModel], isAllowMultipleSelect: Bool, isFromNewFilter: Bool = false) {
        self.isFromNewFilter = isFromNewFilter
        filterContentView = BTFilterOptionsView(options: options, isAllowMultipleSelect: isAllowMultipleSelect, isNewFilter: isFromNewFilter)
        initValue = filterContentView.selecteds
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
        filterContentView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        initViewHeight = maxViewHeight
        super.setupUI()
        setupContentView()
    }
    
    override func getValuesWhenFinish() -> [AnyHashable] {
        return self.filterContentView.selecteds.compactMap { $0.id }
    }
    
    override func isValueChange() -> Bool {
        return initValue != self.filterContentView.selecteds
    }
    
    private func setupContentView() {
        contentView.addSubview(filterContentView)
        filterContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    func update(_ datas: [BTCapsuleModel]) {
        filterContentView.update(options: datas)
        initValue = filterContentView.selecteds
    }
}

extension BTFilterValueOptionsController: BTFilterOptionsViewDelegate {
    func valueChanged(_ value: BTCapsuleModel, selected: Bool) {
        self.delegate?.valueSelected(value, selected: selected)
    }
    
    func search(_ keywords: String) {
        self.delegate?.search(keywords)
    }
}
