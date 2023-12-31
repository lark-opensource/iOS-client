//
//  BTRatingEditAgent.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/17.
//

import Foundation
import RxCocoa
import RxSwift
import SKBrowser
import SKFoundation
import SKResource
import UniverseDesignToast

final class BTRatingEditAgent: BTBaseEditAgent {

    /// 是否是点击完成按钮结束
    private var clickDone = false

    /// 当前编辑的字段
    private var editingField: BTFieldRatingCellProtocol?

    override var editType: BTFieldType { .number }
    
    /// 是否打开 Panel 来编辑
    private let editInPanel: Bool

    init(fieldID: String, recordID: String, editInPanel: Bool) {
        self.editInPanel = editInPanel
        super.init(fieldID: fieldID, recordID: recordID)
    }
    
    override func startEditing(_ cell: BTFieldCellProtocol) {
        editingField = cell as? BTFieldRatingCellProtocol
        
        coordinator?.currentCard?.keyboard.stop()
        
        if editInPanel {
            setupPanel()
        }
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        
        innerStopEditing(immediately: immediately)
        if editInPanel {
            // 关闭面板
            panel.hide(immediately: immediately, clickDone: false)
        }
    }
    
    private func innerStopEditing(immediately: Bool) {
        guard let editingField = editingField else {
            DocsLogger.warning("editingField is nil")
            baseDelegate?.didStopEditing()
            return
        }
        editingField.stopEditing()
        if editInPanel {
            self.baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        }
        self.coordinator?.invalidateEditAgent()
        self.editingField = nil
        
        coordinator?.currentCard?.keyboard.start()
    }
    
    func commit(value: Int?, sync: Bool = false) {
        guard let editingField = editingField else {
            DocsLogger.error("editingField is nil")
            return
        }
        // 正常提交
        let doubleValue: Double?
        if let value = value {
            doubleValue = Double(value)
        } else {
            doubleValue = nil
        }
        editHandler?.didModifyNumberField(fieldID: fieldID, value: doubleValue, didClickDone: clickDone)
        
        // 埋点
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            trackParams["click"] = "mark_content_change"
            trackParams["mark_type"] = editingField.fieldModel.property.rating?.symbol
            DocsTracker.newLog(enumEvent: .bitableRatingCellEditClick, parameters: trackParams)
        }
    }

    override var editingPanelRect: CGRect {
        return panel.mainView.convert(panel.mainView.bounds, to: inputSuperview)
    }
    
    lazy private var panel: BTRatingPanel = {
        let panel = BTRatingPanel()
        panel.delegate = self
        return panel
    }()
    
    private func setupPanel() {
        /// 初始化内容值
        updateValue()
        
        /// 显示面板
        inputSuperview.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.layoutIfNeeded()
        panel.show { [weak self] in
            self?.editingField?.panelDidStartEditing()
        }
    }
    
    /// 更新内容值
    private func updateValue() {
        guard let fieldModel = editingField?.fieldModel else {
            return
        }
        
        let max = Int(fieldModel.property.max ?? 1)
        let min = Int(fieldModel.property.min ?? 5)
        let length = max - min + 1
        let iconWidth: CGFloat
        let iconTitleSpacing: CGFloat
        let iconSpacing: CGFloat
        let iconPadding: CGFloat
        if length <= 5 {
            iconWidth = 42
            iconTitleSpacing = 15
            iconSpacing = 7
            iconPadding = 1.9
        } else if length <= 8 {
            iconWidth = 36
            iconTitleSpacing = 19
            iconSpacing = 6
            iconPadding = 1.63
        } else {
            iconWidth = 26
            iconTitleSpacing = 25
            iconSpacing = 4
            iconPadding = 1.18
        }
        
        // 更新进度条值
        var value: Int? = nil
        if let valueRaw = editingField?.fieldModel.numberValue.first?.rawValue {
            value = Int(valueRaw)
        }
        
        /// 初始化评分组件
        let symbol = fieldModel.property.rating?.symbol ?? BTRatingModel.defaultSymbol
        let config = BTRatingView.Config(
            minValue: min,
            maxValue: max,
            iconWidth: iconWidth,
            iconTitleSpacing: iconTitleSpacing,
            iconSpacing: iconSpacing,
            iconPadding: iconPadding,
            maxWidth: length >= 11 ? inputSuperview.frame.width: nil,
            syncLock: true,
            iconBuilder: { value in
                return BitableCacheProvider.current.ratingIcon(symbol: symbol, value: value)
            },
            titleBuilder: { value in
                return String(value)
            }
        )
        
        panel.ratingView.update(config, value)
        
        /// 初始化标题栏
        panel.titleView.titleLabel.text = fieldModel.name
        
    }
    
    override func updateInput(fieldModel: BTFieldModel) {
        updateValue()
    }
}

extension BTRatingEditAgent: BTRatingPanelDelegate {
    
    func close(_ panel: BTRatingPanel, clickDone: Bool) {
        self.clickDone = clickDone
        innerStopEditing(immediately: false)
        self.clickDone = false
    }
    
    func ratingValueChanged(_ panel: BTRatingPanel, value: Int?) {
        commit(value: value)
    }
    
    func scrollTillFieldVisible() {
        guard let field = relatedVisibleField else { return }
        coordinator?.currentCard?.scrollTillFieldBottomIsVisible(field)
    }
}
