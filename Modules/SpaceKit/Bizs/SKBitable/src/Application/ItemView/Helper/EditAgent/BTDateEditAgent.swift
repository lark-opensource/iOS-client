// 
// Created by duanxiaochen.7 on 2020/3/25.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKBrowser

final class BTDateEditAgent: BTBaseEditAgent {
    private var picker: BTDatePicker?
    private var finishDate: Date?
    private var trackInfo = BTTrackInfo()

    override var editingPanelRect: CGRect {
        if let panel = picker?.wrapperView {
            let rect = panel.convert(panel.bounds, to: inputSuperview)
            return rect
        }
        return .zero
    }

    override func updateInput(fieldModel: BTFieldModel) {
        super.updateInput(fieldModel: fieldModel)
        picker?.updatePicker(fieldModel: fieldModel)
    }

    override var editType: BTFieldType { .dateTime }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        guard let bindField = relatedVisibleField as? BTFieldDateCellProtocol else { return }

        picker = BTDatePicker(delegate: self, fieldModel: bindField.fieldModel)
        guard let picker = picker else { return }
        inputSuperview.addSubview(picker)
        picker.snp.makeConstraints { it in
            it.top.equalTo(inputSuperview.snp.bottom)
            it.left.right.height.equalToSuperview()
        }
        inputSuperview.layoutIfNeeded()
       
        UIView.animate(withDuration: 0.25, animations: {
            picker.snp.remakeConstraints { it in
                it.edges.equalToSuperview()
            }
            picker.setNeedsLayout()
        }, completion: { (finish) in
            if finish {
               bindField.panelDidStartEditing()
            }
        })
        
        inputSuperview.bringSubviewToFront(picker)
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        let bindField = relatedVisibleField as? BTFieldDateCellProtocol
        bindField?.stopEditing()
        guard picker?.superview != nil else { return }
        if immediately {
            picker?.removeFromSuperview()
            picker = nil
        } else {
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.picker?.snp.remakeConstraints { it in
                        it.top.equalTo(self.inputSuperview.snp.bottom)
                        it.left.right.height.equalToSuperview()
                    }
                    self.inputSuperview.layoutIfNeeded()
                },
                completion: { finish in
                    if finish {                    
                        self.picker?.removeFromSuperview()
                        self.picker = nil
                        
                    }
                }
            )
        }

        if sync {
            editHandler?.didFinishPickingDate(fieldID: fieldID, date: finishDate, trackInfo: trackInfo)
        }
        self.baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        self.coordinator?.invalidateEditAgent()
    }
}


extension BTDateEditAgent: BTDatePickerDelegate {
    func didFinishPickingDate(result: String, trackInfo: BTTrackInfo) {
        if result.count == 0 {
            finishDate = nil
        } else {
            if var date = picker?.currentDate {
                // 如果datePicker没选时间用的默认当前时间会带秒，这里把秒置空，需要注意顺序
                date.nanosecond = 0
                date.millisecond = 0
                date.second = 0
                finishDate = date
            }
        }
        stopEditing(immediately: false, sync: true)
    }
    
    func dismissPicker(_ picker: BTDatePicker, trackInfo: BTTrackInfo) {
        stopEditing(immediately: false)
    }

    var dateField: BTFieldDateCellProtocol? {
        return relatedVisibleField as? BTFieldDateCellProtocol
    }
}
