//
//  BTProgressEditAgent.swift
//  SKBitable
//
//  Created by yinyuan on 2022/11/20.
//

import Foundation
import RxCocoa
import RxSwift
import SKBrowser
import SKFoundation
import SKResource
import UniverseDesignToast

final class BTProgressEditAgent: BTBaseEditAgent {
    
    /// 开始编辑时的文本
    private var startEditingTxt: String?
    /// 当前正在编辑的文本（不一定格式正确）
    private var currentEditingTxt: String?
    /// 最近一次格式有效的文本
    private var lastValidEditingTxt: String?

    /// 是否是点击完成按钮结束
    private var clickDone = false

    /// 当前编辑的字段
    private var editingField: BTFieldProgressCellProtocol?

    override var editType: BTFieldType { .number }
    
    /// 最近一次编辑的输入类型
    private var lastInputType: String = "none"

    override func startEditing(_ cell: BTFieldCellProtocol) {
        editingField = cell as? BTFieldProgressCellProtocol
        if let editingField = editingField {
            editingField.updateEditingStatus(true)
            editingField.updateBorderMode(.editing)
        } else {
            DocsLogger.error("invalid editingField")
        }
        
        coordinator?.currentCard?.keyboard.stop()
        
        setupPanel()
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        
        innerStopEditing(immediately: immediately, sync: sync)
        
        // 关闭面板
        panel.hide(immediately: immediately, clickDone: false)
    }
    
    private func innerStopEditing(immediately: Bool, sync: Bool = false) {
        guard let editingField = editingField else {
            baseDelegate?.didStopEditing()
            return
        }
        
        editingField.updateEditingStatus(false)
        
        editingField.stopEditing()
        
        // 提交数据
        self.commit(value: currentEditingTxt, sync: sync)
        
        self.baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        self.coordinator?.invalidateEditAgent()
        self.editingField = nil
        
        coordinator?.currentCard?.keyboard.start()
    }
    
    private func commit(value: String?, sync: Bool = false) {
        guard let bindField = editingField else {
            DocsLogger.error("editingField is nil")
            return
        }
        let result = syncInterceptor(value: value)
        if sync, coordinator?.shouldContinueEditing(fieldID: fieldID, inRecordID: recordID) == false {
            // 没有编辑权限，重置刷新
            lastInputType = "none"
            bindField.reloadData()
            editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
        } else if sync, result.pass {
            // 正常提交
            editHandler?.didModifyNumberField(fieldID: fieldID, value: result.value, didClickDone: clickDone)
        } else if sync, !result.pass {
            // 格式不正确
            lastInputType = "none"
            bindField.reloadData()
            if result.errorLog.isEmpty {
                editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
            } else {
                showErrorMsg(message: result.errorLog)
            }
        }
        
        // 埋点
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            trackParams["click"] = "progress_content_change"
            trackParams["input_type"] = lastInputType
            DocsTracker.newLog(enumEvent: .bitableProgressCellEditClick, parameters: trackParams)
        }
    }

    override var editingPanelRect: CGRect {
        return panel.mainView.convert(panel.mainView.bounds, to: inputSuperview)
    }

    private func syncInterceptor(value: String?) -> (pass: Bool, value: Double?, errorLog: String) {
        let result = BTNumberEditAgent.parseNumber(value: value)
        
        //相同内容不要同步
        if result.textValue == startEditingTxt {
            return (false, result.value, result.errorLog)
        }

        return (result.pass, result.value, result.errorLog)
    }
    
    lazy private var panel: BTProgressPanel = {
        let panel = BTProgressPanel(baseContext: coordinator?.viewModel.baseContext)
        panel.delegate = self
        return panel
    }()
    
    private func setupPanel() {
        guard let fieldModel = editingField?.fieldModel else {
            return
        }
        // 设置初始化编辑值
        if let number = fieldModel.numberValue.first?.rawValue {
            startEditingTxt = BTFormatTypeConfig.format(number)
            currentEditingTxt = BTFormatTypeConfig.format(number)
            lastValidEditingTxt = currentEditingTxt
        }
        
        /// 初始化拖动条
        panel.slider.maxValue = fieldModel.property.max ?? 100
        panel.slider.minValue = fieldModel.property.min ?? 0
        panel.slider.progressColor = fieldModel.property.progress?.color
        
        /// 初始化输入框
        if let kbView = panel.progressTextField.input.inputView as? BTNumberKeyboardView, let commonTrackParams = coordinator?.viewModel.getCommonTrackParams() {
            kbView.commonTrackParams = commonTrackParams
        }
        
        /// 初始化标题栏
        panel.titleView.titleLabel.text = fieldModel.name
        
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
        // 更新输入框值
        var targetShowText: String?
        if let currentEditingTxt = currentEditingTxt {
            if panel.progressTextField.input.isEditing {
                // 显示为编辑态值
                targetShowText = currentEditingTxt
            } else {
                // 显示为格式化值
                if let value = BTNumberEditAgent.parseNumber(value: currentEditingTxt).value, let formatter = editingField?.fieldModel.property.formatter {
                    targetShowText = BTFormatTypeConfig.format(value: value, formatCode: formatter)
                } else {
                    targetShowText = currentEditingTxt
                }
            }
        } else {
            targetShowText = nil
        }
        panel.progressTextField.text = targetShowText
        
        // 更新进度条值
        let result = BTNumberEditAgent.parseNumber(value: currentEditingTxt)
        if result.pass {
            if let value = result.value {
                panel.slider.currentValue = value
            } else {
                // 空值显示为最小值
                panel.slider.currentValue = panel.slider.minValue
            }
        }
    }
    
    /// 限制最大输入长度
    private func limitMaxInput(_ textView: UITextField) {
        if BTNumberEditAgent.trapMaxInput(text: textView.text) {
            textView.text = currentEditingTxt
        } else {
            currentEditingTxt = textView.text
        }
    }
    
    private func showErrorMsg(message: String) {
        UDToast.showFailure(with: message, on: self.inputSuperview.window ?? self.inputSuperview)
    }
}

extension BTProgressEditAgent: BTProgressPanelDelegate {
    
    func close(_ panel: BTProgressPanel, clickDone: Bool) {
        guard let editingField = editingField else {
            // 已经通过其他外部途径结束
            return
        }
        self.clickDone = clickDone
        innerStopEditing(immediately: false, sync: true)
        self.clickDone = false
    }
    
    func progressChanged(_ panel: BTProgressPanel, value: Double) {
        currentEditingTxt = BTFormatTypeConfig.format(value)
        lastValidEditingTxt = currentEditingTxt
        lastInputType = "drag"
        updateValue()
    }
    
    func textFieldDidBeginEditing(_ panel: BTProgressPanel, textField: UITextField) {
        updateValue()
    }

    func textFieldDidChange(_ panel: BTProgressPanel, textField: UITextField) {
        // 超长检测
        limitMaxInput(textField)
        
        // 更新进度条
        let result = BTNumberEditAgent.parseNumber(value: textField.text)
        if result.pass {
            if let value = result.value {
                panel.slider.currentValue = value
            } else {
                panel.slider.currentValue = panel.slider.minValue
            }
            currentEditingTxt = result.textValue
            lastValidEditingTxt = currentEditingTxt
            lastInputType = "input"
        } else {
            // 格式不正确，不更新进度条，但要更新 currentEditingTxt
            currentEditingTxt = result.textValue
        }
    }

    func textFieldDidEndEditing(_ panel: BTProgressPanel, textField: UITextField) {
        // 更新进度条
        let result = BTNumberEditAgent.parseNumber(value: textField.text)
        if result.pass {
            currentEditingTxt = result.textValue
            lastValidEditingTxt = currentEditingTxt
            lastInputType = "input"
        } else {
            currentEditingTxt = lastValidEditingTxt
            if !result.errorLog.isEmpty {
                showErrorMsg(message: result.errorLog)
            }
        }
        updateValue()
    }
}
