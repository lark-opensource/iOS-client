//
//  BTChatterEditAgent.swift
//  SKBitable
//
//  Created by X-MAN on 2023/1/12.
//

import Foundation
import SKBrowser
import SKCommon
import UniverseDesignToast
import SKResource
import LarkRustClient
import SKFoundation

struct BTSelectChatterInfo {
    var type: BTChatterType = .user
    var chatters: [BTChatterProtocol]
    var currentChatter: BTChatterProtocol?
}

final class BTChatterEditAgent: BTBaseEditAgent {
    private lazy var panel: BTChatterPanel = {
        func judgeOpenSource() -> BTChatterPanelViewModel.OpenSource {
            guard let displayMode = coordinator?.viewModel.mode else {
                return .record(chatterType: chatterType)
            }
            switch displayMode {
            case .form:
                return .form
            case .indRecord:
                return .indRecord
            default:
                return .record(chatterType: chatterType)
            }
        }
        let panel = BTChatterPanel(self.coordinator?.editorDocsInfo,
                                   hostView: inputSuperview,
                                   openSource: judgeOpenSource(),
                                   chatterType: self.chatterType,
                                   isSubmitMode: coordinator?.viewModel.mode == BTViewMode.form || coordinator?.viewModel.mode == BTViewMode.addRecord || coordinator?.viewModel.mode == BTViewMode.submit,
                                   lastSelectNotifies: self.obtainLastNotifyStrategy())
        panel.delegate = self // delegate 必须在 BTUserPanel 初始化完成之后再设置，不然 bindUI 会调用到 delegate 方法，造成不可避免的影响
        return panel
    }()

    override var editType: BTFieldType {
        switch chatterType {
        case .user:
            return .user
        case .group:
            return .group
        }
    }

    private(set) var chatterType: BTChatterType

    override var editingPanelRect: CGRect {
        return .zero
    }

    init(fieldID: String, recordID: String, chatterType: BTChatterType = .user) {
        self.chatterType = chatterType
        super.init(fieldID: fieldID, recordID: recordID)
    }

    override func updateInput(fieldModel: BTFieldModel) {
        super.updateInput(fieldModel: fieldModel)
        let datas: [BTCapsuleModel]
        switch self.chatterType {
        case .group:
            datas = fieldModel.groups.compactMap({ group in
                return group.asChatterFieldCapsuleModel(isSelected: false)
            })
        case .user:
            datas = fieldModel.users.compactMap({ user in
                return user.asChatterFieldCapsuleModel(isSelected: false)
            })
        }
        panel.updateSelected(datas)
        panel.titleLabel.text = fieldModel.name
    }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        coordinator?.currentCard?.keyboard.stop()
        let bindField = relatedVisibleField as? BTFieldChatterCellProtocol

        if let datas = bindField?.addedMembers {
            panel.updateSelected(datas)
        }
        if let couldAddMultipleMembers = bindField?.fieldModel.property.multiple {
            panel.isMultipleMembers = couldAddMultipleMembers
        }
        if let name = bindField?.fieldModel.name {
            panel.titleLabel.text = name
        }

        inputSuperview.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.layoutIfNeeded()
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group {
            editHandler?
                .trackBitableEvent(
                    eventType: "ccm_bitable_group_field_select_view",
                    params: [
                        "is_multi_group": panel.isMultipleMembers ? "true" : "false"
                    ]
                )
        }
        panel.show {
            bindField?.panelDidStartEditing()
        }
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        panel.hide(immediately: immediately)
        coordinator?.currentCard?.keyboard.start()
    }
}

extension BTChatterEditAgent: BTMemberPanelDelegate {
    func doSelect(_ panel: BTChatterPanel, chatters: [BTChatterProtocol], currentChatter: BTChatterProtocol?, trackInfo: SKBrowser.BTTrackInfo, noUpdateChatterData: Bool, completion: ((BTChatterProtocol?) -> Void)?) {
        let selectInfo = BTSelectChatterInfo(type: chatterType, chatters: chatters, currentChatter: currentChatter)
        editHandler?.didSelectChatters(with: fieldID, chatterInfo: selectInfo, trackInfo: trackInfo, noUpdateChatterData: noUpdateChatterData) {
            [weak panel] (model, error) in
            DispatchQueue.main.async {
                if let error = error as? RCError {
                    if let view = panel?.window {
                        if case let .businessFailure(errorInfo) = error, errorInfo.errorStatus == 599 {
                            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Group_CannotLoadGroupInfo_Description, on: view)
                        } else {
                            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Group_CannotLoadGroupInfoRefreshRequired_Description, on: view)
                        }
                    }
                }
                completion?(model)
            }
        }
    }
    
    func quickAddViewClick() {
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
            return
        }
        editHandler?.quickAddViewClick(fieldID: fieldID)
        let muti = (relatedVisibleField as? BTFieldChatterCellProtocol)?.fieldModel.property.multiple ?? false
        editHandler?
            .trackBitableEvent(
                eventType: "ccm_bitable_group_field_select_click",
                params: [
                    "click": "add_group",
                    "target": "ccm_bitable_group_field_add_view",
                    "is_multi_group": muti ? "true" : "false"
                ]
            )
    }
    
    func trackSearchStartEdit() {
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
            return
        }
        editHandler?
            .trackBitableEvent(
                eventType: "ccm_bitable_group_field_select_click",
                params: [
                    "click": "search_group"
                ]
            )
    }
    
    func trackSelectCell() {
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
            return
        }
        editHandler?
            .trackBitableEvent(
                eventType: "ccm_bitable_group_field_select_click",
                params: [
                    "click": "select_group"
                ]
            )
    }
    
    func trackCancel() {
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
            return
        }
        editHandler?
            .trackBitableEvent(
                eventType: "ccm_bitable_group_field_select_click",
                params: [
                    "click": "cancel"
                ]
            )
    }

    func didClickItem(with model: SKBrowser.BTCapsuleModel, fileName: String?) {
        baseDelegate?.didClickItem(with: model, fileName: fileName)
    }

    func saveNotifyStrategy(notifiesEnabled: Bool) {
        editHandler?.saveNotifyStrategy(notifiesEnabled: notifiesEnabled)
    }

    func obtainLastNotifyStrategy() -> Bool {
        if chatterType == .group {
            return false
        }
        return editHandler?.obtainLastNotifyStrategy() ?? true
    }

    func finishSelecting(_ panel: BTChatterPanel, type: BTChatterType, chatters: [BTChatterProtocol], notifiesEnabled: Bool, trackInfo: BTTrackInfo, justUpdateChatterData: Bool, noUpdateChatterData: Bool) {
        if !noUpdateChatterData {
            let selectInfo = BTSelectChatterInfo(type: chatterType, chatters: chatters, currentChatter: nil)
            editHandler?.didSelectChatters(with: fieldID, chatterInfo: selectInfo, trackInfo: trackInfo, noUpdateChatterData: false, completion: nil)
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, type == .group {
                editHandler?
                    .trackBitableEvent(
                        eventType: "ccm_bitable_group_field_select_click",
                        params: [
                            "click": "confirm",
                            "is_multi_group": panel.isMultipleMembers ? "true" : "false",
                            "group_num": chatters.count
                        ]
                    )
            }
        }
        if justUpdateChatterData {
            return
        }
        panel.removeFromSuperview()
        let bindField = relatedVisibleField as? BTFieldChatterCellProtocol
        bindField?.stopEditing()
        baseDelegate?.didCloseEditPanel(self, payloadParams: ["notify": notifiesEnabled])
        coordinator?.invalidateEditAgent()
        coordinator?.currentCard?.keyboard.start()
    }
}
