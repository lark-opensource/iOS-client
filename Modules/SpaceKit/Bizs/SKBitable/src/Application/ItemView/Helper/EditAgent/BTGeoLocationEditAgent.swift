//
//  BTLocationEditAgent.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/5/1.
//  

import SKFoundation
import LarkCoreLocation
import LarkLocationPicker
import EENavigator
import LarkUIKit
import SKResource
import UniverseDesignToast
import UniverseDesignDialog
import CoreLocation
import RxSwift


protocol BTGeoLocationEditAgentDelegate: AnyObject {
    func startAutoLocate(forFieldID: String, forToken token: String, authFailHandler: @escaping (LocationAuthorizationError?) -> Void)
    func startReGeocode(forFieldID: String, chooseLocation: ChooseLocation)
    func deleteGeoLocation(forFieldID: String)
}

final class BTGeoLocationEditAgent: BTBaseEditAgent {
    weak var delegate: BTGeoLocationEditAgentDelegate?
    
    override var editType: BTFieldType { .location }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        guard let geoField = cell as? BTFieldLocationCellProtocol else {
            return
        }
        if geoField.isClickDeleteMenuItem {
            geoField.isClickDeleteMenuItem = false
            self.deleteCurrentGeoLocation()
            return
        }
        switch cell.fieldModel.property.inputType {
        case .notLimit:
            showChooseLocationVC(rootVC: coordinator?.attachedController, cell: cell)
        case .onlyMobile:
            startLocate(cell)
        }
    }
    
    override func stopEditing(immediately: Bool, sync: Bool = false) {
        coordinator?.invalidateEditAgent()
    }
    
    override var editingPanelRect: CGRect {
        return .zero
    }
    
    private func showChooseLocationVC(rootVC: UIViewController?, cell: BTFieldCellProtocol) {
        guard let rootVC = rootVC else {
            return
        }
        let mapTokenValue = getLocationSecureToken(for: .mapAuth, isInForm: cell.fieldModel.isInForm)
        let picker = BTChooseLocationViewController(forToken: PSDAToken(mapTokenValue, type: .location))
        picker.sendLocationCallBack = { [weak self] location in
            guard let self = self else { return }
            self.didSelectLocation(location)
        }
        picker.cancelCallBack = { [weak self] in
            self?.stopEdit()
        }
        let nav = LkNavigationController(rootViewController: picker)
        Navigator.shared.present(nav, from: rootVC)
    }
    private func startLocate(_ cell: BTFieldCellProtocol) {
        let authToken = getLocationSecureToken(for: .autoLocateAuth, isInForm: cell.fieldModel.isInForm)
        let locateToken = getLocationSecureToken(for: .autoLocate, isInForm: cell.fieldModel.isInForm)
        BTFetchGeoLocationHelper.requestAuthIfNeed(forToken: authToken) { [weak self] error in
            guard let self = self else { return }
            let bindField = self.relatedVisibleField as? BTFieldLocationCellProtocol
            bindField?.stopEditing()
            self.coordinator?.invalidateEditAgent()
            if let error = error {
                self.handleAuthError(error)
            } else {
                  self.delegate?.startAutoLocate(forFieldID: self.fieldID, forToken: locateToken, authFailHandler: { error in
                    if let error = error {
                        self.handleAuthError(error)
                    }
                })
            }
        }
    }
    
    private func stopEdit() {
        let bindField = relatedVisibleField as? BTFieldLocationCellProtocol
        bindField?.stopEditing()
        coordinator?.invalidateEditAgent()
    }
    private func didSelectLocation(_ location: ChooseLocation) {
        stopEdit()
        self.delegate?.startReGeocode(forFieldID: self.fieldID, chooseLocation: location)
    }
    private func deleteCurrentGeoLocation() {
        self.delegate?.deleteGeoLocation(forFieldID: self.fieldID)
        stopEdit()
        trackOnClick("delete")
    }
    
    private func handleAuthError(_ error: LocationAuthorizationError) {
        switch error {
        case .denied: self.showDialogForAuthDeny()
        case .adminDisabledGPS: self.showToast(BundleI18n.SKResource.Bitable_Field_NoLocationPermissionToast)
        case .serviceDisabled, .psdaRestricted: self.showToast(BundleI18n.SKResource.Bitable_Field_UnableToLocateToast)
        default: return
        }
    }
    private func showDialogForAuthDeny() {
        guard let fromVC = coordinator?.attachedController else {
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_Field_LocationPermissionPopupTitle)
        dialog.setContent(text: BundleI18n.SKResource.Bitable_Field_LocationPermissionPopupContentiOS())
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonSettings, dismissCompletion: {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
    
    private func showToast(_ text: String) {
        guard let fromVC = coordinator?.attachedController else {
            return
        }
        UDToast.showFailure(with: text, on: fromVC.view)
    }
    
    private func trackOnClick(_ clickType: String) {
        guard let bindField = relatedVisibleField as? BTFieldLocationCellProtocol else {
            return
        }
        let params: [String: Any] = [
            "location_input": bindField.fieldModel.property.inputType.trackText,
            "click": clickType
        ]
        editHandler?.trackEvent(eventType: DocsTracker.EventType.bitableGeoCardClick.rawValue, params: params)
    }

    enum SecureScene {
        case autoLocate
        case autoLocateAuth
        case mapAuth
    }
    // 地理位置安全管控
    // https://thrones.bytedance.net/security-and-compliance/data-collect/api-control
    // https://bytedance.feishu.cn/docx/HB0Vdxb7iowFz2xHEddcTlAhn9c
    // https://bytedance.feishu.cn/wiki/wikcnySXeFTfDoU2ZWMCkJHMlqf
    private func getLocationSecureToken(for scene: SecureScene, isInForm: Bool) -> String {
        switch scene {
        case .autoLocate:
            return isInForm ? "LARK-PSDA-bitable_form_auto_location_field" : "LARK-PSDA-bitable_card_auto_location_field"
        case .autoLocateAuth:
            return isInForm ? "LARK-PSDA-bitable_form_auto_location_field_auth" : "LARK-PSDA-bitable_card_auto_location_field_auth"
        case .mapAuth:
            return isInForm ? "LARK-PSDA-bitable_form_map_location_field" : "LARK-PSDA-bitable_card_map_location_field"
        }
    }
}
